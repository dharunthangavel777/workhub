import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/models/user_model.dart';
import '../../data/models/experience_model.dart';
import '../../data/services/storage_service.dart';
import '../services/notification_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ??
        '907495421370-7vf7inr3sm98canbn06vls0044qm2879.apps.googleusercontent.com',
  );
  final StorageService _storage = StorageService();

  UserModel? _userModel;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  bool _isGuest = false;

  UserModel? get userModel => _userModel;
  AuthStatus get status => _status;
  bool get isLoading =>
      _status == AuthStatus.loading || _status == AuthStatus.initial;
  bool get isAuthenticated => _auth.currentUser != null;
  bool get isGuest => _isGuest;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initUser();
  }

  Future<void> _initUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      _status = AuthStatus.authenticated;
      notifyListeners();
      await _fetchUserModel(user.uid);
      NotificationService().saveTokenToFirestore();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  Future<void> _fetchUserModel(String uid) async {
    _userSubscription?.cancel();
    _userSubscription =
        _firestore.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final user = UserModel.fromMap(snapshot.data()!);
        if (user.isBanned) {
          signOut();
          _errorMessage = "Your account has been permanently banned.";
          _status = AuthStatus.error;
          notifyListeners();
        } else {
          _userModel = user;
          _status = AuthStatus.authenticated;
          notifyListeners();
        }
      } else {
        // User exists in Auth but not in Firestore yet
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint("Auth Stream Error: $e");
      _errorMessage = "Failed to load profile: $e";
      _status = AuthStatus.error;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrCreateUser(User user) async {
    try {
      debugPrint("Checking/Creating user in Firestore at users/${user.uid}...");
      final docRef = _firestore.collection('users').doc(user.uid);
      // Timeout added to prevent black screen on emulator hang
      final doc = await docRef.get().timeout(const Duration(seconds: 15));

      if (!doc.exists) {
        debugPrint("User not found. Creating new user document...");
        _userModel = UserModel(
          uid: user.uid,
          email: user.email!,
          displayName: user.displayName ?? 'User',
          photoURL: user.photoURL,
          role: UserRole.worker,
          createdAt: DateTime.now(),
          isFirstLogin: true,
        );

        await docRef.set(_userModel!.toMap());
        debugPrint("User document created successfully.");
      } else {
        debugPrint("User found. Fetching existing document...");
        final data = doc.data()!;
        if (data['isBanned'] == true) {
          throw FirebaseAuthException(
              code: 'user-banned', message: 'Your account has been banned.');
        }
        _userModel = UserModel.fromMap(data);
      }

      // Ensure FCM token is saved before sending any notifications
      await NotificationService().saveTokenToFirestore();

      // Send Welcome Notification
      if (!doc.exists) {
        // New User
        await NotificationService().sendNotification(
          recipientId: user.uid,
          title: "Welcome to Work Hub! 🚀",
          body:
              "We're excited to have you on board. Start exploring jobs or projects now!",
        );
      } else {
        // Existing User
        await NotificationService().sendNotification(
          recipientId: user.uid,
          title: "Welcome Back! 👋",
          body: "Great to see you again. Check out what's new!",
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Firestore Error (Fetch/Create): $e");
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    User? firebaseUser;

    // Phase 1: Authentication
    try {
      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(authProvider);
        firebaseUser = userCredential.user;
      } else {
        // Clear previous session safely
        try {
          await _googleSignIn.signOut();
        } catch (_) {}

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return;
        }

        final googleAuth = await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: null,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        firebaseUser = userCredential.user;
      }

      if (firebaseUser != null) {
        debugPrint("Google Sign-In Succeeded: ${firebaseUser.uid}");
      }
    } catch (e) {
      debugPrint("Authentication Error: $e");

      // Silently handle user cancellation
      bool isCancelled = false;
      if (kIsWeb) {
        if (e is FirebaseAuthException &&
            (e.code == 'popup-closed-by-user' || e.code == 'cancelled')) {
          isCancelled = true;
        }
      } else {
        if (e.toString().contains('sign_in_canceled') ||
            (e is FirebaseAuthException &&
                e.code == 'account-exists-with-different-credential')) {
          // Note: account-exists is usually a different case, but for simplicity in "cancellation" flow
          // we are focusing on sign_in_canceled.
        }
        if (e.toString().contains('sign_in_canceled')) {
          isCancelled = true;
        }
      }

      if (isCancelled) {
        _status = AuthStatus.unauthenticated;
      } else {
        _errorMessage = "Failed to sign in: ${e.toString()}";
        _status = AuthStatus.error;
      }
      notifyListeners();
      return;
    }

    // Phase 2: Database Sync
    if (firebaseUser != null) {
      _isGuest = false;
      try {
        await _fetchOrCreateUser(firebaseUser);
        await _fetchUserModel(firebaseUser.uid);
      } catch (e) {
        debugPrint("Phase 2 Error (Sync Failed): $e");
        await signOut();
        _errorMessage =
            "Server sync timed out. Please check your internet and try again.";
        _status = AuthStatus.error;
        notifyListeners();
        return;
      }
    }
  }

  // Profile Completion Methods

  Future<bool> completeWorkerProfile({
    required String username,
    required String fullName,
    required String location,
    required String jobCategory,
    required List<String> skills,
    String? bio,
    List<ExperienceModel>? experiences,
    Map<String, dynamic>? portfolio,
  }) async {
    if (_userModel == null) return false;
    _setLoading(true);

    try {
      // 1. Update User Model
      final updatedUser = _userModel!.copyWith(
        displayName: fullName,
        username: username,
        bio: bio,
        location: location,
        jobCategory: jobCategory,
        skills: skills,
        resumeUrl: _userModel!.resumeUrl,
        isFirstLogin: false,
        experiences: experiences,
        portfolio: portfolio,
      );

      // 3. Save to Firestore
      await _firestore.collection('users').doc(_userModel!.uid).update({
        'displayName': fullName,
        'username': username,
        'bio': bio,
        'location': location,
        'jobCategory': jobCategory,
        'skills': skills,
        'resumeUrl': _userModel!.resumeUrl,
        'isFirstLogin': false,
        'experiences': experiences?.map((e) => e.toMap()).toList(),
        'portfolio': portfolio,
      });

      _userModel = updatedUser;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Complete Worker Profile Error: $e");
      _errorMessage = "Failed to complete profile: $e";
      _setLoading(false);
      return false;
    }
  }

  Future<bool> completeOwnerProfile({
    required String companyName,
    required String location,
    required String companyWebsite,
    required String managerName,
  }) async {
    if (_userModel == null) return false;
    _setLoading(true);

    try {
      // Update User Model
      final updatedUser = _userModel!.copyWith(
        companyName: companyName,
        location: location,
        companyWebsite: companyWebsite,
        managerName: managerName,
        displayName: companyName, // Update locally as well
        isFirstLogin: false,
      );

      // Save to Firestore
      await _firestore.collection('users').doc(_userModel!.uid).update({
        'companyName': companyName,
        'location': location,
        'companyWebsite': companyWebsite,
        'managerName': managerName,
        'displayName':
            companyName, // Sync for backwards compatibility or simple display
        'isFirstLogin': false,
      });

      _userModel = updatedUser;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Complete Owner Profile Error: $e");
      _errorMessage = "Failed to complete profile: $e";
      _setLoading(false);
      return false;
    }
  }

  Future<void> updateRole(UserRole role) async {
    if (_userModel == null) return;
    _setLoading(true);
    try {
      if (role == UserRole.businessOwner) {
        await convertToOwner();
      } else {
        await _firestore.collection('users').doc(_userModel!.uid).update({
          'role': role.name,
        });
        await _fetchUserModel(_userModel!.uid);
      }
    } catch (e) {
      debugPrint("Update Role Error: $e");
    } finally {
      _setLoading(false);
    }
  }

  /// Implementation of clean role switch from Worker to Owner
  Future<void> convertToOwner() async {
    if (_userModel == null) return;
    final uid = _userModel!.uid;

    try {
      // 1. Purge all worker-specific data from Firestore
      final updates = {
        'role': 'businessOwner',
        'isFirstLogin': true,
        'isVerified': false,
        'displayName': 'Company Owner', // Default for new owners
        'bannerImage': FieldValue.delete(),
        'username': FieldValue.delete(),
        'bio': FieldValue.delete(),
        'skills': FieldValue.delete(),
        'badges': FieldValue.delete(),
        'portfolio': FieldValue.delete(),
        'experiences': FieldValue.delete(),
        'resumeUrl': FieldValue.delete(),
        'jobCategory': FieldValue.delete(),
        'location': FieldValue.delete(), // Owner info will be set in onboarding
        'fullName': FieldValue.delete(),
        'totalExperience': FieldValue.delete(),
        'currentCompany': FieldValue.delete(),
        'expectedSalary': FieldValue.delete(),
        'jobPreference': FieldValue.delete(),
        'hourlyRate': FieldValue.delete(),
        'availability': FieldValue.delete(),
        'completedProjects': 0,
        'rating': 0.0,
        'totalEarnings': 0.0,
        'pendingClearance': 0.0,
        'ratingsCount': 0,
        'bankAccounts': FieldValue.delete(),
        'phoneNumber':
            FieldValue.delete(), // Often personal, owners use business contact
        'walletAddress': FieldValue.delete(),
        'savedJobIds': [],
        'savedProjectIds': [],
        'ownerRequestStatus': 'approved',
        'activeMode': 'job', // Owners typically stay in job mode or manage mode
      };

      await _firestore.collection('users').doc(uid).update(updates);

      // 2. Clear subcollections
      final appSub = await _firestore
          .collection('users')
          .doc(uid)
          .collection('applications')
          .get();
      for (var doc in appSub.docs) {
        await doc.reference.delete();
      }

      // 3. Remove application entries from job/project posts
      final jobPosts = await _firestore
          .collection('job_posts')
          .where('applicants.$uid', isNotEqualTo: null)
          .get();
      for (var doc in jobPosts.docs) {
        await doc.reference.update({'applicants.$uid': FieldValue.delete()});
      }

      final projectPosts = await _firestore
          .collection('project_posts')
          .where('applicants.$uid', isNotEqualTo: null)
          .get();
      for (var doc in projectPosts.docs) {
        await doc.reference.update({'applicants.$uid': FieldValue.delete()});
      }

      // Cleanup Reels
      final reels = await _firestore
          .collection('reels')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in reels.docs) {
        await doc.reference.delete();
      }

      // Cleanup Bids subcollection
      final bidsSub = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bids')
          .get();
      for (var doc in bidsSub.docs) {
        await doc.reference.delete();
      }

      // 4. Refresh local user model
      await _fetchUserModel(uid);
      notifyListeners();
    } catch (e) {
      debugPrint("Convert to Owner Error: $e");
      rethrow;
    }
  }

  Future<void> checkVerificationStatus() async {
    if (_userModel == null) return;
    try {
      await _fetchUserModel(_userModel!.uid);
      notifyListeners();
    } catch (e) {
      debugPrint("Check Verification Error: $e");
    }
  }

  Future<void> signOut() async {
    await _userSubscription?.cancel();
    _userSubscription = null;
    await _auth.signOut();
    await _googleSignIn.signOut();
    _userModel = null;
    _errorMessage = null;
    _isGuest = false;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void setGuestMode(bool value) {
    _isGuest = value;
    if (value) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> followUser(String targetUid) async {
    if (_userModel == null) return;
    final currentUid = _userModel!.uid;
    try {
      await _firestore.collection('users').doc(currentUid).update({
        'following.$targetUid': true,
      });
      await _firestore.collection('users').doc(targetUid).update({
        'followers.$currentUid': true,
      });
      await _fetchUserModel(currentUid);
    } catch (e) {
      debugPrint("Follow Error: $e");
    }
  }

  Future<void> unfollowUser(String targetUid) async {
    if (_userModel == null) return;
    final currentUid = _userModel!.uid;
    try {
      await _firestore.collection('users').doc(currentUid).update({
        'following.$targetUid': FieldValue.delete(),
      });
      await _firestore.collection('users').doc(targetUid).update({
        'followers.$currentUid': FieldValue.delete(),
      });
      await _fetchUserModel(currentUid);
    } catch (e) {
      debugPrint("Unfollow Error: $e");
    }
  }

  Future<void> updateBio(String bio) async {
    if (_userModel == null) return;
    try {
      await _firestore.collection('users').doc(_userModel!.uid).update({
        'bio': bio,
      });
      await _fetchUserModel(_userModel!.uid);
    } catch (e) {
      debugPrint("Update Bio Error: $e");
    }
  }

  Future<void> updateExperiences(List<ExperienceModel> experiences) async {
    if (_userModel == null) return;
    try {
      await _firestore.collection('users').doc(_userModel!.uid).update({
        'experiences': experiences.map((e) => e.toMap()).toList(),
      });
      await _fetchUserModel(_userModel!.uid);
    } catch (e) {
      debugPrint("Update Experiences Error: $e");
    }
  }

  Future<void> updateProfileImage(File imageFile) async {
    if (_userModel == null) return;
    // _setLoading(true);
    try {
      final url = await _storage.uploadProfileImage(_userModel!.uid, imageFile);
      if (url != null) {
        await _firestore.collection('users').doc(_userModel!.uid).update({
          'photoURL': url,
        });
        await _fetchUserModel(_userModel!.uid);
      }
    } catch (e) {
      debugPrint("Update Profile Image Error: $e");
    } finally {
      // _setLoading(false);
    }
  }

  Future<void> addPortfolioItem(String title, File imageFile) async {
    if (_userModel == null) return;
    // _setLoading(true);
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final url = await _storage.uploadPortfolioItem(
        _userModel!.uid,
        fileName,
        imageFile,
      );
      if (url != null) {
        final item = {'title': title, 'imageUrl': url};
        await _firestore.collection('users').doc(_userModel!.uid).update({
          'portfolio.$fileName': item,
        });
        await _fetchUserModel(_userModel!.uid);
      }
    } catch (e) {
      debugPrint("Add Portfolio Item Error: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateResume(File resumeFile) async {
    if (_userModel == null) return;
    _setLoading(true);
    try {
      final fileName =
          'resume_${DateTime.now().millisecondsSinceEpoch}.${resumeFile.path.split('.').last}';
      final path = 'users/${_userModel!.uid}/resumes/$fileName';

      final url = await _storage.uploadFile(path, resumeFile);
      if (url != null) {
        await _firestore.collection('users').doc(_userModel!.uid).update({
          'resumeUrl': url,
        });
        await _fetchUserModel(_userModel!.uid);
      }
    } catch (e) {
      debugPrint("Update Resume Error: $e");
      _errorMessage = "Failed to upload resume: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> switchWorkerMode(String mode) async {
    if (_userModel == null) return;
    try {
      await _firestore.collection('users').doc(_userModel!.uid).update({
        'activeMode': mode,
      });
      _userModel = _userModel!.copyWith(activeMode: mode);
      notifyListeners();
    } catch (e) {
      debugPrint("Switch Mode Error: $e");
    }
  }

  Future<bool> submitOwnerRequest(Map<String, dynamic> businessData) async {
    if (_userModel == null) return false;
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(_userModel!.uid).update({
        'ownerRequestStatus': 'pending',
        'ownerRequestData': businessData,
      });
      _userModel = _userModel!.copyWith(
        ownerRequestStatus: 'pending',
        ownerRequestData: businessData,
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Submit Owner Request Error: $e");
      _errorMessage = "Failed to submit request: $e";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserFields(Map<String, dynamic> updates) async {
    if (_userModel == null) return;
    // _setLoading(true);
    try {
      await _firestore.collection('users').doc(_userModel!.uid).update(updates);
      await _fetchUserModel(_userModel!.uid);
    } catch (e) {
      debugPrint("Update User Fields Error: $e");
      _errorMessage = "Failed to update profile: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markSubscriptionAsSeen() async {
    if (_userModel == null) return;
    try {
      await _firestore.collection('users').doc(_userModel!.uid).update({
        'hasSeenSubscription': true,
      });
      _userModel = _userModel!.copyWith(hasSeenSubscription: true);
      notifyListeners();
    } catch (e) {
      debugPrint("Mark Subscription Seen Error: $e");
    }
  }

  void _setLoading(bool value) {
    _status = value ? AuthStatus.loading : AuthStatus.authenticated;
    notifyListeners();
  }
}
