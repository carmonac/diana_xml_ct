import 'package:diana/diana.dart';

class XmlResponse {
  /// Creates a XML response with the given [data].
  static DianaResponse send(
    dynamic data, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    final contentType = 'application/xml';
    final serializer =
        ContentTypeRegistry.getContentTypeHandler(contentType) as Serializable;
    return DianaResponse(
      statusCode,
      body: serializer.serialize(data),
      headers: {'Content-Type': contentType, ...?headers},
    );
  }
}
