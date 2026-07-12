import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  FirebaseStorage get _storage => FirebaseStorage.instance;

  // Upload receipt image to Firebase Storage and return download URL
  Future<String> uploadReceipt(String localPath, String userId, String transactionId) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Receipt file not found at path: $localPath');
    }

    try {
      final ref = _storage.ref().child('users/$userId/receipts/$transactionId.jpg');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Delete receipt image from Firebase Storage by URL
  Future<void> deleteReceipt(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }
}
