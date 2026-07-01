import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/category_calculator.dart';
import '../../../../core/utils/cedula_formatter.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../categories/presentation/widgets/category_selector.dart';
import '../viewmodels/athlete_viewmodel.dart';
import '../../../../core/utils/name_formatter.dart';

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
  String? _categoriaOverride;
  bool _saving = false;
  bool _hasCamera = false;
  File? _fotoFile;

  final _picker = ImagePicker();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _checkCameraAvailability();
    if (_isEditing) {
      final p = widget.existing!;
      _firstNamesCtrl.text = p.firstNames;
      _lastNamesCtrl.text = p.lastNames;
      _cedulaCtrl.text = formatCedula(p.cedula);
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
      _categoriaOverride = p.categoriaPersonalizada;
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

  void _checkCameraAvailability() {
    setState(() => _hasCamera = _picker.supportsImageSource(ImageSource.camera));
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
    final cs = Theme.of(context).colorScheme;
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Seleccionar fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.accent,
            onPrimary: cs.onPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  Future<void> _pickIngresoDate() async {
    final cs = Theme.of(context).colorScheme;
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Seleccionar fecha de ingreso',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.accent,
            onPrimary: cs.onPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _fechaIngreso = picked);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 600);
    if (picked != null) {
      setState(() => _fotoFile = File(picked.path));
    }
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
        categoria: _categoriaOverride,
      );

      if (_isEditing) {
        final e = widget.existing!;
        player.id = e.id;
        player.fotoUrl = e.fotoUrl;
        player.profileId = e.profileId;
        player.clubId = e.clubId;
        player.createdAt = e.createdAt;
        player.atletaStatus = e.atletaStatus;
        player.statusReason = e.statusReason;
        player.statusStartDate = e.statusStartDate;
        player.statusEndDate = e.statusEndDate;
        player.restriccion = e.restriccion;
      }

      if (_fotoFile != null) {
        player.fotoUrl = _fotoFile!.path;
      }

      final vm = context.read<AthleteViewModel>();
      final ok = await vm.save(player);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Atleta actualizado correctamente' : 'Atleta registrado'),
              backgroundColor: const Color(0xFF22C55E),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No fue posible guardar los cambios'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible guardar los cambios'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = _isEditing;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerHighest,
        title: Text(isEditing ? 'Editar Atleta' : 'Nuevo Atleta',
          style: TextStyle(color: cs.onSurface)),
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
              _animatedSection(Icons.person, 'INFORMACIÓN PERSONAL', 'Datos básicos del atleta', [
                _buildTextField(_firstNamesCtrl, 'Nombres', Icons.person, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingrese los nombres';
                  return null;
                }, cs: cs),
                const SizedBox(height: 12),
                _buildTextField(_lastNamesCtrl, 'Apellidos', Icons.person_outline_rounded, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingrese los apellidos';
                  return null;
                }, cs: cs),
                const SizedBox(height: 12),
                _buildSexoDropdown(cs),
                const SizedBox(height: 12),
                _buildBirthDateField(cs),
                const SizedBox(height: 12),
                _buildTextField(
                  _cedulaCtrl, 'Cédula', Icons.badge,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CedulaFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingrese la cédula';
                    if (!CedulaFormatter.isValid(v)) return 'Cédula inválida';
                    return null;
                  },
                  cs: cs,
                ),
                const SizedBox(height: 12),
                _buildDateField('Fecha de Ingreso', _fechaIngreso, Icons.assignment_ind, _pickIngresoDate, null, cs),
              ], delay: Duration.zero, cs: cs),
              const SizedBox(height: 24),
              _animatedSection(Icons.sports_volleyball, 'INFORMACIÓN DEPORTIVA', 'Rol y capacidades en el campo', [
                _buildTextField(
                  _numeroCtrl, 'Número Camiseta', Icons.format_list_numbered,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d]'))],
                  cs: cs,
                ),
                const SizedBox(height: 12),
                _buildPosicionDropdown('Posición Principal', _posicion, (v) {
                  if (v != null) setState(() => _posicion = v);
                }, cs),
                const SizedBox(height: 12),
                _buildPosicionDropdown('Posición Secundaria', _posicionSecundaria, (v) {
                  if (v != null) setState(() => _posicionSecundaria = v);
                }, cs),
                const SizedBox(height: 12),
                _buildTextField(
                  _alturaCtrl, 'Altura (cm)', Icons.height,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  cs: cs,
                ),
                const SizedBox(height: 12),
                _buildManoDropdown(cs),
                const SizedBox(height: 12),
                CategorySelector(
                  selectedCategory: _categoriaOverride,
                  onChanged: (v) => setState(() => _categoriaOverride = v),
                  label: 'Categoría (opcional)',
                ),
                const SizedBox(height: 12),
                _buildSwitchRow(Icons.star, '¿Es Capitán?', _esCapitan, (v) {
                  setState(() => _esCapitan = v);
                }, cs),
              ], delay: const Duration(milliseconds: 80), cs: cs),
              const SizedBox(height: 24),
              _animatedSection(Icons.medical_services, 'INFORMACIÓN MÉDICA', 'Datos de salud del atleta', [
                _buildTipoSangreDropdown(cs),
                const SizedBox(height: 12),
                _buildSaludDropdown(cs),
                const SizedBox(height: 12),
                _buildTextField(_condicionFisicaCtrl, 'Condición Física', Icons.fitness_center, cs: cs),
              ], delay: const Duration(milliseconds: 160), cs: cs),
              const SizedBox(height: 24),
              _animatedSection(Icons.camera_alt, 'FOTOGRAFÍA', 'Imagen del atleta', [
                _buildPhotoSection(cs),
              ], delay: const Duration(milliseconds: 240), cs: cs),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Guardando...' : (isEditing ? 'Guardar Cambios' : 'Guardar Atleta')),
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

  Widget _buildPhotoSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_fotoFile != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(image: FileImage(_fotoFile!), fit: BoxFit.cover),
            ),
          ),
        if (_hasCamera)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Seleccionar imagen'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Tomar fotografía'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Seleccionar imagen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
            ),
          ),
      ],
    );
  }

  Widget _buildBirthDateField(ColorScheme cs) {
    final edad = _edadCalculada;
    final cat = CategoryCalculator.calculate(edad);
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cake, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text('Fecha de Nacimiento',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _formatDate(_fechaNacimiento),
                  style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Icon(Icons.edit_calendar_rounded, color: AppColors.accent, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _ageChip('$edad años', AppColors.primary),
                const SizedBox(width: 8),
                _ageChip(cat, AppColors.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ageChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _sectionCard(IconData icon, String title, String subtitle, ColorScheme cs) {
    return Card(
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    required ColorScheme cs,
  }) {
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
        fillColor: cs.surfaceContainerHighest,
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

  Widget _buildDateField(String label, DateTime date, IconData icon, VoidCallback onTap, int? edad, ColorScheme cs) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            labelText: edad != null ? '$label ($edad años)' : label,
            labelStyle: TextStyle(color: cs.onSurfaceVariant),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            filled: true,
            fillColor: cs.surfaceContainerHighest,
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
            text: '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
          ),
          validator: (_) => null,
        ),
      ),
    );
  }

  Widget _buildSexoDropdown(ColorScheme cs) {
    return DropdownButtonFormField<Sexo>(
      value: _sexo,
      dropdownColor: cs.surfaceContainerHighest,
      style: TextStyle(color: cs.onSurface),
      decoration: _dropdownDecoration('Sexo', Icons.wc, cs),
      items: Sexo.values.map((e) {
        return DropdownMenuItem(value: e, child: Text(e == Sexo.masculino ? 'Masculino' : 'Femenino'));
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _sexo = v);
      },
    );
  }

  Widget _buildTipoSangreDropdown(ColorScheme cs) {
    return DropdownButtonFormField<TipoSangre>(
      value: _tipoSangre,
      dropdownColor: cs.surfaceContainerHighest,
      style: TextStyle(color: cs.onSurface),
      decoration: _dropdownDecoration('Tipo de Sangre', Icons.bloodtype, cs),
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

  Widget _buildManoDropdown(ColorScheme cs) {
    return DropdownButtonFormField<ManoDominante>(
      value: _manoDominante,
      dropdownColor: cs.surfaceContainerHighest,
      style: TextStyle(color: cs.onSurface),
      decoration: _dropdownDecoration('Mano Dominante', Icons.pan_tool, cs),
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

  Widget _buildPosicionDropdown(String label, Posicion value, ValueChanged<Posicion?> onChanged, ColorScheme cs) {
    return DropdownButtonFormField<Posicion>(
      value: value,
      dropdownColor: cs.surfaceContainerHighest,
      style: TextStyle(color: cs.onSurface),
      decoration: _dropdownDecoration(label, Icons.sports, cs),
      items: Posicion.values.map((p) {
        return DropdownMenuItem(value: p, child: Text(_posicionLabel(p)));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSaludDropdown(ColorScheme cs) {
    return DropdownButtonFormField<EstadoSalud>(
      value: _estadoSalud,
      dropdownColor: cs.surfaceContainerHighest,
      style: TextStyle(color: cs.onSurface),
      decoration: _dropdownDecoration('Estado de Salud', Icons.health_and_safety, cs),
      items: EstadoSalud.values.map((e) {
        return DropdownMenuItem(value: e, child: Text(_saludLabel(e)));
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _estadoSalud = v);
      },
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon, ColorScheme cs) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      prefixIcon: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Widget _buildSwitchRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
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

  Widget _animatedSection(IconData icon, String title, String subtitle, List<Widget> fields, {required Duration delay, required ColorScheme cs}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400) + delay,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionCard(icon, title, subtitle, cs),
          const SizedBox(height: 16),
          ...fields,
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

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
