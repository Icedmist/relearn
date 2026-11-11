import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relearn/data/app_store.dart';
import 'package:relearn/data/models.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'recording a collection credits the correct points and balance',
    () async {
      final store = container.read(appStoreProvider.notifier);
      final before = container.read(appStoreProvider).beneficiaryById('ben-1')!;

      final points = await store.recordCollection(
        beneficiaryId: 'ben-1',
        lines: [
          (
            material: container.read(appStoreProvider).materialById('mat-1')!,
            quantity: 2,
          ),
        ],
      );

      final after = container.read(appStoreProvider).beneficiaryById('ben-1')!;
      expect(points, 20); // 2 kg × 10 pts/kg
      expect(after.balance, before.balance + 20);
      expect(
        container.read(appStoreProvider).ledgerFor('ben-1').first.points,
        20,
      );
    },
  );

  test('redemption deducts points and stock together', () async {
    final store = container.read(appStoreProvider.notifier);
    final before = container.read(appStoreProvider);
    final balance = before.beneficiaryById('ben-1')!.balance;
    final stock = before.rewardById('rew-2')!.stock;

    final error = await store.redeem(
      beneficiaryId: 'ben-1',
      rewardId: 'rew-2',
      qty: 1,
    );

    final after = container.read(appStoreProvider);
    expect(error, isNull);
    expect(after.beneficiaryById('ben-1')!.balance, balance - 80);
    expect(after.rewardById('rew-2')!.stock, stock - 1);
  });

  test('redemption is rejected without enough points', () async {
    final store = container.read(appStoreProvider.notifier);
    final error = await store.redeem(
      beneficiaryId: 'ben-5',
      rewardId: 'rew-2',
      qty: 1,
    );

    expect(error, isNotNull);
    expect(
      container.read(appStoreProvider).beneficiaryById('ben-5')!.balance,
      0,
    );
  });

  test('disallowed materials stay out of the collector picker', () {
    final state = container.read(appStoreProvider);
    final allowed = state.materials
        .where((m) => m.allowed && m.active)
        .toList();
    expect(allowed.any((m) => m.name.contains('Iron')), isFalse);
    expect(
      allowed.every(
        (m) => m.unit == MaterialUnit.kg || m.unit == MaterialUnit.piece,
      ),
      isTrue,
    );
  });
}
