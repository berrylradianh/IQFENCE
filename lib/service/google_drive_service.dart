import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:iqfence/config/drive_config.dart';

class GoogleDriveService {
  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      final authClient = await clientViaServiceAccount(credentials, scopes);
      final driveApi = drive.DriveApi(authClient);

      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [dotenv.env['GOOGLE_DRIVE_FOLDER_ID']!];

      final fileContent = imageFile.openRead();
      final media = drive.Media(fileContent, imageFile.lengthSync());

      final uploadedFile = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      await driveApi.permissions.create(
        drive.Permission()
          ..type = 'anyone'
          ..role = 'reader',
        uploadedFile.id!,
      );

      final fileInfo =
          await driveApi.files.get(uploadedFile.id!, $fields: 'webViewLink');
      final webViewLink = (fileInfo as drive.File).webViewLink;

      authClient.close();
      return webViewLink;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  String getDirectImageUrl(String url) {
    final RegExp regExp = RegExp(r'file/d/([a-zA-Z0-9_-]+)/');
    final match = regExp.firstMatch(url);
    if (match != null) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return url;
  }
}
