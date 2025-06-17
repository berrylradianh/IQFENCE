import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

final credentials = ServiceAccountCredentials.fromJson({
  "type": dotenv.env['SERVICE_ACCOUNT_TYPE'],
  "project_id": dotenv.env['SERVICE_ACCOUNT_PROJECT_ID'],
  "private_key_id": dotenv.env['SERVICE_ACCOUNT_PRIVATE_KEY_ID'],
  "private_key": dotenv.env['SERVICE_ACCOUNT_PRIVATE_KEY'],
  "client_email": dotenv.env['SERVICE_ACCOUNT_CLIENT_EMAIL'],
  "client_id": dotenv.env['SERVICE_ACCOUNT_CLIENT_ID'],
  "auth_uri": dotenv.env['SERVICE_ACCOUNT_AUTH_URI'],
  "token_uri": dotenv.env['SERVICE_ACCOUNT_TOKEN_URI'],
  "auth_provider_x509_cert_url":
      dotenv.env['SERVICE_ACCOUNT_AUTH_PROVIDER_X509_CERT_URL'],
  "client_x509_cert_url": dotenv.env['SERVICE_ACCOUNT_CLIENT_X509_CERT_URL'],
  "universe_domain": dotenv.env['SERVICE_ACCOUNT_UNIVERSE_DOMAIN'],
});

final scopes = [drive.DriveApi.driveFileScope];
