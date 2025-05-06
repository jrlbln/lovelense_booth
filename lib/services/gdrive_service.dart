import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:url_launcher/url_launcher.dart';

// Provider for the Google Drive service
final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService();
});

class GoogleDriveService {
  // The folder ID where photos will be uploaded
  static const String _photosFolder = '16PimG6RSsGPfHgywc6Ma1wKKhtcdMoyX';
  static const String _imageMimeType = 'image/jpeg';

  // Load the service account credentials from assets
  Future<String> _loadServiceAccountJson() async {
    return await rootBundle.loadString('assets/service_account.json');
  }

  // Get authenticated HTTP client with service account
  Future<http.Client> _getAuthenticatedClient() async {
    try {
      final serviceAccountJson = await _loadServiceAccountJson();
      final credentials =
          ServiceAccountCredentials.fromJson(serviceAccountJson);

      return await clientViaServiceAccount(
          credentials, [drive.DriveApi.driveFileScope]);
    } catch (e) {
      if (kDebugMode) {
        print('Authentication error: $e');
      }
      rethrow;
    }
  }

  // Upload an image to Google Drive
  Future<String?> uploadImage(String imagePath,
      {String? customFileName}) async {
    try {
      // Handle data URIs for web
      Uint8List imageBytes;

      if (kIsWeb && imagePath.startsWith('data:')) {
        // Extract bytes from data URI
        final dataUri = Uri.parse(imagePath);
        final base64Data = dataUri.data?.contentAsString() ?? '';
        imageBytes = base64Decode(base64Data.split(',').last);
      } else {
        final imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          throw Exception('File not found: $imagePath');
        }
        imageBytes = await imageFile.readAsBytes();
      }

      final client = await _getAuthenticatedClient();
      final driveApi = drive.DriveApi(client);

      // Create a drive file
      final fileName = customFileName ??
          'lovelense_${DateTime.now().millisecondsSinceEpoch}.jpg';
      var driveFile = drive.File();
      driveFile.name = fileName;
      driveFile.parents = [_photosFolder];

      // Upload file to drive
      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(
          Stream.fromIterable([imageBytes]),
          imageBytes.length,
          contentType: _imageMimeType,
        ),
      );

      // Make the file viewable to anyone with the link
      await driveApi.permissions.create(
        drive.Permission()
          ..role = 'reader'
          ..type = 'anyone',
        response.id!,
      );

      // Get the web view link
      final updatedFile = await driveApi.files.get(
        response.id!,
        $fields: 'webViewLink',
      ) as drive.File;

      // Close the client
      client.close();

      return updatedFile.webViewLink;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading to Google Drive: $e');
      }
      return null;
    }
  }
}
