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
    // Calculate rent due date as 1 day before the joining day each month
    // For example, if joined on 24th Nov, rent is due on 23rd of every month
    
    final now = DateTime.now();
    final dueDayOfMonth = joinedDate.day - 1;
    
    // Calculate the next occurrence of the due day
    DateTime dueDate;
    
    // Try current month first
    dueDate = DateTime(now.year, now.month, dueDayOfMonth);
    
    // If the due date has passed this month, move to next month
    if (dueDate.isBefore(now) || dueDate.day == now.day && dueDate.month == now.month && dueDate.year == now.year) {
      // Move to next month
      if (now.month == 12) {
        dueDate = DateTime(now.year + 1, 1, dueDayOfMonth);
      } else {
        dueDate = DateTime(now.year, now.month + 1, dueDayOfMonth);
      }
    }
    
    return dueDate;
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