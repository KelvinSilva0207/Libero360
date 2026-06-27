enum MedicalLeaveStatus { active, finished, cancelled }

class MedicalLeave {
  int id = 0;
  int playerId;
  String reason;
  DateTime startDate;
  DateTime? endDate;
  String notes;
  DateTime createdAt;
  String createdBy;
  MedicalLeaveStatus status;

  MedicalLeave({
    required this.playerId,
    required this.reason,
    required this.startDate,
    this.endDate,
    this.notes = '',
    DateTime? createdAt,
    this.createdBy = '',
    this.status = MedicalLeaveStatus.active,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive => status == MedicalLeaveStatus.active;

  bool get isExpiringSoon {
    if (!isActive || endDate == null) return false;
    return endDate!.difference(DateTime.now()).inDays <= 3;
  }
}
