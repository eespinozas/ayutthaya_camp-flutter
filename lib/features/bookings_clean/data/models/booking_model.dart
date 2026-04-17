import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking_entity.dart';

/// Booking Model (Data Layer)
/// Extends BookingEntity and adds serialization capabilities
/// Handles conversion to/from Firebase Firestore
class BookingModel extends BookingEntity {
  const BookingModel({
    super.id,
    required super.userId,
    required super.userName,
    required super.userEmail,
    required super.scheduleId,
    required super.scheduleTime,
    required super.scheduleType,
    required super.instructor,
    required super.classDate,
    super.status,
    required super.createdAt,
    super.updatedAt,
    super.cancelledAt,
    super.cancellationReason,
    super.attendedAt,
    super.attendedBy,
    super.attendanceConfirmedAt,
    super.userConfirmedAttendance,
  });

  /// Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'scheduleId': scheduleId,
      'scheduleTime': scheduleTime,
      'scheduleType': scheduleType,
      'instructor': instructor,
      'classDate': Timestamp.fromDate(classDate),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
      'attendedAt':
          attendedAt != null ? Timestamp.fromDate(attendedAt!) : null,
      'attendedBy': attendedBy,
      'attendanceConfirmedAt': attendanceConfirmedAt != null
          ? Timestamp.fromDate(attendanceConfirmedAt!)
          : null,
      'userConfirmedAttendance': userConfirmedAttendance,
    };
  }

  /// Create from Firestore document
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Read Timestamp and convert to local date
    final firestoreDate = (data['classDate'] as Timestamp).toDate();
    // Create date in local timezone using UTC date components
    final classDate = DateTime(
      firestoreDate.year,
      firestoreDate.month,
      firestoreDate.day,
    );

    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      scheduleId: data['scheduleId'] ?? '',
      scheduleTime: data['scheduleTime'] ?? '',
      scheduleType: data['scheduleType'] ?? '',
      instructor: data['instructor'] ?? '',
      classDate: classDate,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason'],
      attendedAt: data['attendedAt'] != null
          ? (data['attendedAt'] as Timestamp).toDate()
          : null,
      attendedBy: data['attendedBy'],
      attendanceConfirmedAt: data['attendanceConfirmedAt'] != null
          ? (data['attendanceConfirmedAt'] as Timestamp).toDate()
          : null,
      userConfirmedAttendance: data['userConfirmedAttendance'] ?? false,
    );
  }

  /// Create from JSON (for testing or other data sources)
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      scheduleId: json['scheduleId'] ?? '',
      scheduleTime: json['scheduleTime'] ?? '',
      scheduleType: json['scheduleType'] ?? '',
      instructor: json['instructor'] ?? '',
      classDate: DateTime.parse(json['classDate']),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      cancellationReason: json['cancellationReason'],
      attendedAt: json['attendedAt'] != null
          ? DateTime.parse(json['attendedAt'])
          : null,
      attendedBy: json['attendedBy'],
      attendanceConfirmedAt: json['attendanceConfirmedAt'] != null
          ? DateTime.parse(json['attendanceConfirmedAt'])
          : null,
      userConfirmedAttendance: json['userConfirmedAttendance'] ?? false,
    );
  }

  /// Convert from Entity to Model
  factory BookingModel.fromEntity(BookingEntity entity) {
    return BookingModel(
      id: entity.id,
      userId: entity.userId,
      userName: entity.userName,
      userEmail: entity.userEmail,
      scheduleId: entity.scheduleId,
      scheduleTime: entity.scheduleTime,
      scheduleType: entity.scheduleType,
      instructor: entity.instructor,
      classDate: entity.classDate,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      cancelledAt: entity.cancelledAt,
      cancellationReason: entity.cancellationReason,
      attendedAt: entity.attendedAt,
      attendedBy: entity.attendedBy,
      attendanceConfirmedAt: entity.attendanceConfirmedAt,
      userConfirmedAttendance: entity.userConfirmedAttendance,
    );
  }

  /// Convert to Entity
  BookingEntity toEntity() {
    return BookingEntity(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      scheduleId: scheduleId,
      scheduleTime: scheduleTime,
      scheduleType: scheduleType,
      instructor: instructor,
      classDate: classDate,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cancelledAt: cancelledAt,
      cancellationReason: cancellationReason,
      attendedAt: attendedAt,
      attendedBy: attendedBy,
      attendanceConfirmedAt: attendanceConfirmedAt,
      userConfirmedAttendance: userConfirmedAttendance,
    );
  }
}
