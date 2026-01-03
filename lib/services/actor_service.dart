import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/actor_model.dart';

class ActorService {
  static final _users = FirebaseFirestore.instance.collection('users');

  /// Ensure the user document has at least one actor. If none exists,
  /// create a default actor with handle: {displayName}@nebula.local (fallback to uid prefix).
  /// Returns the list of actors for the user (may be from cache when offline).
  static Future<List<Actor>> ensureDefaultActorsForUser({
    required String uid,
    required String displayName,
    required String username,
  }) async {
    try {
      final docRef = _users.doc(uid);
      final docSnap = await docRef.get();

      Map<String, dynamic>? data = docSnap.data();
      final rawActors =
          (data?['actors'] as List<dynamic>?)?.cast<Map<String, dynamic>>();

      if (rawActors != null && rawActors.isNotEmpty) {
        // convert and return
        return rawActors.map((m) => Actor.fromMap(m)).toList();
      }

      // Build a default handle
      String handleName = displayName.isNotEmpty ? displayName : username;
      if (handleName.isEmpty) {
        // fallback to first 6 chars of uid
        handleName = uid.substring(0, uid.length >= 6 ? 6 : uid.length);
      }
      final handle = '$handleName@nebula.local';

      final defaultActor = Actor(
        handle: handle,
        displayName: displayName.isNotEmpty ? displayName : handleName,
        type: 'Person',
        publicKey: null,
        avatarUrl: null,
      );

      // merge into users doc, but ensure offline-safe (set with merge)
      await docRef.set({
        'actors': [defaultActor.toMap()],
        'actorInitializedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return [defaultActor];
    } catch (e) {
      // On errors (including offline read issues), return an empty list gracefully
      return [];
    }
  }
}
