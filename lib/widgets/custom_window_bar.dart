import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomWindowBar extends StatelessWidget {
  const CustomWindowBar({super.key});

  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      width: double.infinity,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => windowManager.startDragging(),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  /// 🧠 LOGO IZQUIERDA
                  Image.asset(
                    'assets/img/quantum_logo_blanco.png',
                    height: 20,
                  ),

                  const SizedBox(width: 12),

                  /// TEXTO OPCIONAL
                  const Text(
                    'Quantum Experience',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const Spacer(),

                  /// 🍎 BOTONES ESTILO macOS
                  Row(
                    children: [
                      _MacButton(
                        color: const Color(0xFFFFBD2E),
                        onTap: () => windowManager.minimize(),
                      ),
                      const SizedBox(width: 8),
                      _MacButton(
                        color: const Color(0xFF28C840),
                        onTap: () async {
                          final isMaximized = await windowManager.isMaximized();
                          if (isMaximized) {
                            await windowManager.unmaximize();
                          } else {
                            await windowManager.maximize();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _MacButton(
                        color: const Color(0xFFFF5F57),
                        onTap: () => windowManager.close(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🍎 BOTÓN macOS
class _MacButton extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;

  const _MacButton({
    required this.color,
    required this.onTap,
  });

  @override
  State<_MacButton> createState() => _MacButtonState();
}

class _MacButtonState extends State<_MacButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: _hover
                ? [
              BoxShadow(
                color: widget.color.withOpacity(0.6),
                blurRadius: 6,
              )
            ]
                : [],
          ),
        ),
      ),
    );
  }
}