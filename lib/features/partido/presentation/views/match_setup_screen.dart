import 'package:flutter/material.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/match_config.dart';
import 'player_selection_screen.dart';

class MatchSetupScreen extends StatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  final _localCtrl = TextEditingController();
  final _visitorCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  TipoPartido _tipoPartido = TipoPartido.amistoso;
  int _setsTotales = 5;

  @override
  void dispose() {
    _localCtrl.dispose();
    _visitorCtrl.dispose();
    _lugarCtrl.dispose();
    super.dispose();
  }

  void _continuar() {
    final local = _localCtrl.text.trim();
    final visitor = _visitorCtrl.text.trim();
    if (local.isEmpty || visitor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa los nombres de ambos equipos'), backgroundColor: Colors.red),
      );
      return;
    }
    final config = MatchConfig(
      localName: local,
      visitorName: visitor,
      setsTotales: _setsTotales,
      tipoPartido: _tipoPartido,
      lugar: _lugarCtrl.text.trim().isEmpty ? null : _lugarCtrl.text.trim(),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerSelectionScreen(config: config)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Configurar Partido', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('assets/images/logo_libero.png', width: 80, height: 80),
            const SizedBox(height: 20),
            const Text(
              'NUEVO PARTIDO',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFFF8C00), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 32),
            _section('Equipos'),
            const SizedBox(height: 12),
            _buildTextField(_localCtrl, 'Equipo Local', Icons.shield),
            const SizedBox(height: 12),
            _buildTextField(_visitorCtrl, 'Equipo Visitante', Icons.shield_outlined),
            const SizedBox(height: 24),
            _section('Detalles'),
            const SizedBox(height: 12),
            _buildTipoDropdown(),
            const SizedBox(height: 12),
            _buildSetsSelector(),
            const SizedBox(height: 12),
            _buildTextField(_lugarCtrl, 'Lugar (opcional)', Icons.location_on),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _continuar,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Seleccionar Jugadores'),
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
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFFF8C00), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
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
      ),
    );
  }

  Widget _buildTipoDropdown() {
    return DropdownButtonFormField<TipoPartido>(
      value: _tipoPartido,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Tipo de Partido',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.category, color: Color(0xFF0081CF), size: 20),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: const [
        DropdownMenuItem(value: TipoPartido.amistoso, child: Text('Amistoso')),
        DropdownMenuItem(value: TipoPartido.liga, child: Text('Liga')),
        DropdownMenuItem(value: TipoPartido.torneo, child: Text('Torneo')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _tipoPartido = v);
      },
    );
  }

  Widget _buildSetsSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_list_numbered, color: Color(0xFF0081CF), size: 20),
          const SizedBox(width: 12),
          const Text('Sets a ganar:', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          _setChip(3),
          const SizedBox(width: 8),
          _setChip(5),
        ],
      ),
    );
  }

  Widget _setChip(int n) {
    final selected = _setsTotales == n;
    return GestureDetector(
      onTap: () => setState(() => _setsTotales = n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF8C00) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFFF8C00) : Colors.white24,
          ),
        ),
        child: Text(
          '$n',
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
