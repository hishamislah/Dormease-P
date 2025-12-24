class Tenant {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String emergencyContact;
  final String description;
  final String roomNumber;
  final DateTime joinedDate;
  final double monthlyRent;
  final double securityDeposit;
  final bool underNotice;
  final bool rentDue;
  final String imagePath;
  final DateTime? rentDueDate;
  final DateTime? leavingDate;
  final double? partialRent;
  final List<PaymentRecord> paymentHistory;

  Tenant({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.emergencyContact = '',
    this.description = '',
    required this.roomNumber,
    required this.joinedDate,
    required this.monthlyRent,
    required this.securityDeposit,
    this.underNotice = false,
    this.rentDue = false,
    this.imagePath = 'assets/images/dp.png',
    this.rentDueDate,
    this.leavingDate,
    this.partialRent,
    this.paymentHistory = const [],
  });

  DateTime get nextRentDueDate {
    // Calculate rent due date as 1 day before the month completes
    // For example, if joined on May 29, 2025, rent is due on June 28, 2025
    
    // Get the next month's same day
    DateTime nextMonth;
    if (joinedDate.month == 12) {
      nextMonth = DateTime(joinedDate.year + 1, 1, joinedDate.day);
    } else {
      nextMonth = DateTime(joinedDate.year, joinedDate.month + 1, joinedDate.day);
    }
    
    // Subtract 1 day to get the day before
    return nextMonth.subtract(const Duration(days: 1));
  }

  String get rentPeriodDescription {
    final dueDate = nextRentDueDate;
    return "Joined: ${joinedDate.day}/${joinedDate.month}/${joinedDate.year}\nRent Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}";
  }
}

class PaymentRecord {
  final String id;
  final DateTime date;
  final double amount;
  final String status; // 'Paid', 'Pending', 'Overdue'
  final String month;
  final String paymentMethod;

  PaymentRecord({
    required this.id,
    required this.date,
    required this.amount,
    required this.status,
    required this.month,
    this.paymentMethod = 'Cash',
  });
}