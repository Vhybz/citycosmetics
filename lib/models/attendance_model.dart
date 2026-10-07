import 'package:intl/intl.dart';

class AttendanceRecord {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String? branchCode;
  final DateTime date;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double? checkInLat;
  final double? checkInLon;
  final double distanceMeters;
  final String status; // 'on_time', 'late', 'checked_out', 'auto_checked_out'
  final bool isVerifiedLocation;
  final String? notes;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.branchCode,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    this.checkInLat,
    this.checkInLon,
    required this.distanceMeters,
    required this.status,
    required this.isVerifiedLocation,
    this.notes,
  });

  bool get isCheckedOut => checkOutTime != null || status == 'checked_out' || status == 'auto_checked_out';
  bool get isCheckedIn => !isCheckedOut;

  Duration get durationWorked {
    final end = checkOutTime ?? DateTime.now();
    return end.difference(checkInTime);
  }

  String get formattedHoursWorked {
    final dur = durationWorked;
    final hours = dur.inHours;
    final mins = dur.inMinutes.remainder(60);
    return '${hours}h ${mins}m';
  }

  String get statusDisplay {
    switch (status) {
      case 'on_time': return 'ON TIME';
      case 'late': return 'LATE';
      case 'checked_out': return 'CHECKED OUT';
      case 'auto_checked_out': return 'AUTO CHECKED OUT';
      default: return status.toUpperCase();
    }
  }

  AttendanceRecord copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userRole,
    String? branchCode,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? checkInLat,
    double? checkInLon,
    double? distanceMeters,
    String? status,
    bool? isVerifiedLocation,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      branchCode: branchCode ?? this.branchCode,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLat: checkInLat ?? this.checkInLat,
      checkInLon: checkInLon ?? this.checkInLon,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      status: status ?? this.status,
      isVerifiedLocation: isVerifiedLocation ?? this.isVerifiedLocation,
      notes: notes ?? this.notes,
    );
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['date'] != null) {
      final dateStr = json['date'].toString();
      if (dateStr.contains('T')) {
        parsedDate = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
      } else {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          parsedDate = DateTime(
            int.tryParse(parts[0]) ?? DateTime.now().year,
            int.tryParse(parts[1]) ?? DateTime.now().month,
            int.tryParse(parts[2]) ?? DateTime.now().day,
          );
        } else {
          parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
        }
      }
    } else {
      parsedDate = DateTime.now();
    }

    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Staff Member',
      userRole: json['user_role']?.toString() ?? 'Staff',
      branchCode: json['branch_code']?.toString(),
      date: parsedDate,
      checkInTime: json['check_in_time'] != null
          ? (DateTime.tryParse(json['check_in_time'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      checkOutTime: json['check_out_time'] != null
          ? DateTime.tryParse(json['check_out_time'].toString())?.toLocal()
          : null,
      checkInLat: (json['check_in_lat'] as num?)?.toDouble(),
      checkInLon: (json['check_in_lon'] as num?)?.toDouble(),
      distanceMeters: (json['distance_meters'] as num? ?? 0.0).toDouble(),
      status: json['status']?.toString() ?? 'on_time',
      isVerifiedLocation: json['is_verified_location'] ?? true,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'branch_code': branchCode,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'check_in_lat': checkInLat,
      'check_in_lon': checkInLon,
      'distance_meters': distanceMeters,
      'status': status,
      'is_verified_location': isVerifiedLocation,
      'notes': notes,
    };
  }
}
