import 'package:cloud_firestore/cloud_firestore.dart';

class EventoService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para obtener todos los eventos
  static Stream<QuerySnapshot> getEventosStream() {
    return _firestore
        .collection('eventos')
        .orderBy('fecha_hora', descending: true)
        .snapshots();
  }

  // Metodo auxiliar para formatear la fecha (solo fecha, sin hora)
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
    required String nombreFoto,
    required DateTime fechaHora,
    required String autor,
  }) async {
    try {
      await _firestore.collection('eventos').add({
        'titulo': titulo,
        'lugar': lugar,
        'nombre_categoria': nombreCategoria,
        'nombre_foto': nombreFoto,
        'fecha_hora': Timestamp.fromDate(fechaHora),
        'autor': autor,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtener categorias
  static Stream<QuerySnapshot> getCategoriasStream() {
    return _firestore.collection('categorias').snapshots();
  }

  // Obtener categorias como lista
  static Future<List<String>> getCategorias() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('categorias').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['nombre'] as String? ?? '';
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Obtener categorias con sus imágenes
  static Future<Map<String, String>> getCategoriasConImagenes() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('categorias').get();
      Map<String, String> categoriasMap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String nombre = data['nombre'] as String? ?? '';
        String nombreFoto = data['nombre_foto'] as String? ?? '';
        if (nombre.isNotEmpty) {
          categoriasMap[nombre] = nombreFoto;
        }
      }
      return categoriasMap;
    } catch (e) {
      return {};
    }
  }

  // Stream para obtener eventos del usuario registrado
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
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtener un evento especifico por ID (cuando se selecciona uno de la lista)
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
      return null;
    }
  }

  // Stream para obtener un evento especifico en tiempo real
  static Stream<DocumentSnapshot> getEventoStream(String eventoId) {
    return _firestore.collection('eventos').doc(eventoId).snapshots();
  }

  // Método auxiliar para formatear la fecha y hora completa se usa en el detalle del evento
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
