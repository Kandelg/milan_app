import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/core/widgets.dart';
import 'package:milan_app/features/discover/discover_controller.dart';
import 'package:milan_app/features/stories/story_helpers.dart';

/// Bottom sheet for posting a story: photo (gallery) or written status.
class StoryComposer extends ConsumerStatefulWidget {
  const StoryComposer({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const StoryComposer(),
    );
  }

  @override
  ConsumerState<StoryComposer> createState() => _StoryComposerState();
}

class _StoryComposerState extends ConsumerState<StoryComposer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _text = TextEditingController();
  String _background = kStoryBackgrounds.first;
  Uint8List? _photoBytes;
  String? _photoName;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1440,
    );
    if (file == null) return;
    setState(() {
      _photoBytes = null;
      _photoName = file.name;
    });
    final Uint8List bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _photoBytes = bytes);
  }

  Future<void> _submitPhoto() async {
    final Uint8List? bytes = _photoBytes;
    final String? name = _photoName;
    if (bytes == null || name == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(storyControllerProvider.notifier)
          .postPhoto(fileName: name, bytes: bytes);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        showAppSnack(context, '$error', error: true);
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _submitText() async {
    if (_text.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(storyControllerProvider.notifier)
          .postText(body: _text.text, background: _background);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        showAppSnack(context, '$error', error: true);
        setState(() => _busy = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            strings.addStory,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            tabs: <Widget>[
              Tab(icon: const Icon(Icons.photo), text: strings.photoStory),
              Tab(icon: const Icon(Icons.edit), text: strings.textStory),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 340,
            child: TabBarView(
              controller: _tabs,
              children: <Widget>[
                _PhotoTab(
                  bytes: _photoBytes,
                  busy: _busy,
                  onPick: _pickPhoto,
                  onSubmit: _submitPhoto,
                  shareLabel: strings.share,
                ),
                _TextTab(
                  controller: _text,
                  background: _background,
                  busy: _busy,
                  hint: strings.writeSomething,
                  shareLabel: strings.share,
                  onBackground: (String c) =>
                      setState(() => _background = c),
                  onSubmit: _submitText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTab extends StatelessWidget {
  const _PhotoTab({
    required this.bytes,
    required this.busy,
    required this.onPick,
    required this.onSubmit,
    required this.shareLabel,
  });

  final Uint8List? bytes;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onSubmit;
  final String shareLabel;

  @override
  Widget build(BuildContext context) {
    final Uint8List? preview = bytes;
    return Column(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: busy ? null : onPick,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.antiAlias,
              child: preview == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.add_photo_alternate_outlined, size: 48),
                      ],
                    )
                  : Image.memory(preview, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GlassButton(
          label: shareLabel,
          onPressed: (preview == null || busy) ? null : onSubmit,
        ),
      ],
    );
  }
}

class _TextTab extends StatelessWidget {
  const _TextTab({
    required this.controller,
    required this.background,
    required this.busy,
    required this.hint,
    required this.shareLabel,
    required this.onBackground,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String background;
  final bool busy;
  final String hint;
  final String shareLabel;
  final ValueChanged<String> onBackground;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Color(parseStoryColor(background)),
            ),
            child: TextField(
              controller: controller,
              enabled: !busy,
              maxLines: null,
              maxLength: 280,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white70),
                border: InputBorder.none,
                counterStyle: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: kStoryBackgrounds.map((String c) {
            final bool selected = c == background;
            return GestureDetector(
              onTap: busy ? null : () => onBackground(c),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(parseStoryColor(c)),
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        GlassButton(
          label: shareLabel,
          onPressed: busy ? null : onSubmit,
        ),
      ],
    );
  }
}
