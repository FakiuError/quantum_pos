import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomTopBar extends StatelessWidget {
  final String sectionTitle;
  final String userName;
  final VoidCallback onMenuTap;

  const CustomTopBar({
    super.key,
    required this.sectionTitle,
    required this.userName,
    required this.onMenuTap, required String section,
  });

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: GestureDetector(
        onPanStart: (_) => windowManager.startDragging(),
        behavior: HitTestBehavior.translucent,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
              ),
              child: Row(
                children: [
                  /// ☰ MENU
                  IconButton(
                    onPressed: onMenuTap,
                    splashRadius: 20,
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// LOGO
                  Image.asset(
                    'assets/img/logo_quantum_negro.png',
                    height: 32,
                  ),

                  const SizedBox(width: 12),

                  /// NOMBRE EMPRESA
                  const Text(
                    'Quantum Experience',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const SizedBox(width: 32),

                  /// SECCIÓN ACTUAL
                  Text(
                    sectionTitle,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),

                  const Spacer(),

                  /// USUARIO
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.black,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 24),

                  /// macOS BUTTONS
                  _MacButton(
                    color: const Color(0xFFFFBD2E),
                    onTap: () => windowManager.minimize(),
                  ),
                  const SizedBox(width: 10),
                  _MacButton(
                    color: const Color(0xFF28C840),
                    onTap: () async {
                      final isMax = await windowManager.isMaximized();
                      isMax
                          ? windowManager.unmaximize()
                          : windowManager.maximize();
                    },
                  ),
                  const SizedBox(width: 10),
                  _MacButton(
                    color: const Color(0xFFFF5F57),
                    onTap: () => windowManager.close(),
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

class _MacButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _MacButton({
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}