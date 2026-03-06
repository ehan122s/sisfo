import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ExcelService {
  /// Generates an Excel file for Attendance Report
  Future<File> generateAttendanceReport(
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
    // data expected to be a flat list of attendance logs merged with student info
    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      final rowIndex = i + 3;

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(
        row['full_name'] ?? '-',
      ); // Nama

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(
        row['nisn'] ?? '-',
      ); // NISN

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(
        row['class_name'] ?? '-',
      ); // Kelas

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(
        row['company_name'] ?? '-',
      ); // Perusahaan

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
      ); // Tanggal

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(
        checkInStr,
      ); // Jam Masuk

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(
        checkOutStr,
      ); // Jam Pulang

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(
        row['status'] ?? '-',
      ); // Status
    }

    // Auto-fit columns (not natively supported perfectly, but we can set fixed widths)
    // excel.sheets[sheetName]?.setColAutoFit(0); // Deprecated/Experimental in some versions

    // Save File
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'Laporan_Absensi_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final file = File('${directory.path}/$fileName');

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      return file;
    } else {
      throw Exception('Failed to save Excel file');
    }
  }
}
