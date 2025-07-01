import 'package:diana/diana.dart';
import 'package:diana_xml_ct/diana_xml_ct.dart';

@Dto({'single': 'user', 'list': 'users'})
class User {
  String? name;
  int? age;

  User({this.name, this.age});

  @override
  String toString() => 'User(name: $name, age: $age)';
}

@Controller()
class HomeController {
  // Response in XML example of a list of DTOs
  // The XML response for the list of Users would look like this:
  /*
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
  */
  @Get(path: '/user')
  Future<List<User>> getUsers() async {
    return [
      User(name: 'Alice', age: 30),
      User(name: 'Bob', age: 25),
      User(name: 'Charlie', age: 35),
    ];
  }

  // Response in XML example of a single DTO
  // The XML response for the User would look like this:
  /*
  <user>
    <name>Carlos</name>
    <age>38</age>
  </user>
  */
  @Get(path: '/user/<id>')
  Future<DianaResponse> getCar() async {
    return XmlResponse.send(User(name: 'Carlos', age: 38));
  }
}
