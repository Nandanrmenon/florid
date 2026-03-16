import 'package:cached_network_image/cached_network_image.dart';
import 'package:florid/models/fdroid_app.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppDetailsIcon extends StatefulWidget {
  final FDroidApp app;
  const AppDetailsIcon({super.key, required this.app});

  @override
  State<AppDetailsIcon> createState() => _AppDetailsIconState();
}

class _AppDetailsIconState extends State<AppDetailsIcon> {
  late List<String> _candidates;
  int _index = 0;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    _candidates = widget.app.iconUrls;
  }

  void _next() {
    if (!mounted) return;

    // Always use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Move through all candidates before showing a fallback
      if (_index < _candidates.length - 1) {
        setState(() {
          _index++;
        });
      } else {
        setState(() {
          _showFallback = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showFallback) {
      return Container(
        color: Colors.white.withValues(alpha: 0.2),
        child: const Icon(Symbols.android, color: Colors.white, size: 40),
      );
    }

    if (_index >= _candidates.length) {
      return Container(
        color: Colors.white.withValues(alpha: 0.2),
        child: const Icon(Symbols.apps, color: Colors.white, size: 40),
      );
    }

    final url = _candidates[_index];
    return Material(
      // color: Colors.white,
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        cacheKey: '${widget.app.packageName}:$url',
        imageBuilder: (context, imageProvider) => Image(
          image: imageProvider,
          fit: BoxFit.fitHeight,
          filterQuality: FilterQuality.high,
        ),
        errorWidget: (context, _, _) {
          // Move to next candidate or fallback.
          _next();
          return Container(
            color: Colors.white.withValues(alpha: 0.2),
            child: const Icon(
              Symbols.broken_image,
              color: Colors.white,
              size: 40,
            ),
          );
        },
        placeholder: (context, _) => Container(
          color: Colors.white.withValues(alpha: 0.2),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        // Suppress per-attempt error spam for fallback candidates.
        errorListener: (_) {},
      ),
    );
  }
}
