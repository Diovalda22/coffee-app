import 'package:flutter_dotenv/flutter_dotenv.dart';

final String baseDomain = dotenv.env['BASE_DOMAIN'] ?? '';
final String baseUrl = '$baseDomain/api';
final String baseImageUrl = '$baseDomain/storage/';
