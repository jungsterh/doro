import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/session.dart';
import '../models/task.dart';

class ExportService {
  List<_ExportRow> _buildRows(List<Session> sessions, List<Task> tasks) {
    final taskMap = {for (final t in tasks) t.id: t};
    final rows = sessions
        .where((s) => s.isCompleted)
        .map((s) => _ExportRow(
              date: DateFormat('yyyy-MM-dd').format(s.startTime),
              task: taskMap[s.taskId]?.name ?? 'Unknown',
              seconds: s.durationSeconds,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return rows;
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> exportCsv(List<Session> sessions, List<Task> tasks) async {
    final rows = _buildRows(sessions, tasks);
    final data = [
      ['Date', 'Activity', 'Duration (HH:MM:SS)', 'Duration (minutes)'],
      ...rows.map((r) => [
            r.date,
            r.task,
            _formatDuration(r.seconds),
            (r.seconds / 60).toStringAsFixed(1),
          ]),
    ];
    final csv = const ListToCsvConverter().convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/doro_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Doro –Time Tracking Export',
    );
  }

  Future<void> exportPdf(List<Session> sessions, List<Task> tasks) async {
    final rows = _buildRows(sessions, tasks);
    final now = DateFormat('MMM d, yyyy').format(DateTime.now());

    final dailyTotals = <String, int>{};
    for (final r in rows) {
      dailyTotals[r.date] = (dailyTotals[r.date] ?? 0) + r.seconds;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Doro –Time Tracking Summary',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Generated $now',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (ctx) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                children: ['Date', 'Activity', 'Duration', 'Minutes']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9)),
                        ))
                    .toList(),
              ),
              ...rows.map((r) => pw.TableRow(
                    children: [
                      r.date,
                      r.task,
                      _formatDuration(r.seconds),
                      (r.seconds / 60).toStringAsFixed(1),
                    ]
                        .map((c) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(c,
                                  style: const pw.TextStyle(fontSize: 9)),
                            ))
                        .toList(),
                  )),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text('Daily Totals',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                children: ['Date', 'Total Duration', 'Total Minutes']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9)),
                        ))
                    .toList(),
              ),
              ...dailyTotals.entries.map((e) => pw.TableRow(
                    children: [
                      e.key,
                      _formatDuration(e.value),
                      (e.value / 60).toStringAsFixed(1),
                    ]
                        .map((c) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(c,
                                  style: const pw.TextStyle(fontSize: 9)),
                            ))
                        .toList(),
                  )),
            ],
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'doro_export.pdf',
    );
  }
}

class _ExportRow {
  final String date;
  final String task;
  final int seconds;
  _ExportRow({required this.date, required this.task, required this.seconds});
}
