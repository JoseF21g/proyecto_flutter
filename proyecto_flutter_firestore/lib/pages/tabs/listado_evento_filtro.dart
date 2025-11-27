import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proyecto_flutter_firestore/constant.dart';
import '../../service/evento_services.dart';
import '../../service/google_auth.dart';
import 'detalle_evento_eliminar.dart';

class ListadoEventoFiltro extends StatefulWidget {
  const ListadoEventoFiltro({super.key});

  @override
  State<ListadoEventoFiltro> createState() => _ListadoEventoFiltroState();
}

class _ListadoEventoFiltroState extends State<ListadoEventoFiltro> {
  Future<void> _confirmarEliminar(
    BuildContext context,
    String eventoId,
    String titulo,
  ) async {
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
              exito ? ' Evento eliminado' : ' Error al eliminar el evento',
            ),
            backgroundColor: exito ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailUsuario = GoogleSignInService.getCurrentUser()?.email ?? '';

    if (emailUsuario.isEmpty) {
      return const Center(child: Text('No se pudo obtener el usuario actual'));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: EventoService.getEventosPorUsuarioStream(emailUsuario),
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
                    'Error al cargar tus eventos',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // Sin datos
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No has creado eventos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usa el botón + para crear tu primer evento',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // Lista de eventos - ordenar en el cliente
          final eventos = snapshot.data!.docs;

          // Ordenar por fecha_hora de forma descendente recientes primero
          eventos.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final fechaA = dataA['fecha_hora'] as Timestamp?;
            final fechaB = dataB['fecha_hora'] as Timestamp?;

            if (fechaA == null && fechaB == null) return 0;
            if (fechaA == null) return 1;
            if (fechaB == null) return -1;

            return fechaB.compareTo(fechaA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final doc = eventos[index];
              final evento = doc.data() as Map<String, dynamic>;
              final eventoId = doc.id;
              final titulo = evento['titulo'] ?? 'Sin título';
              final lugar = evento['lugar'] ?? 'Sin ubicación';
              final fechaHora = evento['fecha_hora'] as Timestamp?;
              final categoria = evento['nombre_categoria'] ?? '';
              final nombreFoto = evento['nombre_foto'] ?? '';

              return Slidable(
                key: ValueKey(eventoId),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (slidableContext) async {
                        await _confirmarEliminar(context, eventoId, titulo);
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Eliminar',
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Color(kPrimaryColor),
                      radius: 24,
                      child: nombreFoto.isNotEmpty
                          ? ClipOval(
                              child: Image.asset(
                                'assets/img/$nombreFoto',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.event,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            )
                          : const Icon(Icons.event, color: Colors.white),
                    ),
                    title: Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lugar,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (categoria.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Color(kSecondaryLightColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              categoria,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(kPrimaryColor),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.swipe_left,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Desliza para eliminar',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(kPrimaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        EventoService.formatearFecha(fechaHora),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(kSecondaryLightColor),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DetalleEventoEliminar(
                            eventoId: eventoId,
                            nombreFoto: nombreFoto,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
