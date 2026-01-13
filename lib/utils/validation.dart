import 'response.dart';
import 'package:shelf/shelf.dart';

Response? requireFields(
    Map data, List<String> fields, {
  Map<String, String>? messages,
}) {
  for (final f in fields) {
    if (data[f] == null || (data[f] is String && (data[f] as String).trim().isEmpty)) {
      return badRequest(messages?[f] ?? '$f is required');
    }
  }
  return null;
}

