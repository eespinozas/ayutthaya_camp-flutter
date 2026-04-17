import 'package:equatable/equatable.dart';

/// Booking Status Enum
enum BookingStatus {
  confirmed, // Reserva confirmada
  attended, // Usuario asistió
  cancelled, // Usuario canceló
  noShow, // No asistió
}

/// Domain Entity for Booking
/// Pure business logic object with no dependencies on Firebase or external frameworks
class BookingEntity extends Equatable {
  final String? id;
  final String userId;
  final String userName;
  final String userEmail;
  final String scheduleId;
  final String scheduleTime;
  final String scheduleType;
  final String instructor;
  final DateTime classDate;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime? attendedAt;
  final String? attendedBy;
  final DateTime? attendanceConfirmedAt;
  final bool userConfirmedAttendance;

  const BookingEntity({
    this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.scheduleId,
    required this.scheduleTime,
    required this.scheduleType,
    required this.instructor,
    required this.classDate,
    this.status = BookingStatus.confirmed,
    required this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.attendedAt,
    this.attendedBy,
    this.attendanceConfirmedAt,
    this.userConfirmedAttendance = false,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userEmail,
        scheduleId,
        scheduleTime,
        scheduleType,
        instructor,
        classDate,
        status,
        createdAt,
        updatedAt,
        cancelledAt,
        cancellationReason,
        attendedAt,
        attendedBy,
        attendanceConfirmedAt,
        userConfirmedAttendance,
      ];

  /// Business Logic: Check if booking is for today
  bool get isToday {
    final now = DateTime.now();
    return classDate.year == now.year &&
        classDate.month == now.month &&
        classDate.day == now.day;
  }

  /// Business Logic: Check if booking is in the future
  bool get isFuture {
    final now = DateTime.now();
    return classDate.isAfter(DateTime(now.year, now.month, now.day));
  }

  /// Business Logic: Check if booking is in the past
  bool get isPast {
    final now = DateTime.now();
    return classDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Business Logic: Check if user can confirm attendance
  /// Window: 30 min before until 30 min after class start time
  bool get canConfirmAttendance {
    if (status != BookingStatus.confirmed) return false;
    if (userConfirmedAttendance) return false;

    final now = DateTime.now();
    final classDateTime = _getClassDateTime();

    final windowStart = classDateTime.subtract(const Duration(minutes: 30));
    final windowEnd = classDateTime.add(const Duration(minutes: 30));

    return now.isAfter(windowStart) && now.isBefore(windowEnd);
  }

  /// Business Logic: Check if user missed confirmation window
  bool get missedConfirmationWindow {
    if (status != BookingStatus.confirmed) return false;
    if (userConfirmedAttendance) return false;

    final now = DateTime.now();
    final classDateTime = _getClassDateTime();
    final windowEnd = classDateTime.add(const Duration(minutes: 30));

    return now.isAfter(windowEnd);
  }

  /// Business Logic: Get confirmation status text
  String get confirmationStatusText {
    if (status == BookingStatus.cancelled) return 'Cancelada';
    if (status == BookingStatus.attended) return 'Asistió';
    if (status == BookingStatus.noShow) return 'No asistió';

    if (userConfirmedAttendance) return 'Confirmada';
    if (missedConfirmationWindow) return 'No confirmada';
    if (canConfirmAttendance) return 'Pendiente confirmación';

    return 'Agendada';
  }

  /// Business Logic: Check if booking can be cancelled
  bool get canBeCancelled {
    return status == BookingStatus.confirmed && !isPast;
  }

  /// Helper: Get class DateTime from classDate and scheduleTime
  DateTime _getClassDateTime() {
    final timeParts = scheduleTime.split(':');
    final classHour = int.parse(timeParts[0]);
    final classMinute = int.parse(timeParts[1]);

    return DateTime(
      classDate.year,
      classDate.month,
      classDate.day,
      classHour,
      classMinute,
    );
  }

  /// Copy with
  BookingEntity copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? scheduleId,
    String? scheduleTime,
    String? scheduleType,
    String? instructor,
    DateTime? classDate,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    DateTime? attendedAt,
    String? attendedBy,
    DateTime? attendanceConfirmedAt,
    bool? userConfirmedAttendance,
  }) {
    return BookingEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      scheduleType: scheduleType ?? this.scheduleType,
      instructor: instructor ?? this.instructor,
      classDate: classDate ?? this.classDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      attendedAt: attendedAt ?? this.attendedAt,
      attendedBy: attendedBy ?? this.attendedBy,
      attendanceConfirmedAt:
          attendanceConfirmedAt ?? this.attendanceConfirmedAt,
      userConfirmedAttendance:
          userConfirmedAttendance ?? this.userConfirmedAttendance,
    );
  }
}
