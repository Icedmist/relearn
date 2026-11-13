import 'package:intl/intl.dart';

enum BeneficiaryType { pupil, teacher }

extension BeneficiaryTypeX on BeneficiaryType {
  String get label => this == BeneficiaryType.pupil ? 'Pupil' : 'Teacher';
}

enum MaterialUnit { kg, piece }

extension MaterialUnitX on MaterialUnit {
  String get label => this == MaterialUnit.kg ? 'kg' : 'piece';
  String get shortLabel => this == MaterialUnit.kg ? 'kg' : 'pc';
}

enum LedgerType { earn, redeem, adjust, reversal }

extension LedgerTypeX on LedgerType {
  String get label => switch (this) {
    LedgerType.earn => 'Earned',
    LedgerType.redeem => 'Redeemed',
    LedgerType.adjust => 'Adjustment',
    LedgerType.reversal => 'Void',
  };
}

class School {
  const School({
    required this.id,
    required this.name,
    required this.address,
    required this.active,
  });

  final String id;
  final String name;
  final String address;
  final bool active;

  School copyWith({String? name, String? address, bool? active}) => School(
    id: id,
    name: name ?? this.name,
    address: address ?? this.address,
    active: active ?? this.active,
  );
}

class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.publicId,
    required this.schoolId,
    required this.name,
    required this.type,
    required this.className,
    required this.balance,
    this.guardianPhone,
    this.cardBlocked = false,
    this.active = true,
  });

  final String id;
  final String publicId;
  final String schoolId;
  final String name;
  final BeneficiaryType type;
  final String className;
  final int balance;
  final String? guardianPhone;
  final bool cardBlocked;
  final bool active;

  Beneficiary copyWith({
    String? name,
    String? className,
    int? balance,
    String? guardianPhone,
    bool? cardBlocked,
    bool? active,
  }) => Beneficiary(
    id: id,
    publicId: publicId,
    schoolId: schoolId,
    name: name ?? this.name,
    type: type,
    className: className ?? this.className,
    balance: balance ?? this.balance,
    guardianPhone: guardianPhone ?? this.guardianPhone,
    cardBlocked: cardBlocked ?? this.cardBlocked,
    active: active ?? this.active,
  );

  String initials() {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.pointsPerUnit,
    required this.allowed,
    required this.active,
    this.imageUrl,
  });

  final String id;
  final String name;
  final MaterialUnit unit;
  final double pointsPerUnit;
  final bool allowed;
  final bool active;
  final String? imageUrl;

  MaterialItem copyWith({
    double? pointsPerUnit,
    bool? allowed,
    bool? active,
    String? imageUrl,
  }) => MaterialItem(
    id: id,
    name: name,
    unit: unit,
    pointsPerUnit: pointsPerUnit ?? this.pointsPerUnit,
    allowed: allowed ?? this.allowed,
    active: active ?? this.active,
    imageUrl: imageUrl ?? this.imageUrl,
  );
}

class Reward {
  const Reward({
    required this.id,
    required this.name,
    required this.pointsCost,
    required this.stock,
    required this.active,
    this.category = 'Other',
    this.description,
    this.imageUrl,
  });

  final String id;
  final String name;
  final int pointsCost;
  final int stock;
  final bool active;
  final String category;
  final String? description;
  final String? imageUrl;

  Reward copyWith({
    String? name,
    int? pointsCost,
    int? stock,
    bool? active,
    String? category,
    String? description,
    String? imageUrl,
  }) => Reward(
    id: id,
    name: name ?? this.name,
    pointsCost: pointsCost ?? this.pointsCost,
    stock: stock ?? this.stock,
    active: active ?? this.active,
    category: category ?? this.category,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
  );
}

class StaffUser {
  const StaffUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.schoolId,
    this.schoolName,
    this.lastActive,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool active;
  final String? schoolId;
  final String? schoolName;
  final DateTime? lastActive;

  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isCollector => role == 'collector';
  String get roleLabel => switch (role) {
    'admin' => 'Admin',
    'teacher' => 'Teacher',
    _ => 'Collector',
  };
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.beneficiaryId,
    required this.type,
    required this.points,
    required this.at,
    this.note,
  });

  final String id;
  final String beneficiaryId;
  final LedgerType type;
  final int points;
  final DateTime at;
  final String? note;
}

class CollectionRecord {
  const CollectionRecord({
    required this.id,
    required this.beneficiaryId,
    required this.collectorName,
    required this.summary,
    required this.kg,
    required this.points,
    required this.at,
    this.voided = false,
  });

  final String id;
  final String beneficiaryId;
  final String collectorName;
  final String summary;
  final double kg;
  final int points;
  final DateTime at;
  final bool voided;
}

class RedemptionRecord {
  const RedemptionRecord({
    required this.id,
    required this.beneficiaryId,
    required this.collectorName,
    required this.rewardName,
    required this.qty,
    required this.points,
    required this.at,
    this.voided = false,
  });

  final String id;
  final String beneficiaryId;
  final String collectorName;
  final String rewardName;
  final int qty;
  final int points;
  final DateTime at;
  final bool voided;
}

final _pointsFormat = NumberFormat.decimalPattern();

String formatPoints(num points) => _pointsFormat.format(points);

String formatDateShort(DateTime date) =>
    DateFormat('d MMM, HH:mm').format(date);

String formatDateRange(DateTime date) =>
    DateFormat('EEE, d MMM yyyy').format(date);
