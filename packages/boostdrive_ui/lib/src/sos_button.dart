import 'package:flutter/material.dart';

class BoostSosButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const BoostSosButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<BoostSosButton> createState() => _BoostSosButtonState();
}

class _BoostSosButtonState extends State<BoostSosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onPressed,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse Effect
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 160 * _animation.value,
                  height: 160 * _animation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.2),
                  ),
                );
              },
            ),
            // Main Button
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.red, Color(0xFFD32F2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sos, size: 48, color: Colors.white),
                        SizedBox(height: 4),
                        Text(
                          'EMERGENCY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
