import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/attendance_record.dart';
import '../../../estadisticas/data/models/models.dart';

class AttendancePdfExport {
  static Future<void> exportMonthly(BuildContext context, DateTime month) async {
    try {
      await DatabaseService.instance.initialize();
      final allRecords = await DatabaseService.instance.getAttendanceRecords();
      final players = await DatabaseService.instance.getPlayers();

      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0);

      final monthRecords = allRecords.where((r) =>
        r.fecha.isAfter(monthStart.subtract(const Duration(days: 1))) &&
        r.fecha.isBefore(monthEnd.add(const Duration(days: 1))));

      final dates = monthRecords.map((r) =>
        DateTime(r.fecha.year, r.fecha.month, r.fecha.day)).toSet().toList()..sort();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Libero360 - Reporte de Asistencia',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                pw.SizedBox(height: 4),
                pw.Text('${_monthName(month.month)} ${month.year}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                pw.SizedBox(height: 8),
                pw.Divider(),
              ],
            ),
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Libero360 - Generado el ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
          build: (context) => [
            _buildStatsTable(dates, players, monthRecords.toList()),
            pw.SizedBox(height: 20),
            _buildRankingTable(players, monthRecords.toList()),
            pw.SizedBox(height: 20),
            _buildStreaks(players, monthRecords.toList()),
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/asistencia_${month.year}_${month.month.toString().padLeft(2, '0')}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF guardado en: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _buildStatsTable(
    List<DateTime> dates,
    List<Player> players,
    List<AttendanceRecord> records,
  ) {
    final activePlayers = players.where((p) => p.atletaStatus == AthleteStatus.active).toList();
    activePlayers.sort((a, b) => (a.numero ?? 0).compareTo(b.numero ?? 0));

    final headers = ['#', 'Atleta'];
    for (final d in dates) {
      final label = '${d.day}/${d.month}';
      headers.add(label);
    }
    headers.addAll(['%', 'Asist.', 'Faltas']);

    final rows = <List<String>>[];
    for (final p in activePlayers) {
      final row = <String>['${p.numero ?? "-"}', p.nombre];
      int asistencias = 0;
      int faltas = 0;

      for (final d in dates) {
        final dayRecords = records.where((r) =>
          r.playerId == p.id &&
          r.fecha.year == d.year &&
          r.fecha.month == d.month &&
          r.fecha.day == d.day);
        if (dayRecords.isNotEmpty) {
          final asistio = dayRecords.any((r) => r.asistio);
          row.add(asistio ? '✓' : '✗');
          if (asistio) asistencias++;
        } else {
          row.add('-');
        }
      }

      if (!records.any((r) => r.playerId == p.id)) {
        continue;
      }

      faltas = dates.length - asistencias;
      final total = asistencias + faltas;
      final pct = total > 0 ? ((asistencias / total) * 100).toStringAsFixed(0) : '0';
      row.addAll(['$pct%', '$asistencias', '$faltas']);

      rows.add(row);
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
      cellStyle: const pw.TextStyle(fontSize: 7),
      cellAlignments: {
        for (int i = 0; i < headers.length; i++) i: i == 1 ? pw.Alignment.centerLeft : pw.Alignment.center,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(15),
        1: const pw.FixedColumnWidth(80),
        for (int i = 2; i < headers.length - 3; i++) i: const pw.FixedColumnWidth(20),
        headers.length - 3: const pw.FixedColumnWidth(25),
        headers.length - 2: const pw.FixedColumnWidth(25),
        headers.length - 1: const pw.FixedColumnWidth(25),
      },
    );
  }

  static pw.Widget _buildRankingTable(List<Player> players, List<AttendanceRecord> records) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Ranking de Asistencia',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['#', 'Atleta', 'Asistencia', 'Faltas', '%'],
          data: players.where((p) => records.any((r) => r.playerId == p.id)).map((p) {
            final pRecords = records.where((r) => r.playerId == p.id).toList();
            final asistencias = pRecords.where((r) => r.asistio).length;
            final faltas = pRecords.where((r) => !r.asistio).length;
            final total = asistencias + faltas;
            final pct = total > 0 ? ((asistencias / total) * 100).toStringAsFixed(0) : '0';
            return ['${p.numero ?? "-"}', p.nombre, '$asistencias', '$faltas', '$pct%'];
          }).toList()
            ..sort((a, b) => int.parse(b[4].replaceAll('%', '')).compareTo(int.parse(a[4].replaceAll('%', '')))),
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.center,
          },
        ),
      ],
    );
  }

  static pw.Widget _buildStreaks(List<Player> players, List<AttendanceRecord> records) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Rachas',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        ...players.where((p) => records.any((r) => r.playerId == p.id)).map((p) {
          final pRecords = records.where((r) => r.playerId == p.id).toList()
            ..sort((a, b) => a.fecha.compareTo(b.fecha));
          int streak = 0;
          int maxStreak = 0;
          int maxAbsent = 0;
          int currentAbsent = 0;
          for (final r in pRecords) {
            if (r.asistio) {
              streak++;
              if (streak > maxStreak) maxStreak = streak;
              currentAbsent = 0;
            } else {
              currentAbsent++;
              if (currentAbsent > maxAbsent) maxAbsent = currentAbsent;
              streak = 0;
            }
          }
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              children: [
                pw.Text('${p.nombre}: ', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('🔥 $maxStreak asistencias seguidas',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.green)),
                if (maxAbsent > 0)
                  pw.Text('  ⚠ $maxAbsent faltas seguidas',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.red)),
              ],
            ),
          );
        }),
      ],
    );
  }

  static String _monthName(int m) {
    const names = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return names[m - 1];
  }
}
