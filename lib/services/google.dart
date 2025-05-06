import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';

class GoogleDriveService {
  // Replace with your actual folder ID and ensure the account is authenticated
  static const String _weddingFolderId = '1kjxzKUMCmwq1YMj1TlaMxM4VtBWIdL2B';
  static const String _imageMimeType = 'image/jpeg';

  // Load the service account credentials from assets
  Future<String> _loadServiceAccountJson() async {
    return await rootBundle.loadString('assets/service_account.json');
  }

  // Get authenticated HTTP client with service account
  Future<http.Client> _getAuthenticatedClient() async {
    final serviceAccountJson = await _loadServiceAccountJson();
    final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);

    return await clientViaServiceAccount(
        credentials, [drive.DriveApi.driveFileScope]);
  }

  // Upload an image to Google Drive
  // Added parameter to control whether shots should be decremented internally
  Future<String?> uploadImage(File imageFile, String fileName,
      {bool shouldDecrementShots = true}) async {
    try {
      final client = await _getAuthenticatedClient();
      final driveApi = drive.DriveApi(client);

      // Create a drive file
      var driveFile = drive.File();
      driveFile.name = fileName;
      driveFile.parents = [_weddingFolderId];

      // Upload file to drive
      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(
          imageFile.openRead(),
          await imageFile.length(),
          contentType: _imageMimeType,
        ),
      );

      return response.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading to Google Drive: $e');
      }
      return null;
    }
  }
}
