import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      print('🔧 [SERVICE] Iniciando Google Sign-In');

      // Primero, intentar cerrar sesión para limpiar estado
      await _googleSignIn.signOut();
      print('🧹 [SERVICE] Estado limpiado');

      print('📱 [SERVICE] Llamando a signIn()...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('⚠️ [SERVICE] Usuario canceló la selección');
        return null;
      }

      print('✅ [SERVICE] Usuario seleccionado: ${googleUser.email}');
      print('🔑 [SERVICE] Obteniendo tokens...');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('❌ [SERVICE] Error: tokens no disponibles');
        throw FirebaseAuthException(
          code: 'ERROR_MISSING_TOKEN',
          message: 'No se pudo obtener el token de autenticación',
        );
      }

      print('✅ [SERVICE] Tokens obtenidos');
      print('🎫 [SERVICE] Creando credential...');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔥 [SERVICE] Autenticando con Firebase...');
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      print('✅ [SERVICE] Autenticado con Firebase');
      final User? user = userCredential.user;

      if (user != null) {
        print('💾 [SERVICE] Guardando en Firestore...');
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'photoURL': user.photoURL ?? '',
            'provider': 'google',
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('✅ [SERVICE] Datos guardados en Firestore');
        } else {
          print('ℹ️ [SERVICE] Usuario ya existe en Firestore');
        }
      }

      print('🎉 [SERVICE] Login completado exitosamente!');
      return userCredential;
    } on PlatformException catch (e) {
      print(
        '❌ [SERVICE PLATFORM ERROR] Code: ${e.code}, Message: ${e.message}',
      );
      print('❌ [SERVICE PLATFORM ERROR] Details: ${e.details}');

      // Error 10 es DEVELOPER_ERROR - problema de configuración
      if (e.code == 'sign_in_failed' && e.message?.contains('10') == true) {
        throw Exception(
          'Error de configuración de Google Sign-In.\n\n'
          'Posibles causas:\n'
          '1. El SHA-1 no está registrado en Firebase Console\n'
          '2. La aplicación no está habilitada en Google Cloud Console\n'
          '3. El paquete (applicationId) no coincide\n\n'
          'Detalles técnicos: ${e.message}',
        );
      }

      rethrow;
    } catch (e) {
      print('❌ [SERVICE ERROR] $e');
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw e;
    }
  }

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}
