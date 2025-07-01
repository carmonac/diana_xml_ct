import 'package:xml/xml.dart';

import 'package:diana/diana.dart';

@ContentTypeSerializer(['application/xml', 'text/xml'])
class XmlContentType extends ContentType with Serializable, Deserializable {
  XmlContentType(super.contentTypes);

  @override
  Future deserialize(DianaRequest request, Type type) async {
    try {
      final bodyString = await request.readAsString();

      if (bodyString.isEmpty) {
        return null;
      }

      // Parse the XML
      final document = XmlDocument.parse(bodyString);

      // Check if the root element contains a list of items
      if (type.toString().startsWith('List<')) {
        final elementTypeName = type
            .toString()
            .replaceFirst('List<', '')
            .replaceFirst('>', '');

        // Look for repeating child elements that could represent a list
        final rootElement = document.rootElement;
        final childElements = rootElement.children
            .whereType<XmlElement>()
            .toList();

        if (childElements.isNotEmpty) {
          final elementType = _findTypeByName(elementTypeName);
          if (elementType != null) {
            final items = childElements.map((element) {
              final xmlMap = _xmlToMap(element);
              return _deserializeByType(xmlMap, elementType);
            }).toList();

            // Use List.castFrom to create a properly typed list
            return List.castFrom<dynamic, dynamic>(items);
          }

          // Fallback if type is not found
          return childElements.map((e) => _xmlToMap(e)).toList();
        }
      }

      final xmlMap = _xmlToMap(document.rootElement);
      return _deserializeByType(xmlMap, type);
    } catch (e) {
      throw BadRequestException('Invalid XML body: $e');
    }
  }

  dynamic _deserializeByType(Map<String, dynamic> xmlMap, Type type) {
    if (DtoRegistry.isRegistered(type)) {
      return DtoRegistry.deserializeByType(xmlMap, type);
    } else if (type == String) {
      return xmlMap['#text']?.toString() ?? '';
    } else if (type == int) {
      return int.tryParse(xmlMap['#text']?.toString() ?? '') ?? 0;
    } else if (type == double) {
      return double.tryParse(xmlMap['#text']?.toString() ?? '') ?? 0.0;
    } else if (type == bool) {
      return xmlMap['#text']?.toString().toLowerCase() == 'true';
    }
    // Fallback for unsupported types
    return xmlMap;
  }

  Map<String, dynamic> _xmlToMap(XmlElement element) {
    final Map<String, dynamic> result = {};

    // Add attributes as properties with @ prefix
    for (final attribute in element.attributes) {
      result['@${attribute.name.local}'] = attribute.value;
    }

    // Process child elements
    final Map<String, List<dynamic>> children = {};

    for (final child in element.children) {
      if (child is XmlElement) {
        final childName = child.name.local;

        if (!children.containsKey(childName)) {
          children[childName] = [];
        }

        // If element has only text content, use the text value
        if (child.children.length == 1 && child.children.first is XmlText) {
          final textValue = child.innerText.trim();
          if (textValue.isNotEmpty) {
            children[childName]!.add(textValue);
          } else {
            children[childName]!.add(_xmlToMap(child));
          }
        } else {
          children[childName]!.add(_xmlToMap(child));
        }
      } else if (child is XmlText) {
        final textValue = child.value.trim();
        if (textValue.isNotEmpty) {
          result['#text'] = textValue;
        }
      }
    }

    // Convert single-item lists to direct values
    for (final entry in children.entries) {
      if (entry.value.length == 1) {
        result[entry.key] = entry.value.first;
      } else {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  @override
  serialize(object) {
    if (object == null) {
      return '<null/>';
    }

    if (object is List) {
      final buffer = StringBuffer();
      String rootElementName = 'items';
      String itemElementName = 'item';

      if (object.isNotEmpty && object.first != null) {
        final customOptions = DtoRegistry.getCustomOptions(object.first);
        if (customOptions != null) {
          rootElementName = customOptions['list'] ?? 'items';
          itemElementName = customOptions['single'] ?? 'item';
        }
      }

      buffer.write('<$rootElementName>');

      for (final item in object) {
        if (item != null && DtoRegistry.isRegistered(item.runtimeType)) {
          final serializedData = DtoRegistry.serialize(item);
          if (serializedData != null) {
            buffer.write(_mapToXml(itemElementName, serializedData));
          }
        } else {
          buffer.write(_serializeItem(itemElementName, item));
        }
      }

      buffer.write('</$rootElementName>');
      return buffer.toString();
    }

    if (object is Map<String, dynamic>) {
      return _mapToXml('root', object);
    }

    if (DtoRegistry.isRegistered(object.runtimeType)) {
      final serializedData = DtoRegistry.serialize(object);
      if (serializedData != null) {
        String rootElementName = 'root';
        final customOptions = DtoRegistry.getCustomOptions(object);
        if (customOptions != null) {
          rootElementName = customOptions['single'] ?? 'root';
        }
        return _mapToXml(rootElementName, serializedData);
      }
    }

    if (object is String || object is num || object is bool) {
      return '<value>$object</value>';
    }

    return '<value>${object.toString()}</value>';
  }

  String _serializeItem(String elementName, dynamic item) {
    if (item == null) {
      return '<$elementName/>';
    }

    if (DtoRegistry.isRegistered(item.runtimeType)) {
      final serializedData = DtoRegistry.serialize(item);
      if (serializedData != null) {
        return _mapToXml(elementName, serializedData);
      }
    }

    if (item is Map<String, dynamic>) {
      return _mapToXml(elementName, item);
    }

    if (item is List) {
      final buffer = StringBuffer();
      buffer.write('<$elementName>');
      for (int i = 0; i < item.length; i++) {
        buffer.write(_serializeItem('item', item[i]));
      }
      buffer.write('</$elementName>');
      return buffer.toString();
    }

    return '<$elementName>$item</$elementName>';
  }

  String _mapToXml(String rootName, Map<String, dynamic> map) {
    final buffer = StringBuffer();
    buffer.write('<$rootName');

    for (final entry in map.entries) {
      if (entry.key.startsWith('@')) {
        final attributeName = entry.key.substring(1);
        buffer.write(' $attributeName="${entry.value}"');
      }
    }
    buffer.write('>');

    if (map.containsKey('#text')) {
      buffer.write(map['#text']);
    }

    for (final entry in map.entries) {
      if (!entry.key.startsWith('@') && entry.key != '#text') {
        final value = entry.value;
        if (value is List) {
          for (final item in value) {
            if (item is Map<String, dynamic>) {
              buffer.write(_mapToXml(entry.key, item));
            } else {
              buffer.write('<${entry.key}>$item</${entry.key}>');
            }
          }
        } else if (value is Map<String, dynamic>) {
          buffer.write(_mapToXml(entry.key, value));
        } else {
          buffer.write('<${entry.key}>$value</${entry.key}>');
        }
      }
    }

    buffer.write('</$rootName>');
    return buffer.toString();
  }

  Type? _findTypeByName(String typeName) {
    switch (typeName) {
      case 'String':
        return String;
      case 'int':
        return int;
      case 'double':
        return double;
      case 'bool':
        return bool;
      case 'num':
        return num;
      case 'Object':
        return Object;
      case 'dynamic':
        return dynamic;
    }
    return DtoRegistry.findTypeByName(typeName);
  }
}
