import 'package:cloud_firestore/cloud_firestore.dart';

class EventoService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para obtener todos los eventos en tiempo real
  static Stream<QuerySnapshot> getEventosStream() {
    return _firestore
        .collection('eventos')
        .orderBy('fecha_hora', descending: true)
        .snapshots();
  }

  // Método auxiliar para formatear la fecha (solo fecha, sin hora)
  static String formatearFecha(Timestamp? timestamp) {
    if (timestamp == null) return 'Sin fecha';

    DateTime fecha = timestamp.toDate();
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  // Agregar un nuevo evento
  static Future<bool> agregarEvento({
    required String titulo,
    required String lugar,
    required String nombreCategoria,
    required DateTime fechaHora,
    required String autor,
  }) async {
    try {
      await _firestore.collection('eventos').add({
        'titulo': titulo,
        'lugar': lugar,
        'nombre_categoria': nombreCategoria,
        'fecha_hora': Timestamp.fromDate(fechaHora),
        'autor': autor,
      });
      print(' Evento agregado exitosamente');
      return true;
    } catch (e) {
      print('Error al agregar evento: $e');
      return false;
    }
  }

  // Obtener categorías disponibles (si las tienes en Firestore)
  static Stream<QuerySnapshot> getCategoriasStream() {
    return _firestore.collection('categorias').snapshots();
  }

  // Obtener categorías como lista
  static Future<List<String>> getCategorias() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('categorias').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['nombre'] as String? ?? '';
      }).toList();
    } catch (e) {
      print('Error al obtener categorías: $e');
      return [];
    }
  }

  // Stream para obtener eventos de un usuario específico
  static Stream<QuerySnapshot> getEventosPorUsuarioStream(String emailUsuario) {
    return _firestore
        .collection('eventos')
        .where('autor', isEqualTo: emailUsuario)
        .snapshots();
  }

  // Eliminar un evento
  static Future<bool> eliminarEvento(String eventoId) async {
    try {
      await _firestore.collection('eventos').doc(eventoId).delete();
      print('Evento eliminado exitosamente');
      return true;
    } catch (e) {
      print('Error al eliminar evento: $e');
      return false;
    }
  }

  // Obtener un evento específico por ID
  static Future<Map<String, dynamic>?> getEventoPorId(String eventoId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('eventos')
          .doc(eventoId)
          .get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      print('Error al obtener evento: $e');
      return null;
    }
  }

  // Stream para obtener un evento específico en tiempo real
  static Stream<DocumentSnapshot> getEventoStream(String eventoId) {
    return _firestore.collection('eventos').doc(eventoId).snapshots();
  }

  // Método auxiliar para formatear la fecha y hora completa
  static String formatearFechaHora(Timestamp? timestamp) {
    if (timestamp == null) return 'Sin fecha';

    DateTime fechaHora = timestamp.toDate();
    final dia = fechaHora.day.toString().padLeft(2, '0');
    final mes = fechaHora.month.toString().padLeft(2, '0');
    final anio = fechaHora.year.toString();
    final hora = fechaHora.hour.toString().padLeft(2, '0');
    final minuto = fechaHora.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }
}
