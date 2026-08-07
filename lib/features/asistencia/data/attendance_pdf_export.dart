import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:libero360/features/estadisticas/data/local_db/database_service.dart';
import 'package:libero360/features/estadisticas/data/models/models.dart';
import 'medical_leave_repository.dart';
import '../../../core/utils/name_formatter.dart';

class AttendancePdfExport {
  final DatabaseService _db = DatabaseService.instance;
  final MedicalLeaveRepository _medicalRepo = MedicalLeaveRepository.instance;

  Future<pw.Document> generate({
    int? year,
    int? month,
    DateTime? start,
    DateTime? end,
    DateTime? day,
    String? category,
    String clubName = 'Club',
    String? clubLogoUrl,
    String coachName = '',
  }) async {
    await _db.initialize();
    final records = await _db.getAttendanceRecords();
    final allPlayers = await _db.getAllPlayers(includeDeleted: false);
    final activeLeaves = await _medicalRepo.getActive();
    final playerOnLeave = activeLeaves.map((l) => l.playerId).toSet();
    final players = <int, Player>{for (final p in allPlayers) p.id: p};

    final isDay = day != null;
    final isRange = !isDay && start != null && end != null;
    final dayStart = isDay ? DateTime(day.year, day.month, day.day) : null;
    final rangeStart = isRange ? DateTime(start.year, start.month, start.day) : null;
    final rangeEnd = isRange ? DateTime(end.year, end.month, end.day).add(const Duration(days: 1)) : null;

    final periodRecords = records.where((r) {
      if (isDay) {
        return r.fecha.year == dayStart!.year &&
            r.fecha.month == dayStart.month &&
            r.fecha.day == dayStart.day;
      }
      if (isRange) {
        final d = DateTime(r.fecha.year, r.fecha.month, r.fecha.day);
        return !d.isBefore(rangeStart!) && d.isBefore(rangeEnd!);
      }
      return r.fecha.year == year && r.fecha.month == month;
    }).toList();

    final playerStats = <int, _PlayerAttendance>{};
    for (final r in periodRecords) {
      playerStats.putIfAbsent(r.playerId, () => _PlayerAttendance(playerId: r.playerId));
      if (r.asistio) {
        playerStats[r.playerId]!.present++;
      } else if (playerOnLeave.contains(r.playerId) ||
          (players[r.playerId]?.estadoSalud == EstadoSalud.lesionado) ||
          (players[r.playerId]?.atletaStatus == AthleteStatus.injured)) {
        playerStats[r.playerId]!.medicalRest++;
      } else {
        playerStats[r.playerId]!.absent++;
      }
    }

    final totalDays = periodRecords.map((r) => '${r.fecha.year}-${r.fecha.month}-${r.fecha.day}').toSet().length;

    final periodLabel = isDay
        ? _shortDate(dayStart!)
        : isRange
            ? '${_shortDate(rangeStart!)} al ${_shortDate(rangeEnd!.subtract(const Duration(days: 1)))}'
            : '${DateFormat.MMMM('es').format(DateTime(year!, month!))} $year';
    final genDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pw.MemoryImage? logo;
    if (clubLogoUrl != null && clubLogoUrl.isNotEmpty) {
      try {
        final resp = await http.get(Uri.parse(clubLogoUrl));
        if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
          logo = pw.MemoryImage(resp.bodyBytes);
        }
      } catch (_) {
        logo = null;
      }
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          _header(clubName, logo, periodLabel, coachName, genDate),
          pw.SizedBox(height: 20),
          if (totalDays > 0) _summaryRow(totalDays, playerStats.values.toList()),
          pw.SizedBox(height: 16),
          _playerTable(
            playerStats.entries
                .where((e) => players.containsKey(e.key))
                .map((e) => (player: players[e.key]!, stats: e.value))
                .where((x) => category == null || category.isEmpty || x.player.posicionLabel == category || x.player.categoria == category)
                .toList()
              ..sort((a, b) => b.stats.percentage.compareTo(a.stats.percentage)),
          ),
        ],
      ),
    );

    return pdf;
  }

  String _shortDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  pw.Widget _header(String club, pw.MemoryImage? logo, String periodLabel, String coach, String genDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null) ...[
                  pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(logo, width: 38, height: 38, fit: pw.BoxFit.cover),
                  ),
                  pw.SizedBox(width: 12),
                ],
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(club,
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF263238))),
                    pw.SizedBox(height: 2),
                    pw.Text('Reporte de Asistencia',
                        style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.Text('LIBERO360',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey500,
                    letterSpacing: 2)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 2, color: PdfColor.fromInt(0xFF263238)),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            _infoBlock('Período', periodLabel),
            if (coach.isNotEmpty) ...[
              pw.SizedBox(width: 32),
              _infoBlock('Entrenador', coach),
            ],
            pw.Spacer(),
            pw.Text('Generado: $genDate', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
      ],
    );
  }

  pw.Widget _infoBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF37474F))),
      ],
    );
  }

  pw.Widget _summaryRow(int totalDays, List<_PlayerAttendance> stats) {
    final totalPlayers = stats.length;
    final totalPresent = stats.fold(0, (sum, s) => sum + s.present);
    final totalAbsent = stats.fold(0, (sum, s) => sum + s.absent);
    final totalRest = stats.fold(0, (sum, s) => sum + s.medicalRest);
    final avgPercentage = totalPlayers > 0 && totalDays > 0
        ? (totalPresent / (totalPlayers * totalDays) * 100).toStringAsFixed(1)
        : '0.0';

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _statBox('Días', totalDays.toString(), PdfColors.blueGrey700),
        _statBox('Atletas', totalPlayers.toString(), PdfColors.blueGrey700),
        _statBox('Presentes', totalPresent.toString(), PdfColors.green700),
        _statBox('Ausencias', totalAbsent.toString(), PdfColors.red700),
        _statBox('Reposos', totalRest.toString(), PdfColors.orange700),
        _statBox('Eficacia', '$avgPercentage%', PdfColors.blue700),
      ],
    );
  }

  pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF2F6FA),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(value,
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: color)),
          pw.Text(label, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  pw.Widget _playerTable(List<({Player player, _PlayerAttendance stats})> items) {
    final headers = ['#', 'Nombre', 'Presentes', 'Ausencias', 'Reposo', '%'];
    final rows = items.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final x = entry.value;
      return [
        i.toString(),
        NameFormatter.playerDisplayName(x.player),
        x.stats.present.toString(),
        x.stats.absent.toString(),
        x.stats.medicalRest.toString(),
        '${x.stats.percentage.toStringAsFixed(0)}%',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF263238),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.4)),
      ),
      headers: headers,
      data: rows,
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(52),
        3: const pw.FixedColumnWidth(52),
        4: const pw.FixedColumnWidth(44),
        5: const pw.FixedColumnWidth(40),
      },
    );
  }

  Future<void> saveAndShare({
    int? year,
    int? month,
    DateTime? start,
    DateTime? end,
    DateTime? day,
    String? category,
    String clubName = '',
    String? clubLogoUrl,
    String coachName = '',
  }) async {
    final pdf = await generate(
      year: year,
      month: month,
      start: start,
      end: end,
      day: day,
      category: category,
      clubName: clubName,
      clubLogoUrl: clubLogoUrl,
      coachName: coachName,
    );
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final isDay = day != null;
    final isRange = !isDay && start != null && end != null;

    final String fileName;
    final String shareText;
    if (isDay) {
      fileName = 'asistencia_dia_${day.day.toString().padLeft(2, '0')}${day.month.toString().padLeft(2, '0')}${day.year}.pdf';
      shareText = 'Reporte de Asistencia - ${_shortDate(day)}';
    } else if (isRange) {
      fileName = 'asistencia_semana_${start.day.toString().padLeft(2, '0')}${start.month.toString().padLeft(2, '0')}_${end.day.toString().padLeft(2, '0')}${end.month.toString().padLeft(2, '0')}.pdf';
      shareText = 'Reporte de Asistencia - ${_shortDate(start)} al ${_shortDate(end)}';
    } else {
      fileName = 'asistencia_${DateFormat.MMMM('es').format(DateTime(year!, month!))}_$year.pdf';
      shareText = 'Reporte de Asistencia - ${DateFormat.MMMM('es').format(DateTime(year, month))} $year';
    }

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: shareText);
  }
}

class _PlayerAttendance {
  final int playerId;
  int present = 0;
  int absent = 0;
  int medicalRest = 0;

  _PlayerAttendance({required this.playerId});

  int get total => present + absent + medicalRest;
  double get percentage => total > 0 ? (present / total * 100) : 0;
}
