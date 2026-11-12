import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

/// Snapshot loaded from Supabase. Kept deliberately small: the pilot data set
/// fits comfortably in memory and every screen can then render synchronously.
class RemoteData {
  const RemoteData({
    required this.schools,
    required this.beneficiaries,
    required this.materials,
    required this.rewards,
    required this.ledger,
    required this.collections,
    required this.redemptions,
    required this.users,
    this.profile,
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
}

/// Thin Supabase data-access layer. Screens never talk to Supabase directly;
/// they go through AppStore, which owns this repository.
class SupabaseRepository {
  SupabaseRepository(this._client);

  static final SupabaseRepository instance = SupabaseRepository(
    Supabase.instance.client,
  );

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<RemoteData> loadAll() async {
    final responses = await Future.wait<dynamic>([
      _client.from('schools').select().order('name'),
      _client.from('beneficiaries').select().order('full_name'),
      _client.from('beneficiary_balances').select(),
      _client.from('materials').select().order('name'),
      _client.from('rewards').select().order('points_cost'),
      _client
          .from('points_ledger')
          .select()
          .order('created_at', ascending: false)
          .limit(1000),
      _client
          .from('collections')
          .select(
            'id, beneficiary_id, collector_id, created_at, voided, note, '
            'profiles(name), '
            'collection_items(quantity, points, materials(name, unit))',
          )
          .order('created_at', ascending: false)
          .limit(500),
      _client
          .from('redemptions')
          .select(
            'id, beneficiary_id, collector_id, qty, points_spent, created_at, '
            'voided, rewards(name), profiles(name)',
          )
          .order('created_at', ascending: false)
          .limit(500),
      _client.from('staff_directory').select().order('name'),
    ]);

    final schools = _rows(responses[0]).map(_school).toList();
    final balances = <String, int>{
      for (final row in _rows(responses[2]))
        row['beneficiary_id'] as String: (row['balance'] as num).toInt(),
    };
    final beneficiaries = _rows(responses[1])
        .map((row) => _beneficiary(row, balances))
        .toList();
    final materials = _rows(responses[3]).map(_material).toList();
    final rewards = _rows(responses[4]).map(_reward).toList();
    final ledger = _rows(responses[5]).map(_ledger).toList();
    final collections = _rows(responses[6]).map(_collection).toList();
    final redemptions = _rows(responses[7]).map(_redemption).toList();
    final users = _rows(responses[8]).map(_staff).toList();

    final current = _client.auth.currentUser;
    final profile = users.where((u) => u.id == current?.id).firstOrNull;

    return RemoteData(
      schools: schools,
      beneficiaries: beneficiaries,
      materials: materials,
      rewards: rewards,
      ledger: ledger,
      collections: collections,
      redemptions: redemptions,
      users: users,
      profile: profile,
    );
  }

  Future<School> addSchool({
    required String name,
    required String address,
  }) async {
    final row = await _client
        .from('schools')
        .insert({'name': name, 'address': address})
        .select()
        .single();
    return _school(row);
  }

  Future<void> setSchoolActive(String id, bool active) async {
    await _client.from('schools').update({'active': active}).eq('id', id);
  }

  Future<void> setStaffActive(String id, bool active) async {
    await _client.from('profiles').update({'active': active}).eq('id', id);
  }

  Future<void> renameSchool(
    String id, {
    required String name,
    required String address,
  }) async {
    await _client
        .from('schools')
        .update({'name': name, 'address': address})
        .eq('id', id);
  }

  Future<Beneficiary> addBeneficiary({
    required String name,
    required BeneficiaryType type,
    required String schoolId,
    required String className,
    String? guardianPhone,
  }) async {
    final row = await _client
        .from('beneficiaries')
        .insert({
          'full_name': name,
          'type': type.name,
          'school_id': schoolId,
          'class': className,
          'guardian_phone': guardianPhone,
        })
        .select()
        .single();
    return _beneficiary(row, const {});
  }

  Future<void> setCardBlocked(String id, bool blocked) async {
    await _client
        .from('beneficiaries')
        .update({'card_blocked': blocked})
        .eq('id', id);
  }

  Future<MaterialItem> addMaterial({
    required String name,
    required MaterialUnit unit,
    required double pointsPerUnit,
    String? imageUrl,
  }) async {
    final row = await _client
        .from('materials')
        .insert({
          'name': name,
          'unit': unit.name,
          'points_per_unit': pointsPerUnit,
          'image_url': ?imageUrl,
        })
        .select()
        .single();
    return _material(row);
  }

  Future<void> updateMaterial(
    String id, {
    double? pointsPerUnit,
    bool? allowed,
    bool? active,
    String? imageUrl,
  }) async {
    await _client
        .from('materials')
        .update({
          'points_per_unit': ?pointsPerUnit,
          'allowed': ?allowed,
          'active': ?active,
          'image_url': ?imageUrl,
        })
        .eq('id', id);
  }

  Future<Reward> addReward({
    required String name,
    required int pointsCost,
    required int stock,
    String category = 'Other',
    String? description,
    String? imageUrl,
  }) async {
    final row = await _client
        .from('rewards')
        .insert({
          'name': name,
          'points_cost': pointsCost,
          'stock': stock,
          'category': category,
          'description': ?description,
          'image_url': ?imageUrl,
        })
        .select()
        .single();
    return _reward(row);
  }

  Future<void> updateReward(
    String id, {
    String? name,
    int? pointsCost,
    int? stock,
    bool? active,
    String? category,
    String? description,
    String? imageUrl,
  }) async {
    await _client
        .from('rewards')
        .update({
          'name': ?name,
          'points_cost': ?pointsCost,
          'stock': ?stock,
          'active': ?active,
          'category': ?category,
          'description': ?description,
          'image_url': ?imageUrl,
        })
        .eq('id', id);
  }

  Future<int> restock(String id, int qty) async {
    final result = await _client.rpc(
      'restock_reward',
      params: {'p_reward_id': id, 'p_qty': qty},
    );
    return ((result as Map)['stock'] as num).toInt();
  }

  Future<int> recordCollection({
    required String beneficiaryId,
    required List<({MaterialItem material, double quantity})> lines,
    String? note,
  }) async {
    final result = await _client.rpc(
      'record_collection',
      params: {
        'p_beneficiary_id': beneficiaryId,
        'p_items': [
          for (final line in lines)
            {'material_id': line.material.id, 'quantity': line.quantity},
        ],
        'p_idempotency_key': _uuid.v4(),
        'p_note': note,
      },
    );
    return ((result as Map)['points'] as num).toInt();
  }

  /// Returns null on success or a human-readable error message.
  Future<String?> redeem({
    required String beneficiaryId,
    required String rewardId,
    required int qty,
  }) async {
    try {
      await _client.rpc(
        'redeem_reward',
        params: {
          'p_beneficiary_id': beneficiaryId,
          'p_reward_id': rewardId,
          'p_qty': qty,
          'p_idempotency_key': _uuid.v4(),
        },
      );
      return null;
    } on PostgrestException catch (error) {
      return _friendly(error.message);
    } catch (error) {
      return '$error';
    }
  }

  Future<void> adjustPoints(
    String beneficiaryId,
    int points,
    String reason,
  ) async {
    await _client.rpc(
      'adjust_points',
      params: {
        'p_beneficiary_id': beneficiaryId,
        'p_points': points,
        'p_reason': reason,
      },
    );
  }

  /// Creates a staff account through Supabase Auth, then assigns its role.
  /// Sign-up runs with the publishable key, so the admin's session is restored
  /// immediately afterwards and the caller stays signed in.
  Future<String> createStaffUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final auth = _client.auth;
    final adminRefresh = auth.currentSession?.refreshToken;
    AuthResponse response;
    try {
      response = await auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
    } finally {
      if (adminRefresh != null) {
        await auth.setSession(adminRefresh);
      }
    }

    final user = response.user;
    if (user == null) {
      throw AuthException('The account was not created.');
    }

    await _client
        .from('profiles')
        .update({'name': name, 'role': role})
        .eq('id', user.id);
    return user.id;
  }

  /// Uploads an item photo to the public `item-images` bucket and returns its
  /// public URL. Storage RLS allows only admins to write.
  Future<String> uploadItemImage({
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
    final path = '${DateTime.now().millisecondsSinceEpoch}-$safe';
    await _client.storage
        .from('item-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            cacheControl: '3600',
          ),
        );
    return _client.storage.from('item-images').getPublicUrl(path);
  }

  Future<StaffUser?> currentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client
        .from('profiles')
        .select('name, role, active')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return null;
    return StaffUser(
      id: user.id,
      name: (row['name'] as String?)?.trim().isNotEmpty == true
          ? row['name'] as String
          : user.email ?? 'Staff',
      email: user.email ?? '',
      role: row['role'] as String? ?? 'collector',
      active: row['active'] as bool? ?? true,
    );
  }

  static String _friendly(String message) {
    const known = {
      'insufficient points': 'Not enough points for this reward.',
      'insufficient stock': 'That reward is out of stock.',
      'card is blocked': 'This card is blocked.',
      'beneficiary is inactive': 'This beneficiary is inactive.',
    };
    final key = known.keys.firstWhere(
      (k) => message.toLowerCase().contains(k),
      orElse: () => '',
    );
    return key.isEmpty ? message : known[key]!;
  }

  static List<Map<String, dynamic>> _rows(dynamic value) =>
      (value as List).cast<Map<String, dynamic>>();

  static School _school(Map<String, dynamic> row) => School(
    id: row['id'] as String,
    name: row['name'] as String? ?? '',
    address: row['address'] as String? ?? '',
    active: row['active'] as bool? ?? true,
  );

  static Beneficiary _beneficiary(
    Map<String, dynamic> row,
    Map<String, int> balances,
  ) {
    final id = row['id'] as String;
    return Beneficiary(
      id: id,
      publicId: row['public_id'] as String? ?? '',
      schoolId: row['school_id'] as String,
      name: row['full_name'] as String? ?? '',
      type: row['type'] == 'teacher'
          ? BeneficiaryType.teacher
          : BeneficiaryType.pupil,
      className: row['class'] as String? ?? '',
      balance: balances[id] ?? 0,
      guardianPhone: row['guardian_phone'] as String?,
      cardBlocked: row['card_blocked'] as bool? ?? false,
      active: row['active'] as bool? ?? true,
    );
  }

  static MaterialItem _material(Map<String, dynamic> row) => MaterialItem(
    id: row['id'] as String,
    name: row['name'] as String? ?? '',
    unit: row['unit'] == 'piece' ? MaterialUnit.piece : MaterialUnit.kg,
    pointsPerUnit: (row['points_per_unit'] as num?)?.toDouble() ?? 0,
    allowed: row['allowed'] as bool? ?? true,
    active: row['active'] as bool? ?? true,
    imageUrl: row['image_url'] as String?,
  );

  static Reward _reward(Map<String, dynamic> row) => Reward(
    id: row['id'] as String,
    name: row['name'] as String? ?? '',
    pointsCost: (row['points_cost'] as num?)?.toInt() ?? 0,
    stock: (row['stock'] as num?)?.toInt() ?? 0,
    active: row['active'] as bool? ?? true,
    category: row['category'] as String? ?? 'Other',
    description: row['description'] as String?,
    imageUrl: row['image_url'] as String?,
  );

  static LedgerEntry _ledger(Map<String, dynamic> row) => LedgerEntry(
    id: '${row['id']}',
    beneficiaryId: row['beneficiary_id'] as String,
    type: switch (row['type']) {
      'redeem' => LedgerType.redeem,
      'adjust' => LedgerType.adjust,
      'void' => LedgerType.reversal,
      _ => LedgerType.earn,
    },
    points: (row['points'] as num?)?.toInt() ?? 0,
    at: DateTime.parse(row['created_at'] as String).toLocal(),
    note: row['note'] as String?,
  );

  static CollectionRecord _collection(Map<String, dynamic> row) {
    var points = 0;
    var kg = 0.0;
    final parts = <String>[];
    final items = (row['collection_items'] as List?) ?? const [];
    for (final item in items.cast<Map<String, dynamic>>()) {
      final material = item['materials'] as Map<String, dynamic>?;
      final unit = material?['unit'] as String? ?? 'kg';
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
      points += (item['points'] as num?)?.toInt() ?? 0;
      if (unit == 'kg') kg += quantity;
      final label = unit == 'kg'
          ? '${_trim(quantity)} kg'
          : '${quantity.toInt()} pcs';
      parts.add('${material?['name'] ?? 'Material'} · $label');
    }
    final collector = row['profiles'] as Map<String, dynamic>?;
    return CollectionRecord(
      id: row['id'] as String,
      beneficiaryId: row['beneficiary_id'] as String,
      collectorName: collector?['name'] as String? ?? 'Staff',
      summary: parts.join(' + '),
      kg: kg,
      points: points,
      at: DateTime.parse(row['created_at'] as String).toLocal(),
      voided: row['voided'] as bool? ?? false,
    );
  }

  static RedemptionRecord _redemption(Map<String, dynamic> row) {
    final collector = row['profiles'] as Map<String, dynamic>?;
    final reward = row['rewards'] as Map<String, dynamic>?;
    return RedemptionRecord(
      id: row['id'] as String,
      beneficiaryId: row['beneficiary_id'] as String,
      collectorName: collector?['name'] as String? ?? 'Staff',
      rewardName: reward?['name'] as String? ?? 'Reward',
      qty: (row['qty'] as num?)?.toInt() ?? 0,
      points: (row['points_spent'] as num?)?.toInt() ?? 0,
      at: DateTime.parse(row['created_at'] as String).toLocal(),
      voided: row['voided'] as bool? ?? false,
    );
  }

  static StaffUser _staff(Map<String, dynamic> row) => StaffUser(
    id: row['id'] as String,
    name: row['name'] as String? ?? '',
    email: row['email'] as String? ?? '',
    role: row['role'] as String? ?? 'collector',
    active: row['active'] as bool? ?? true,
    lastActive: row['last_sign_in_at'] == null
        ? null
        : DateTime.tryParse(row['last_sign_in_at'] as String)?.toLocal(),
  );

  static String _trim(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
