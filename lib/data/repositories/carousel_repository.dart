import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/carousel_slide_model.dart';
import 'dart:developer';

class CarouselRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CarouselSlideModel>> fetchSlides() async {
    try {
      final snapshot = await _firestore
          .collection('carousel_slides')
          .where('is_active', isEqualTo: true)
          .orderBy('order_index', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is part of the map
        return CarouselSlideModel.fromJson(data);
      }).toList();
    } catch (e) {
      log('Error fetching slides from Firestore: $e');
      return [];
    }
  }

  // Admin methods implementation for Flutter Admin Screen
  // (In case the user still wants to use the Flutter Admin Screen as well)
  Future<List<CarouselSlideModel>> fetchAllSlidesAdmin() async {
    try {
      final snapshot = await _firestore
          .collection('carousel_slides')
          .orderBy('order_index', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CarouselSlideModel.fromJson(data);
      }).toList();
    } catch (e) {
      log('Error fetching admin slides from Firestore: $e');
      rethrow;
    }
  }

  Future<void> addSlide(CarouselSlideModel slide) async {
    try {
      final data = slide.toJson();
      // Remove ID from data as Firestore generates it, or use set if ID is provided
      data.remove('id');
      data['created_at'] = FieldValue.serverTimestamp();

      await _firestore.collection('carousel_slides').add(data);
    } catch (e) {
      log('Error adding slide: $e');
      rethrow;
    }
  }

  Future<void> updateSlide(String id, Map<String, dynamic> updates) async {
    try {
      if (updates.containsKey('id')) updates.remove('id');
      updates['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection('carousel_slides').doc(id).update(updates);
    } catch (e) {
      log('Error updating slide: $e');
      rethrow;
    }
  }

  Future<void> deleteSlide(String id) async {
    try {
      await _firestore.collection('carousel_slides').doc(id).delete();
    } catch (e) {
      log('Error deleting slide: $e');
      rethrow;
    }
  }
}
