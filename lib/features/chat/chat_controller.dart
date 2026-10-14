import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/data/providers.dart';

/// Live match list for the signed-in user.
///
/// In Riverpod 3 every provider is auto-disposed by default, so no
/// `.autoDispose` modifier is needed here.
final matchesProvider = StreamProvider<List<Match>>((ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream<List<Match>>.value(const <Match>[]);
  return ref.watch(matchRepositoryProvider).watchMatches(userId);
});

/// Live messages of a single match.
final messagesProvider = StreamProvider.family<List<Message>, String>((
  ref,
  String matchId,
) {
  return ref.watch(matchRepositoryProvider).watchMessages(matchId);
});

/// Chat actions: sending, reading and unmatching.
class ChatController {
  const ChatController(this._ref);

  final Ref _ref;

  Future<void> send({
    required String matchId,
    required String senderId,
    required String body,
  }) async {
    await _ref
        .read(matchRepositoryProvider)
        .sendMessage(matchId: matchId, senderId: senderId, body: body);
  }

  Future<void> markAsRead({
    required String matchId,
    required String userId,
  }) async {
    await _ref
        .read(matchRepositoryProvider)
        .markAsRead(matchId: matchId, userId: userId);
  }

  Future<void> unmatch(String matchId) async {
    await _ref.read(matchRepositoryProvider).unmatch(matchId);
  }
}

final chatControllerProvider = Provider<ChatController>(
  (ref) => ChatController(ref),
);
