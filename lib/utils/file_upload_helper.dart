import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class FileUploadHelper {
  static final StorageService _storageService = StorageService();

  // Example: Upload a profile picture
  static Future<String?> uploadProfilePicture(dynamic file, String userId) async {
    try {
      // Initialize storage if not already initialized
      await _storageService.initializeStorage();

      // Add metadata
      final metadata = {
        'uploadedBy': userId,
        'uploadedAt': DateTime.now().toIso8601String(),
        'type': 'profile_picture'
      };

      // Upload file
      final downloadUrl = await _storageService.uploadFile(
        file: file,
        path: 'profile_pictures/$userId',
        metadata: metadata,
      );

      if (downloadUrl != null) {
        print('Profile picture uploaded successfully: $downloadUrl');
        return downloadUrl;
      } else {
        print('Failed to upload profile picture');
        return null;
      }
    } catch (e) {
      print('Error in uploadProfilePicture: $e');
      return null;
    }
  }

  // Example: Upload a document
  static Future<String?> uploadDocument(dynamic file, String userId, String documentType) async {
    try {
      await _storageService.initializeStorage();

      final metadata = {
        'uploadedBy': userId,
        'uploadedAt': DateTime.now().toIso8601String(),
        'type': documentType,
      };

      final downloadUrl = await _storageService.uploadFile(
        file: file,
        path: 'documents/$userId/$documentType',
        metadata: metadata,
      );

      if (downloadUrl != null) {
        print('Document uploaded successfully: $downloadUrl');
        
        // Get and print metadata
        final fileMetadata = await _storageService.getFileMetadata(downloadUrl);
        print('File metadata: $fileMetadata');
        
        return downloadUrl;
      } else {
        print('Failed to upload document');
        return null;
      }
    } catch (e) {
      print('Error in uploadDocument: $e');
      return null;
    }
  }

  // Example: Delete a file
  static Future<bool> deleteUploadedFile(String fileUrl) async {
    try {
      final result = await _storageService.deleteFile(fileUrl);
      if (result) {
        print('File deleted successfully');
      } else {
        print('Failed to delete file');
      }
      return result;
    } catch (e) {
      print('Error in deleteUploadedFile: $e');
      return false;
    }
  }

  // Example usage in a widget
  static Widget buildUploadButton({
    required BuildContext context,
    required String userId,
    required Function(String?) onUploadComplete,
  }) {
    return ElevatedButton(
      onPressed: () async {
        try {
          // Here you would implement file picking logic
          // For example, using file_picker package
          
          // For demonstration, we'll just show how the upload would work
          // Replace this with actual file picking logic
          if (kIsWeb) {
            // Web file handling
            // final result = await FilePicker.platform.pickFiles();
            // if (result != null) {
            //   final bytes = result.files.first.bytes!;
            //   final url = await uploadProfilePicture(bytes, userId);
            //   onUploadComplete(url);
            // }
          } else {
            // Mobile file handling
            // final File file = await pickFile();
            // final url = await uploadProfilePicture(file, userId);
            // onUploadComplete(url);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading file: $e')),
          );
        }
      },
      child: const Text('Upload File'),
    );
  }
} 