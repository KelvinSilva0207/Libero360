import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/cedula_formatter.dart';
import '../../../estadisticas/data/models/models.dart';
import '../viewmodels/athlete_viewmodel.dart';

class AthleteFormScreen extends StatefulWidget {
  final Player? existing;
  const AthleteFormScreen({super.key, this.existing});

  @override
  State<AthleteFormScreen> createState() => _AthleteFormScreenState();
}

class _AthleteFormScreenState extends State<AthleteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNamesCtrl = TextEditingController();
  final _lastNamesCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _condicionFisicaCtrl = TextEditingController(text: 'Excelente');

  DateTime _fechaNacimiento = DateTime.now().subtract(const Duration(days: 365 * 20));
  DateTime _fechaIngreso = DateTime.now();
  Posicion _posicion = Posicion.sinDefinir;
  Posicion _posicionSecundaria = Posicion.sinDefinir;
  Sexo _sexo = Sexo.masculino;
  TipoSangre _tipoSangre = TipoSangre.oPositivo;
  ManoDominante _manoDominante = ManoDominante.derecha;
  bool _esCapitan = false;
  EstadoSalud _estadoSalud = EstadoSalud.disponible;
  bool _saving = false;
  File? _fotoFile;

  final _picker = ImagePicker();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.existing!;
      _firstNamesCtrl.text = p.firstNames;
      _lastNamesCtrl.text = p.lastNames;
      _cedulaCtrl.text = p.cedula;
      _numeroCtrl.text = p.numero?.toString() ?? '';
      if (p.altura > 0) _alturaCtrl.text = p.altura.toStringAsFixed(1);
      _condicionFisicaCtrl.text = p.condicionFisica;
      _fechaNacimiento = p.fechaNacimiento;
      _fechaIngreso = p.fechaIngreso;
      _posicion = p.posicion;
      _posicionSecundaria = p.posicionSecundaria;
      _sexo = p.sexo;
      _tipoSangre = p.tipoSangre;
      _manoDominante = p.manoDominante;
      _esCapitan = p.esCapitan;
      _estadoSalud = p.estadoSalud;
    }
  }

  @override
  void dispose() {
    _firstNamesCtrl.dispose();
    _lastNamesCtrl.dispose();
    _cedulaCtrl.dispose();
    _numeroCtrl.dispose();
    _alturaCtrl.dispose();
    _condicionFisicaCtrl.dispose();
    super.dispose();
  }

  int get _edadCalculada {
    final hoy = DateTime.now();
    int edad = hoy.year - _fechaNacimiento.year;
    if (hoy.month < _fechaNacimiento.month ||
        (hoy.month == _fechaNacimiento.month && hoy.day < _fechaNacimiento.day)) {
      edad--;
    }
    return edad;
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
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  Future<void> _pickIngresoDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso,
      firstDate: DateTime(2000),
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
    if (picked != null) setState(() => _fechaIngreso = picked);
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Foto del atleta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imageSourceOption(ctx, Icons.camera_alt_rounded, 'Cámara', ImageSource.camera),
                _imageSourceOption(ctx, Icons.photo_library_rounded, 'Galería', ImageSource.gallery),
              ],
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 600);
    if (picked != null) setState(() => _fotoFile = File(picked.path));
  }

  Widget _imageSourceOption(BuildContext ctx, IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, source),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.accent, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final alt = double.tryParse(_alturaCtrl.text.trim().replaceAll(',', '.'));
      final player = Player.create(
        firstNames: _firstNamesCtrl.text.trim(),
        lastNames: _lastNamesCtrl.text.trim(),
        cedula: unformatCedula(_cedulaCtrl.text.trim()),
        fechaNacimiento: _fechaNacimiento,
        numero: _numeroCtrl.text.trim().isEmpty ? null : int.parse(_numeroCtrl.text.trim()),
        posicion: _posicion,
        esCapitan: _esCapitan,
        estadoSalud: _estadoSalud,
        condicionFisica: _condicionFisicaCtrl.text.trim(),
        sexo: _sexo,
        altura: alt ?? 0,
        tipoSangre: _tipoSangre,
        manoDominante: _manoDominante,
        posicionSecundaria: _posicionSecundaria,
        fechaIngreso: _fechaIngreso,
      );

      if (_isEditing) {
        player.id = widget.existing!.id;
        player.fotoUrl = widget.existing!.fotoUrl;
        player.profileId = widget.existing!.profileId;
        player.clubId = widget.existing!.clubId;
        player.createdAt = widget.existing!.createdAt;
      }

      final vm = context.read<AthleteViewModel>();
      final ok = await vm.save(player);
      if (mounted) {
        if (ok) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${vm.error}'), backgroundColor: Colors.red),
          );
        }
      }
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
    final isEditing = _isEditing;
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        title: Text(isEditing ? 'Editar Atleta' : 'Nuevo Atleta',
          style: const TextStyle(color: Colors.white)),
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
              _section('Foto'),
              const SizedBox(height: 8),
              _buildPhotoPicker(),
              const SizedBox(height: 20),
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
              _buildTextField(
                _cedulaCtrl, 'Cédula', Icons.badge,
                keyboardType: TextInputType.number,
                inputFormatters: [CedulaFormatter()],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingrese la cédula';
                  final digits = v.replaceAll('.', '');
                  if (digits.length < 9) return 'Cédula incompleta';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildDateField('Fecha de Nacimiento', _fechaNacimiento, Icons.cake, _pickDate, _edadCalculada),
              const SizedBox(height: 12),
              _buildDateField('Fecha de Ingreso', _fechaIngreso, Icons.assignment_ind, _pickIngresoDate, null),
              const SizedBox(height: 20),
              _section('Categoría'),
              const SizedBox(height: 4),
              _buildCategoryDisplay(),
              const SizedBox(height: 20),
              _section('Datos Físicos'),
              const SizedBox(height: 8),
              _buildSexoDropdown(),
              const SizedBox(height: 12),
              _buildTextField(
                _alturaCtrl, 'Altura (cm, opcional)', Icons.height,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              ),
              const SizedBox(height: 12),
              _buildTipoSangreDropdown(),
              const SizedBox(height: 12),
              _buildManoDropdown(),
              const SizedBox(height: 20),
              _section('Posición y Rol'),
              const SizedBox(height: 8),
              _buildPosicionDropdown('Posición Principal', _posicion, (v) {
                if (v != null) setState(() => _posicion = v);
              }),
              const SizedBox(height: 12),
              _buildPosicionDropdown('Posición Secundaria', _posicionSecundaria, (v) {
                if (v != null) setState(() => _posicionSecundaria = v);
              }),
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
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Guardando...' : (isEditing ? 'Guardar Cambios' : 'Guardar Atleta')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
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

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _fotoFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_fotoFile!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.camera_alt, color: AppColors.primaryLight, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Foto del atleta', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  _fotoFile != null ? 'Foto seleccionada' : 'Toca para agregar foto',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDisplay() {
    final edad = _edadCalculada;
    final cat = _categoriaForAge(edad);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(cat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Text('$edad años', style: const TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  String _categoriaForAge(int age) {
    if (age <= 12) return 'U13';
    if (age <= 14) return 'U15';
    if (age <= 16) return 'U17';
    if (age <= 18) return 'U19';
    return 'Libre';
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
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
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

  Widget _buildDateField(String label, DateTime date, IconData icon, VoidCallback onTap, int? edad) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: edad != null ? '$label ($edad años)' : label,
            labelStyle: const TextStyle(color: Colors.white54),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.white38, size: 18),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
          controller: TextEditingController(
            text: '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
          ),
          validator: (_) => null,
        ),
      ),
    );
  }

  Widget _buildSexoDropdown() {
    return DropdownButtonFormField<Sexo>(
      value: _sexo,
      dropdownColor: AppColors.surfaceLight,
      style: const TextStyle(color: Colors.white),
      decoration: _dropdownDecoration('Sexo', Icons.wc),
      items: Sexo.values.map((e) {
        return DropdownMenuItem(value: e, child: Text(e == Sexo.masculino ? 'Masculino' : 'Femenino'));
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _sexo = v);
      },
    );
  }

  Widget _buildTipoSangreDropdown() {
    return DropdownButtonFormField<TipoSangre>(
      value: _tipoSangre,
      dropdownColor: AppColors.surfaceLight,
      style: const TextStyle(color: Colors.white),
      decoration: _dropdownDecoration('Tipo de Sangre', Icons.bloodtype),
      items: TipoSangre.values.map((e) {
        final label = {
          TipoSangre.aPositivo: 'A+',
          TipoSangre.aNegativo: 'A-',
          TipoSangre.bPositivo: 'B+',
          TipoSangre.bNegativo: 'B-',
          TipoSangre.abPositivo: 'AB+',
          TipoSangre.abNegativo: 'AB-',
          TipoSangre.oPositivo: 'O+',
          TipoSangre.oNegativo: 'O-',
        }[e] ?? e.name;
        return DropdownMenuItem(value: e, child: Text(label));
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _tipoSangre = v);
      },
    );
  }

  Widget _buildManoDropdown() {
    return DropdownButtonFormField<ManoDominante>(
      value: _manoDominante,
      dropdownColor: AppColors.surfaceLight,
      style: const TextStyle(color: Colors.white),
      decoration: _dropdownDecoration('Mano Dominante', Icons.pan_tool),
      items: ManoDominante.values.map((e) {
        final label = {
          ManoDominante.derecha: 'Derecha',
          ManoDominante.izquierda: 'Izquierda',
          ManoDominante.ambidiestro: 'Ambidiestro',
        }[e] ?? e.name;
        return DropdownMenuItem(value: e, child: Text(label));
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _manoDominante = v);
      },
    );
  }

  Widget _buildPosicionDropdown(String label, Posicion value, ValueChanged<Posicion?> onChanged) {
    return DropdownButtonFormField<Posicion>(
      value: value,
      dropdownColor: AppColors.surfaceLight,
      style: const TextStyle(color: Colors.white),
      decoration: _dropdownDecoration(label, Icons.sports),
      items: Posicion.values.map((p) {
        return DropdownMenuItem(value: p, child: Text(_posicionLabel(p)));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSaludDropdown() {
    return DropdownButtonFormField<EstadoSalud>(
      value: _estadoSalud,
      dropdownColor: AppColors.surfaceLight,
      style: const TextStyle(color: Colors.white),
      decoration: _dropdownDecoration('Estado de Salud', Icons.health_and_safety),
      items: EstadoSalud.values.map((e) {
        return DropdownMenuItem(value: e, child: Text(_saludLabel(e)));
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _estadoSalud = v);
      },
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Widget _buildSwitchRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
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
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
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
