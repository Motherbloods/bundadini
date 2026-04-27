import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/examination_model.dart';
import '../../data/models/patient_model.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/rule_engine.dart';

class ExcelService {
  ExcelService._();

  static Future<void> exportAndShare({
    required List<ExaminationModel> examinations,
    required List<PatientModel> patients,
    required DateTime from,
    required DateTime to,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Rekap Pemeriksaan'];

    //  Header row
    final headers = [
      'No',
      'Nama Ibu',
      'NIK',
      'Kader',
      'Tanggal',
      'Usia Kehamilan (mgg)',
      'Sistolik (mmHg)',
      'Diastolik (mmHg)',
      'Status Tensi',
      'BB (kg)',
      'TB (cm)',
      'LILA (cm)',
      'BMI',
      'Status LILA',
      'DJJ (bpm)',
      'Status DJJ',
      'Status Ibu',
      'Status Janin',
      'Rekomendasi',
      'Keluhan Ibu',
      'Catatan Kader',
    ];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#C62828'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    for (var i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    //  Set column widths
    final colWidths = [
      5.0,
      25.0,
      18.0,
      20.0,
      14.0,
      10.0,
      10.0,
      10.0,
      14.0,
      8.0,
      8.0,
      8.0,
      8.0,
      12.0,
      8.0,
      14.0,
      16.0,
      14.0,
      50.0,
      25.0,
      25.0
    ];
    for (var i = 0; i < colWidths.length; i++) {
      sheet.setColumnWidth(i, colWidths[i]);
    }
    sheet.setRowHeight(0, 40);

    //  Map pasien by id
    final patientMap = {for (final p in patients) p.id: p};

    //  Data rows
    final altStyle =
        CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFEBEE'));
    final normalStyle =
        CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'));

    for (var i = 0; i < examinations.length; i++) {
      final e = examinations[i];
      final p = patientMap[e.patientId];
      final row = i + 1;
      final style = i.isEven ? normalStyle : altStyle;

      final values = [
        IntCellValue(row),
        TextCellValue(p?.nama ?? '-'),
        TextCellValue(p?.nik ?? '-'),
        TextCellValue(e.kaderNama),
        TextCellValue(DateFormatter.toDisplay(e.tanggal)),
        IntCellValue(e.usiaKehamilan),
        IntCellValue(e.sistolik),
        IntCellValue(e.diastolik),
        TextCellValue(_tensiStatus(e.sistolik, e.diastolik)),
        DoubleCellValue(e.beratBadan),
        DoubleCellValue(e.tinggiBadan),
        DoubleCellValue(e.lingkarLengan),
        DoubleCellValue(double.parse(e.bmi.toStringAsFixed(1))),
        TextCellValue(RuleEngine.isKek(e.lingkarLengan) ? 'KEK' : 'Normal'),
        IntCellValue(e.djj),
        TextCellValue(JaninStatus.label(e.statusJanin)),
        TextCellValue(ExaminationStatus.label(e.statusIbu)),
        TextCellValue(JaninStatus.label(e.statusJanin)),
        TextCellValue(e.rekomendasi.join('; ')),
        TextCellValue(e.keluhanIbu ?? '-'),
        TextCellValue(e.catatanKader ?? '-'),
      ];

      for (var j = 0; j < values.length; j++) {
        final cell = sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row));
        cell.value = values[j];
        cell.cellStyle = style;
      }
      sheet.setRowHeight(row, 22);
    }

    //  Hapus sheet default
    excel.delete('Sheet1');

    //  Simpan ke file
    final bytes = excel.save();
    if (bytes == null) throw Exception('Gagal membuat file Excel');

    final dir = await getTemporaryDirectory();
    final stamp = DateFormatter.toFileStamp(DateTime.now());
    final fileName = 'Rekap_BundaDini_$stamp.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    //  Share
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'Rekap Pemeriksaan Bunda Dini — $stamp',
        text:
            'Data rekap pemeriksaan ibu hamil\nPeriode: ${DateFormatter.toDisplay(from)} s/d ${DateFormatter.toDisplay(to)}',
      ),
    );
  }

  static String _tensiStatus(int sis, int dia) {
    if (sis >= 140 || dia >= 90) return 'Hipertensi';
    if (sis < 90 || dia < 60) return 'Hipotensi';
    return 'Normal';
  }
}
