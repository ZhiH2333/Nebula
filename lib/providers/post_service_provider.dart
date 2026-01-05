import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/post_service.dart';

final postServiceProvider = Provider<PostService>((ref) {
  return PostService();
});
