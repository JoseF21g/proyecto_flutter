import 'dart:async';
import 'package:flutter/material.dart';
import 'package:proyecto_flutter_firestore/constant.dart';
import '../service/google_auth.dart';
import 'tabs/main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _autoSignIn();
  }

  @override
  void dispose() {
    _statusController.close();
    super.dispose();
  }

  Future<void> _autoSignIn() async {
    try {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });

      _statusController.add('🔄 Iniciando proceso de autenticación...');
      print('🔄 [AUTH] Iniciando proceso de autenticación');

      _statusController.add('🔧 Inicializando Google Sign-In...');
      print('🔧 [AUTH] Inicializando Google Sign-In');

      _statusController.add('📱 Esperando selección de cuenta...');
      print('📱 [AUTH] Llamando a signInWithGoogle');

      final userCredential = await GoogleSignInService.signInWithGoogle();

      _statusController.add('✅ Cuenta seleccionada');
      print('✅ [AUTH] Usuario autenticado: ${userCredential?.user?.email}');

      if (userCredential != null && mounted) {
        _statusController.add('💾 Guardando datos en Firestore...');
        print('💾 [AUTH] Guardando datos del usuario en Firestore');

        _statusController.add('🎉 ¡Login exitoso!');
        print('🎉 [AUTH] Login completado exitosamente');

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        _statusController.add('⚠️ Login cancelado');
        print('⚠️ [AUTH] Usuario canceló el login');
        setState(() {
          _hasError = true;
          _errorMessage = 'Login cancelado por el usuario';
        });
      }
    } catch (e) {
      final errorMsg = e.toString();
      _statusController.add('❌ Error: $errorMsg');
      print('❌ [AUTH ERROR] $errorMsg');
      print('❌ [AUTH ERROR TRACE] ${StackTrace.current}');

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = errorMsg;
        });
      }
    }
  }

  Future<void> _retrySignIn() async {
    await _autoSignIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(kPrimaryLightColor), Color(kPrimaryColor)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<String>(
            stream: _statusController.stream,
            builder: (context, snapshot) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Bienvenido',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!_hasError)
                    Column(
                      children: [
                        const SizedBox(height: 40),
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            snapshot.data ?? 'Iniciando...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Error al iniciar sesión',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage ?? 'Error desconocido',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _retrySignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(kPrimaryColor),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Reintentar',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
