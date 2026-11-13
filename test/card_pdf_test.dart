import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:relearn/core/services/card_pdf.dart';
import 'package:relearn/data/models.dart';

void main() {
  test('card PDF contains every selected beneficiary', () async {
    final beneficiaries = [
      const Beneficiary(
        id: 'ben-1',
        publicId: 'RL-0042-7K3Q',
        schoolId: 'sch-1',
        name: 'Amina Yusuf',
        type: BeneficiaryType.pupil,
        className: 'Primary 5',
        balance: 230,
      ),
      const Beneficiary(
        id: 'ben-2',
        publicId: 'RL-0043-8M2P',
        schoolId: 'sch-1',
        name: 'Musa Ahmed',
        type: BeneficiaryType.pupil,
        className: 'Primary 4',
        balance: 120,
      ),
    ];

    final bytes = await CardPdf.build(
      beneficiaries: beneficiaries,
      schoolName: 'Gombe Model Primary School',
    );

    expect(bytes.length, greaterThan(1000));
    expect(latin1.decode(bytes.take(5).toList()), '%PDF-');
  });

  test('card PDF rejects an empty selection', () async {
    await expectLater(
      CardPdf.build(beneficiaries: const [], schoolName: 'School'),
      throwsArgumentError,
    );
  });
}
