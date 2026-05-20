import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ExcelService {
  /// Generates and downloads an Excel file for Attendance Report (Flutter Web)
  Future<void> generateAttendanceReport(
    List<Map<String, dynamic>> data,
    String teacherName,
  ) async {
    var excel = Excel.createExcel();

    // Default sheet
    String sheetName = 'Laporan Absensi';
    Sheet sheetObject = excel[sheetName];
    excel.delete('Sheet1'); // Remove default sheet

    // Styles
    CellStyle headerStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#CCCCCC'),
    );

    // Add Title
    var titleCell = sheetObject.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    );
    titleCell.value = TextCellValue('Laporan Absensi Siswa - $teacherName');
    titleCell.cellStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 16,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#CCCCCC'),
    );

    // Headers
    List<String> headers = [
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
      var cell = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data Rows
    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      final rowIndex = i + 3;

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(
        row['full_name'] ?? '-',
      );

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(
        row['nisn'] ?? '-',
      );

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(
        row['class_name'] ?? '-',
      );

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(
        row['company_name'] ?? '-',
      );

      // Format Date/Time
      String dateStr = '-';
      String checkInStr = '-';
      String checkOutStr = '-';

      if (row['created_at'] != null) {
        final dt = DateTime.parse(row['created_at']).toLocal();
        dateStr = DateFormat('dd/MM/yyyy').format(dt);
        checkInStr = DateFormat('HH:mm').format(dt);
      }

      if (row['check_out_time'] != null) {
        final dt = DateTime.parse(row['check_out_time']).toLocal();
        checkOutStr = DateFormat('HH:mm').format(dt);
      }

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(
        dateStr,
      );

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(
        checkInStr,
      );

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(
        checkOutStr,
      );

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(
        row['status'] ?? '-',
      );
    }

    // Generate bytes
    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Failed to generate Excel file');
    }

    // Download via browser (Flutter Web)
    final fileName =
        'Laporan_Absensi_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    final blob = html.Blob([
      fileBytes,
    ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
