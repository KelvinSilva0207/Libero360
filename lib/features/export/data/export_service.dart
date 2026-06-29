import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:excel/excel.dart' as xl;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../asistencia/data/medical_leave_model.dart';
import '../../asistencia/data/medical_leave_repository.dart';
import '../../estadisticas/data/local_db/database_service.dart';
import '../../estadisticas/data/models/attendance_record.dart';
import '../../estadisticas/data/models/match.dart';
import '../../estadisticas/data/models/player.dart';
import '../../estadisticas/data/models/stat_event.dart';
import '../../estadisticas/data/models/models.dart';
import '../../partido/data/match_event.dart';
import '../../statistics/data/rotation_stats_model.dart';

enum ExportFormat { csv, excel, pdf }

enum ExportDataType {
  playerStats,
  teamStats,
  attendance,
  medicalLeaves,
  matches,
  timeline,
  rotations,
  service,
  dashboard,
}

class ExportResult {
  final Uint8List bytes;
  final String mimeType;
  final String fileName;

  const ExportResult({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });
}

class ExportService {
  static final ExportService instance = ExportService._internal();
  ExportService._internal();

  final DatabaseService _db = DatabaseService.instance;
  final MedicalLeaveRepository _medicalRepo = MedicalLeaveRepository.instance;
  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');
  final DateFormat _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');

  String get _brand => 'Libero360';
  String get _version => '3.0.0';

  // ==========================================================
  // PUBLIC API
  // ==========================================================

  Future<ExportResult> export(
    ExportDataType type,
    ExportFormat format, {
    String? profileId,
    String? clubId,
  }) async {
    switch (format) {
      case ExportFormat.csv:
        final csv = await _buildCsv(type, profileId: profileId, clubId: clubId);
        final bytes = utf8.encode(csv);
        return ExportResult(
          bytes: Uint8List.fromList(bytes),
          mimeType: 'text/csv',
          fileName: '${_fileName(type)}.csv',
        );
      case ExportFormat.excel:
        final bytes = await _buildExcel(type, profileId: profileId, clubId: clubId);
        return ExportResult(
          bytes: bytes,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          fileName: '${_fileName(type)}.xlsx',
        );
      case ExportFormat.pdf:
        final bytes = await _buildPdf(type, profileId: profileId, clubId: clubId);
        return ExportResult(
          bytes: bytes,
          mimeType: 'application/pdf',
          fileName: '${_fileName(type)}.pdf',
        );
    }
  }

  Future<void> share(ExportResult result) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${result.fileName}');
    await file.writeAsBytes(result.bytes);
    await Share.shareXFiles([XFile(file.path)], text: '$_brand - Exportación');
  }

  // ==========================================================
  // FILE NAME HELPERS
  // ==========================================================

  String _fileName(ExportDataType type) {
    final now = DateTime.now();
    final ts = DateFormat('yyyyMMdd_HHmmss').format(now);
    switch (type) {
      case ExportDataType.playerStats: return '${_brand}_EstadisticasIndividuales_$ts';
      case ExportDataType.teamStats: return '${_brand}_EstadisticasEquipo_$ts';
      case ExportDataType.attendance: return '${_brand}_Asistencia_$ts';
      case ExportDataType.medicalLeaves: return '${_brand}_Reposos_$ts';
      case ExportDataType.matches: return '${_brand}_Partidos_$ts';
      case ExportDataType.timeline: return '${_brand}_Timeline_$ts';
      case ExportDataType.rotations: return '${_brand}_Rotaciones_$ts';
      case ExportDataType.service: return '${_brand}_Servicio_$ts';
      case ExportDataType.dashboard: return '${_brand}_Dashboard_$ts';
    }
  }

  // ==========================================================
  // CHECKSUM
  // ==========================================================

  String _computeChecksum(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  // ==========================================================
  // DATA HELPERS
  // ==========================================================

  Future<List<Player>> _getPlayers({String? profileId}) async {
    final all = await _db.getActivePlayers();
    if (profileId != null) return all.where((p) => p.profileId == profileId).toList();
    return all;
  }

  Future<List<Match>> _getMatches({String? profileId}) async {
    final all = await _db.getAllMatches();
    if (profileId != null) return all.where((m) => m.profileId == profileId).toList();
    return all;
  }

  Future<List<AttendanceRecord>> _getAttendance({String? profileId}) async {
    final all = await _db.getAllAttendanceRecords();
    if (profileId != null) return all.where((a) => a.profileId == profileId).toList();
    return all;
  }

  Future<List<StatEvent>> _getStats({String? profileId}) async {
    final all = await _db.getAllEvents();
    if (profileId != null) return all.where((e) => e.profileId == profileId).toList();
    return all;
  }

  Future<List<RotationStatsRecord>> _getRotations() async {
    return _db.getAllRotationStatsRecords();
  }

  Future<List<MedicalLeave>> _getMedicalLeaves() async {
    return _medicalRepo.getAll();
  }

  // ==========================================================
  // CSV BUILDER
  // ==========================================================

  Future<String> _buildCsv(ExportDataType type, {String? profileId, String? clubId}) async {
    final buf = StringBuffer();
    buf.writeln('$_brand - $_version');
    buf.writeln('Exportado: ${_dateTimeFmt.format(DateTime.now())}');
    buf.writeln('');

    switch (type) {
      case ExportDataType.playerStats:
        await _writePlayerStatsCsv(buf, profileId: profileId);
      case ExportDataType.teamStats:
        await _writeTeamStatsCsv(buf, profileId: profileId);
      case ExportDataType.attendance:
        await _writeAttendanceCsv(buf, profileId: profileId);
      case ExportDataType.medicalLeaves:
        await _writeMedicalLeavesCsv(buf);
      case ExportDataType.matches:
        await _writeMatchesCsv(buf, profileId: profileId);
      case ExportDataType.timeline:
        await _writeTimelineCsv(buf, profileId: profileId);
      case ExportDataType.rotations:
        await _writeRotationsCsv(buf);
      case ExportDataType.service:
        await _writeServiceCsv(buf, profileId: profileId);
      case ExportDataType.dashboard:
        await _writeDashboardCsv(buf, profileId: profileId);
    }

    final csv = buf.toString();
    buf.writeln('');
    buf.writeln('# Checksum: ${_computeChecksum(csv)}');
    return buf.toString();
  }

  Future<void> _writePlayerStatsCsv(StringBuffer buf, {String? profileId}) async {
    final players = await _getPlayers(profileId: profileId);
    final events = await _getStats(profileId: profileId);

    buf.writeln('Jugadora,Nº,Posición,F.Nacimiento,Edad,Ataques,Bloqueos,Servicios,Recepciones,Defensas,Total');
    for (final p in players) {
      final pe = events.where((e) => e.playerId == p.id).toList();
      final ataques = pe.where((e) => e.tipoAccion == TipoAccion.ataque).length;
      final bloqueos = pe.where((e) => e.tipoAccion == TipoAccion.bloqueo).length;
      final servicios = pe.where((e) => e.tipoAccion == TipoAccion.saque).length;
      final recepciones = pe.where((e) => e.tipoAccion == TipoAccion.recepcion).length;
      final defensas = pe.where((e) => e.tipoAccion == TipoAccion.defensa).length;
      buf.writeln('"${p.displayName}",${p.numero ?? ""},"${p.posicion.name}","${_dateFmt.format(p.fechaNacimiento)}",${p.edad},$ataques,$bloqueos,$servicios,$recepciones,$defensas,${pe.length}');
    }
  }

  Future<void> _writeTeamStatsCsv(StringBuffer buf, {String? profileId}) async {
    final events = await _getStats(profileId: profileId);
    final total = events.length;
    final porTipo = <String, int>{};
    for (final e in events) {
      porTipo[e.tipoAccion.name] = (porTipo[e.tipoAccion.name] ?? 0) + 1;
    }
    buf.writeln('Tipo,Cantidad,Porcentaje');
    for (final entry in porTipo.entries) {
      final pct = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0.0';
      buf.writeln('"${entry.key}",${entry.value},$pct%');
    }
    buf.writeln('Total,$total,100%');
  }

  Future<void> _writeAttendanceCsv(StringBuffer buf, {String? profileId}) async {
    final records = await _getAttendance(profileId: profileId);
    buf.writeln('Jugadora,Fecha,Asistió,Observaciones');
    for (final r in records) {
      final player = await _db.getPlayerById(r.playerId);
      final name = player?.displayName ?? 'ID ${r.playerId}';
      buf.writeln('"$name","${_dateFmt.format(r.fecha)}",${r.asistio ? "Sí" : "No"},"${r.observaciones}"');
    }
  }

  Future<void> _writeMedicalLeavesCsv(StringBuffer buf) async {
    final leaves = await _getMedicalLeaves();
    buf.writeln('Jugadora,Razón,Inicio,Fin,Estado,Notas');
    for (final l in leaves) {
      final player = await _db.getPlayerById(l.playerId);
      final name = player?.displayName ?? 'ID ${l.playerId}';
      final end = l.endDate != null ? _dateFmt.format(l.endDate!) : '';
      buf.writeln('"$name","${l.reason}","${_dateFmt.format(l.startDate)}","$end","${l.status.name}","${l.notes}"');
    }
  }

  Future<void> _writeMatchesCsv(StringBuffer buf, {String? profileId}) async {
    final matches = await _getMatches(profileId: profileId);
    buf.writeln('Fecha,Local,Visitante,Puntos L,Puntos V,Sets L,Sets V,Resultado,Tipo,Competencia,Lugar');
    for (final m in matches) {
      buf.writeln('"${_dateFmt.format(m.fecha)}","${m.equipoLocal}","${m.equipoVisitante}",${m.puntosLocal},${m.puntosVisitante},${m.setsLocal},${m.setsVisitante},"${m.resultadoFinal ?? ""}","${m.tipoPartido.name}","${m.competitionName ?? ""}","${m.lugar ?? ""}"');
    }
  }

  Future<void> _writeTimelineCsv(StringBuffer buf, {String? profileId}) async {
    final events = await _getStats(profileId: profileId);
    buf.writeln('Fecha,Jugadora,Acción,Resultado,Set,Puntos');
    for (final e in events) {
      final player = await _db.getPlayerById(e.playerId);
      final name = player?.displayName ?? 'ID ${e.playerId}';
      buf.writeln('"${_dateTimeFmt.format(e.timestamp)}","$name","${e.tipoAccion.name}","${e.resultado.name}",${e.setNumero},${e.puntoLocal}-${e.puntoVisitante}');
    }
  }

  Future<void> _writeRotationsCsv(StringBuffer buf) async {
    final rotations = await _getRotations();
    buf.writeln('Partido,Set,Rotación,Puntos Ganados,Puntos Perdidos,Efectividad');
    for (final r in rotations) {
      final eff = r.totalPoints > 0 ? (r.pointsWon / r.totalPoints * 100).toStringAsFixed(1) : '0.0';
      buf.writeln('${r.matchId},${r.setNumber},${r.rotationIndex + 1},${r.pointsWon},${r.pointsLost},$eff%');
    }
  }

  Future<void> _writeServiceCsv(StringBuffer buf, {String? profileId}) async {
    final events = await _getStats(profileId: profileId);
    final serves = events.where((e) => e.tipoAccion == TipoAccion.saque).toList();
    buf.writeln('Jugadora,Servicios,Puntos Directos,Errores,Efectividad');
    final byPlayer = <int, List<StatEvent>>{};
    for (final s in serves) {
      byPlayer.putIfAbsent(s.playerId, () => []);
      byPlayer[s.playerId]!.add(s);
    }
    for (final entry in byPlayer.entries) {
      final player = await _db.getPlayerById(entry.key);
      final name = player?.displayName ?? 'ID ${entry.key}';
      final total = entry.value.length;
      final puntos = entry.value.where((e) => e.resultado == ResultadoAccion.exitoso).length;
      final errores = entry.value.where((e) => e.resultado == ResultadoAccion.error).length;
      final eff = total > 0 ? ((puntos - errores) / total * 100).toStringAsFixed(1) : '0.0';
      buf.writeln('"$name",$total,$puntos,$errores,$eff%');
    }
  }

  Future<void> _writeDashboardCsv(StringBuffer buf, {String? profileId}) async {
    final players = await _getPlayers(profileId: profileId);
    final matches = await _getMatches(profileId: profileId);
    final attendance = await _getAttendance(profileId: profileId);
    final events = await _getStats(profileId: profileId);
    final leaves = await _getMedicalLeaves();

    buf.writeln('Métrica,Valor');
    buf.writeln('Total Jugadoras,${players.length}');
    buf.writeln('Total Partidos,${matches.length}');
    buf.writeln('Total Asistencias,${attendance.length}');
    buf.writeln('Total Eventos,${events.length}');
    buf.writeln('Reposos Activos,${leaves.where((l) => l.isActive).length}');
    final won = matches.where((m) => m.resultadoFinal == 'Ganado' || m.puntosLocal > m.puntosVisitante).length;
    buf.writeln('Partidos Ganados,$won');
    buf.writeln('Partidos Perdidos,${matches.length - won}');
    buf.writeln('');
    buf.writeln('Categorías');
    final cats = <String, int>{};
    for (final p in players) {
      cats[p.categoria] = (cats[p.categoria] ?? 0) + 1;
    }
    for (final entry in cats.entries) {
      buf.writeln('"${entry.key}",${entry.value}');
    }
  }

  // ==========================================================
  // EXCEL BUILDER
  // ==========================================================

  Future<Uint8List> _buildExcel(ExportDataType type, {String? profileId, String? clubId}) async {
    final wb = xl.Excel.createExcel();
    final sheet = wb['${type.name}'];


    _writeExcelHeader(sheet);

    switch (type) {
      case ExportDataType.playerStats:
        await _writePlayerStatsExcel(sheet, profileId: profileId);
      case ExportDataType.teamStats:
        await _writeTeamStatsExcel(sheet, profileId: profileId);
      case ExportDataType.attendance:
        await _writeAttendanceExcel(sheet, profileId: profileId);
      case ExportDataType.medicalLeaves:
        await _writeMedicalLeavesExcel(sheet);
      case ExportDataType.matches:
        await _writeMatchesExcel(sheet, profileId: profileId);
      case ExportDataType.timeline:
        await _writeTimelineExcel(sheet, profileId: profileId);
      case ExportDataType.rotations:
        await _writeRotationsExcel(sheet);
      case ExportDataType.service:
        await _writeServiceExcel(sheet, profileId: profileId);
      case ExportDataType.dashboard:
        await _writeDashboardExcel(sheet, profileId: profileId);
    }

    return Uint8List.fromList(wb.encode()!);
  }

  void _writeExcelHeader(xl.Sheet sheet) {
    sheet.cell(xl.CellIndex.indexByString('A1')).value = xl.TextCellValue('$_brand - $_version');
    sheet.cell(xl.CellIndex.indexByString('A2')).value = xl.TextCellValue('Exportado: ${_dateTimeFmt.format(DateTime.now())}');
  }

  void _writeExcelRow(xl.Sheet sheet, int row, List<String> values) {
    for (var i = 0; i < values.length; i++) {
      final col = String.fromCharCode(65 + i);
      sheet.cell(xl.CellIndex.indexByString('$col$row')).value = xl.TextCellValue(values[i]);
    }
  }

  void _writeExcelHeaderRow(xl.Sheet sheet, int row, List<String> headers) {
    for (var i = 0; i < headers.length; i++) {
      final col = String.fromCharCode(65 + i);
      final cell = sheet.cell(xl.CellIndex.indexByString('$col$row'));
      cell.value = xl.TextCellValue(headers[i]);
      cell.cellStyle = xl.CellStyle(bold: true);
    }
  }

  Future<void> _writePlayerStatsExcel(xl.Sheet sheet, {String? profileId}) async {
    final players = await _getPlayers(profileId: profileId);
    final events = await _getStats(profileId: profileId);
    _writeExcelHeaderRow(sheet, 4, ['Jugadora', 'Nº', 'Posición', 'F.Nacimiento', 'Edad', 'Ataques', 'Bloqueos', 'Servicios', 'Recepciones', 'Defensas', 'Total']);
    var row = 5;
    for (final p in players) {
      final pe = events.where((e) => e.playerId == p.id).toList();
      _writeExcelRow(sheet, row++, [
        p.displayName, p.numero?.toString() ?? '', p.posicion.name, _dateFmt.format(p.fechaNacimiento),
        p.edad.toString(),
        pe.where((e) => e.tipoAccion == TipoAccion.ataque).length.toString(),
        pe.where((e) => e.tipoAccion == TipoAccion.bloqueo).length.toString(),
        pe.where((e) => e.tipoAccion == TipoAccion.saque).length.toString(),
        pe.where((e) => e.tipoAccion == TipoAccion.recepcion).length.toString(),
        pe.where((e) => e.tipoAccion == TipoAccion.defensa).length.toString(),
        pe.length.toString(),
      ]);
    }
  }

  Future<void> _writeTeamStatsExcel(xl.Sheet sheet, {String? profileId}) async {
    final events = await _getStats(profileId: profileId);
    final porTipo = <String, int>{};
    for (final e in events) {
      porTipo[e.tipoAccion.name] = (porTipo[e.tipoAccion.name] ?? 0) + 1;
    }
    _writeExcelHeaderRow(sheet, 4, ['Tipo', 'Cantidad', 'Porcentaje']);
    var row = 5;
    for (final entry in porTipo.entries) {
      final pct = events.length > 0 ? (entry.value / events.length * 100).toStringAsFixed(1) : '0.0';
      _writeExcelRow(sheet, row++, [entry.key, entry.value.toString(), '$pct%']);
    }
    _writeExcelRow(sheet, row, ['Total', events.length.toString(), '100%']);
  }

  Future<void> _writeAttendanceExcel(xl.Sheet sheet, {String? profileId}) async {
    final records = await _getAttendance(profileId: profileId);
    _writeExcelHeaderRow(sheet, 4, ['Jugadora', 'Fecha', 'Asistió', 'Observaciones']);
    var row = 5;
    for (final r in records) {
      final player = await _db.getPlayerById(r.playerId);
      final name = player?.displayName ?? 'ID ${r.playerId}';
      _writeExcelRow(sheet, row++, [name, _dateFmt.format(r.fecha), r.asistio ? 'Sí' : 'No', r.observaciones]);
    }
  }

  Future<void> _writeMedicalLeavesExcel(xl.Sheet sheet) async {
    final leaves = await _getMedicalLeaves();
    _writeExcelHeaderRow(sheet, 4, ['Jugadora', 'Razón', 'Inicio', 'Fin', 'Estado', 'Notas']);
    var row = 5;
    for (final l in leaves) {
      final player = await _db.getPlayerById(l.playerId);
      final name = player?.displayName ?? 'ID ${l.playerId}';
      final end = l.endDate != null ? _dateFmt.format(l.endDate!) : '';
      _writeExcelRow(sheet, row++, [name, l.reason, _dateFmt.format(l.startDate), end, l.status.name, l.notes]);
    }
  }

  Future<void> _writeMatchesExcel(xl.Sheet sheet, {String? profileId}) async {
    final matches = await _getMatches(profileId: profileId);
    _writeExcelHeaderRow(sheet, 4, ['Fecha', 'Local', 'Visitante', 'Pts L', 'Pts V', 'Sets L', 'Sets V', 'Resultado', 'Tipo', 'Competencia', 'Lugar']);
    var row = 5;
    for (final m in matches) {
      _writeExcelRow(sheet, row++, [
        _dateFmt.format(m.fecha), m.equipoLocal, m.equipoVisitante,
        m.puntosLocal.toString(), m.puntosVisitante.toString(),
        m.setsLocal.toString(), m.setsVisitante.toString(),
        m.resultadoFinal ?? '', m.tipoPartido.name, m.competitionName ?? '', m.lugar ?? '',
      ]);
    }
  }

  Future<void> _writeTimelineExcel(xl.Sheet sheet, {String? profileId}) async {
    final events = await _getStats(profileId: profileId);
    _writeExcelHeaderRow(sheet, 4, ['Fecha', 'Jugadora', 'Acción', 'Resultado', 'Set', 'Puntos']);
    var row = 5;
    for (final e in events) {
      final player = await _db.getPlayerById(e.playerId);
      final name = player?.displayName ?? 'ID ${e.playerId}';
      _writeExcelRow(sheet, row++, [
        _dateTimeFmt.format(e.timestamp), name, e.tipoAccion.name, e.resultado.name,
        e.setNumero.toString(), '${e.puntoLocal}-${e.puntoVisitante}',
      ]);
    }
  }

  Future<void> _writeRotationsExcel(xl.Sheet sheet) async {
    final rotations = await _getRotations();
    _writeExcelHeaderRow(sheet, 4, ['Partido', 'Set', 'Rotación', 'Pts Ganados', 'Pts Perdidos', 'Efectividad']);
    var row = 5;
    for (final r in rotations) {
      final eff = r.totalPoints > 0 ? (r.pointsWon / r.totalPoints * 100).toStringAsFixed(1) : '0.0';
      _writeExcelRow(sheet, row++, [
        r.matchId.toString(), r.setNumber.toString(), (r.rotationIndex + 1).toString(),
        r.pointsWon.toString(), r.pointsLost.toString(), '$eff%',
      ]);
    }
  }

  Future<void> _writeServiceExcel(xl.Sheet sheet, {String? profileId}) async {
    final events = await _getStats(profileId: profileId);
    final serves = events.where((e) => e.tipoAccion == TipoAccion.saque).toList();
    final byPlayer = <int, List<StatEvent>>{};
    for (final s in serves) {
      byPlayer.putIfAbsent(s.playerId, () => []);
      byPlayer[s.playerId]!.add(s);
    }
    _writeExcelHeaderRow(sheet, 4, ['Jugadora', 'Servicios', 'Pts Directos', 'Errores', 'Efectividad']);
    var row = 5;
    for (final entry in byPlayer.entries) {
      final player = await _db.getPlayerById(entry.key);
      final name = player?.displayName ?? 'ID ${entry.key}';
      final total = entry.value.length;
      final pts = entry.value.where((e) => e.resultado == ResultadoAccion.exitoso).length;
      final errs = entry.value.where((e) => e.resultado == ResultadoAccion.error).length;
      final eff = total > 0 ? ((pts - errs) / total * 100).toStringAsFixed(1) : '0.0';
      _writeExcelRow(sheet, row++, [name, total.toString(), pts.toString(), errs.toString(), '$eff%']);
    }
  }

  Future<void> _writeDashboardExcel(xl.Sheet sheet, {String? profileId}) async {
    final players = await _getPlayers(profileId: profileId);
    final matches = await _getMatches(profileId: profileId);
    final attendance = await _getAttendance(profileId: profileId);
    final events = await _getStats(profileId: profileId);
    final leaves = await _getMedicalLeaves();

    _writeExcelHeaderRow(sheet, 4, ['Métrica', 'Valor']);
    _writeExcelRow(sheet, 5, ['Total Jugadoras', players.length.toString()]);
    _writeExcelRow(sheet, 6, ['Total Partidos', matches.length.toString()]);
    _writeExcelRow(sheet, 7, ['Total Asistencias', attendance.length.toString()]);
    _writeExcelRow(sheet, 8, ['Total Eventos', events.length.toString()]);
    _writeExcelRow(sheet, 9, ['Reposos Activos', leaves.where((l) => l.isActive).length.toString()]);
    final won = matches.where((m) => m.resultadoFinal == 'Ganado' || m.puntosLocal > m.puntosVisitante).length;
    _writeExcelRow(sheet, 10, ['Partidos Ganados', won.toString()]);
    _writeExcelRow(sheet, 11, ['Partidos Perdidos', (matches.length - won).toString()]);
  }

  // ==========================================================
  // PDF BUILDER
  // ==========================================================

  Future<Uint8List> _buildPdf(ExportDataType type, {String? profileId, String? clubId}) async {
    final doc = pw.Document();
    final theme = pw.ThemeDataWith(
      base: pw.ThemeData(),
      defaultTextStyle: const pw.TextStyle(fontSize: 10),
    );

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(context),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('$_brand - ${_pdfTitle(type)}', style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Paragraph(text: 'Exportado: ${_dateTimeFmt.format(DateTime.now())}'),
          pw.SizedBox(height: 12),
          ...switch (type) {
            ExportDataType.playerStats => await _buildPlayerStatsPdf(context),
            ExportDataType.teamStats => await _buildTeamStatsPdf(context),
            ExportDataType.attendance => await _buildAttendancePdf(context, profileId: profileId),
            ExportDataType.medicalLeaves => await _buildMedicalLeavesPdf(context),
            ExportDataType.matches => await _buildMatchesPdf(context, profileId: profileId),
            ExportDataType.timeline => await _buildTimelinePdf(context, profileId: profileId),
            ExportDataType.rotations => await _buildRotationsPdf(context),
            ExportDataType.service => await _buildServicePdf(context, profileId: profileId),
            ExportDataType.dashboard => await _buildDashboardPdf(context, profileId: profileId),
          },
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  String _pdfTitle(ExportDataType type) {
    switch (type) {
      case ExportDataType.playerStats: return 'Estadísticas Individuales';
      case ExportDataType.teamStats: return 'Estadísticas por Equipo';
      case ExportDataType.attendance: return 'Reporte de Asistencia';
      case ExportDataType.medicalLeaves: return 'Reposos Médicos';
      case ExportDataType.matches: return 'Partidos';
      case ExportDataType.timeline: return 'Timeline de Eventos';
      case ExportDataType.rotations: return 'Análisis de Rotaciones';
      case ExportDataType.service: return 'Estadísticas de Servicio';
      case ExportDataType.dashboard: return 'Dashboard Resumen';
    }
  }

  pw.Widget _buildPdfHeader(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('$_brand', style: pw.TextStyle(fontSize: 12, color: PdfColors.blue800, fontWeight: pw.FontWeight.bold)),
            pw.Text('v$_version', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ],
        ),
        pw.Divider(color: PdfColors.blue800),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('$_brand - Todos los derechos reservados', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey)),
            pw.Text('Página ${context.pageNumber}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey)),
          ],
        ),
      ],
    );
  }

  Future<List<pw.Widget>> _buildPlayerStatsPdf(pw.Context context) async {
    final players = await _getPlayers();
    final events = await _getStats();
    final headers = ['Jugadora', 'Nº', 'Posición', 'Ataques', 'Bloqueos', 'Servicios', 'Total'];
    final rows = players.map((p) {
      final pe = events.where((e) => e.playerId == p.id).toList();
      return [
        p.displayName,
        p.numero?.toString() ?? '',
        p.posicion.name,
        pe.where((e) => e.tipoAccion == TipoAccion.ataque).length.toString(),
        pe.where((e) => e.tipoAccion == TipoAccion.bloqueo).length.toString(),
        pe.where((e) => e.tipoAccion == TipoAccion.saque).length.toString(),
        pe.length.toString(),
      ];
    }).toList();
    return [_buildTable(headers, rows)];
  }

  Future<List<pw.Widget>> _buildTeamStatsPdf(pw.Context context) async {
    final events = await _getStats();
    final porTipo = <String, int>{};
    for (final e in events) {
      porTipo[e.tipoAccion.name] = (porTipo[e.tipoAccion.name] ?? 0) + 1;
    }
    final headers = ['Tipo', 'Cantidad', 'Porcentaje'];
    final rows = porTipo.entries.map((e) => [
      e.key,
      e.value.toString(),
      events.length > 0 ? '${(e.value / events.length * 100).toStringAsFixed(1)}%' : '0.0%',
    ]).toList();
    rows.add(['Total', events.length.toString(), '100%']);
    return [_buildTable(headers, rows)];
  }

  Future<List<pw.Widget>> _buildAttendancePdf(pw.Context context, {String? profileId}) async {
    final records = await _getAttendance(profileId: profileId);
    final headers = ['Jugadora', 'Fecha', 'Asistió', 'Observaciones'];
    final rows = <List<String>>[];
    for (final r in records) {
      final player = await _db.getPlayerById(r.playerId);
      final name = player?.displayName ?? 'ID ${r.playerId}';
      rows.add([name, _dateFmt.format(r.fecha), r.asistio ? 'Sí' : 'No', r.observaciones]);
    }
    return [_buildTable(headers, rows)];
  }

  Future<List<pw.Widget>> _buildMedicalLeavesPdf(pw.Context context) async {
    final leaves = await _getMedicalLeaves();
    final headers = ['Jugadora', 'Razón', 'Inicio', 'Fin', 'Estado'];
    final rows = <List<String>>[];
    for (final l in leaves) {
      final player = await _db.getPlayerById(l.playerId);
      final name = player?.displayName ?? 'ID ${l.playerId}';
      final end = l.endDate != null ? _dateFmt.format(l.endDate!) : '';
      rows.add([name, l.reason, _dateFmt.format(l.startDate), end, l.status.name]);
    }
    return [_buildTable(headers, rows)];
  }

  Future<List<pw.Widget>> _buildMatchesPdf(pw.Context context, {String? profileId}) async {
    final matches = await _getMatches(profileId: profileId);
    final headers = ['Fecha', 'Local', 'Visitante', 'Resultado', 'Tipo'];
    final rows = matches.map((m) => [
      _dateFmt.format(m.fecha),
      m.equipoLocal,
      m.equipoVisitante,
      '${m.puntosLocal}-${m.puntosVisitante}',
      m.tipoPartido.name,
    ]).toList();
    return [_buildTable(headers, rows)];
  }

  Future<List<pw.Widget>> _buildTimelinePdf(pw.Context context, {String? profileId}) async {
    final events = await _getStats(profileId: profileId);
    final headers = ['Fecha', 'Jugadora', 'Acción', 'Resultado'];
    final rows = <List<String>>[];
    for (final e in events.take(100)) {
      final player = await _db.getPlayerById(e.playerId);
      final name = player?.displayName ?? 'ID ${e.playerId}';
      rows.add([_dateTimeFmt.format(e.timestamp), name, e.tipoAccion.name, e.resultado.name]);
    }
    return [
      pw.Paragraph(text: 'Mostrando ${rows.length} eventos (últimos 100)'),
      pw.SizedBox(height: 8),
      _buildTable(headers, rows),
    ];
  }

  Future<List<pw.Widget>> _buildRotationsPdf(pw.Context context) async {
    final rotations = await _getRotations();
    final headers = ['Partido', 'Set', 'Rotación', 'Pts Ganados', 'Pts Perdidos', 'Efectividad'];
    final rows = rotations.map((r) {
      final eff = r.totalPoints > 0 ? (r.pointsWon / r.totalPoints * 100).toStringAsFixed(1) : '0.0';
      return [
        r.matchId.toString(), r.setNumber.toString(), 'R${r.rotationIndex + 1}',
        r.pointsWon.toString(), r.pointsLost.toString(), '$eff%',
      ];
    }).toList();
    return [_buildTable(headers, rows)];
  }

  Future<List<pw.Widget>> _buildServicePdf(pw.Context context, {String? profileId}) async {
    final events = await _getStats(profileId: profileId);
    final serves = events.where((e) => e.tipoAccion == TipoAccion.saque).toList();
    final byPlayer = <int, List<StatEvent>>{};
    for (final s in serves) {
      byPlayer.putIfAbsent(s.playerId, () => []);
      byPlayer[s.playerId]!.add(s);
    }
    final headers = ['Jugadora', 'Servicios', 'Pts Directos', 'Errores', 'Efectividad'];
    final rows = <List<String>>[];
    for (final entry in byPlayer.entries) {
      final player = await _db.getPlayerById(entry.key);
      final name = player?.displayName ?? 'ID ${entry.key}';
      final total = entry.value.length;
      final pts = entry.value.where((e) => e.resultado == ResultadoAccion.exitoso).length;
      final errs = entry.value.where((e) => e.resultado == ResultadoAccion.error).length;
      final eff = total > 0 ? ((pts - errs) / total * 100).toStringAsFixed(1) : '0.0';
      rows.add([name, total.toString(), pts.toString(), errs.toString(), '$eff%']);
    }
    return [_buildTable(headers, rows)];
  }

  Future<List<pw.Widget>> _buildDashboardPdf(pw.Context context, {String? profileId}) async {
    final players = await _getPlayers(profileId: profileId);
    final matches = await _getMatches(profileId: profileId);
    final attendance = await _getAttendance(profileId: profileId);
    final events = await _getStats(profileId: profileId);
    final leaves = await _getMedicalLeaves();
    final won = matches.where((m) => m.resultadoFinal == 'Ganado' || m.puntosLocal > m.puntosVisitante).length;

    final headers = ['Métrica', 'Valor'];
    final rows = [
      ['Total Jugadoras', players.length.toString()],
      ['Total Partidos', matches.length.toString()],
      ['Total Asistencias', attendance.length.toString()],
      ['Total Eventos', events.length.toString()],
      ['Reposos Activos', leaves.where((l) => l.isActive).length.toString()],
      ['Partidos Ganados', won.toString()],
      ['Partidos Perdidos', (matches.length - won).toString()],
    ];

    return [
      _buildTable(headers, rows),
      pw.SizedBox(height: 16),
      pw.Header(level: 1, text: 'Distribución por Categoría'),
      _buildCategoriaChart(players),
    ];
  }

  pw.Widget _buildTable(List<String> headers, List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headers: headers,
      data: rows,
    );
  }

  pw.Widget _buildCategoriaChart(List<Player> players) {
    final cats = <String, int>{};
    for (final p in players) {
      cats[p.categoria] = (cats[p.categoria] ?? 0) + 1;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: cats.entries.map((e) {
        final pct = players.length > 0 ? (e.value / players.length * 100).toStringAsFixed(0) : '0';
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 80,
                child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.Container(
                width: e.value * 20.0,
                height: 12,
                decoration: pw.BoxDecoration(color: PdfColors.blue600),
              ),
              pw.SizedBox(width: 6),
              pw.Text('${e.value} ($pct%)', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
