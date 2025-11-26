import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_flutter_firestore/constant.dart';
import '../../service/google_auth.dart';
import '../auth_screen.dart';
import '../forms/agregar_evento.dart';
import 'home_page.dart';
import 'listado_evento.dart';
import 'listado_evento_filtro.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Lista de páginas
  final List<Widget> _pages = [
    const HomePage(),
    const ListadoEvento(),
    const ListadoEventoFiltro(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = GoogleSignInService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(Icons.person, color: Colors.blue)
                : null,
          ),
        ),
        title: const Text('App de Eventos'),
        backgroundColor: Color(kPrimaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await GoogleSignInService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              }
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      // todo esso va en el appbar

      // navigation bar
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Color(kSecondaryLightColor),
        selectedItemColor: Color(kPrimaryLightColor),
        unselectedItemColor: Color(kPrimaryColor),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Eventos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.filter_list),
            label: 'Eventos Propios',
          ),
        ],
      ),

      // floating action button para agregar evento
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AgregarEvento()),
          );
        },
        backgroundColor: Color(kPrimaryColor),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Agregar Evento',
      ),
    );
  }
}
