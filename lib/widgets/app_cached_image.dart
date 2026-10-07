import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/image_cache_service.dart';

class AppCachedImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext context)? errorBuilder;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  State<AppCachedImage> createState() => _AppCachedImageState();
}

class _AppCachedImageState extends State<AppCachedImage> {
  File? _localFile;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant AppCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final path = widget.imageUrl.trim();
    if (path.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    if (path.startsWith('assets/') || kIsWeb) {
      return;
    }

    if (!path.startsWith('http')) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    final cached = await ImageCacheService.getCachedImageFile(path);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _localFile = cached;
          _hasError = false;
        });
      }
      return;
    }

    final downloaded = await ImageCacheService.downloadAndCacheImage(path);
    if (mounted) {
      setState(() {
        _localFile = downloaded;
        _hasError = downloaded == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.imageUrl.trim();

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stack) => _buildError(context),
      );
    }

    if (kIsWeb) {
      return Image.network(
        path,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stack) => _buildError(context),
      );
    }

    if (_localFile != null) {
      return Image.file(
        _localFile!,
        key: ValueKey(_localFile!.path),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stack) => _buildError(context),
      );
    }

    if (_hasError) {
      return _buildError(context);
    }

    return Image.network(
      path,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) => _buildError(context),
    );
  }

  Widget _buildError(BuildContext context) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context);
    }
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_not_supported_outlined, color: Theme.of(context).dividerColor),
    );
  }
}
