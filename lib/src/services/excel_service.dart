import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ExcelService {
  // ── Excel Export ──────────────────────────────────────────────────────────

  Future<void> generateFullReport({
    required List<Map<String, dynamic>> attendanceData,
    required List<Map<String, dynamic>> journalData,
    required String teacherName,
    required int month,
    required int year,
  }) async {
    var excel = Excel.createExcel();

    final monthName = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(DateTime(year, month));

    // ── Sheet 1: Absensi ───────────────────────────────────────────────────
    _buildAttendanceSheet(excel, attendanceData, teacherName, monthName);

    // ── Sheet 2: Jurnal ────────────────────────────────────────────────────
    _buildJournalSheet(excel, journalData, teacherName, monthName);

    // Hapus Sheet1 SETELAH sheet lain dibuat
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    // Download
    final fileBytes = excel.save();
    if (fileBytes == null) throw Exception('Gagal generate Excel');

    final fileName =
        'Laporan_PKL_${monthName.replaceAll(' ', '_')}_${teacherName.replaceAll(' ', '_')}.xlsx';

    _downloadFile(
      fileBytes,
      fileName,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  void _buildAttendanceSheet(
    Excel excel,
    List<Map<String, dynamic>> data,
    String teacherName,
    String monthName,
  ) {
    final sheet = excel['Absensi'];

    final headerBg = ExcelColor.fromHexString('#1E3A8A');
    final titleBg = ExcelColor.fromHexString('#EFF6FF');
    final evenBg = ExcelColor.fromHexString('#F8FAFF');

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontColorHex: ExcelColor.fromHexString('#1E3A8A'),
      backgroundColorHex: titleBg,
      horizontalAlign: HorizontalAlign.Left,
    );

    final subStyle = CellStyle(
      fontSize: 11,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontColorHex: ExcelColor.fromHexString('#64748B'),
      backgroundColorHex: titleBg,
    );

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: headerBg,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Title rows
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('LAPORAN ABSENSI SISWA PKL')
      ..cellStyle = titleStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
      ..value = TextCellValue(
        'Guru Pembimbing: $teacherName | Periode: $monthName',
      )
      ..cellStyle = subStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
      ..value = TextCellValue(
        'Dicetak: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
      )
      ..cellStyle = subStyle;

    // Headers
    final headers = [
      'No',
      'Nama Siswa',
      'NISN',
      'Kelas',
      'Perusahaan',
      'Tanggal',
      'Jam Masuk',
      'Jam Pulang',
      'Status',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4))
        ..value = TextCellValue(headers[i])
        ..cellStyle = headerStyle;
    }

    // Column widths
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 28);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 12);
    sheet.setColumnWidth(7, 12);
    sheet.setColumnWidth(8, 12);

    // Data rows
    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      final rowIndex = i + 5;
      final isEven = i % 2 == 0;
      final rowBg = isEven ? evenBg : ExcelColor.fromHexString('#FFFFFF');

      final dataStyle = CellStyle(
        fontSize: 10,
        fontFamily: getFontFamily(FontFamily.Calibri),
        backgroundColorHex: rowBg,
        horizontalAlign: HorizontalAlign.Center,
      );

      final nameStyle = CellStyle(
        fontSize: 10,
        fontFamily: getFontFamily(FontFamily.Calibri),
        backgroundColorHex: rowBg,
        horizontalAlign: HorizontalAlign.Left,
      );

      // Format tanggal
      String dateStr = '-';
      String checkInStr = '-';
      String checkOutStr = '-';

      if (row['date'] != null) {
        try {
          final dt = DateTime.parse(row['date']);
          dateStr = DateFormat('dd/MM/yyyy').format(dt);
        } catch (_) {}
      } else if (row['created_at'] != null) {
        try {
          final dt = DateTime.parse(row['created_at']).toLocal();
          dateStr = DateFormat('dd/MM/yyyy').format(dt);
        } catch (_) {}
      }

      if (row['check_in_time'] != null) {
        try {
          final dt = DateTime.parse(row['check_in_time']).toLocal();
          checkInStr = DateFormat('HH:mm').format(dt);
        } catch (_) {}
      }

      if (row['check_out_time'] != null) {
        try {
          final dt = DateTime.parse(row['check_out_time']).toLocal();
          checkOutStr = DateFormat('HH:mm').format(dt);
        } catch (_) {}
      }

      final cells = [
        (0, '${i + 1}', dataStyle),
        (1, row['full_name'] ?? '-', nameStyle),
        (2, row['nisn'] ?? '-', dataStyle),
        (3, row['class_name'] ?? '-', dataStyle),
        (4, row['company_name'] ?? '-', nameStyle),
        (5, dateStr, dataStyle),
        (6, checkInStr, dataStyle),
        (7, checkOutStr, dataStyle),
        (8, row['status'] ?? '-', dataStyle),
      ];

      for (final (col, val, style) in cells) {
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          )
          ..value = TextCellValue(val)
          ..cellStyle = style;
      }
    }

    // Summary row
    final summaryRow = data.length + 6;
    final hadir = data.where((r) => r['status'] == 'Hadir').length;
    final telat = data.where((r) => r['status'] == 'Telat').length;
    final alpha = data.where((r) => r['status'] == 'Alpa').length;

    final summaryStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontFamily: getFontFamily(FontFamily.Calibri),
      backgroundColorHex: ExcelColor.fromHexString('#DBEAFE'),
    );

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow))
      ..value = TextCellValue('Total')
      ..cellStyle = summaryStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
      ..value = TextCellValue('${data.length} record')
      ..cellStyle = summaryStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: summaryRow))
      ..value = TextCellValue('Hadir:$hadir Telat:$telat Alpa:$alpha')
      ..cellStyle = summaryStyle;
  }

  void _buildJournalSheet(
    Excel excel,
    List<Map<String, dynamic>> data,
    String teacherName,
    String monthName,
  ) {
    final sheet = excel['Jurnal'];

    final headerBg = ExcelColor.fromHexString('#065F46');
    final titleBg = ExcelColor.fromHexString('#ECFDF5');
    final evenBg = ExcelColor.fromHexString('#F0FDF4');

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontColorHex: ExcelColor.fromHexString('#065F46'),
      backgroundColorHex: titleBg,
    );

    final subStyle = CellStyle(
      fontSize: 11,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontColorHex: ExcelColor.fromHexString('#64748B'),
      backgroundColorHex: titleBg,
    );

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: headerBg,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('LAPORAN JURNAL KEGIATAN PKL')
      ..cellStyle = titleStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
      ..value = TextCellValue(
        'Guru Pembimbing: $teacherName | Periode: $monthName',
      )
      ..cellStyle = subStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
      ..value = TextCellValue(
        'Dicetak: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
      )
      ..cellStyle = subStyle;

    final headers = [
      'No',
      'Nama Siswa',
      'Tanggal',
      'Aktivitas',
      'Kendala',
      'Catatan',
      'Status',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4))
        ..value = TextCellValue(headers[i])
        ..cellStyle = headerStyle;
    }

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 40);
    sheet.setColumnWidth(4, 30);
    sheet.setColumnWidth(5, 30);
    sheet.setColumnWidth(6, 14);

    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      final rowIndex = i + 5;
      final isEven = i % 2 == 0;
      final rowBg = isEven ? evenBg : ExcelColor.fromHexString('#FFFFFF');

      final dataStyle = CellStyle(
        fontSize: 10,
        fontFamily: getFontFamily(FontFamily.Calibri),
        backgroundColorHex: rowBg,
        horizontalAlign: HorizontalAlign.Center,
      );

      final textStyle = CellStyle(
        fontSize: 10,
        fontFamily: getFontFamily(FontFamily.Calibri),
        backgroundColorHex: rowBg,
        horizontalAlign: HorizontalAlign.Left,
        textWrapping: TextWrapping.WrapText,
      );

      String dateStr = '-';
      if (row['date'] != null) {
        try {
          final dt = DateTime.parse(row['date']);
          dateStr = DateFormat('dd/MM/yyyy').format(dt);
        } catch (_) {}
      } else if (row['created_at'] != null) {
        try {
          final dt = DateTime.parse(row['created_at']).toLocal();
          dateStr = DateFormat('dd/MM/yyyy').format(dt);
        } catch (_) {}
      }

      final studentName =
          row['profiles']?['full_name'] ?? row['full_name'] ?? '-';
      final isApproved = row['is_approved'] == true;

      final cells = [
        (0, '${i + 1}', dataStyle),
        (1, studentName, textStyle),
        (2, dateStr, dataStyle),
        (3, row['activities'] ?? '-', textStyle),
        (4, row['challenges'] ?? '-', textStyle),
        (5, row['notes'] ?? '-', textStyle),
        (6, isApproved ? 'Disetujui' : 'Menunggu', dataStyle),
      ];

      for (final (col, val, style) in cells) {
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          )
          ..value = TextCellValue(val)
          ..cellStyle = style;
      }
    }
  }

  // ── PDF Export ────────────────────────────────────────────────────────────

  Future<void> generatePdfReport({
    required List<Map<String, dynamic>> attendanceData,
    required List<Map<String, dynamic>> journalData,
    required String teacherName,
    required int month,
    required int year,
  }) async {
    final pdf = pw.Document();
    final monthName = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(DateTime(year, month));
    final printDate = DateFormat(
      'dd MMMM yyyy HH:mm',
      'id_ID',
    ).format(DateTime.now());

    // ── Halaman 1: Absensi ────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        header: (context) => _buildPdfHeader(
          'LAPORAN ABSENSI SISWA PKL',
          teacherName,
          monthName,
          printDate,
          PdfColor.fromHex('#1E3A8A'),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildAttendancePdfTable(attendanceData),
          pw.SizedBox(height: 12),
          _buildAttendanceSummary(attendanceData),
        ],
      ),
    );

    // ── Halaman 2: Jurnal ─────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        header: (context) => _buildPdfHeader(
          'LAPORAN JURNAL KEGIATAN PKL',
          teacherName,
          monthName,
          printDate,
          PdfColor.fromHex('#065F46'),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildJournalPdfTable(journalData),
          pw.SizedBox(height: 12),
          _buildJournalSummary(journalData),
        ],
      ),
    );

    final bytes = await pdf.save();
    final fileName =
        'Laporan_PKL_${monthName.replaceAll(' ', '_')}_${teacherName.replaceAll(' ', '_')}.pdf';

    _downloadFile(bytes, fileName, 'application/pdf');
  }

  pw.Widget _buildPdfHeader(
    String title,
    String teacherName,
    String monthName,
    String printDate,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: color, width: 2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Guru Pembimbing: $teacherName  |  Periode: $monthName',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Dicetak: $printDate',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAttendancePdfTable(List<Map<String, dynamic>> data) {
    final headers = [
      'No',
      'Nama',
      'Kelas',
      'Perusahaan',
      'Tanggal',
      'Masuk',
      'Pulang',
      'Status',
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF1E3A8A),
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.center,
        7: pw.Alignment.center,
      },
      oddRowDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFEFF6FF),
      ),
      data: data.asMap().entries.map((entry) {
        final i = entry.key;
        final row = entry.value;

        String dateStr = '-';
        String checkInStr = '-';
        String checkOutStr = '-';

        if (row['date'] != null) {
          try {
            dateStr = DateFormat(
              'dd/MM/yy',
            ).format(DateTime.parse(row['date']));
          } catch (_) {}
        }
        if (row['check_in_time'] != null) {
          try {
            checkInStr = DateFormat(
              'HH:mm',
            ).format(DateTime.parse(row['check_in_time']).toLocal());
          } catch (_) {}
        }
        if (row['check_out_time'] != null) {
          try {
            checkOutStr = DateFormat(
              'HH:mm',
            ).format(DateTime.parse(row['check_out_time']).toLocal());
          } catch (_) {}
        }

        return [
          '${i + 1}',
          row['full_name'] ?? '-',
          row['class_name'] ?? '-',
          row['company_name'] ?? '-',
          dateStr,
          checkInStr,
          checkOutStr,
          row['status'] ?? '-',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildAttendanceSummary(List<Map<String, dynamic>> data) {
    final hadir = data.where((r) => r['status'] == 'Hadir').length;
    final telat = data.where((r) => r['status'] == 'Telat').length;
    final alpha = data.where((r) => r['status'] == 'Alpa').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFDBEAFE),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total', '${data.length}', PdfColors.blue800),
          _summaryItem('Hadir', '$hadir', PdfColors.green800),
          _summaryItem('Telat', '$telat', PdfColors.orange800),
          _summaryItem('Alpa', '$alpha', PdfColors.red800),
        ],
      ),
    );
  }

  pw.Widget _buildJournalPdfTable(List<Map<String, dynamic>> data) {
    final headers = ['No', 'Nama', 'Tanggal', 'Aktivitas', 'Status'];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF065F46),
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.center,
        2: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      oddRowDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFECFDF5),
      ),
      data: data.asMap().entries.map((entry) {
        final i = entry.key;
        final row = entry.value;

        String dateStr = '-';
        if (row['date'] != null) {
          try {
            dateStr = DateFormat(
              'dd/MM/yy',
            ).format(DateTime.parse(row['date']));
          } catch (_) {}
        } else if (row['created_at'] != null) {
          try {
            dateStr = DateFormat(
              'dd/MM/yy',
            ).format(DateTime.parse(row['created_at']).toLocal());
          } catch (_) {}
        }

        final studentName =
            row['profiles']?['full_name'] ?? row['full_name'] ?? '-';
        final isApproved = row['is_approved'] == true;
        final activities = row['activities'] ?? '-';
        final truncated = activities.length > 60
            ? '${activities.substring(0, 60)}...'
            : activities;

        return [
          '${i + 1}',
          studentName,
          dateStr,
          truncated,
          isApproved ? 'Disetujui' : 'Menunggu',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildJournalSummary(List<Map<String, dynamic>> data) {
    final approved = data.where((r) => r['is_approved'] == true).length;
    final pending = data.where((r) => r['is_approved'] != true).length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFD1FAE5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total Jurnal', '${data.length}', PdfColors.green900),
          _summaryItem('Disetujui', '$approved', PdfColors.green800),
          _summaryItem('Menunggu', '$pending', PdfColors.orange800),
        ],
      ),
    );
  }

  pw.Widget _summaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  // ── Download Helper ───────────────────────────────────────────────────────

  void _downloadFile(List<int> bytes, String fileName, String mimeType) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
