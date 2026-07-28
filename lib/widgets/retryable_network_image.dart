import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class RetryableNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Map<String, String>? headers;
  final Widget Function(BuildContext context)? fallbackBuilder;
  final int maxAutoRetries;

  const RetryableNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.headers,
    this.fallbackBuilder,
    this.maxAutoRetries = 2,
  });

  @override
  State<RetryableNetworkImage> createState() =>
      _RetryableNetworkImageState();
}

class _RetryableNetworkImageState
    extends State<RetryableNetworkImage> {
  int _attempt = 0;
  bool _autoRetriesExhausted = false;

  void _retry() {
    if (!mounted) return;
    setState(() {
      _attempt++;
      if (_attempt >= widget.maxAutoRetries) {
        _autoRetriesExhausted = true;
      }
    });
  }

  void _manualRetry() {
    if (!mounted) return;
    setState(() {
      _attempt = 0;
      _autoRetriesExhausted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.trim().isEmpty) {
      return _buildFallback(context);
    }

    return CachedNetworkImage(
      key: ValueKey('${widget.url}_$_attempt'),
      imageUrl: widget.url,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      httpHeaders: widget.headers,

      placeholder: (context, url) {
        return _buildLoading();
      },

      errorWidget: (context, url, error) {
        if (!_autoRetriesExhausted &&
            _attempt < widget.maxAutoRetries) {
          Future.delayed(
            Duration(milliseconds: 800 * (_attempt + 1)),
            () {
              if (mounted) {
                _retry();
              }
            },
          );
          return _buildLoading();
        }

        if (widget.fallbackBuilder != null) {
          return widget.fallbackBuilder!(context);
        }

        return GestureDetector(
          onTap: _manualRetry,
          child: _buildRetry(),
        );
      },

      fadeInDuration: const Duration(milliseconds: 250),
      fadeOutDuration: const Duration(milliseconds: 100),
      cacheKey: _buildCacheKey(widget.url),
    );
  }

  String _buildCacheKey(String url) {
    return url.trim();
  }

  Widget _buildLoading() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade300,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    if (widget.fallbackBuilder != null) {
      return widget.fallbackBuilder!(context);
    }
    return GestureDetector(
      onTap: _manualRetry,
      child: _buildRetry(),
    );
  }

  Widget _buildRetry() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade300,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh, size: 28, color: Colors.grey),
          SizedBox(height: 4),
          Text(
            'تلاش دوباره',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}