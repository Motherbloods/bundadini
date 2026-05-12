import 'package:bundadini/core/utils/date_formatter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/examination_model.dart';
import '../../data/models/patient_model.dart';
import '../../core/utils/rule_engine.dart';

class PdfService {
  PdfService._();

  static const _red = PdfColor.fromInt(0xFFC62828);
  static const _green = PdfColor.fromInt(0xFF2E7D32);
  static const _orange = PdfColor.fromInt(0xFFE65100);
  static const _grey = PdfColor.fromInt(0xFF757575);
  static const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
  static const _divider = PdfColor.fromInt(0xFFE0E0E0);

  /// Membuat PDF rekap tabel untuk SEMUA [examinations] dalam range [from]–[to].
  /// [patientMap] memetakan patientId → PatientModel agar nama & data ibu
  /// diambil dari Firestore, bukan hardcode.
  static Future<void> generateRekapAndPrint({
    required List<ExaminationModel> examinations,
    required Map<String, PatientModel> patientMap,
    required String namaPuskesmas,
    required String bidanNama,
    required DateTime from,
    required DateTime to,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape, // landscape agar tabel lega
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => [
        // Header
        _buildRekapHeader(namaPuskesmas, from, to, fontBold, font),
        pw.SizedBox(height: 12),
        pw.Divider(thickness: 2, color: _red),
        pw.SizedBox(height: 12),

        // Tabel rekap semua pemeriksaan
        _buildRekapTable(examinations, patientMap, font, fontBold),
        pw.SizedBox(height: 28),

        // Footer tanda tangan bidan
        _buildFooter('', bidanNama, DateTime.now(), font, fontBold),
      ],
    ));

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static pw.Widget _buildRekapHeader(String puskesmas, DateTime from,
      DateTime to, pw.Font fontBold, pw.Font font) {
    return pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(puskesmas.toUpperCase(),
              style: pw.TextStyle(font: fontBold, fontSize: 14, color: _red)),
          pw.SizedBox(height: 4),
          pw.Text('REKAP PEMERIKSAAN IBU HAMIL',
              style: pw.TextStyle(font: fontBold, fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Periode: ${_fmt(from)} s/d ${_fmt(to)}   |   Tanggal Cetak: ${_fmt(DateTime.now())}',
            style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRekapTable(
    List<ExaminationModel> exams,
    Map<String, PatientModel> patientMap,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final headers = [
      'No',
      'Nama Ibu',
      'NIK',
      'Kader',
      'Tanggal',
      'Usia\nKehamilan\n(mgg)',
      'TP',
      'Sistolik\n(mmHg)',
      'Diastolik\n(mmHg)',
      'Status\nTensi',
      'BB\n(kg)',
      'LILA\n(cm)',
      'BMI',
      'DJJ\n(bpm)',
      'Status Ibu',
      'Status\nJanin',
    ];

    final tableData = <List<String>>[];
    for (var i = 0; i < exams.length; i++) {
      final e = exams[i];
      final p = patientMap[e.patientId];

      final tpStr = p?.hpht != null ? _hitungTp(p!.hpht!) : 'Belum diisi';

      tableData.add([
        '${i + 1}',
        p?.nama ?? '-',
        p?.nik ?? '-',
        e.kaderNama,
        _fmt(e.tanggal),
        '${e.usiaKehamilan}',
        tpStr,
        '${e.sistolik}',
        '${e.diastolik}',
        _tensiStatus(e.sistolik, e.diastolik),
        e.beratBadan.toStringAsFixed(1),
        e.lingkarLengan.toStringAsFixed(1),
        e.bmi.toStringAsFixed(1),
        '${e.djj}',
        ExaminationStatus.label(e.statusIbu),
        JaninStatus.label(e.statusJanin),
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: tableData,
      headerStyle:
          pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: _red),
      cellStyle: pw.TextStyle(font: font, fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.center,
        7: pw.Alignment.center,
        8: pw.Alignment.center,
        9: pw.Alignment.center,
        10: pw.Alignment.center,
        11: pw.Alignment.center,
        12: pw.Alignment.center,
        13: pw.Alignment.center,
        14: pw.Alignment.center,
        15: pw.Alignment.center,
      },
      rowDecoration: const pw.BoxDecoration(color: _lightGrey),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(22),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(2.5),
        4: const pw.FixedColumnWidth(52),
        5: const pw.FixedColumnWidth(36),
        6: const pw.FixedColumnWidth(52),
        7: const pw.FixedColumnWidth(36),
        8: const pw.FixedColumnWidth(36),
        9: const pw.FixedColumnWidth(46),
        10: const pw.FixedColumnWidth(30),
        11: const pw.FixedColumnWidth(30),
        12: const pw.FixedColumnWidth(30),
        13: const pw.FixedColumnWidth(30),
        14: const pw.FlexColumnWidth(2),
        15: const pw.FlexColumnWidth(2),
      },
    );
  }

  static Future<void> generateAndPrint({
    required ExaminationModel exam,
    required String patientNama,
    required String patientNik,
    required String patientTglLahir,
    required String patientGolDarah,
    required String patientAlamat,
    required String patientNoHp,
    required String patientHpht, // format dd/MM/yyyy — dari DateFormatter
    required String patientFotoUrl,
    required String namaPuskesmas,
    required String bidanNama,
    String taksiranPersalinan = '-',
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    // Hitung HPL (Hari Perkiraan Lahir) dari HPHT (data Firestore, bukan hardcode)
    print('HPHT masuk ke PDF: $patientHpht');
    final tpStr = _hitungTpFromString(patientHpht);
    print('TP hasil hitung di PDF: $tpStr');
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
          tpStr, // HPL (Hari Perkiraan Lahir) dihitung dari HPHT Firestore
          font,
          fontBold,
        ),
        pw.SizedBox(height: 16),

        // TABEL PEMERIKSAAN
        _buildSection('HASIL PEMERIKSAAN', fontBold),
        pw.SizedBox(height: 8),
        _buildParamTable(exam, font, fontBold),
        pw.SizedBox(height: 16),

        // KESIMPULAN
        _buildSection('KESIMPULAN', fontBold),
        pw.SizedBox(height: 8),
        _buildKesimpulan(exam, font, fontBold),
        pw.SizedBox(height: 16),

        // REKOMENDASI
        _buildSection('REKOMENDASI', fontBold),
        pw.SizedBox(height: 8),
        _buildRekomendasi(exam, font),
        pw.SizedBox(height: 32),

        // FOOTER / TANDA TANGAN
        _buildFooter(exam.kaderNama, bidanNama, exam.tanggal, font, fontBold),
      ],
    ));

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static pw.Widget _buildHeader(
      String puskesmas, ExaminationModel exam, pw.Font fontBold, pw.Font font) {
    return pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
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
        ],
      ),
    );
  }

  static pw.Widget _buildPatientInfo(
    String nama,
    String nik,
    String tglLahir,
    String golDarah,
    String alamat,
    String noHp,
    String hpht,
    String tp,
    pw.Font font,
    pw.Font fontBold,
  ) {
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
        // HPL (Hari Perkiraan Lahir) — tidak hardcode, dihitung dari HPHT Firestore
        _infoRow('HPL (Hari Perkiraan Lahir)', tp, font, fontBold),
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
            width: 140,
            child: pw.Text(label,
                style: pw.TextStyle(font: font, fontSize: 10, color: _grey))),
        pw.Text(': ', style: pw.TextStyle(font: font, fontSize: 10)),
        pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(font: fontBold, fontSize: 10))),
      ]),
    );
  }

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
      [
        'Keluhan Ibu',
        exam.keluhanList.isNotEmpty
            ? exam.keluhanList.join(', ') +
                (exam.keluhanLainnya != null ? ', ${exam.keluhanLainnya}' : '')
            : '-',
        ''
      ],
      [
        'TFU (cm)',
        exam.tfu != null ? '${exam.tfu!.toStringAsFixed(1)} cm' : '-',
        ''
      ],
      [
        'Catatan Bidan',
        exam.catatanBidan != null && exam.catatanBidan!.isNotEmpty
            ? exam.catatanBidan!
            : '(Belum ada catatan bidan)',
        ''
      ],
    ];

    return pw.TableHelper.fromTextArray(
      headers: ['Parameter', 'Nilai', 'Keterangan'],
      data: rows,
      headerStyle:
          pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: _red),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center
      },
      rowDecoration: const pw.BoxDecoration(color: _lightGrey),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2)
      },
    );
  }

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

  static pw.Widget _buildFooter(String kaderNama, String bidanNama,
      DateTime tanggal, pw.Font font, pw.Font fontBold) {
    return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      // Kader (kiri) — hanya tampil jika ada kaderNama
      if (kaderNama.isNotEmpty)
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
            pw.SizedBox(height: 48),
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

  /// Format tanggal ke dd/MM/yyyy
  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Hitung HPL (Hari Perkiraan Lahir) (Naegele) dari objek DateTime HPHT.
  /// TP = HPHT + 7 hari, - 3 bulan, + 1 tahun.
  static String _hitungTp(DateTime hpht) {
    try {
      final tp = DateTime(
        hpht.year + 1,
        hpht.month - 3,
        hpht.day + 7,
      );
      return _fmt(tp);
    } catch (_) {
      return '-';
    }
  }

  /// Hitung TP dari string format dd/MM/yyyy (dari DateFormatter.toDisplay).
  static String _hitungTpFromString(String hphtStr) {
    final hpht = DateFormatter.parseFlexible(hphtStr);

    if (hpht == null) return 'Belum diisi';

    final taksiran = DateFormatter.taksiran(hpht);

    if (taksiran == null) return 'Belum diisi';

    return _fmt(taksiran);
  }

  static String _tensiStatus(int sis, int dia) {
    if (sis >= 140 || dia >= 90) return 'Hipertensi';
    if (sis < 90 || dia < 60) return 'Hipotensi';
    return 'Normal';
  }
}
