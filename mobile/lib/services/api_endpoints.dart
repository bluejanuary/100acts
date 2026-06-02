import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get _base => dotenv.env['API_URL']!;

  // Auth
  static String get login       => '$_base/api/auth/login';
  static String get register    => '$_base/api/auth/register';
  static String get refresh     => '$_base/api/auth/refresh';
  static String get me          => '$_base/api/auth/me';

  // Config
  static String get config      => '$_base/api/config';

  // Acts
  static String get acts        => '$_base/api/acts';

  // Uploads
  static String get presign     => '$_base/api/uploads/presign';
}
