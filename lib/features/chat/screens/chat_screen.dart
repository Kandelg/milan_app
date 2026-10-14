import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/data/providers.dart';
import 'package:milan_app/features/chat/chat_controller.dart';

/// Real-time conversation inside one match.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Mark incoming messages as read once the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref
        .read(chatControllerProvider)
        .markAsRead(matchId: widget.matchId, userId: userId);
  }

  Future<void> _send() async {
    final String body = _input.text.trim();
    final String? userId = ref.read(currentUserIdProvider);
    if (body.isEmpty || userId == null || _sending) return;

    setState(() => _sending = true);
    _input.clear();

    try {
      await ref
          .read(chatControllerProvider)
          .send(matchId: widget.matchId, senderId: userId, body: body);
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, 'Message not sent: $error', error: true);
      // Put the text back so the user does not lose it.
      _input.text = body;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Picks an image, uploads it under the caller's folder and sends its URL
  /// as a normal message (the bubble renders it inline).
  Future<void> _sendPhoto() async {
    if (_sending) return;
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _sending = true);
    try {
      final storage = ref.read(storageRepositoryProvider);
      final file = await storage.pickImage();
      if (file == null) {
        if (mounted) setState(() => _sending = false);
        return;
      }
      final bytes = await file.readAsBytes();
      final String url = await storage.uploadProfilePhoto(
        userId: '$userId/chat',
        fileName: file.name,
        bytes: bytes,
      );
      await ref
          .read(chatControllerProvider)
          .send(matchId: widget.matchId, senderId: userId, body: url);
    } catch (error) {
      if (mounted) {
        showAppSnack(context, 'Photo not sent: $error', error: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmUnmatch() async {
    final AppStrings strings = AppStrings.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.unmatch),
        content: const Text(
          'This removes the match and the conversation for both of you. '
          'This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.unmatch),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(chatControllerProvider).unmatch(widget.matchId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Message>> messages = ref.watch(
      messagesProvider(widget.matchId),
    );
    final String? myId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: MatchAppBarTitle(matchId: widget.matchId),
        actions: <Widget>[
          IconButton(
            tooltip: 'Unmatch',
            onPressed: _confirmUnmatch,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: GlassBackground(
        child: Column(
          children: <Widget>[
            Expanded(
              child: messages.when(
                loading: () => const AppLoader(),
                error: (Object error, StackTrace stack) =>
                    AppErrorView(error: error),
                data: (List<Message> list) {
                  if (list.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.waving_hand_outlined,
                      title: 'Say hello 👋',
                      message: 'You matched! Break the ice with a message.',
                    );
                  }

                  // Keep the newest message in view as the list grows.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );

                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: list.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Message message = list[index];
                      return _Bubble(
                        body: message.body,
                        mine: message.senderId == myId,
                        time: DateFormat.jm().format(message.createdAt),
                      );
                    },
                  );
                },
              ),
            ),
            _Composer(
              controller: _input,
              sending: _sending,
              onSend: _send,
              onPhoto: _sendPhoto,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the other participant's name and photo in the app bar.
class MatchAppBarTitle extends ConsumerWidget {
  const MatchAppBarTitle({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Match>> matches = ref.watch(matchesProvider);
    final List<Match> list = matches.value ?? const <Match>[];

    for (final Match match in list) {
      if (match.id == matchId) {
        return Row(
          children: <Widget>[
            AppAvatar(photoUrl: match.other.primaryPhoto, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                match.other.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        );
      }
    }

    return const Text('Chat');
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.body,
    required this.mine,
    required this.time,
  });

  final String body;
  final bool mine;
  final String time;

  static bool _isImageUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return false;
    final String path = uri.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isPhoto = _isImageUrl(body);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: isPhoto
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: mine
              ? const LinearGradient(
                  colors: <Color>[Color(0xFFFF9F43), Color(0xFFEE2E31)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: mine ? null : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mine ? 20 : 6),
            bottomRight: Radius.circular(mine ? 6 : 20),
          ),
          border: mine
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFFFF6B4A)
                  .withValues(alpha: mine ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  body,
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                  errorBuilder: (context, error, stack) => const SizedBox(
                    width: 220,
                    height: 120,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    body,
                    style: TextStyle(
                      color: mine
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: mine
                          ? Colors.white.withValues(alpha: 0.85)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onPhoto,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            IconButton(
              tooltip: strings.addPhoto,
              onPressed: sending ? null : onPhoto,
              icon: Icon(
                Icons.image_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: strings.typeMessage,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.55),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    tooltip: strings.sendMessage,
                    onPressed: sending ? null : onSend,
                    icon: sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

