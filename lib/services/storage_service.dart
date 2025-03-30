import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import 'package:js/js.dart' if (dart.library.html) 'dart:js_util';

@JS()
@staticInterop
class PromiseJsImpl<T> {}

@JS()
@staticInterop
class JsObject {}

@JS()
@staticInterop
class AuthJsImpl {}

@JS()
@staticInterop
class UserJsImpl {}

@JS()
@staticInterop
class UserCredentialJsImpl {}

@JS()
@staticInterop
class ReferenceJsImpl {}

@JS()
@staticInterop
class FullMetadataJsImpl {}

@JS()
@staticInterop
class UploadTaskSnapshotJsImpl {}

@JS()
@staticInterop
class ListResultJsImpl {}

@JS()
@staticInterop
class SettableMetadataJsImpl {}

@JS()
@staticInterop
class ActionCodeInfoJsImpl {}

@JS()
@staticInterop
class IdTokenResultJsImpl {}

@JS()
@staticInterop
class ConfirmationResultJsImpl {}

@JS()
@staticInterop
class MultiFactorSessionJsImpl {}

@JS()
@staticInterop
class TotpSecretJsImpl {}

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  // Initialize Firebase Storage with custom settings if needed
  Future<void> initializeStorage() async {
    if (kIsWeb) {
      // Web-specific initialization
      _storage.setMaxUploadRetryTime(const Duration(seconds: 30));
      _storage.setMaxOperationRetryTime(const Duration(seconds: 30));
    }
  }

  // Upload file and get download URL
  Future<String?> uploadFile({
    required dynamic file, // File or Uint8List
    required String path,
    Map<String, String>? metadata,
  }) async {
    try {
      // Generate unique file name
      final String fileName = '${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}';
      final Reference ref = _storage.ref('$path/$fileName');

      UploadTask uploadTask;
      
      // Create metadata
      final SettableMetadata settableMetadata = SettableMetadata(
        contentType: 'application/octet-stream',
        customMetadata: metadata,
      );
      
      if (kIsWeb) {
        // Handle web upload
        uploadTask = ref.putData(file, settableMetadata);
      } else {
        // Handle mobile upload
        uploadTask = ref.putFile(file as File, settableMetadata);
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      final String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Delete file from storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Get file metadata
  Future<Map<String, dynamic>?> getFileMetadata(String fileUrl) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      final FullMetadata metadata = await ref.getMetadata();
      
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'created': metadata.timeCreated?.toIso8601String(),
        'updated': metadata.updated?.toIso8601String(),
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      print('Error getting file metadata: $e');
      return null;
    }
  }

  // Update file metadata
  Future<bool> updateFileMetadata(String fileUrl, Map<String, String> metadata) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      
      // Create a new SettableMetadata instance with the updated metadata
      final SettableMetadata newMetadata = SettableMetadata(
        customMetadata: metadata,
      );
      
      await ref.updateMetadata(newMetadata);
      return true;
    } catch (e) {
      print('Error updating file metadata: $e');
      return false;
    }
  }
} 