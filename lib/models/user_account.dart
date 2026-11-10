enum AuthProviderType {
  none,
  google,
  microsoft,
}

class UserAccount {
  final String displayName;
  final String email;
  final String avatarUrl;
  final AuthProviderType provider;
  final DateTime lastSync;
  final bool isConnected;

  const UserAccount({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.provider,
    required this.lastSync,
    this.isConnected = true,
  });

  static UserAccount defaultGuest() {
    return UserAccount(
      displayName: 'Local User',
      email: 'offline.workspace@greensoft.local',
      avatarUrl: '',
      provider: AuthProviderType.none,
      lastSync: DateTime.now(),
      isConnected: false,
    );
  }

  static UserAccount mockGoogle(String name, String email) {
    return UserAccount(
      displayName: name.isNotEmpty ? name : 'Sachinthaka Sandaruwan',
      email: email.isNotEmpty ? email : 'sachinthaka@gmail.com',
      avatarUrl: 'G',
      provider: AuthProviderType.google,
      lastSync: DateTime.now(),
      isConnected: true,
    );
  }

  static UserAccount mockMicrosoft(String name, String email) {
    return UserAccount(
      displayName: name.isNotEmpty ? name : 'Sachinthaka Sandaruwan',
      email: email.isNotEmpty ? email : 'sachinthaka@outlook.com',
      avatarUrl: 'M',
      provider: AuthProviderType.microsoft,
      lastSync: DateTime.now(),
      isConnected: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'email': email,
        'avatarUrl': avatarUrl,
        'provider': provider.index,
        'lastSync': lastSync.toIso8601String(),
        'isConnected': isConnected,
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        displayName: json['displayName'] ?? 'Local User',
        email: json['email'] ?? 'offline@greensoft.local',
        avatarUrl: json['avatarUrl'] ?? '',
        provider: AuthProviderType.values[json['provider'] ?? 0],
        lastSync: json['lastSync'] != null
            ? DateTime.tryParse(json['lastSync']) ?? DateTime.now()
            : DateTime.now(),
        isConnected: json['isConnected'] ?? false,
      );
}
