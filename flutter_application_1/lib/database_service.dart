import 'package:cloud_firestore/cloud_firestore.dart';
// IMPORTANTE: Verifica que los nombres de los archivos sean iguales a estos
import 'models/atleta_model.dart';
import 'models/representante_model.dart';
import 'models/institucion_model.dart';
import 'models/partido_model.dart';
import 'models/asistencia_model.dart';

class DatabaseService {
  // Conexión con la base de datos de Firebase
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. GUARDAR TODO (ATLETA + REPRESENTANTE) ---
  // Esta función cumple con las Formas Normales: guarda en dos tablas distintas
  Future<void> registrarAtletaConRepresentante(Atleta atleta, Representante rep) async {
    try {
      // Guardamos al representante en su colección
      await _db.collection('representantes').doc(rep.id).set(rep.toMap());

      // Guardamos al atleta en su colección (ya lleva el id_representante dentro)
      await _db.collection('atletas').doc(atleta.id).set(atleta.toMap());
      
      print("¡Éxito! Datos guardados en la nube.");
    } catch (e) {
      print("Error en Firebase: $e");
    }
  }

  // --- 2. CONSULTAR LISTA DE ATLETAS ---
  // Esto servirá para que el entrenador vea a todos los muchachos en la App
  Stream<List<Atleta>> obtenerAtletas() {
    return _db.collection('atletas').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Atleta.fromFirestore(doc)).toList());
  }

  // --- 3. GUARDAR INSTITUCIÓN ---
  Future<void> guardarInstitucion(Institucion inst) async {
    await _db.collection('instituciones').doc(inst.id.toString()).set(inst.toMap());
  }
}