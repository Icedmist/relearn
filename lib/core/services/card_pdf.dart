import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models.dart';

/// Builds printable A4 sheets of beneficiary cards.
///
/// Each sheet holds eight cards (two columns by four rows). The QR contains
/// only the public ID. Cards deliberately omit the beneficiary's name so a lost
/// card does not expose a pupil's identity; the public ID, type, class and
/// school are still printed so a damaged QR can be keyed in by hand.
abstract final class CardPdf {
  static const _forest = PdfColor.fromInt(0xFF123B2A);
  static const _leaf = PdfColor.fromInt(0xFF2E9E5B);
  static const _muted = PdfColor.fromInt(0xFF6B7A72);
  static const _line = PdfColor.fromInt(0xFFD8E2DA);
  static const _cream = PdfColor.fromInt(0xFFF7F4EA);

  static const _cardsPerPage = 8;
  static const _columns = 2;
  static const _gap = 4 * PdfPageFormat.mm;

  // A4 has 190 mm of usable width after the 10 mm margins. Two 90 mm cards
  // plus the gap fit with room to spare; the previous 93 mm width rounded over
  // the edge and silently collapsed the grid to one card per row.
  static const _cardWidth = 90 * PdfPageFormat.mm;
  static const _cardHeight = 60 * PdfPageFormat.mm;

  static Future<Uint8List> build({
    required List<Beneficiary> beneficiaries,
    required String schoolName,
    bool compress = true,
  }) async {
    if (beneficiaries.isEmpty) {
      throw ArgumentError('Select at least one beneficiary.');
    }

    final document = pw.Document(
      title: 'ReLearn cards - $schoolName',
      author: 'ReLearn',
      creator: 'ReLearn',
      compress: compress,
    );

    for (var start = 0; start < beneficiaries.length; start += _cardsPerPage) {
      final chunk = beneficiaries.sublist(
        start,
        math.min(start + _cardsPerPage, beneficiaries.length),
      );
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10 * PdfPageFormat.mm),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(schoolName),
              pw.SizedBox(height: 4 * PdfPageFormat.mm),
              _grid(chunk, schoolName),
            ],
          ),
        ),
      );
    }

    return document.save();
  }

  /// Lays cards out in fixed rows of two. A plain wrap depended on floating
  /// point widths and lost every card once the overflow passed the page edge.
  static pw.Widget _grid(List<Beneficiary> cards, String schoolName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i += _columns)
          pw.Padding(
            padding: pw.EdgeInsets.only(
              bottom: i + _columns < cards.length ? _gap : 0,
            ),
            child: pw.Row(
              children: [
                _card(cards[i], schoolName),
                if (i + 1 < cards.length) ...[
                  pw.SizedBox(width: _gap),
                  _card(cards[i + 1], schoolName),
                ],
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _header(String schoolName) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(
            horizontal: 2.5 * PdfPageFormat.mm,
            vertical: 1.2 * PdfPageFormat.mm,
          ),
          decoration: pw.BoxDecoration(
            color: _leaf,
            borderRadius: pw.BorderRadius.circular(1.2 * PdfPageFormat.mm),
          ),
          child: pw.Text(
            'ReLearn',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        pw.SizedBox(width: 3 * PdfPageFormat.mm),
        pw.Expanded(
          child: pw.Text(
            schoolName,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              color: _forest,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ),
        pw.Text(
          'Recycle to Learn',
          style: pw.TextStyle(color: _muted, fontSize: 7),
        ),
      ],
    );
  }

  static pw.Widget _card(Beneficiary beneficiary, String schoolName) {
    final type = beneficiary.type.label;
    return pw.Container(
      width: _cardWidth,
      height: _cardHeight,
      padding: const pw.EdgeInsets.all(3.5 * PdfPageFormat.mm),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line, width: 0.7),
        borderRadius: pw.BorderRadius.circular(2.5 * PdfPageFormat.mm),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 1.8 * PdfPageFormat.mm,
                  vertical: 0.8 * PdfPageFormat.mm,
                ),
                decoration: pw.BoxDecoration(
                  color: _forest,
                  borderRadius: pw.BorderRadius.circular(PdfPageFormat.mm),
                ),
                child: pw.Text(
                  'ReLearn',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 7,
                  ),
                ),
              ),
              pw.Spacer(),
              pw.Text(
                'RECYCLE TO LEARN',
                style: pw.TextStyle(
                  color: _muted,
                  fontSize: 5.5,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2 * PdfPageFormat.mm),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '$type card',
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(
                          color: _forest,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 0.6 * PdfPageFormat.mm),
                      pw.Text(
                        beneficiary.className,
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(color: _muted, fontSize: 7.5),
                      ),
                      pw.SizedBox(height: 0.6 * PdfPageFormat.mm),
                      pw.Text(
                        schoolName,
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(color: _muted, fontSize: 6.5),
                      ),
                      pw.Spacer(),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 2 * PdfPageFormat.mm,
                          vertical: PdfPageFormat.mm,
                        ),
                        decoration: pw.BoxDecoration(
                          color: _cream,
                          borderRadius: pw.BorderRadius.circular(
                            PdfPageFormat.mm,
                          ),
                        ),
                        child: pw.Text(
                          beneficiary.publicId,
                          style: pw.TextStyle(
                            color: _forest,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 3 * PdfPageFormat.mm),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: beneficiary.publicId,
                  width: 25 * PdfPageFormat.mm,
                  height: 25 * PdfPageFormat.mm,
                  drawText: false,
                  color: _forest,
                  backgroundColor: PdfColors.white,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 1.5 * PdfPageFormat.mm),
          pw.Text(
            'This card belongs to your school. Return it if found.',
            style: pw.TextStyle(color: _muted, fontSize: 5.5),
          ),
        ],
      ),
    );
  }
}
