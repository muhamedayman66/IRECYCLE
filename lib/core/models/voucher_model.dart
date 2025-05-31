class VoucherModel {
  final String id;
  final String code;
  final double value;
  final DateTime expiryDate;
  final bool isUsed;
  final String? usedBy;
  final DateTime? usedAt;

  VoucherModel({
    required this.id,
    required this.code,
    required this.value,
    required this.expiryDate,
    required this.isUsed,
    this.usedBy,
    this.usedAt,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'],
      code: json['code'],
      value: json['value'].toDouble(),
      expiryDate: DateTime.parse(json['expiryDate']),
      isUsed: json['isUsed'],
      usedBy: json['usedBy'],
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'value': value,
      'expiryDate': expiryDate.toIso8601String(),
      'isUsed': isUsed,
      'usedBy': usedBy,
      'usedAt': usedAt?.toIso8601String(),
    };
  }
}
