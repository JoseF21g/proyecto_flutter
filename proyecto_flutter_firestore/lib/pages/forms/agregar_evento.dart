import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_flutter_firestore/constant.dart';
import '../../service/evento_services.dart';
import '../../service/google_auth.dart';

class AgregarEvento extends StatefulWidget {
  const AgregarEvento({super.key});

  @override
  State<AgregarEvento> createState() => _AgregarEventoState();
}

class _AgregarEventoState extends State<AgregarEvento> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _lugarController = TextEditingController();
  final _autorController = TextEditingController();

  String? _categoriaSeleccionada;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  bool _isLoading = false;
  Map<String, String> _categoriasConImagenes = {}; // nombre_categoria -> nombre_imagen

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    // Obtener el correo del usuario actual
    final User? user = GoogleSignInService.getCurrentUser();
    if (user != null) {
      _autorController.text = user.email ?? '';
    }

    // Cargar categorías con sus imágenes
    final categorias = await EventoService.getCategoriasConImagenes();
    setState(() {
      _categoriasConImagenes = categorias;
      if (_categoriasConImagenes.isNotEmpty) {
        _categoriaSeleccionada = _categoriasConImagenes.keys.first;
      }
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _lugarController.dispose();
    _autorController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Color(kPrimaryColor), onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Color(kPrimaryColor), onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _horaSeleccionada = picked;
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    List<String> meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  String _formatearHora(TimeOfDay hora) {
    final hourStr = hora.hour.toString().padLeft(2, '0');
    final minuteStr = hora.minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  Future<void> _guardarEvento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor selecciona una fecha'), backgroundColor: Colors.red));
      return;
    }

    if (_horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor selecciona una hora'), backgroundColor: Colors.red));
      return;
    }

    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor selecciona una categoría'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Combinar fecha y hora
    final fechaHora = DateTime(_fechaSeleccionada!.year, _fechaSeleccionada!.month, _fechaSeleccionada!.day, _horaSeleccionada!.hour, _horaSeleccionada!.minute);

    final exito = await EventoService.agregarEvento(titulo: _tituloController.text.trim(), lugar: _lugarController.text.trim(), nombreCategoria: _categoriaSeleccionada!, nombreFoto: _categoriasConImagenes[_categoriaSeleccionada!] ?? '', fechaHora: fechaHora, autor: _autorController.text.trim());

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento creado exitosamente'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al crear el evento'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Evento'), backgroundColor: Color(kPrimaryColor), foregroundColor: Colors.white, elevation: 0),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(kPrimaryColor)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título del evento
                    TextFormField(
                      controller: _tituloController,
                      decoration: InputDecoration(
                        labelText: 'Título del Evento',
                        hintText: 'Ej: Concierto de Rock',
                        prefixIcon: Icon(Icons.title, color: Color(kPrimaryColor)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(kPrimaryColor), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa el título';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Lugar
                    TextFormField(
                      controller: _lugarController,
                      decoration: InputDecoration(
                        labelText: 'Lugar',
                        hintText: 'Ej: Estadio Nacional',
                        prefixIcon: Icon(Icons.location_on, color: Color(kPrimaryColor)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(kPrimaryColor), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa el lugar';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Categoría
                    DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category, color: Color(kPrimaryColor)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(kPrimaryColor), width: 2),
                        ),
                      ),
                      items: _categoriasConImagenes.keys.map((categoria) {
                        return DropdownMenuItem(value: categoria, child: Text(categoria));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoriaSeleccionada = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor selecciona una categoría';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Fecha
                    InkWell(
                      onTap: _seleccionarFecha,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha',
                          prefixIcon: Icon(Icons.calendar_today, color: Color(kPrimaryColor)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(kPrimaryColor), width: 2),
                          ),
                        ),
                        child: Text(_fechaSeleccionada == null ? 'Seleccionar fecha' : _formatearFecha(_fechaSeleccionada!), style: TextStyle(color: _fechaSeleccionada == null ? Colors.grey : Colors.black)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Hora
                    InkWell(
                      onTap: _seleccionarHora,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Hora',
                          prefixIcon: Icon(Icons.access_time, color: Color(kPrimaryColor)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(kPrimaryColor), width: 2),
                          ),
                        ),
                        child: Text(_horaSeleccionada == null ? 'Seleccionar hora' : _formatearHora(_horaSeleccionada!), style: TextStyle(color: _horaSeleccionada == null ? Colors.grey : Colors.black)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Autor (bloqueado)
                    TextFormField(
                      controller: _autorController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Autor',
                        prefixIcon: Icon(Icons.person, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Botón Guardar
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _guardarEvento,
                      icon: const Icon(Icons.save),
                      label: const Text('Crear Evento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(kPrimaryColor),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
