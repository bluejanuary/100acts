import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get _base => dotenv.env['API_URL']!;

  // Auth
  static String get login       => '$_base/api/auth/mobile-login';
  static String get register    => '$_base/api/auth/register';
  static String get refresh     => '$_base/api/auth/refresh';
  static String get me          => '$_base/api/auth/me';

  // Config
  static String get config      => '$_base/api/config';

  // Acts
  static String get acts        => '$_base/api/acts';
  static String get allActs     => '$_base/api/acts/all';

  // Uploads
  static String get presign     => '$_base/api/uploads/presign';

  // Act by ID (for update / detail fetch)
  static String actById(String id) => '$_base/api/acts/$id';

  // Summary: minimal {id,lat,long,category} for the visible map bounds
  static String actsSummary({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) =>
      '$_base/api/acts/summary?swLat=$swLat&swLng=$swLng&neLat=$neLat&neLng=$neLng';
}
