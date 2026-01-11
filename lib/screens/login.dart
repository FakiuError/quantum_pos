import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panaderia_nicol_pos/Widget/input.dart';
import 'package:panaderia_nicol_pos/Services/Login_service.dart';
import 'package:panaderia_nicol_pos/screens/mesas_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final LoginService _loginService = LoginService();

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _verificarSesionGuardada();
  }

  Future<void> _verificarSesionGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final idUsuario = prefs.getInt('idUsuario');
    if (idUsuario != null) {
      //Navigator.pushReplacement(
        //context,
        //MaterialPageRoute(
          //builder: (context) => MesasScreen(idUsuario: idUsuario),
        //),
      //);
    } else {
      setState(() => _cargando = false);
    }
  }

  Future<void> _iniciarSesion() async {
    final String usuario = _usuarioController.text.trim();
    final String contrasena = _contrasenaController.text.trim();

    if (usuario.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    final Map<String, dynamic>? loginResult =
    await _loginService.login(usuario, contrasena);

    if (loginResult != null && loginResult['success'] == true) {
      final int idUsuario = loginResult['id'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('idUsuario', idUsuario);
      await prefs.setString('nombreUsuario', usuario);

      //Navigator.pushReplacement(
        //context,
        //MaterialPageRoute(
          //builder: (context) => MesasScreen(idUsuario: idUsuario),
        //),
      //);
    } else {
      String errorMessage =
          loginResult?['message'] ?? 'Error desconocido al iniciar sesión.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFc0733d)),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: size.height * 0.3,
              child: Image.asset(
                'assets/img/logo.png',
                fit: BoxFit.cover,
              ),
            ),
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 250),
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Text("Ingresar",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 30),
                            Form(
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _usuarioController,
                                    keyboardType: TextInputType.text,
                                    autocorrect: false,
                                    decoration:
                                    InputDecoratios.inputDecoration(
                                      hintext: "Ingrese el nombre de usuario",
                                      labeltext: "Usuario",
                                      icono: const Icon(
                                          Icons.alternate_email_rounded,
                                          color: Color(0xFFc0733d)),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  TextFormField(
                                    controller: _contrasenaController,
                                    autocorrect: false,
                                    obscureText: true,
                                    decoration:
                                    InputDecoratios.inputDecoration(
                                      hintext: "*******",
                                      labeltext: "Contraseña",
                                      icono: const Icon(Icons.lock_outline,
                                          color: Color(0xFFc0733d)),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  MaterialButton(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(10)),
                                    disabledColor: Colors.grey,
                                    color: const Color(0xFFc0733d),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 80, vertical: 15),
                                      child: const Text(
                                        "Ingresar",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    onPressed: _iniciarSesion,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 25),
                        child: Text(
                          "Quantum Experience 2025",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}