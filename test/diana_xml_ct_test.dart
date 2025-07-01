import 'package:diana/diana.dart';
import 'package:diana_xml_ct/diana_xml_ct.dart';
import 'package:test/test.dart';

void main() {
  group('XmlContentType', () {
    final contentType = XmlContentType([]);

    // Mock DTO for testing
    group('DTOs', () {
      setUp(() {
        if (!DtoRegistry.isRegistered(User)) {
          DtoRegistry.registerDto<User>(
            fieldExtractor: (user) => {'id': user.id, 'name': user.name},
            fromMap: (json) => User(
              id: int.tryParse(json['id']?.toString() ?? ''),
              name: json['name'] as String,
            ),
          );
        }
      });

      test('serialize a single DTO object', () {
        final user = User()
          ..id = 1
          ..name = 'Test User';
        final result = contentType.serialize(user);
        expect(result, equals('<root><id>1</id><name>Test User</name></root>'));
      });

      test('deserialize a single DTO object', () async {
        final request = MockDianaRequest(
          '<User><id>1</id><name>Test User</name></User>',
        );
        final result = await contentType.deserialize(request, User) as User;
        expect(result.id, equals(1));
        expect(result.name, equals('Test User'));
      });

      test('serialize a list of DTO objects', () {
        final users = [
          User()
            ..id = 1
            ..name = 'User One',
          User()
            ..id = 2
            ..name = 'User Two',
        ];
        final result = contentType.serialize(users);
        expect(
          result,
          equals(
            '<items><item><id>1</id><name>User One</name></item><item><id>2</id><name>User Two</name></item></items>',
          ),
        );
      });

      test('deserialize a list of DTO objects', () async {
        final request = MockDianaRequest(
          '<users><User><id>1</id><name>User One</name></User><User><id>2</id><name>User Two</name></User></users>',
        );
        final result =
            await contentType.deserialize(
                  request,
                  TypeHelper<List<User>>().type,
                )
                as List;
        expect(result, isA<List>());
        expect(result.length, equals(2));
        expect(result[0], isA<User>());
        expect(result[1], isA<User>());
        expect((result[0] as User).name, equals('User One'));
        expect((result[1] as User).id, equals(2));
      });
    });

    group('DTOs with custom XML element names', () {
      setUp(() {
        if (!DtoRegistry.isRegistered(CustomUser)) {
          DtoRegistry.registerDto<CustomUser>(
            fieldExtractor: (user) => {'id': user.id, 'name': user.name},
            fromMap: (json) => CustomUser(
              id: int.tryParse(json['id']?.toString() ?? ''),
              name: json['name'] as String,
            ),
          );
        }
      });

      test('serialize a single DTO object with default element name', () {
        final user = CustomUser()
          ..id = 1
          ..name = 'Test User';
        final result = contentType.serialize(user);
        expect(result, equals('<root><id>1</id><name>Test User</name></root>'));
      });

      test('serialize a list of DTO objects with default element names', () {
        final users = [
          CustomUser()
            ..id = 1
            ..name = 'User One',
          CustomUser()
            ..id = 2
            ..name = 'User Two',
        ];
        final result = contentType.serialize(users);
        expect(
          result,
          equals(
            '<items><item><id>1</id><name>User One</name></item><item><id>2</id><name>User Two</name></item></items>',
          ),
        );
      });

      test('deserialize a list of custom DTO objects', () async {
        final request = MockDianaRequest(
          '<users><user><id>1</id><name>User One</name></user><user><id>2</id><name>User Two</name></user></users>',
        );
        final result =
            await contentType.deserialize(
                  request,
                  TypeHelper<List<CustomUser>>().type,
                )
                as List;
        expect(result, isA<List>());
        expect(result.length, equals(2));
        expect(result[0], isA<CustomUser>());
        expect(result[1], isA<CustomUser>());
        expect((result[0] as CustomUser).name, equals('User One'));
        expect((result[1] as CustomUser).id, equals(2));
      });
    });

    group('Primitives', () {
      test('serialize a string', () {
        final result = contentType.serialize('hello');
        expect(result, equals('<value>hello</value>'));
      });

      test('deserialize a string from a simple element', () async {
        final request = MockDianaRequest('<value>hello</value>');
        final result = await contentType.deserialize(request, String);
        expect(result, isA<String>());
        expect(result, contains('hello'));
      });

      test('serialize an integer', () {
        final result = contentType.serialize(123);
        expect(result, equals('<value>123</value>'));
      });

      test('deserialize an integer', () async {
        final request = MockDianaRequest('<value>123</value>');
        final result = await contentType.deserialize(request, int);
        expect(result, equals(123));
      });

      test('serialize a double', () {
        final result = contentType.serialize(123.45);
        expect(result, equals('<value>123.45</value>'));
      });

      test('deserialize a double', () async {
        final request = MockDianaRequest('<value>123.45</value>');
        final result = await contentType.deserialize(request, double);
        expect(result, equals(123.45));
      });

      test('serialize a boolean', () {
        final result = contentType.serialize(true);
        expect(result, equals('<value>true</value>'));
      });

      test('deserialize a boolean', () async {
        final request = MockDianaRequest('<value>true</value>');
        final result = await contentType.deserialize(request, bool);
        expect(result, isTrue);
      });

      test('serialize null', () {
        final result = contentType.serialize(null);
        expect(result, equals('<null/>'));
      });

      test('deserialize an empty body to null', () async {
        final request = MockDianaRequest('');
        final result = await contentType.deserialize(request, Object);
        expect(result, isNull);
      });
    });

    group('Lists of primitives', () {
      test('serialize a list of strings', () {
        final result = contentType.serialize(['a', 'b', 'c']);
        expect(
          result,
          equals('<items><item>a</item><item>b</item><item>c</item></items>'),
        );
      });

      test('deserialize a list of strings', () async {
        final request = MockDianaRequest(
          '<items><item>a</item><item>b</item></items>',
        );
        final result =
            await contentType.deserialize(
                  request,
                  TypeHelper<List<String>>().type,
                )
                as List;
        expect(result, isA<List<dynamic>>());
        expect(result, equals(['a', 'b']));
      });
    });
  });
}

class User {
  int? id;
  String? name;

  User({this.id, this.name});
}

class CustomUser {
  int? id;
  String? name;

  CustomUser({this.id, this.name});
}

class MockDianaRequest implements DianaRequest {
  final String body;

  MockDianaRequest(this.body);

  @override
  Future<String> readAsString() => Future.value(body);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TypeHelper<T> {
  Type get type => T;
}
