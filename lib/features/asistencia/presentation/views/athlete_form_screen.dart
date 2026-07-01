import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/local_db/database_service.dart';

class AthleteFormScreen extends StatefulWidget {
  const AthleteFormScreen({super.key});

  @override
  State<AthleteFormScreen> createState() => _AthleteFormScreenState();
}

class _AthleteFormScreenState extends State<AthleteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNamesCtrl = TextEditingController();
  final _lastNamesCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _condicionFisicaCtrl = TextEditingController(text: 'Excelente');
  final _fotoUrlCtrl = TextEditingController();

  DateTime _fechaNacimiento = DateTime.now().subtract(const Duration(days: 365 * 20));
  Posicion _posicion = Posicion.sinDefinir;
  bool _esCapitan = false;
  EstadoSalud _estadoSalud = EstadoSalud.disponible;
  bool _saving = false;

  @override
  void dispose() {
    _firstNamesCtrl.dispose();
    _lastNamesCtrl.dispose();
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
            primary: AppColors.accent,
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
        firstNames: _firstNamesCtrl.text.trim(),
        lastNames: _lastNamesCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim(),
        fechaNacimiento: _fechaNacimiento,
        numero: _numeroCtrl.text.trim().isEmpty ? null : int.parse(_numeroCtrl.text.trim()),
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Nuevo Atleta', style: TextStyle(color: cs.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
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
              _buildTextField(_firstNamesCtrl, 'Nombres', Icons.person, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingrese los nombres';
                return null;
              }),
              const SizedBox(height: 12),
              _buildTextField(_lastNamesCtrl, 'Apellidos', Icons.person_outline_rounded, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingrese los apellidos';
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
                _numeroCtrl, 'Número de Camisa (opcional)', Icons.numbers,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Guardando...' : 'Guardar Atleta'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: cs.onPrimary,
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
        color: AppColors.accent,
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
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: TextFormField(
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            labelText: 'Fecha de Nacimiento ($_edadCalculada)',
            labelStyle: TextStyle(color: cs.onSurfaceVariant),
            prefixIcon: const Padding(
              padding: EdgeInsetsDirectional.only(start: 12, end: 8),
              child: Icon(Icons.cake, color: AppColors.primary, size: 20),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
            suffixIcon: Icon(Icons.calendar_today, color: cs.onSurface.withValues(alpha: 0.6), size: 18),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<Posicion>(
      value: _posicion,
      dropdownColor: AppColors.surfaceLight,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: 'Posición Principal',
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIcon: const Padding(
          padding: EdgeInsetsDirectional.only(start: 12, end: 8),
          child: Icon(Icons.sports, color: AppColors.primary, size: 20),
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      items: Posicion.values.map((p) {
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
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<EstadoSalud>(
      value: _estadoSalud,
      dropdownColor: AppColors.surfaceLight,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: 'Estado de Salud',
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIcon: const Padding(
          padding: EdgeInsetsDirectional.only(start: 12, end: 8),
          child: Icon(Icons.health_and_safety, color: AppColors.primary, size: 20),
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: cs.onSurface, fontSize: 14)),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
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
      case Posicion.sinDefinir: return 'Ninguna / Sin definir';
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
