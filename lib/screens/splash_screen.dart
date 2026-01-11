import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'mesas_screen.dart';
import 'package:panaderia_nicol_pos/screens/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final String _baseUrl = 'http://200.7.100.146/api-panaderia_nicol/pos';

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final idUsuario = prefs.getInt('idUsuario');
    final nombreUsuario = prefs.getString('nombreUsuario');

    if (idUsuario == null || nombreUsuario == null) {
      _redirigirLogin();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/verificar_usuario.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_usuario": idUsuario}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true) {
          //Navigator.pushReplacement(
            //context,
            //MaterialPageRoute(builder: (_) => MesasScreen(idUsuario: idUsuario)),
          //);
        } else {
          await prefs.clear();
          _mostrarAlerta(data["message"] ?? "El usuario fue desactivado.");
        }
      } else {
        _redirigirLogin();
      }
    } catch (e) {
      _redirigirLogin();
    }
  }

  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Sesión inválida"),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _redirigirLogin();
            },
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  void _redirigirLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/img/quantum_logo.png', width: 180, height: 180),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              "Cargando...",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}