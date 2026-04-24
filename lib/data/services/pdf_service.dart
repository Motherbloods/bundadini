import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/examination_model.dart';
import '../../core/utils/rule_engine.dart';

class PdfService {
  PdfService._();

  static const _red = PdfColor.fromInt(0xFFC62828);
  static const _green = PdfColor.fromInt(0xFF2E7D32);
  static const _orange = PdfColor.fromInt(0xFFE65100);
  static const _grey = PdfColor.fromInt(0xFF757575);
  static const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
  static const _divider = PdfColor.fromInt(0xFFE0E0E0);

  static Future<void> generateAndPrint({
    required ExaminationModel exam,
    required String patientNama,
    required String patientNik,
    required String patientTglLahir,
    required String patientGolDarah,
    required String patientAlamat,
    required String patientNoHp,
    required String patientHpht,
    required String patientFotoUrl,
    required String namaPuskesmas,
    required String bidanNama,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        // HEADER
        _buildHeader(namaPuskesmas, exam, fontBold, font),
        pw.SizedBox(height: 16),
        pw.Divider(thickness: 2, color: _red),
        pw.SizedBox(height: 12),

        // DATA IBU
        _buildSection('DATA IBU HAMIL', fontBold),
        pw.SizedBox(height: 8),
        _buildPatientInfo(
            patientNama,
            patientNik,
            patientTglLahir,
            patientGolDarah,
            patientAlamat,
            patientNoHp,
            patientHpht,
            font,
            fontBold),
        pw.SizedBox(height: 16),

        // TABEL PEMERIKSAAN─
        _buildSection('HASIL PEMERIKSAAN', fontBold),
        pw.SizedBox(height: 8),
        _buildParamTable(exam, font, fontBold),
        pw.SizedBox(height: 16),

        // KESIMPULAN
        _buildSection('KESIMPULAN', fontBold),
        pw.SizedBox(height: 8),
        _buildKesimpulan(exam, font, fontBold),
        pw.SizedBox(height: 16),

        // REKOMENDASI─
        _buildSection('REKOMENDASI', fontBold),
        pw.SizedBox(height: 8),
        _buildRekomendasi(exam, font),
        pw.SizedBox(height: 32),

        // FOOTER / TANDA TANGAN─
        _buildFooter(exam.kaderNama, bidanNama, exam.tanggal, font, fontBold),
      ],
    ));

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  // Header
  static pw.Widget _buildHeader(
      String puskesmas, ExaminationModel exam, pw.Font fontBold, pw.Font font) {
    return pw.Column(children: [
      pw.Text(puskesmas.toUpperCase(),
          style: pw.TextStyle(font: fontBold, fontSize: 16, color: _red)),
      pw.SizedBox(height: 4),
      pw.Text('LAPORAN PEMERIKSAAN IBU HAMIL',
          style: pw.TextStyle(font: fontBold, fontSize: 13)),
      pw.SizedBox(height: 4),
      pw.Text(
        'Tanggal Cetak: ${_fmt(DateTime.now())}',
        style: pw.TextStyle(font: font, fontSize: 10, color: _grey),
      ),
    ]);
  }

  // Data pasien
  static pw.Widget _buildPatientInfo(
      String nama,
      String nik,
      String tglLahir,
      String golDarah,
      String alamat,
      String noHp,
      String hpht,
      pw.Font font,
      pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _divider),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _infoRow('Nama', nama, font, fontBold),
        _infoRow('NIK', nik, font, fontBold),
        _infoRow('Tanggal Lahir', tglLahir, font, fontBold),
        _infoRow('Golongan Darah', golDarah, font, fontBold),
        _infoRow('Nomor HP', noHp, font, fontBold),
        _infoRow('HPHT', hpht, font, fontBold),
        _infoRow('Alamat', alamat, font, fontBold),
      ]),
    );
  }

  static pw.Widget _infoRow(
      String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.SizedBox(
            width: 120,
            child: pw.Text(label,
                style: pw.TextStyle(font: font, fontSize: 10, color: _grey))),
        pw.Text(': ', style: pw.TextStyle(font: font, fontSize: 10)),
        pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(font: fontBold, fontSize: 10))),
      ]),
    );
  }

  // Tabel parameter
  static pw.Widget _buildParamTable(
      ExaminationModel exam, pw.Font font, pw.Font fontBold) {
    final rows = [
      [
        'Tensi Sistolik',
        '${exam.sistolik} mmHg',
        _tensiStatus(exam.sistolik, exam.diastolik)
      ],
      ['Tensi Diastolik', '${exam.diastolik} mmHg', ''],
      ['Usia Kehamilan', '${exam.usiaKehamilan} minggu', ''],
      [
        'Berat Badan',
        '${exam.beratBadan.toStringAsFixed(1)} kg',
        exam.kenaikanBb != 0
            ? '${exam.kenaikanBb >= 0 ? '+' : ''}${exam.kenaikanBb.toStringAsFixed(1)} kg'
            : ''
      ],
      ['Tinggi Badan', '${exam.tinggiBadan.toStringAsFixed(0)} cm', ''],
      [
        'LILA',
        '${exam.lingkarLengan.toStringAsFixed(1)} cm',
        RuleEngine.isKek(exam.lingkarLengan) ? 'KEK' : 'Normal'
      ],
      ['BMI', exam.bmi.toStringAsFixed(1), RuleEngine.kategoriBmi(exam.bmi)],
      ['DJJ', '${exam.djj} bpm', JaninStatus.label(exam.statusJanin)],
      ['Keluhan Ibu', exam.keluhanIbu ?? '-', ''],
      ['Catatan Kader', exam.catatanKader ?? '-', ''],
    ];

    return pw.TableHelper.fromTextArray(
      headers: ['Parameter', 'Nilai', 'Keterangan'],
      data: rows,
      headerStyle:
          pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: _red),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center
      },
      rowDecoration: pw.BoxDecoration(color: _lightGrey),
      oddRowDecoration: pw.BoxDecoration(color: PdfColors.white),
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2)
      },
    );
  }

  // Kesimpulan─
  static pw.Widget _buildKesimpulan(
      ExaminationModel exam, pw.Font font, pw.Font fontBold) {
    final ibuColor = exam.statusIbu == ExaminationStatus.risikoTinggi
        ? _red
        : exam.statusIbu == ExaminationStatus.perluPerhatian
            ? _orange
            : _green;
    final janinColor = exam.statusJanin != JaninStatus.normal ? _red : _green;

    return pw.Row(children: [
      pw.Expanded(
          child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: ibuColor),
            borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(children: [
          pw.Text('Kondisi Ibu',
              style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
          pw.SizedBox(height: 4),
          pw.Text(ExaminationStatus.label(exam.statusIbu),
              style:
                  pw.TextStyle(font: fontBold, fontSize: 12, color: ibuColor)),
        ]),
      )),
      pw.SizedBox(width: 12),
      pw.Expanded(
          child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: janinColor),
            borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(children: [
          pw.Text('Kondisi Janin',
              style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
          pw.SizedBox(height: 4),
          pw.Text(JaninStatus.label(exam.statusJanin),
              style: pw.TextStyle(
                  font: fontBold, fontSize: 12, color: janinColor)),
        ]),
      )),
    ]);
  }

  // Rekomendasi
  static pw.Widget _buildRekomendasi(ExaminationModel exam, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
          color: _lightGrey,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: _divider)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: exam.rekomendasi
            .map((r) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ',
                            style: pw.TextStyle(font: font, fontSize: 10)),
                        pw.Expanded(
                            child: pw.Text(r,
                                style: pw.TextStyle(font: font, fontSize: 10))),
                      ]),
                ))
            .toList(),
      ),
    );
  }

  // Footer─
  static pw.Widget _buildFooter(String kaderNama, String bidanNama,
      DateTime tanggal, pw.Font font, pw.Font fontBold) {
    return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      // Kader (kiri)
      pw.Expanded(
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
            pw.Text('Diperiksa oleh:',
                style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
            pw.SizedBox(height: 4),
            pw.Text(kaderNama,
                style: pw.TextStyle(font: fontBold, fontSize: 11)),
            pw.SizedBox(height: 2),
            pw.Text('Tanggal: ${_fmt(tanggal)}',
                style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
          ])),
      // Bidan (kanan)
      pw.Expanded(
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
            pw.Text('Mengetahui, Bidan Pendamping',
                style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
            pw.SizedBox(height: 48), // ruang tanda tangan
            pw.Container(
                width: 120,
                child: pw.Divider(thickness: 0.8, color: PdfColors.black)),
            pw.SizedBox(height: 4),
            pw.Text(
                bidanNama.isNotEmpty
                    ? bidanNama
                    : '(................................)',
                style: pw.TextStyle(font: fontBold, fontSize: 11)),
          ])),
    ]);
  }

  // Helpers
  static pw.Widget _buildSection(String title, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
          color: _red, borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Text(title,
          style: pw.TextStyle(
              font: fontBold, fontSize: 11, color: PdfColors.white)),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _tensiStatus(int sis, int dia) {
    if (sis >= 140 || dia >= 90) return 'Hipertensi';
    if (sis < 90 || dia < 60) return 'Hipotensi';
    return 'Normal';
  }
}
