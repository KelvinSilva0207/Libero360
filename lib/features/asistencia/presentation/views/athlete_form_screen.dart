import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/local_db/database_service.dart';

class AthleteFormScreen extends StatefulWidget {
  const AthleteFormScreen({super.key});

  @override
  State<AthleteFormScreen> createState() => _AthleteFormScreenState();
}

class _AthleteFormScreenState extends State<AthleteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController(text: '1');
  final _condicionFisicaCtrl = TextEditingController(text: 'Excelente');
  final _fotoUrlCtrl = TextEditingController();

  DateTime _fechaNacimiento = DateTime.now().subtract(const Duration(days: 365 * 20));
  Posicion _posicion = Posicion.colocador;
  bool _esCapitan = false;
  EstadoSalud _estadoSalud = EstadoSalud.disponible;
  bool _saving = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cedulaCtrl.dispose();
    _numeroCtrl.dispose();
    _condicionFisicaCtrl.dispose();
    _fotoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF8C00),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  String get _edadCalculada {
    final hoy = DateTime.now();
    int edad = hoy.year - _fechaNacimiento.year;
    if (hoy.month < _fechaNacimiento.month ||
        (hoy.month == _fechaNacimiento.month && hoy.day < _fechaNacimiento.day)) {
      edad--;
    }
    return '$edad años';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final player = Player.create(
        nombre: _nombreCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim(),
        fechaNacimiento: _fechaNacimiento,
        numero: int.parse(_numeroCtrl.text.trim()),
        posicion: _posicion,
        esCapitan: _esCapitan,
        fotoUrl: _fotoUrlCtrl.text.trim().isEmpty ? null : _fotoUrlCtrl.text.trim(),
        estadoSalud: _estadoSalud,
        condicionFisica: _condicionFisicaCtrl.text.trim(),
      );

      await DatabaseService.instance.initialize();
      await DatabaseService.instance.savePlayer(player);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Nuevo Atleta', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section('Información Personal'),
              const SizedBox(height: 8),
              _buildTextField(_nombreCtrl, 'Nombre Completo', Icons.person, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingrese el nombre';
                return null;
              }),
              const SizedBox(height: 12),
              _buildTextField(_cedulaCtrl, 'Cédula', Icons.badge, keyboardType: TextInputType.number, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingrese la cédula';
                return null;
              }),
              const SizedBox(height: 12),
              _buildDateField(),
              const SizedBox(height: 12),
              _buildTextField(
                _numeroCtrl, 'Número de Camisa', Icons.numbers,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingrese el número';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _section('Posición y Rol'),
              const SizedBox(height: 8),
              _buildPosicionDropdown(),
              const SizedBox(height: 12),
              _buildSwitchRow(Icons.star, '¿Es Capitán?', _esCapitan, (v) {
                setState(() => _esCapitan = v);
              }),
              const SizedBox(height: 20),
              _section('Estado Físico'),
              const SizedBox(height: 8),
              _buildSaludDropdown(),
              const SizedBox(height: 12),
              _buildTextField(_condicionFisicaCtrl, 'Condición Física Actual', Icons.fitness_center),
              const SizedBox(height: 20),
              _section('Adicional'),
              const SizedBox(height: 8),
              _buildTextField(_fotoUrlCtrl, 'URL de Foto (opcional)', Icons.image),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Guardando...' : 'Guardar Atleta'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFFF8C00),
        fontWeight: FontWeight.bold,
        fontSize: 14,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFF0081CF), size: 20),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF8C00)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: TextFormField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Fecha de Nacimiento ($_edadCalculada)',
            labelStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.cake, color: Color(0xFF0081CF), size: 20),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF8C00)),
            ),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.white38, size: 18),
          ),
          controller: TextEditingController(
            text:
                '${_fechaNacimiento.day.toString().padLeft(2, '0')}/${_fechaNacimiento.month.toString().padLeft(2, '0')}/${_fechaNacimiento.year}',
          ),
          validator: (_) => null,
        ),
      ),
    );
  }

  Widget _buildPosicionDropdown() {
    return DropdownButtonFormField<Posicion>(
      value: _posicion,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Posición Principal',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.sports, color: Color(0xFF0081CF), size: 20),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: [
        Posicion.colocador,
        Posicion.opuesto,
        Posicion.receptor,
        Posicion.central,
        Posicion.libre,
      ].map((p) {
        return DropdownMenuItem(
          value: p,
          child: Text(_posicionLabel(p)),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _posicion = v);
      },
    );
  }

  Widget _buildSaludDropdown() {
    return DropdownButtonFormField<EstadoSalud>(
      value: _estadoSalud,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Estado de Salud',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.health_and_safety, color: Color(0xFF0081CF), size: 20),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: EstadoSalud.values.map((e) {
        return DropdownMenuItem(
          value: e,
          child: Text(_saludLabel(e)),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _estadoSalud = v);
      },
    );
  }

  Widget _buildSwitchRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0081CF), size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFF8C00),
          ),
        ],
      ),
    );
  }

  String _posicionLabel(Posicion p) {
    switch (p) {
      case Posicion.colocador: return 'Armador';
      case Posicion.opuesto: return 'Opuesto';
      case Posicion.receptor: return 'Punta (Receptor)';
      case Posicion.central: return 'Central';
      case Posicion.libre: return 'Líbero';
    }
  }

  String _saludLabel(EstadoSalud e) {
    switch (e) {
      case EstadoSalud.disponible: return 'Disponible';
      case EstadoSalud.lesionado: return 'Lesionado';
      case EstadoSalud.enDuda: return 'En duda';
    }
  }
}
