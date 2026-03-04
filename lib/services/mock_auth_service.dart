import '../mock/mock_users.dart';

class MockUser {
  final String name;
  final String username;

  const MockUser({
    required this.name,
    required this.username,
  });

  factory MockUser.fromJson(Map<String, dynamic> json) {
    return MockUser(
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
    );
  }
}

class MockAuthService {
  static Future<MockUser?> signIn({
    required String username,
    required String password,
  }) async {
    // tiny delay to simulate network
    await Future.delayed(const Duration(milliseconds: 300));

    for (final u in mockUsersJson) {
      final uName = (u['username'] ?? '').toString();
      final uPass = (u['password'] ?? '').toString();

      if (uName == username && uPass == password) {
        return MockUser.fromJson(u);
      }
    }

    return null;
  }
}