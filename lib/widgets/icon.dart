import 'dart:async';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/svg.dart';

class CommonTargetIcon extends StatelessWidget {
  final String src;
  final double size;

  const CommonTargetIcon({super.key, required this.src, required this.size});

  Widget _defaultIcon() {
    return Icon(IconsExt.target, size: size);
  }

  Widget _buildIcon() {
    if (src.isEmpty) {
      return _defaultIcon();
    }

    final base64 = src.getBase64;
    if (base64 != null) {
      return Image.memory(
        base64,
        gaplessPlayback: true,
        errorBuilder: (_, error, _) {
          return _defaultIcon();
        },
      );
    }

    return ImageCacheWidget(src: src, defaultWidget: _defaultIcon());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: _buildIcon());
  }
}

final _cacheMange = DefaultCacheManager();

class ImageCacheWidget extends StatefulWidget {
  final String src;
  final Widget defaultWidget;

  const ImageCacheWidget({
    super.key,
    required this.src,
    required this.defaultWidget,
  });

  @override
  State<ImageCacheWidget> createState() => _ImageCacheWidgetState();
}

class _ImageCacheWidgetState extends State<ImageCacheWidget> {
  final ValueNotifier<File?> _imageNotifier = ValueNotifier(null);
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _getImageFormCache();
  }

  void _getImageFormCache() {
    final src = widget.src;
    if (src.isEmpty) {
      return;
    }
    _streamSubscription?.cancel();
    _streamSubscription = _cacheMange.getFileStream(src).listen((data) {
      if (mounted && data is FileInfo) {
        _imageNotifier.value = data.file;
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _imageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<File?>(
      valueListenable: _imageNotifier,
      builder: (_, data, _) {
        if (data == null) {
          return widget.defaultWidget;
        }
        return widget.src.isSvg
            ? SvgPicture.file(
                data,
                errorBuilder: (_, _, _) => widget.defaultWidget,
              )
            : Image.file(data, errorBuilder: (_, _, _) => widget.defaultWidget);
      },
    );
  }
}
