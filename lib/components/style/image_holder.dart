import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/helpers/logger.dart';
import 'package:possystem/models/xfile.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/translator.dart';

class ImageHolder extends StatelessWidget {
  final ImageProvider image;
  final String? title;
  final String? subtitle;
  final void Function()? onPressed;
  final void Function()? onImageError;
  final FocusNode? focusNode;
  final EdgeInsets padding;
  final double size;

  const ImageHolder({
    super.key,
    required this.image,
    this.title,
    this.subtitle,
    this.size = 256,
    this.onPressed,
    this.onImageError,
    this.focusNode,
    this.padding = const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: size, maxWidth: size),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Ink.image(
                  image: image,
                  fit: BoxFit.cover,
                  onImageError: (error, stack) {
                    Log.err(error, 'image_error', stack);
                    onImageError?.call();
                  },
                ),
                if (title != null)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          stops: const [0.4, 0.6, 1.0],
                        ),
                      ),
                      padding: padding,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            title!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (onPressed != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPressed,
                      focusNode: focusNode,
                      splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                      highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditImageHolder extends StatelessWidget {
  final String? path;
  final void Function(String)? onSelected;
  final void Function()? onPressed;
  final double size;

  const EditImageHolder({
    super.key,
    this.path,
    this.onSelected,
    this.onPressed,
    this.size = 256,
  }) : assert(onSelected != null || onPressed != null);

  @override
  Widget build(BuildContext context) {
    final ImageProvider image =
        path == null ? const AssetImage("assets/food_placeholder.png") as ImageProvider : FileImage(XFile(path!).file);

    return ImageHolder(
      key: const Key('image_holder.edit'),
      image: image,
      title: path == null ? S.imageHolderCreate : S.imageHolderUpdate,
      size: size,
      onPressed: onPressed ??
          () async {
            final file = await context.pushNamed(Routes.imageGallery);
            if (file != null && file is String) onSelected!(file);
          },
    );
  }
}
