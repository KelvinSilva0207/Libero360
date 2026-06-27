import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:libero360/features/estadisticas/data/local_db/database_service.dart';
import 'package:libero360/features/estadisticas/data/models/models.dart';
import 'medical_leave_repository.dart';
import '../../../core/utils/name_formatter.dart';

class AttendancePdfExport {
  final DatabaseService _db = DatabaseService.instance;
  final MedicalLeaveRepository _medicalRepo = MedicalLeaveRepository.instance;

  Future<pw.Document> generate({
    required int year,
    required int month,
    String? category,
    String clubName = 'Club',
    String coachName = '',
  }) async {
    await _db.initialize();
    final records = await _db.getAttendanceRecords();
    final allPlayers = await _db.getAllPlayers(includeDeleted: false);
    final activeLeaves = await _medicalRepo.getActive();
    final playerOnLeave = activeLeaves.map((l) => l.playerId).toSet();
    final players = <int, Player>{for (final p in allPlayers) p.id: p};

    final monthRecords = records.where((r) =>
      r.fecha.year == year && r.fecha.month == month
    ).toList();

    final playerStats = <int, _PlayerAttendance>{};
    for (final r in monthRecords) {
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

    final totalDays = monthRecords.map((r) => '${r.fecha.year}-${r.fecha.month}-${r.fecha.day}').toSet().length;

    final pdf = pw.Document();
    final monthName = DateFormat.MMMM('es').format(DateTime(year, month));
    final genDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          _header(clubName, monthName, year, coachName, genDate),
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

  pw.Widget _header(String club, String monthName, int year, String coach, String genDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('LIBERO360', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
            pw.Text('Reporte de Asistencia', style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
          ],
        ),
        pw.Divider(color: PdfColors.orange300, thickness: 1.5),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            _infoBlock('Club', club),
            pw.SizedBox(width: 40),
            _infoBlock('Período', '$monthName $year'),
            pw.SizedBox(width: 40),
            if (coach.isNotEmpty) _infoBlock('Entrenador', coach),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text('Generado: $genDate', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
      ],
    );
  }

  pw.Widget _infoBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
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
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _statBox('Días', totalDays.toString(), PdfColors.blue700),
        _statBox('Atletas', totalPlayers.toString(), PdfColors.green700),
        _statBox('Presentes', totalPresent.toString(), PdfColors.green600),
        _statBox('Ausencias', totalAbsent.toString(), PdfColors.red600),
        _statBox('Reposos', totalRest.toString(), PdfColors.orange600),
        _statBox('Eficacia', '$avgPercentage%', PdfColors.blue600),
      ],
    );
  }

  pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0x14FFFFFF),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromInt(0x33FFFFFF)),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
          pw.Text(label, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  pw.Widget _playerTable(List<({Player player, _PlayerAttendance stats})> items) {
    final headers = ['#', 'Nombre', 'Pos.', 'Presentes', 'Ausencias', 'Reposo', '%'];
    final rows = items.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final x = entry.value;
      return [
        i.toString(),
        NameFormatter.playerDisplayName(x.player),
        x.player.posicionLabel,
        x.stats.present.toString(),
        x.stats.absent.toString(),
        x.stats.medicalRest.toString(),
        '${x.stats.percentage.toStringAsFixed(0)}%',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      cellStyle: pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.orange700),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      headers: headers,
      data: rows,
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(40),
        3: const pw.FixedColumnWidth(48),
        4: const pw.FixedColumnWidth(48),
        5: const pw.FixedColumnWidth(40),
        6: const pw.FixedColumnWidth(36),
      },
    );
  }

  Future<void> saveAndShare({required int year, required int month, String? category, String clubName = '', String coachName = ''}) async {
    final pdf = await generate(year: year, month: month, category: category, clubName: clubName, coachName: coachName);
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final monthName = DateFormat.MMMM('es').format(DateTime(year, month));
    final file = File('${dir.path}/asistencia_${monthName}_$year.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Reporte de Asistencia - $monthName $year');
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
