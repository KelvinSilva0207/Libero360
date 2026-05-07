import 'package:cloud_firestore/cloud_firestore.dart';

class Atleta {
  final String id;
  final String nombreCompleto;
  final DateTime fechaNacimiento;
  final String sexo;
  final int numeroCamisa;
  final String posicion;
  final String estadoSalud;
  final String condicionFisica;
  final String idRepresentante;
  final int idInstitucion;

  Atleta({
    required this.id,
    required this.nombreCompleto,
    required this.fechaNacimiento,
    required this.sexo,
    required this.numeroCamisa,
    required this.posicion,
    this.estadoSalud = "Disponible",
    this.condicionFisica = "Excelente",
    required this.idRepresentante,
    required this.idInstitucion,
  });

  // ESTA ES LA PIEZA QUE TE FALTA (Agrégala aquí abajo)
  factory Atleta.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Atleta(
      id: doc.id,
      nombreCompleto: data['nombre_completo'] ?? '',
      fechaNacimiento: (data['fecha_nacimiento'] as Timestamp).toDate(),
      sexo: data['sexo'] ?? '',
      numeroCamisa: data['numero_camisa'] ?? 0,
      posicion: data['posicion'] ?? '',
      estadoSalud: data['estado_salud'] ?? 'Disponible',
      condicionFisica: data['condicion_fisica'] ?? 'Excelente',
      idRepresentante: data['id_representante'] ?? '',
      idInstitucion: data['id_institucion'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre_completo': nombreCompleto,
      'fecha_nacimiento': fechaNacimiento,
      'sexo': sexo,
      'numero_camisa': numeroCamisa,
      'posicion': posicion,
      'estado_salud': estadoSalud,
      'condicion_fisica': condicionFisica,
      'id_representante': idRepresentante,
      'id_institucion': idInstitucion,
    };
  }
}