import 'package:flutter/material.dart';


class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: ShaderMask(
              shaderCallback: (bounds) {
                final t = _controller.value;
                return LinearGradient(
                  begin: Alignment(-1 - t * 2, 0),
                  end: Alignment(1 - t * 2, 0),
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.06),
                  ],
                  stops: const [0.35, 0.5, 0.65],
                ).createShader(bounds);
              },
              child: Container(color: Colors.white.withOpacity(0.10)),
            ),
          ),
        );
      },
    );
  }
}