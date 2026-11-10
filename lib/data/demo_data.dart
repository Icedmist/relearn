import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

/// Demo state powers the clickable Stage 0 scaffold. Swap this for a Supabase
/// repository in Stage 1 without changing the screens.
class DemoState {
  const DemoState({
    required this.schools,
    required this.beneficiaries,
    required this.materials,
    required this.rewards,
    required this.ledger,
    required this.collections,
    required this.redemptions,
  });

  final List<School> schools;
  final List<Beneficiary> beneficiaries;
  final List<MaterialItem> materials;
  final List<Reward> rewards;
  final List<LedgerEntry> ledger;
  final List<CollectionRecord> collections;
  final List<RedemptionRecord> redemptions;

  DemoState copyWith({
    List<School>? schools,
    List<Beneficiary>? beneficiaries,
    List<MaterialItem>? materials,
    List<Reward>? rewards,
    List<LedgerEntry>? ledger,
    List<CollectionRecord>? collections,
    List<RedemptionRecord>? redemptions,
  }) => DemoState(
    schools: schools ?? this.schools,
    beneficiaries: beneficiaries ?? this.beneficiaries,
    materials: materials ?? this.materials,
    rewards: rewards ?? this.rewards,
    ledger: ledger ?? this.ledger,
    collections: collections ?? this.collections,
    redemptions: redemptions ?? this.redemptions,
  );

  Beneficiary? beneficiaryById(String id) {
    for (final b in beneficiaries) {
      if (b.id == id) return b;
    }
    return null;
  }

  School? schoolById(String id) {
    for (final s in schools) {
      if (s.id == id) return s;
    }
    return null;
  }

  MaterialItem? materialById(String id) {
    for (final m in materials) {
      if (m.id == id) return m;
    }
    return null;
  }

  Reward? rewardById(String id) {
    for (final r in rewards) {
      if (r.id == id) return r;
    }
    return null;
  }

  int get totalBeneficiaries => beneficiaries.where((b) => b.active).length;

  double get totalKg {
    final now = DateTime.now();
    return collections
        .where(
          (c) => !c.voided && c.at.year == now.year && c.at.month == now.month,
        )
        .fold(0, (sum, c) => sum + c.kg);
  }

  int get pointsAwarded => ledger
      .where((l) => l.points > 0 && l.type != LedgerType.reversal)
      .fold(0, (s, l) => s + l.points);

  int get pointsRedeemed => ledger
      .where((l) => l.type == LedgerType.redeem)
      .fold(0, (s, l) => s + l.points.abs());

  int get rewardsDistributed =>
      redemptions.where((r) => !r.voided).fold(0, (s, r) => s + r.qty);

  List<LedgerEntry> ledgerFor(String beneficiaryId) =>
      ledger.where((l) => l.beneficiaryId == beneficiaryId).toList()
        ..sort((a, b) => b.at.compareTo(a.at));

  static DemoState seed() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);

    const schools = [
      School(
        id: 'sch-1',
        name: 'Gombe Model Primary School',
        address: 'Jekadafari, Gombe',
        active: true,
      ),
      School(
        id: 'sch-2',
        name: 'Federal University Staff School',
        address: 'Tudun Wada, Gombe',
        active: true,
      ),
      School(
        id: 'sch-3',
        name: 'Green Valley Academy',
        address: 'New GRA, Gombe',
        active: false,
      ),
    ];

    final beneficiaries = [
      Beneficiary(
        id: 'ben-1',
        publicId: 'RL-0042-7K3Q',
        schoolId: 'sch-1',
        name: 'Amina Yusuf',
        type: BeneficiaryType.pupil,
        className: 'Primary 5',
        balance: 230,
        guardianPhone: '0803 000 1122',
      ),
      Beneficiary(
        id: 'ben-2',
        publicId: 'RL-0043-8M2P',
        schoolId: 'sch-1',
        name: 'Musa Ahmed',
        type: BeneficiaryType.pupil,
        className: 'Primary 4',
        balance: 120,
      ),
      Beneficiary(
        id: 'ben-3',
        publicId: 'RL-0044-9T6R',
        schoolId: 'sch-1',
        name: 'Grace Okoro',
        type: BeneficiaryType.teacher,
        className: 'Staff',
        balance: 480,
      ),
      Beneficiary(
        id: 'ben-4',
        publicId: 'RL-0045-2H8N',
        schoolId: 'sch-2',
        name: 'Fatima Bello',
        type: BeneficiaryType.pupil,
        className: 'JSS 1',
        balance: 60,
      ),
      Beneficiary(
        id: 'ben-5',
        publicId: 'RL-0046-5W4J',
        schoolId: 'sch-2',
        name: 'Daniel Peter',
        type: BeneficiaryType.pupil,
        className: 'JSS 2',
        balance: 0,
      ),
      Beneficiary(
        id: 'ben-6',
        publicId: 'RL-0047-6C9V',
        schoolId: 'sch-2',
        name: 'Hauwa Ibrahim',
        type: BeneficiaryType.pupil,
        className: 'JSS 1',
        balance: 95,
      ),
      Beneficiary(
        id: 'ben-7',
        publicId: 'RL-0048-3B7X',
        schoolId: 'sch-1',
        name: 'Samuel Adamu',
        type: BeneficiaryType.pupil,
        className: 'Primary 6',
        balance: 40,
        cardBlocked: true,
      ),
      Beneficiary(
        id: 'ben-8',
        publicId: 'RL-0049-4F2Y',
        schoolId: 'sch-3',
        name: 'Blessing Eze',
        type: BeneficiaryType.teacher,
        className: 'Staff',
        balance: 300,
      ),
    ];

    const materials = [
      MaterialItem(
        id: 'mat-1',
        name: 'Paper and cardboard',
        unit: MaterialUnit.kg,
        pointsPerUnit: 10,
        allowed: true,
        active: true,
      ),
      MaterialItem(
        id: 'mat-2',
        name: 'Plastic bottles (PET)',
        unit: MaterialUnit.piece,
        pointsPerUnit: 2,
        allowed: true,
        active: true,
      ),
      MaterialItem(
        id: 'mat-3',
        name: 'Aluminium cans',
        unit: MaterialUnit.piece,
        pointsPerUnit: 3,
        allowed: true,
        active: true,
      ),
      MaterialItem(
        id: 'mat-4',
        name: 'Sachet water wrappers',
        unit: MaterialUnit.kg,
        pointsPerUnit: 8,
        allowed: true,
        active: true,
      ),
      MaterialItem(
        id: 'mat-5',
        name: 'Iron / metal scrap',
        unit: MaterialUnit.kg,
        pointsPerUnit: 0,
        allowed: false,
        active: false,
      ),
    ];

    const rewards = [
      Reward(
        id: 'rew-1',
        name: 'Pencil',
        pointsCost: 20,
        stock: 240,
        active: true,
      ),
      Reward(
        id: 'rew-2',
        name: 'Exercise book',
        pointsCost: 80,
        stock: 96,
        active: true,
      ),
      Reward(
        id: 'rew-3',
        name: 'School backpack',
        pointsCost: 400,
        stock: 6,
        active: true,
      ),
    ];

    final ledger = [
      LedgerEntry(
        id: 'led-1',
        beneficiaryId: 'ben-1',
        type: LedgerType.earn,
        points: 150,
        at: ago(const Duration(hours: 2)),
        note: '15 kg paper',
      ),
      LedgerEntry(
        id: 'led-2',
        beneficiaryId: 'ben-1',
        type: LedgerType.redeem,
        points: -80,
        at: ago(const Duration(hours: 1, minutes: 20)),
        note: 'Exercise book',
      ),
      LedgerEntry(
        id: 'led-3',
        beneficiaryId: 'ben-1',
        type: LedgerType.earn,
        points: 160,
        at: ago(const Duration(minutes: 25)),
        note: '8 kg sachet wrappers',
      ),
      LedgerEntry(
        id: 'led-4',
        beneficiaryId: 'ben-2',
        type: LedgerType.earn,
        points: 120,
        at: ago(const Duration(days: 1, hours: 3)),
        note: '60 PET bottles',
      ),
      LedgerEntry(
        id: 'led-5',
        beneficiaryId: 'ben-3',
        type: LedgerType.earn,
        points: 480,
        at: ago(const Duration(days: 1, hours: 1)),
        note: '48 kg paper',
      ),
      LedgerEntry(
        id: 'led-6',
        beneficiaryId: 'ben-4',
        type: LedgerType.earn,
        points: 60,
        at: ago(const Duration(days: 2)),
        note: '30 aluminium cans',
      ),
      LedgerEntry(
        id: 'led-7',
        beneficiaryId: 'ben-6',
        type: LedgerType.earn,
        points: 95,
        at: ago(const Duration(days: 3)),
        note: '9.5 kg paper',
      ),
      LedgerEntry(
        id: 'led-8',
        beneficiaryId: 'ben-8',
        type: LedgerType.earn,
        points: 300,
        at: ago(const Duration(days: 4)),
        note: '30 kg paper',
      ),
    ];

    final collections = [
      CollectionRecord(
        id: 'col-1',
        beneficiaryId: 'ben-1',
        collectorName: 'Abdullahi A.',
        summary: 'Paper and cardboard · 15 kg',
        kg: 15,
        points: 150,
        at: ago(const Duration(hours: 2)),
      ),
      CollectionRecord(
        id: 'col-2',
        beneficiaryId: 'ben-1',
        collectorName: 'Abdullahi A.',
        summary: 'Sachet wrappers · 8 kg',
        kg: 8,
        points: 160,
        at: ago(const Duration(minutes: 25)),
      ),
      CollectionRecord(
        id: 'col-3',
        beneficiaryId: 'ben-2',
        collectorName: 'Ngozi O.',
        summary: 'PET bottles · 60 pcs',
        kg: 0,
        points: 120,
        at: ago(const Duration(days: 1, hours: 3)),
      ),
      CollectionRecord(
        id: 'col-4',
        beneficiaryId: 'ben-3',
        collectorName: 'Abdullahi A.',
        summary: 'Paper and cardboard · 48 kg',
        kg: 48,
        points: 480,
        at: ago(const Duration(days: 1, hours: 1)),
      ),
      CollectionRecord(
        id: 'col-5',
        beneficiaryId: 'ben-4',
        collectorName: 'Ngozi O.',
        summary: 'Aluminium cans · 30 pcs',
        kg: 0,
        points: 60,
        at: ago(const Duration(days: 2)),
      ),
      CollectionRecord(
        id: 'col-6',
        beneficiaryId: 'ben-6',
        collectorName: 'Abdullahi A.',
        summary: 'Paper and cardboard · 9.5 kg',
        kg: 9.5,
        points: 95,
        at: ago(const Duration(days: 3)),
      ),
      CollectionRecord(
        id: 'col-7',
        beneficiaryId: 'ben-8',
        collectorName: 'Ngozi O.',
        summary: 'Paper and cardboard · 30 kg',
        kg: 30,
        points: 300,
        at: ago(const Duration(days: 4)),
      ),
    ];

    final redemptions = [
      RedemptionRecord(
        id: 'red-1',
        beneficiaryId: 'ben-1',
        collectorName: 'Abdullahi A.',
        rewardName: 'Exercise book',
        qty: 1,
        points: 80,
        at: ago(const Duration(hours: 1, minutes: 20)),
      ),
      RedemptionRecord(
        id: 'red-2',
        beneficiaryId: 'ben-3',
        collectorName: 'Ngozi O.',
        rewardName: 'Pencil',
        qty: 3,
        points: 60,
        at: ago(const Duration(days: 1, hours: 2)),
      ),
      RedemptionRecord(
        id: 'red-3',
        beneficiaryId: 'ben-2',
        collectorName: 'Abdullahi A.',
        rewardName: 'Exercise book',
        qty: 1,
        points: 80,
        at: ago(const Duration(days: 2, hours: 4)),
      ),
    ];

    return DemoState(
      schools: schools,
      beneficiaries: beneficiaries,
      materials: materials,
      rewards: rewards,
      ledger: ledger,
      collections: collections,
      redemptions: redemptions,
    );
  }
}

class DemoStore extends Notifier<DemoState> {
  @override
  DemoState build() => DemoState.seed();

  void addSchool({required String name, required String address}) {
    final school = School(
      id: 'sch-${state.schools.length + 1}',
      name: name,
      address: address,
      active: true,
    );
    state = state.copyWith(schools: [...state.schools, school]);
  }

  void toggleSchool(String id) {
    state = state.copyWith(
      schools: [
        for (final s in state.schools)
          if (s.id == id) s.copyWith(active: !s.active) else s,
      ],
    );
  }

  void renameSchool(
    String id, {
    required String name,
    required String address,
  }) {
    state = state.copyWith(
      schools: [
        for (final s in state.schools)
          if (s.id == id) s.copyWith(name: name, address: address) else s,
      ],
    );
  }

  Beneficiary addBeneficiary({
    required String name,
    required BeneficiaryType type,
    required String schoolId,
    required String className,
    String? guardianPhone,
  }) {
    final n = state.beneficiaries.length + 50;
    final suffix = [
      '7K3Q',
      '8M2P',
      '9T6R',
      '2H8N',
      '5W4J',
      '6C9V',
      '3B7X',
      '4F2Y',
    ][n % 8];
    final beneficiary = Beneficiary(
      id: 'ben-${state.beneficiaries.length + 1}',
      publicId: 'RL-${n.toString().padLeft(4, '0')}-$suffix',
      schoolId: schoolId,
      name: name,
      type: type,
      className: className,
      balance: 0,
      guardianPhone: guardianPhone,
    );
    state = state.copyWith(
      beneficiaries: [...state.beneficiaries, beneficiary],
    );
    return beneficiary;
  }

  void setCardBlocked(String id, bool blocked) {
    state = state.copyWith(
      beneficiaries: [
        for (final b in state.beneficiaries)
          if (b.id == id) b.copyWith(cardBlocked: blocked) else b,
      ],
    );
  }

  void addMaterial({
    required String name,
    required MaterialUnit unit,
    required double pointsPerUnit,
  }) {
    state = state.copyWith(
      materials: [
        ...state.materials,
        MaterialItem(
          id: 'mat-${state.materials.length + 1}',
          name: name,
          unit: unit,
          pointsPerUnit: pointsPerUnit,
          allowed: true,
          active: true,
        ),
      ],
    );
  }

  void addReward({
    required String name,
    required int pointsCost,
    required int stock,
  }) {
    state = state.copyWith(
      rewards: [
        ...state.rewards,
        Reward(
          id: 'rew-${state.rewards.length + 1}',
          name: name,
          pointsCost: pointsCost,
          stock: stock,
          active: true,
        ),
      ],
    );
  }

  void updateMaterial(
    String id, {
    double? pointsPerUnit,
    bool? allowed,
    bool? active,
  }) {
    state = state.copyWith(
      materials: [
        for (final m in state.materials)
          if (m.id == id)
            m.copyWith(
              pointsPerUnit: pointsPerUnit,
              allowed: allowed,
              active: active,
            )
          else
            m,
      ],
    );
  }

  void updateReward(String id, {int? pointsCost, int? stock, bool? active}) {
    state = state.copyWith(
      rewards: [
        for (final r in state.rewards)
          if (r.id == id)
            r.copyWith(pointsCost: pointsCost, stock: stock, active: active)
          else
            r,
      ],
    );
  }

  void restock(String id, int qty) {
    final reward = state.rewardById(id);
    if (reward == null) return;
    updateReward(id, stock: reward.stock + qty);
  }

  int recordCollection({
    required String beneficiaryId,
    required List<({MaterialItem material, double quantity})> lines,
    String? note,
  }) {
    final beneficiary = state.beneficiaryById(beneficiaryId);
    if (beneficiary == null) return 0;

    var total = 0;
    final parts = <String>[];
    for (final line in lines) {
      final points = (line.quantity * line.material.pointsPerUnit).round();
      total += points;
      final qty = line.material.unit == MaterialUnit.kg
          ? '${line.quantity.toStringAsFixed(line.quantity % 1 == 0 ? 0 : 2)} kg'
          : '${line.quantity.toInt()} pcs';
      parts.add('${line.material.name} · $qty');
    }

    final now = DateTime.now();
    final id = 'col-${state.collections.length + 1}';
    final collection = CollectionRecord(
      id: id,
      beneficiaryId: beneficiaryId,
      collectorName: 'Abdullahi A.',
      summary: parts.join(' + '),
      kg: lines
          .where((l) => l.material.unit == MaterialUnit.kg)
          .fold(0.0, (s, l) => s + l.quantity),
      points: total,
      at: now,
    );
    final entry = LedgerEntry(
      id: 'led-${state.ledger.length + 1}',
      beneficiaryId: beneficiaryId,
      type: LedgerType.earn,
      points: total,
      at: now,
      note: note == null || note.isEmpty ? collection.summary : note,
    );

    state = state.copyWith(
      beneficiaries: [
        for (final b in state.beneficiaries)
          if (b.id == beneficiaryId)
            b.copyWith(balance: b.balance + total)
          else
            b,
      ],
      collections: [collection, ...state.collections],
      ledger: [entry, ...state.ledger],
    );
    return total;
  }

  /// Returns an error message, or null on success.
  String? redeem({
    required String beneficiaryId,
    required String rewardId,
    required int qty,
  }) {
    final beneficiary = state.beneficiaryById(beneficiaryId);
    final reward = state.rewardById(rewardId);
    if (beneficiary == null) return 'Beneficiary not found.';
    if (reward == null) return 'Reward not found.';
    if (qty < 1) return 'Choose at least one item.';
    if (!reward.active) return '${reward.name} is not available.';
    if (reward.stock < qty) {
      return 'Only ${reward.stock} ${reward.name}(s) left in stock.';
    }
    final cost = reward.pointsCost * qty;
    if (beneficiary.balance < cost) {
      return 'Not enough points. Balance is ${beneficiary.balance} pts.';
    }

    final now = DateTime.now();
    final redemption = RedemptionRecord(
      id: 'red-${state.redemptions.length + 1}',
      beneficiaryId: beneficiaryId,
      collectorName: 'Abdullahi A.',
      rewardName: reward.name,
      qty: qty,
      points: cost,
      at: now,
    );
    final entry = LedgerEntry(
      id: 'led-${state.ledger.length + 1}',
      beneficiaryId: beneficiaryId,
      type: LedgerType.redeem,
      points: -cost,
      at: now,
      note: '${reward.name} × $qty',
    );

    state = state.copyWith(
      beneficiaries: [
        for (final b in state.beneficiaries)
          if (b.id == beneficiaryId)
            b.copyWith(balance: b.balance - cost)
          else
            b,
      ],
      rewards: [
        for (final r in state.rewards)
          if (r.id == rewardId) r.copyWith(stock: r.stock - qty) else r,
      ],
      redemptions: [redemption, ...state.redemptions],
      ledger: [entry, ...state.ledger],
    );
    return null;
  }

  void adjustPoints(String beneficiaryId, int points, String reason) {
    final now = DateTime.now();
    state = state.copyWith(
      beneficiaries: [
        for (final b in state.beneficiaries)
          if (b.id == beneficiaryId)
            b.copyWith(balance: b.balance + points)
          else
            b,
      ],
      ledger: [
        LedgerEntry(
          id: 'led-${state.ledger.length + 1}',
          beneficiaryId: beneficiaryId,
          type: LedgerType.adjust,
          points: points,
          at: now,
          note: reason,
        ),
        ...state.ledger,
      ],
    );
  }
}

final demoStoreProvider = NotifierProvider<DemoStore, DemoState>(DemoStore.new);
