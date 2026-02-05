import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/models/analytic_data.dart';
import 'package:intl/intl.dart';

class PdfService {
  Future<File> generateAnalyticsReport(AnalyticData data, String period) async {
    final pdf = pw.Document();
    
    // Load font for better styling if needed, or use default
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final dateStr = DateFormat('MMMM d, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) => [
          _buildHeader(period, dateStr),
          pw.SizedBox(height: 20),
          _buildScoreCard(data),
          pw.SizedBox(height: 20),
          _buildQuickStats(data),
          pw.SizedBox(height: 20),
          _buildProductivitySection(data),
          pw.SizedBox(height: 20),
          _buildInsightsSection(data),
          pw.Divider(),
          _buildFooter(),
        ],
      ),
    );

    return _saveDocument(name: 'analytics_report_${period.toLowerCase().replaceAll(' ', '_')}.pdf', pdf: pdf);
  }

  pw.Widget _buildHeader(String period, String date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Analytics Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.Text(
              'Period: $period',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Text(
          date,
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildScoreCard(AnalyticData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Productivity Score', 
                style: pw.TextStyle(fontSize: 14, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '${data.productivityScore}%',
                style: pw.TextStyle(
                  fontSize: 28, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
            ],
          ),
          // We could add a simple bar chart or indicator here if needed
        ],
      ),
    );
  }

  pw.Widget _buildQuickStats(AnalyticData data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem('Emails Sent', '${data.emailsSent}', PdfColors.blue),
        _buildStatItem('Emails Received', '${data.emailsReceived}', PdfColors.green),
        _buildStatItem('Tasks Done', '${data.tasksCompleted}', PdfColors.orange),
        _buildStatItem('Meetings', '${data.meetingsAttended}', PdfColors.purple),
      ],
    );
  }

  pw.Widget _buildStatItem(String label, String value, PdfColor color) {
    return pw.Container(
      width: 100,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProductivitySection(AnalyticData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Productivity Breakdown',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        _buildProgressRow('Focus Time', (data.productivityScore * 4.8) / 60, 8.0, PdfColors.indigoAccent), // Est. based on score (5 * 0.96 hours)
        pw.SizedBox(height: 8),
        _buildProgressRow('Task Efficiency', data.tasksCompleted > 0 ? 85.0 : 0.0, 100, PdfColors.teal), // Mock efficiency or calculate if total tasks known
        pw.SizedBox(height: 8),
        _buildProgressRow('Email Response', 85, 100, PdfColors.cyan), // Static example or calculate if data available
      ],
    );
  }

  pw.Widget _buildProgressRow(String label, double value, double max, PdfColor color) {
    final progress = (value / max).clamp(0.0, 1.0);
    return pw.Row(
      children: [
        pw.SizedBox(width: 100, child: pw.Text(label, style: const pw.TextStyle(fontSize: 12))),
        pw.Expanded(
          child: pw.Stack(
            children: [
              pw.Container(
                height: 8,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.Container(
                width: 250 * progress, // Approximation of width
                height: 8,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 40, child: pw.Text(value.toStringAsFixed(1), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 12))),
      ],
    );
  }

  pw.Widget _buildInsightsSection(AnalyticData data) {
    // Generate some insights based on data
    final insights = <String>[];
    if (data.productivityScore > 80) insights.add('Excellent productivity score! Keep it up.');
    if (data.tasksCompleted > 5) insights.add('Great job on completing tasks.');
    if (data.emailsReceived > 20) insights.add('High volume of incoming emails today.');
    
    if (insights.isEmpty) insights.add('Keep tracking your activities to see more insights.');

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AI Insights',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
          pw.SizedBox(height: 8),
          ...insights.map((insight) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Expanded(child: pw.Text(insight, style: const pw.TextStyle(fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        'Generated by Aixy • ${DateFormat('yyyy').format(DateTime.now())}',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
      ),
    );
  }

  Future<File> _saveDocument({required String name, required pw.Document pdf}) async {
    final bytes = await pdf.save();

    Directory dir;
    if (Platform.isAndroid) {
        dir = (await getExternalStorageDirectory()) ?? await getApplicationDocumentsDirectory();
    } else {
        dir = await getApplicationDocumentsDirectory();
    }
    
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }
}
