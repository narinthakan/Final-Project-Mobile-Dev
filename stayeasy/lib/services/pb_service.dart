import 'package:pocketbase/pocketbase.dart';

class PBService {
  static const baseUrl = 'http://127.0.0.1:8090';
  final PocketBase client = PocketBase(baseUrl);
}