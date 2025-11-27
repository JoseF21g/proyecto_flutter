import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_flutter_firestore/constant.dart';
import '../../service/evento_services.dart';
import 'widgets/info_card.dart';

class DetalleEventoEliminar extends StatelessWidget {
  final String eventoId;
  final String nombreFoto;

  const DetalleEventoEliminar({
    super.key,
    required this.eventoId,
    this.nombreFoto = '',
  });

  Future<void> _confirmarEliminar(BuildContext context, String titulo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Evento'),
        content: Text('¿Estás seguro de que deseas eliminar "$titulo"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      final exito = await EventoService.eliminarEvento(eventoId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              exito ? 'Evento eliminado' : 'Error al eliminar el evento',
            ),
            backgroundColor: exito ? Colors.green : Colors.red,
          ),
        );
        if (exito) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Evento'),
        backgroundColor: Color(kPrimaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: EventoService.getEventoStream(eventoId),
        builder: (context, snapshot) {
          // Estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Color(kPrimaryColor)),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar el evento',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
          }

          // Evento no existe
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Evento no encontrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          // Obtener datos del evento
          final evento = snapshot.data!.data() as Map<String, dynamic>;
          final titulo = evento['titulo'] ?? 'Sin título';
          final lugar = evento['lugar'] ?? 'Sin ubicación';
          final fechaHora = evento['fecha_hora'] as Timestamp?;
          final categoria = evento['nombre_categoria'] ?? 'Sin categoría';
          final autor = evento['autor'] ?? 'Desconocido';
          final nombreFotoEvento = nombreFoto.isNotEmpty
              ? nombreFoto
              : (evento['nombre_foto'] ?? '');

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con gradiente
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(kPrimaryColor), Color(kPrimaryLightColor)],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mostrar foto o icono
                        nombreFotoEvento.isNotEmpty
                            ? Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/img/$nombreFotoEvento',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.white24,
                                        child: Icon(
                                          Icons.event,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )
                            : Icon(Icons.event, size: 80, color: Colors.white),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Contenido
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categoría
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Color(kSecondaryLightColor),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color(kPrimaryColor),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            categoria,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(kPrimaryColor),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Fecha y hora
                      InfoCard(
                        icon: Icons.calendar_today,
                        title: 'Fecha y Hora',
                        content: EventoService.formatearFechaHora(fechaHora),
                      ),
                      const SizedBox(height: 16),

                      // Lugar
                      InfoCard(
                        icon: Icons.location_on,
                        title: 'Lugar',
                        content: lugar,
                      ),
                      const SizedBox(height: 16),

                      // Organizador
                      InfoCard(
                        icon: Icons.person,
                        title: 'Organizador',
                        content: autor,
                      ),
                      const SizedBox(height: 32),

                      // Botones de acción
                      Row(
                        children: [
                          // Botón Eliminar
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _confirmarEliminar(context, titulo);
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text(
                                'Eliminar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Botón Regresar
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text(
                                'Regresar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(kPrimaryColor),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
