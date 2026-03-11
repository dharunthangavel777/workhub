import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:work_hub/features/common/contract/models/contract.dart';

class ContractRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createContract({
    required String projectId,
    required double agreedBudget,
    required String paymentType,
    DateTime? startDate,
    DateTime? expectedCompletion,
    double platformFee = 0.0,
  }) async {
    try {
      final contractRef = _firestore.collection('contracts').doc();
      final contract = Contract(
        id: contractRef.id,
        projectId: projectId,
        agreedBudget: agreedBudget,
        paymentType: paymentType,
        startDate: startDate ?? DateTime.now(),
        expectedCompletion:
            expectedCompletion ?? DateTime.now().add(const Duration(days: 30)),
        platformFee: platformFee,
        createdAt: DateTime.now(),
      );

      await contractRef.set(contract.toMap());

      await _firestore.collection('projects').doc(projectId).update({
        'contractId': contractRef.id,
        'status': 'contract_pending',
      });

      return contractRef.id;
    } catch (e) {
      debugPrint("Create Contract Error: $e");
      throw Exception("Failed to create contract: $e");
    }
  }

  Future<void> acceptContract(
    String contractId,
    String userId,
    String role,
  ) async {
    try {
      final updates = {
        if (role == 'owner') 'ownerAccepted': true,
        if (role == 'worker') 'workerAccepted': true,
        '${role}AcceptedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('contracts').doc(contractId).update(updates);

      final contractDoc =
          await _firestore.collection('contracts').doc(contractId).get();
      final data = contractDoc.data();
      if (data != null &&
          data['ownerAccepted'] == true &&
          data['workerAccepted'] == true) {
        await _firestore.collection('contracts').doc(contractId).update({
          'status': 'active',
          'activatedAt': FieldValue.serverTimestamp(),
        });

        final projectId = data['projectId'];
        await _firestore.collection('projects').doc(projectId).update({
          'status': 'active',
        });
      }
    } catch (e) {
      debugPrint("Accept Contract Error: $e");
      throw Exception("Failed to accept contract: $e");
    }
  }

  Future<Contract?> getContract(String contractId) async {
    try {
      final doc =
          await _firestore.collection('contracts').doc(contractId).get();
      if (doc.exists && doc.data() != null) {
        return Contract.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint("Get Contract Error: $e");
      return null;
    }
  }

  Future<Contract?> getContractByProjectId(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection('contracts')
          .where('projectId', isEqualTo: projectId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Contract.fromMap(doc.id, doc.data());
      }
      return null;
    } catch (e) {
      debugPrint("Get Contract By Project Error: $e");
      return null;
    }
  }

  Future<void> depositToEscrow({
    required String projectId,
    required double amount,
    required String paymentSessionId,
    required String userId,
  }) async {
    try {
      final projectRef = _firestore.collection('projects').doc(projectId);

      await _firestore.runTransaction((transaction) async {
        final projectDoc = await transaction.get(projectRef);
        final currentEscrow =
            (projectDoc.data()?['escrowBalance'] ?? 0.0).toDouble();

        transaction.update(projectRef, {
          'escrowBalance': currentEscrow + amount,
          'lastEscrowDeposit': FieldValue.serverTimestamp(),
        });

        final depositRef = projectRef.collection('escrow_deposits').doc();
        transaction.set(depositRef, {
          'amount': amount,
          'paymentSessionId': paymentSessionId,
          'depositedBy': userId,
          'depositedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint("Deposit to Escrow Error: $e");
      throw Exception("Failed to deposit to escrow: $e");
    }
  }

  Future<double> getEscrowBalance(String projectId) async {
    try {
      final doc = await _firestore.collection('projects').doc(projectId).get();
      return (doc.data()?['escrowBalance'] ?? 0.0).toDouble();
    } catch (e) {
      debugPrint("Get Escrow Balance Error: $e");
      return 0.0;
    }
  }
}



