# Diana XML Content Type

A Diana framework extension that provides XML serialization and deserialization support for HTTP requests and responses.

## Features

- **XML Serialization**: Convert Dart objects and DTOs to XML format
- **XML Deserialization**: Parse XML content into Dart objects and DTOs
- **Custom Element Names**: Configure custom XML element names for DTOs using the `@Dto` annotation
- **List Support**: Handle lists of objects with appropriate XML structure
- **Primitive Types**: Support for basic types (String, int, double, bool)
- **Content Type Support**: Handles both `application/xml` and `text/xml` content types

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  diana_xml_ct: ^1.0.0
```

## Usage

### Basic Setup

No more setup is required

### Creating DTOs with Custom XML Names

Use the `@Dto` annotation with custom XML element names.

```dart
@Dto({'single': 'user', 'list': 'users'})
class User {
  String? name;
  int? age;

  User({this.name, this.age});

  @override
  String toString() => 'User(name: $name, age: $age)';
}
```

### Controller Examples

```dart
@Controller()
class HomeController {
  // Returns a list of users as XML
  @Get(path: '/users')
  Future<List<User>> getUsers() async {
    return [
      User(name: 'Alice', age: 30),
      User(name: 'Bob', age: 25),
      User(name: 'Charlie', age: 35),
    ];
  }

  // Returns a single user as XML
  @Get(path: '/user/<id>')
  Future<DianaResponse> getUser() async {
    return XmlResponse.send(User(name: 'Carlos', age: 38));
  }
}
```

### XML Response Helper

Use the `XmlResponse` helper for explicit XML responses:

```dart
import 'package:diana_xml_ct/diana_xml_ct.dart';

@Get(path: '/user/<id>')
Future<DianaResponse> getUser() async {
  final user = User(name: 'Carlos', age: 38);
  return XmlResponse.send(user, 201, /* add extra headers */);
}
```

## XML Output Examples

### Single DTO Object

For a single `User` object:

```xml
<user>
  <name>Carlos</name>
  <age>38</age>
</user>
```

### List of DTO Objects

For a list of `User` objects:

```xml
<users>
  <user>
    <name>Alice</name>
    <age>30</age>
  </user>
  <user>
    <name>Bob</name>
    <age>25</age>
  </user>
  <user>
    <name>Charlie</name>
    <age>35</age>
  </user>
</users>
```

### Primitive Types

- **String**: `<value>hello</value>`
- **Integer**: `<value>123</value>`
- **Boolean**: `<value>true</value>`
- **Null**: `<null/>`

### Lists of Primitives

```xml
<items>
  <item>a</item>
  <item>b</item>
  <item>c</item>
</items>
```

## Custom XML Element Names

The `@Dto` annotation accepts a map with custom XML element names:

- `'single'`: The XML element name for individual objects
- `'list'`: The XML root element name for lists of objects

```dart
@Dto({'single': 'user', 'list': 'users'})
class User {
  // ...
}
```

Without custom names, the default names are:
- Single objects: `<root>`
- Lists: `<items>` with `<item>` for each element

## Content Type Support

This package automatically handles:
- `application/xml`
- `text/xml`

## Dependencies

- `diana`: The Diana web framework
- `xml`: XML parsing and generation

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.