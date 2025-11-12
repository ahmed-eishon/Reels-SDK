/// Domain Entity: User
///
/// Represents a user/creator in the application.
/// This is a pure Dart class with no external dependencies.
class UserEntity {
  final String id;
  final String name;
  final String avatarUrl;

  const UserEntity({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
