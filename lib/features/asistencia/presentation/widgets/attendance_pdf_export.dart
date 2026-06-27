import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../../core/utils/name_formatter.dart';

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

      final activePlayers = players
          .where((p) => p.atletaStatus == AthleteStatus.active)
          .toList()
        ..sort((a, b) => (a.numero ?? 0).compareTo(b.numero ?? 0));

      final restingPlayers = players
          .where((p) => p.atletaStatus == AthleteStatus.resting)
          .toList()
        ..sort((a, b) => (a.numero ?? 0).compareTo(b.numero ?? 0));

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 8),
                pw.Text('LIBERO 360',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange,
                    letterSpacing: 4,
                  )),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Reporte Mensual de Asistencia',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${_monthName(month.month)} ${month.year}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1.5, color: PdfColors.orange),
              ],
            ),
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'Libero 360 - Generado el ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey),
            ),
          ),
          build: (context) => [
            // Summary row
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _summaryBox('Total días', '${dates.length}', PdfColors.blueGrey),
                  _summaryBox('Presentes', '${monthRecords.where((r) => r.asistio).length}', PdfColors.green),
                  _summaryBox('Ausentes', '${monthRecords.where((r) => !r.asistio).length}', PdfColors.red),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Subtitle: Período
            pw.Text('Período: ${_monthName(month.month)} ${month.year}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            pw.SizedBox(height: 4),
            pw.Text('Total atletas registrados: ${players.length}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            pw.SizedBox(height: 12),

            // Section: Atletas Presentes
            pw.Text('ATLETAS PRESENTES',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
            pw.SizedBox(height: 8),
            if (activePlayers.isEmpty)
              pw.Text('Sin registros', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))
            else
              _buildPresenceTable(activePlayers, dates, monthRecords.toList()),

            pw.SizedBox(height: 20),

            // Section: Atletas Ausentes
            pw.Text('ATLETAS AUSENTES',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
            pw.SizedBox(height: 8),
            if (activePlayers.where((p) => !monthRecords.any((r) => r.playerId == p.id)).toList().isEmpty &&
                !activePlayers.any((p) => monthRecords.any((r) => r.playerId == p.id && !r.asistio)))
              pw.Text('Sin ausencias este mes', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))
            else
              _buildAbsentTable(activePlayers, monthRecords.toList()),

            pw.SizedBox(height: 20),

            // Section: Reposos
            pw.Text('ATLETAS EN REPOSO / LESIONADOS',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
            pw.SizedBox(height: 8),
            if (restingPlayers.isEmpty)
              pw.Text('Sin atletas en reposo este mes', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))
            else
              _buildRestingTable(restingPlayers),
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

  static pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Text(label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ],
    );
  }

  static pw.Widget _buildPresenceTable(
    List<Player> players,
    List<DateTime> dates,
    List<AttendanceRecord> records,
  ) {
    final headers = ['#', 'Atleta'];
    for (final d in dates) {
      headers.add('${d.day}');
    }
    headers.addAll(['%', 'Asist.', 'Faltas']);

    final rows = <List<String>>[];
    for (final p in players) {
      final row = <String>['${p.numero ?? "-"}', NameFormatter.playerDisplayName(p)];
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
        for (int i = 2; i < headers.length - 3; i++) i: const pw.FixedColumnWidth(18),
        headers.length - 3: const pw.FixedColumnWidth(22),
        headers.length - 2: const pw.FixedColumnWidth(22),
        headers.length - 1: const pw.FixedColumnWidth(22),
      },
    );
  }

  static pw.Widget _buildAbsentTable(List<Player> players, List<AttendanceRecord> records) {
    final absentPlayers = players.where((p) =>
      records.any((r) => r.playerId == p.id && !r.asistio)).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['#', 'Atleta', 'Faltas', 'Última falta'],
      data: absentPlayers.map((p) {
        final pRecords = records.where((r) => r.playerId == p.id && !r.asistio).toList();
        final lastDate = pRecords.isNotEmpty
            ? '${pRecords.last.fecha.day}/${pRecords.last.fecha.month}'
            : '-';
        return ['${p.numero ?? "-"}', NameFormatter.playerDisplayName(p), '${pRecords.length}', lastDate];
      }).toList()
        ..sort((a, b) => int.parse(b[2]).compareTo(int.parse(a[2]))),
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.red),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
    );
  }

  static pw.Widget _buildRestingTable(List<Player> players) {
    return pw.TableHelper.fromTextArray(
      headers: ['#', 'Atleta', 'Estado', 'Motivo'],
      data: players.map((p) {
        final reason = p.statusReason?.isNotEmpty == true ? p.statusReason! : '';
        return [
          '${p.numero ?? "-"}',
          NameFormatter.playerDisplayName(p),
          p.atletaStatus.label,
          reason,
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerLeft,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FixedColumnWidth(100),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FixedColumnWidth(120),
      },
    );
  }

  static String _monthName(int m) {
    const names = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return names[m - 1];
  }
}
