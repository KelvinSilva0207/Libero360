import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../../core/utils/name_formatter.dart';

class AthleteEditScreen extends StatefulWidget {
  final Player player;
  const AthleteEditScreen({super.key, required this.player});

  @override
  State<AthleteEditScreen> createState() => _AthleteEditScreenState();
}

class _AthleteEditScreenState extends State<AthleteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNamesCtrl;
  late final TextEditingController _lastNamesCtrl;
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _condicionFisicaCtrl;
  late final TextEditingController _fotoUrlCtrl;

  late DateTime _fechaNacimiento;
  late Posicion _posicion;
  late bool _esCapitan;
  late EstadoSalud _estadoSalud;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.player;
    _firstNamesCtrl = TextEditingController(text: p.firstNames);
    _lastNamesCtrl = TextEditingController(text: p.lastNames);
    _cedulaCtrl = TextEditingController(text: p.cedula);
    _numeroCtrl = TextEditingController(text: p.numero?.toString() ?? '');
    _condicionFisicaCtrl = TextEditingController(text: p.condicionFisica);
    _fotoUrlCtrl = TextEditingController(text: p.fotoUrl ?? '');
    _fechaNacimiento = p.fechaNacimiento;
    _posicion = p.posicion;
    _esCapitan = p.esCapitan;
    _estadoSalud = p.estadoSalud;
  }

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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final p = widget.player;
      p.firstNames = _firstNamesCtrl.text.trim();
      p.lastNames = _lastNamesCtrl.text.trim();
      p.displayName = NameFormatter.displayName(firstNames: _firstNamesCtrl.text.trim(), lastNames: _lastNamesCtrl.text.trim());
      p.nombre = p.displayName;
      p.cedula = _cedulaCtrl.text.trim();
      p.numero = int.tryParse(_numeroCtrl.text.trim());
      p.fechaNacimiento = _fechaNacimiento;
      p.posicion = _posicion;
      p.esCapitan = _esCapitan;
      p.estadoSalud = _estadoSalud;
      p.condicionFisica = _condicionFisicaCtrl.text.trim();
      p.fotoUrl = _fotoUrlCtrl.text.trim().isEmpty ? null : _fotoUrlCtrl.text.trim();
      final db = DatabaseService.instance;
      await db.initialize();
      await db.savePlayer(p);
      if (mounted) Navigator.of(context).pop(true);
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
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerHighest,
        title: Text('Editar Atleta', style: TextStyle(color: cs.onSurface, fontSize: 16)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _guardar,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                : const Text('Guardar', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Información personal'),
            const SizedBox(height: 8),
            _buildTextField(_firstNamesCtrl, 'Nombres', Icons.person_rounded, validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null),
            const SizedBox(height: 10),
            _buildTextField(_lastNamesCtrl, 'Apellidos', Icons.person_rounded, validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null),
            const SizedBox(height: 10),
            _buildTextField(_cedulaCtrl, 'Cédula', Icons.badge_rounded),
            const SizedBox(height: 20),
            _section('Información deportiva'),
            const SizedBox(height: 8),
            _buildTextField(_numeroCtrl, 'Número', Icons.tag_rounded, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            const SizedBox(height: 10),
            _buildDropdown('Posición', _posicion, Posicion.values, (v) => setState(() => _posicion = v), _posicionLabel),
            const SizedBox(height: 10),
            _buildFechaPicker(),
            const SizedBox(height: 20),
            _section('Estado'),
            const SizedBox(height: 8),
            _buildDropdown('Estado de salud', _estadoSalud, EstadoSalud.values, (v) => setState(() => _estadoSalud = v), _saludLabel),
            const SizedBox(height: 10),
            _buildTextField(_condicionFisicaCtrl, 'Condición física', Icons.fitness_center_rounded),
            const SizedBox(height: 10),
            SwitchListTile(
              title: Text('Capitana', style: TextStyle(color: cs.onSurface, fontSize: 14)),
              value: _esCapitan,
              onChanged: (v) => setState(() => _esCapitan = v),
              activeColor: AppColors.accent,
              secondary: Icon(Icons.star_rounded, color: _esCapitan ? AppColors.accent : cs.onSurface.withValues(alpha: 0.38)),
            ),
            if (_fotoUrlCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildTextField(_fotoUrlCtrl, 'URL de foto', Icons.image_rounded),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Text(title, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8));
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {String? Function(String?)? validator, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        controller: ctrl,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: cs.onSurface, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(String label, T value, List<T> items, ValueChanged<T> onChanged, String Function(T) labelFn) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          prefixIcon: Icon(Icons.swap_vert_rounded, size: 18, color: AppColors.textSecondary),
        ),
        style: TextStyle(color: cs.onSurface, fontSize: 14),
        dropdownColor: cs.surfaceContainerHighest,
        items: items.map((v) => DropdownMenuItem(value: v, child: Text(labelFn(v)))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }

  Widget _buildFechaPicker() {
    final cs = Theme.of(context).colorScheme;
    final edad = DateTime.now().year - _fechaNacimiento.year;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: const Icon(Icons.cake_rounded, size: 18, color: AppColors.textSecondary),
        title: Text('${_fechaNacimiento.day}/${_fechaNacimiento.month}/${_fechaNacimiento.year}', style: TextStyle(color: cs.onSurface, fontSize: 14)),
        subtitle: Text('$edad años', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        trailing: const Icon(Icons.edit_calendar_rounded, color: AppColors.textSecondary, size: 18),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _fechaNacimiento,
            firstDate: DateTime(1970),
            lastDate: DateTime.now(),
            builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.dark(primary: AppColors.accent, surface: cs.surfaceContainerHighest),
            ), child: child!),
          );
          if (picked != null) setState(() => _fechaNacimiento = picked);
        },
      ),
    );
  }

  String _posicionLabel(Posicion p) {
    switch (p) {
      case Posicion.colocador: return 'Armador';
      case Posicion.opuesto: return 'Opuesto';
      case Posicion.central: return 'Central';
      case Posicion.receptor: return 'Punta';
      case Posicion.libre: return 'Líbero';
      case Posicion.sinDefinir: return 'Sin definir';
    }
  }

  String _saludLabel(EstadoSalud s) {
    switch (s) {
      case EstadoSalud.disponible: return 'Disponible';
      case EstadoSalud.lesionado: return 'Lesionado';
      case EstadoSalud.enDuda: return 'En duda';
    }
  }
}
