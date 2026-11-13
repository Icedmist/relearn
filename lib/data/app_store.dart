import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import 'models.dart';
import 'supabase_repository.dart';

/// Single in-memory snapshot consumed by every screen. In demo mode it is
/// seeded locally; in live mode it is loaded from Supabase through
/// [SupabaseRepository] and refreshed after every write.
class AppState {
  const AppState({
    required this.schools,
    required this.beneficiaries,
    required this.materials,
    required this.rewards,
    required this.ledger,
    required this.collections,
    required this.redemptions,
    this.users = const [],
    this.profile,
    this.loading = false,
    this.error,
  });

  final List<School> schools;
  final List<Beneficiary> beneficiaries;
  final List<MaterialItem> materials;
  final List<Reward> rewards;
  final List<LedgerEntry> ledger;
  final List<CollectionRecord> collections;
  final List<RedemptionRecord> redemptions;
  final List<StaffUser> users;
  final StaffUser? profile;
  final bool loading;
  final String? error;

  static const empty = AppState(
    schools: [],
    beneficiaries: [],
    materials: [],
    rewards: [],
    ledger: [],
    collections: [],
    redemptions: [],
  );

  bool get isLive => !AppConfig.demoMode;

  AppState copyWith({
    List<School>? schools,
    List<Beneficiary>? beneficiaries,
    List<MaterialItem>? materials,
    List<Reward>? rewards,
    List<LedgerEntry>? ledger,
    List<CollectionRecord>? collections,
    List<RedemptionRecord>? redemptions,
    List<StaffUser>? users,
    StaffUser? profile,
    bool? loading,
    String? error,
    bool clearError = false,
  }) => AppState(
    schools: schools ?? this.schools,
    beneficiaries: beneficiaries ?? this.beneficiaries,
    materials: materials ?? this.materials,
    rewards: rewards ?? this.rewards,
    ledger: ledger ?? this.ledger,
    collections: collections ?? this.collections,
    redemptions: redemptions ?? this.redemptions,
    users: users ?? this.users,
    profile: profile ?? this.profile,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
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

  static AppState seed() {
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
        category: 'Stationery',
        description: 'HB pencil for everyday classwork.',
        pointsCost: 20,
        stock: 240,
        active: true,
      ),
      Reward(
        id: 'rew-2',
        name: 'Exercise book',
        category: 'Books',
        description: '80-page ruled exercise book.',
        pointsCost: 80,
        stock: 96,
        active: true,
      ),
      Reward(
        id: 'rew-3',
        name: 'School backpack',
        category: 'Bags',
        description: 'Durable backpack with padded straps.',
        pointsCost: 400,
        stock: 6,
        active: true,
      ),
      Reward(
        id: 'rew-4',
        name: 'Eraser',
        category: 'Stationery',
        description: 'Soft eraser that does not tear the page.',
        pointsCost: 15,
        stock: 300,
        active: true,
      ),
      Reward(
        id: 'rew-5',
        name: 'Pencil sharpener',
        category: 'Stationery',
        description: 'Compact sharpener with a shatter-proof blade.',
        pointsCost: 15,
        stock: 300,
        active: true,
      ),
      Reward(
        id: 'rew-6',
        name: '30 cm ruler',
        category: 'Maths',
        description: 'Clear 30 cm ruler with metric markings.',
        pointsCost: 25,
        stock: 200,
        active: true,
      ),
      Reward(
        id: 'rew-7',
        name: 'Blue ballpoint pen',
        category: 'Stationery',
        description: 'Smooth-writing blue ballpoint pen.',
        pointsCost: 30,
        stock: 300,
        active: true,
      ),
      Reward(
        id: 'rew-8',
        name: 'HB pencil (pack of 3)',
        category: 'Stationery',
        description: 'Three HB pencils for a full term.',
        pointsCost: 50,
        stock: 200,
        active: true,
      ),
      Reward(
        id: 'rew-9',
        name: 'Drawing book',
        category: 'Art',
        description: 'A4 drawing book with 40 blank pages.',
        pointsCost: 90,
        stock: 80,
        active: true,
      ),
      Reward(
        id: 'rew-10',
        name: 'Crayons (8 colours)',
        category: 'Art',
        description: 'Eight bright, non-toxic wax crayons.',
        pointsCost: 110,
        stock: 80,
        active: true,
      ),
      Reward(
        id: 'rew-11',
        name: 'Coloured pencils (12)',
        category: 'Art',
        description: 'Twelve coloured pencils in a keepsake tin.',
        pointsCost: 120,
        stock: 80,
        active: true,
      ),
      Reward(
        id: 'rew-12',
        name: 'Geometry set',
        category: 'Maths',
        description: 'Compass, protractor, set squares and ruler.',
        pointsCost: 180,
        stock: 40,
        active: true,
      ),
      Reward(
        id: 'rew-13',
        name: 'Lunch box',
        category: 'Lunch',
        description: 'Insulated lunch box with a secure lid.',
        pointsCost: 220,
        stock: 20,
        active: true,
      ),
      Reward(
        id: 'rew-14',
        name: 'Water bottle',
        category: 'Lunch',
        description: '500 ml leak-proof school water bottle.',
        pointsCost: 250,
        stock: 30,
        active: true,
      ),
      Reward(
        id: 'rew-15',
        name: 'Atlas',
        category: 'Books',
        description: 'Illustrated world atlas for social studies.',
        pointsCost: 300,
        stock: 10,
        active: true,
      ),
      Reward(
        id: 'rew-16',
        name: 'Exercise book (pack of 5)',
        category: 'Books',
        description: 'Five ruled exercise books for the term.',
        pointsCost: 350,
        stock: 40,
        active: true,
      ),
      Reward(
        id: 'rew-17',
        name: 'Oxford school dictionary',
        category: 'Books',
        description: 'Oxford school dictionary for class and homework.',
        pointsCost: 350,
        stock: 20,
        active: true,
      ),
      Reward(
        id: 'rew-18',
        name: 'Scientific calculator',
        category: 'Maths',
        description: 'Scientific calculator for maths and science.',
        pointsCost: 500,
        stock: 15,
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

    return AppState(
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

class AppStore extends Notifier<AppState> {
  @override
  AppState build() {
    if (AppConfig.demoMode) return AppState.seed();
    // Kick off the first remote load without blocking the first frame.
    Future<void>(() => reload());
    return AppState.empty.copyWith(loading: true);
  }

  SupabaseRepository? get _repo =>
      AppConfig.demoMode ? null : SupabaseRepository.instance;

  Future<void> reload({bool showLoading = true}) async {
    final repo = _repo;
    if (repo == null) return;
    state = state.copyWith(loading: showLoading, clearError: showLoading);
    try {
      final data = await repo.loadAll();
      state = AppState(
        schools: data.schools,
        beneficiaries: data.beneficiaries,
        materials: data.materials,
        rewards: data.rewards,
        ledger: data.ledger,
        collections: data.collections,
        redemptions: data.redemptions,
        users: data.users,
        profile: data.profile,
      );
    } catch (error) {
      _fail(error);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _fail(Object error) {
    debugPrint('ReLearn data error: $error');
    state = state.copyWith(loading: false, error: _message(error));
  }

  String _message(Object error) => switch (error) {
    PostgrestException(:final message) => message,
    AuthException(:final message) => message,
    _ => '$error',
  };

  Future<void> _write(Future<dynamic> action) async {
    try {
      await action;
      await reload(showLoading: false);
    } catch (error) {
      _fail(error);
      await reload(showLoading: false);
    }
  }

  void addSchool({required String name, required String address}) {
    final repo = _repo;
    if (repo == null) {
      final school = School(
        id: 'sch-${state.schools.length + 1}',
        name: name,
        address: address,
        active: true,
      );
      state = state.copyWith(schools: [...state.schools, school]);
      return;
    }
    _write(repo.addSchool(name: name, address: address));
  }

  void toggleSchool(String id) {
    final school = state.schoolById(id);
    if (school == null) return;
    state = state.copyWith(
      schools: [
        for (final s in state.schools)
          if (s.id == id) s.copyWith(active: !s.active) else s,
      ],
    );
    final repo = _repo;
    if (repo != null) _write(repo.setSchoolActive(id, !school.active));
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
    final repo = _repo;
    if (repo != null) {
      _write(repo.renameSchool(id, name: name, address: address));
    }
  }

  Future<Beneficiary?> addBeneficiary({
    required String name,
    required BeneficiaryType type,
    required String schoolId,
    required String className,
    String? guardianPhone,
  }) async {
    final repo = _repo;
    if (repo != null) {
      try {
        final beneficiary = await repo.addBeneficiary(
          name: name,
          type: type,
          schoolId: schoolId,
          className: className,
          guardianPhone: guardianPhone,
        );
        state = state.copyWith(
          beneficiaries: [...state.beneficiaries, beneficiary],
        );
        return beneficiary;
      } catch (error) {
        _fail(error);
        return null;
      }
    }

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
    final repo = _repo;
    if (repo != null) _write(repo.setCardBlocked(id, blocked));
  }

  /// Returns null on success, or a human-readable error message.
  Future<String?> createStaffUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String? schoolId,
  }) async {
    final repo = _repo;
    if (repo == null) {
      final school = schoolId == null ? null : state.schoolById(schoolId);
      state = state.copyWith(
        users: [
          ...state.users,
          StaffUser(
            id: 'usr-${state.users.length + 1}',
            name: name,
            email: email,
            role: role,
            active: true,
            schoolId: schoolId,
            schoolName: school?.name,
          ),
        ],
      );
      return null;
    }
    try {
      await repo.createStaffUser(
        name: name,
        email: email,
        password: password,
        role: role,
        schoolId: schoolId,
      );
      await reload(showLoading: false);
      return null;
    } catch (error) {
      _fail(error);
      return _message(error);
    }
  }

  void setStaffActive(String id, bool active) {
    state = state.copyWith(
      users: [
        for (final u in state.users)
          if (u.id == id)
            StaffUser(
              id: u.id,
              name: u.name,
              email: u.email,
              role: u.role,
              active: active,
              schoolId: u.schoolId,
              schoolName: u.schoolName,
              lastActive: u.lastActive,
            )
          else
            u,
      ],
    );
    final repo = _repo;
    if (repo != null) _write(repo.setStaffActive(id, active));
  }

  /// Links the signed-in staff member to their school for the first time.
  /// Returns null on success or a human-readable error message.
  Future<String?> setMySchool(String schoolId) async {
    final repo = _repo;
    if (repo == null) {
      final school = state.schoolById(schoolId);
      if (state.profile != null) {
        state = state.copyWith(
          profile: StaffUser(
            id: state.profile!.id,
            name: state.profile!.name,
            email: state.profile!.email,
            role: state.profile!.role,
            active: state.profile!.active,
            schoolId: schoolId,
            schoolName: school?.name,
            lastActive: state.profile!.lastActive,
          ),
        );
      }
      return null;
    }
    try {
      await repo.updateMySchool(schoolId);
      await reload(showLoading: false);
      return null;
    } catch (error) {
      _fail(error);
      return _message(error);
    }
  }

  void addMaterial({
    required String name,
    required MaterialUnit unit,
    required double pointsPerUnit,
  }) {
    final repo = _repo;
    if (repo == null) {
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
      return;
    }
    _write(
      repo.addMaterial(name: name, unit: unit, pointsPerUnit: pointsPerUnit),
    );
  }

  Future<String?> addReward({
    required String name,
    required int pointsCost,
    required int stock,
    String category = 'Other',
    String? description,
    String? imageUrl,
  }) async {
    final repo = _repo;
    if (repo == null) {
      state = state.copyWith(
        rewards: [
          ...state.rewards,
          Reward(
            id: 'rew-${state.rewards.length + 1}',
            name: name,
            pointsCost: pointsCost,
            stock: stock,
            active: true,
            category: category,
            description: description,
            imageUrl: imageUrl,
          ),
        ],
      );
      return null;
    }
    try {
      await repo.addReward(
        name: name,
        pointsCost: pointsCost,
        stock: stock,
        category: category,
        description: description,
        imageUrl: imageUrl,
      );
      await reload(showLoading: false);
      return null;
    } catch (error) {
      _fail(error);
      return _message(error);
    }
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
    final repo = _repo;
    if (repo != null) {
      _write(
        repo.updateMaterial(
          id,
          pointsPerUnit: pointsPerUnit,
          allowed: allowed,
          active: active,
        ),
      );
    }
  }

  Future<String?> updateReward(
    String id, {
    String? name,
    int? pointsCost,
    int? stock,
    bool? active,
    String? category,
    String? description,
    String? imageUrl,
    bool clearImage = false,
    bool clearDescription = false,
  }) async {
    state = state.copyWith(
      rewards: [
        for (final r in state.rewards)
          if (r.id == id)
            Reward(
              id: r.id,
              name: name ?? r.name,
              pointsCost: pointsCost ?? r.pointsCost,
              stock: stock ?? r.stock,
              active: active ?? r.active,
              category: category ?? r.category,
              description: clearDescription
                  ? null
                  : (description ?? r.description),
              imageUrl: clearImage ? null : (imageUrl ?? r.imageUrl),
            )
          else
            r,
      ],
    );
    final repo = _repo;
    if (repo == null) return null;
    try {
      await repo.updateReward(
        id,
        name: name,
        pointsCost: pointsCost,
        stock: stock,
        active: active,
        category: category,
        description: description,
        imageUrl: imageUrl,
        clearImage: clearImage,
        clearDescription: clearDescription,
      );
      await reload(showLoading: false);
      return null;
    } catch (error) {
      _fail(error);
      await reload(showLoading: false);
      return _message(error);
    }
  }

  Future<String?> deleteReward(String id) async {
    final repo = _repo;
    if (repo == null) {
      state = state.copyWith(
        rewards: [
          for (final reward in state.rewards)
            if (reward.id != id) reward,
        ],
      );
      return null;
    }
    try {
      await repo.deleteReward(id);
      await reload(showLoading: false);
      return null;
    } catch (error) {
      if (error is PostgrestException && error.code == '23503') {
        return 'This item has past redemptions. Deactivate it instead.';
      }
      _fail(error);
      return _message(error);
    }
  }

  Future<String?> restock(String id, int qty) async {
    final repo = _repo;
    if (repo == null) {
      final reward = state.rewardById(id);
      if (reward == null) return 'Item not found.';
      state = state.copyWith(
        rewards: [
          for (final item in state.rewards)
            if (item.id == id) item.copyWith(stock: item.stock + qty) else item,
        ],
      );
      return null;
    }
    try {
      await repo.restock(id, qty);
      await reload(showLoading: false);
      return null;
    } catch (error) {
      _fail(error);
      return _message(error);
    }
  }

  /// Uploads a product photo and returns its public URL.
  Future<({String? url, String? error})> uploadItemImage({
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final repo = _repo;
    if (repo == null) {
      return (
        url: null,
        error: 'Photo upload is available when Supabase is connected.',
      );
    }
    try {
      final url = await repo.uploadItemImage(
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
      return (url: url, error: null);
    } catch (error) {
      _fail(error);
      return (url: null, error: _message(error));
    }
  }

  Future<String?> updateProfileName(String name) async {
    final repo = _repo;
    if (repo == null) {
      return 'Name changes are available when Supabase is connected.';
    }
    try {
      await repo.updateProfileName(name);
      await reload(showLoading: false);
      return null;
    } catch (error) {
      _fail(error);
      return _message(error);
    }
  }

  /// Credits a collection and returns the points, or null when the server
  /// rejected the write.
  Future<int?> recordCollection({
    required String beneficiaryId,
    required List<({MaterialItem material, double quantity})> lines,
    String? note,
  }) async {
    final repo = _repo;
    if (repo != null) {
      try {
        final points = await repo.recordCollection(
          beneficiaryId: beneficiaryId,
          lines: lines,
          note: note,
        );
        await reload(showLoading: false);
        return points;
      } catch (error) {
        _fail(error);
        return null;
      }
    }

    final beneficiary = state.beneficiaryById(beneficiaryId);
    if (beneficiary == null) return null;

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
      collectorName: state.profile?.name ?? 'Staff',
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
  Future<String?> redeem({
    required String beneficiaryId,
    required String rewardId,
    required int qty,
  }) async {
    final repo = _repo;
    if (repo != null) {
      final error = await repo.redeem(
        beneficiaryId: beneficiaryId,
        rewardId: rewardId,
        qty: qty,
      );
      if (error == null) await reload(showLoading: false);
      return error;
    }

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
      collectorName: state.profile?.name ?? 'Staff',
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
    final repo = _repo;
    if (repo != null) _write(repo.adjustPoints(beneficiaryId, points, reason));
  }
}

final appStoreProvider = NotifierProvider<AppStore, AppState>(AppStore.new);
