import 'package:flutter/material.dart';
import 'package:milan_app/core/widgets.dart';

/// Step 3 — at least one profile photo.
class PhotosStep extends StatelessWidget {
  const PhotosStep({
    super.key,
    required this.photoUrls,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photoUrls;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('Add photos', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Profiles with photos get far more attention. '
          'The first photo becomes your main picture.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            for (int i = 0; i < photoUrls.length; i++)
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      photoUrls[i],
                      width: 110,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        width: 110,
                        height: 140,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  if (i == 0)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Main',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: IconButton.filledTonal(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      onPressed: busy ? null : () => onRemove(i),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            if (!busy)
              InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 110,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      const Text('Add photo', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            if (busy)
              Container(
                width: 110,
                height: 140,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
          ],
        ),
        if (photoUrls.isEmpty) ...<Widget>[
          const SizedBox(height: 16),
          const AppEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No photos yet',
            message: 'Add a clear photo of yourself so people can recognise you.',
          ),
        ],
      ],
    );
  }
}
