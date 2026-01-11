import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panaderia_nicol_pos/Services/Login_service.dart';
import 'package:panaderia_nicol_pos/screens/mesas_screen.dart';
import 'package:panaderia_nicol_pos/widgets/custom_window_bar.dart';

const kPrimaryColor = Color(0xFFc0733d);
const kOverlayDark = Color(0xFF1F140D);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usuarioCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _loginService = LoginService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _cargando = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _passCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (_usuarioCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete todos los campos")),
      );
      return;
    }

    setState(() => _cargando = true);

    final result = await _loginService.login(
      _usuarioCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    setState(() => _cargando = false);

    if (result != null && result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('idUsuario', result['id']);

      //Navigator.pushReplacement(
        //context,
        //MaterialPageRoute(
          //builder: (_) => MesasScreen(idUsuario: result['id']),
        //),
      //);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?['message'] ?? 'Error al iniciar sesión')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          /// CONTENIDO PRINCIPAL
          Stack(
            fit: StackFit.expand,
            children: [
              /// IMAGEN DE FONDO
              Image.asset(
                'assets/img/pan_bg.jpg',
                fit: BoxFit.cover,
              ),

              /// OVERLAY OSCURO
              Container(
                color: kOverlayDark.withOpacity(0.75),
              ),

              /// LOGIN
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: width * 0.5 > 420 ? 420 : width * 0.9,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/img/quantum_logo_blanco.png',
                          height: 250,
                        ),

                        const SizedBox(height: 24),

                        Text(
                          "Diseñamos tecnología para que tú te enfoques en lo que realmente importa: las personas.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 36),

                        _input(
                          controller: _usuarioCtrl,
                          hint: "Usuario",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _input(
                          controller: _passCtrl,
                          hint: "Contraseña",
                          icon: Icons.lock_outline,
                          obscure: true,
                        ),

                        const SizedBox(height: 26),

                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _iniciarSesion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: _cargando
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(
                              "INICIAR SESIÓN",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white70,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// BARRA SUPERIOR (SIEMPRE ARRIBA)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomWindowBar(),
          ),
        ],
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white54),
        filled: true,
        fillColor: Colors.black.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}