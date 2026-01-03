class Actor {
  final String handle; // e.g. alice@nebula.local or alice@mastodon.social
  final String displayName;
  final String type; // e.g. "Person"
  final String? publicKey;
  final String? avatarUrl;

  const Actor({
    required this.handle,
    required this.displayName,
    required this.type,
    this.publicKey,
    this.avatarUrl,
  });

  factory Actor.fromMap(Map<String, dynamic> map) {
    return Actor(
      handle: map['handle'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      type: map['type'] as String? ?? 'Person',
      publicKey: map['publicKey'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'handle': handle,
      'displayName': displayName,
      'type': type,
      if (publicKey != null) 'publicKey': publicKey,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

  Actor copyWith({
    String? handle,
    String? displayName,
    String? type,
    String? publicKey,
    String? avatarUrl,
  }) {
    return Actor(
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      publicKey: publicKey ?? this.publicKey,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
