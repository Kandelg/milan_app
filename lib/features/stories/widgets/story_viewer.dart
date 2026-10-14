import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/core/constants.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/data/providers.dart';
import 'package:milan_app/features/discover/discover_controller.dart';
import 'package:milan_app/features/stories/story_helpers.dart';

/// Full-screen story viewer, Instagram-style.
class StoryViewer extends ConsumerStatefulWidget {
  const StoryViewer({
    super.key,
    required this.authors,
    required this.initialIndex,
  });

  final List<StoryAuthor> authors;
  final int initialIndex;

  static Future<void> show(
    BuildContext context, {
    required StoryAuthor author,
    required List<StoryAuthor> all,
  }) {
    final int index = all.indexWhere((StoryAuthor a) => a.userId == author.userId);
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      useSafeArea: false,
      builder: (_) => StoryViewer(
        authors: all,
        initialIndex: index < 0 ? 0 : index,
      ),
    );
  }

  @override
  ConsumerState<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<StoryViewer> {
  late int _authorIndex;
  int _storyIndex = 0;
  double _progress = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _authorIndex = widget.initialIndex;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  StoryAuthor get _author => widget.authors[_authorIndex];
  Story get _story => _author.stories[_storyIndex];

  void _startTimer() {
    _timer?.cancel();
    _progress = 0;
    const int ticks = 50;
    final int ms = kStoryPageDuration.inMilliseconds ~/ ticks;
    _timer = Timer.periodic(Duration(milliseconds: ms), (Timer t) {
      if (!mounted) return;
      setState(() => _progress += 1 / ticks);
      if (_progress >= 1) _nextStory();
    });
  }

  void _nextStory() {
    if (_storyIndex + 1 < _author.stories.length) {
      setState(() => _storyIndex++);
      _startTimer();
    } else if (_authorIndex + 1 < widget.authors.length) {
      setState(() {
        _authorIndex++;
        _storyIndex = 0;
      });
      _startTimer();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevStory() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _startTimer();
    } else if (_authorIndex > 0) {
      setState(() {
        _authorIndex--;
        _storyIndex = widget.authors[_authorIndex].stories.length - 1;
      });
      _startTimer();
    } else {
      _startTimer();
    }
  }

  Future<void> _delete() async {
    final AppStrings strings = AppStrings.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.deleteStory),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ref
          .read(storyControllerProvider.notifier)
          .deleteStory(_story.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) showAppSnack(context, '$error', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Story story = _story;
    final String? myId = ref.watch(currentUserIdProvider);
    final bool isMine = myId != null && story.userId == myId;

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _StoryBody(story: story),
          Row(
            children: <Widget>[
              Expanded(child: GestureDetector(onTap: _prevStory)),
              Expanded(child: GestureDetector(onTap: _nextStory)),
            ],
          ),
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _ProgressRow(
                  count: _author.stories.length,
                  current: _storyIndex,
                  progress: _progress,
                ),
                ListTile(
                  leading: AppAvatar(
                    photoUrl: _author.photoUrl,
                    radius: 20,
                  ),
                  title: Text(
                    _author.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    story.remainingLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (isMine)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white),
                          onPressed: _delete,
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo or coloured-text page of one story.
class _StoryBody extends StatelessWidget {
  const _StoryBody({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    if (story.isText) {
      return Container(
        color: Color(parseStoryColor(story.background)),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                story.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }
    final String? url = story.mediaUrl;
    if (url == null || url.isEmpty) {
      return const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
      );
    }
    // Plain Image.network keeps the viewer dependency-free (no extra
    // progress-bar wiring); caching is a nice-to-have here.
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
      ),
    );
  }
}

/// Segmented progress bars across the top of the viewer.
class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.count,
    required this.current,
    required this.progress,
  });

  final int count;
  final int current;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: List<Widget>.generate(
          count,
          (int i) => Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.white38,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: i < current
                    ? 1
                    : (i == current ? progress.clamp(0.0, 1.0) : 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

      