import 'package:dormease/models/tenant.dart';
import 'package:intl/intl.dart';

enum PaymentStatus { paid, pending, overdue }

class PaymentRecord {
  final String id;
  final String tenantId;
  final DateTime monthYear;
  final DateTime dueDate;
  final DateTime? paidDate;
  final double amount;
  final PaymentStatus status;
  final String paymentMethod;
  
  PaymentRecord({
    required this.id,
    required this.tenantId,
    required this.monthYear,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidDate,
    this.paymentMethod = 'Cash',
  });
  
  String get monthYearString => DateFormat('MMMM yyyy').format(monthYear);
  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != PaymentStatus.paid;
}

class PaymentService {
  static List<PaymentRecord> generatePaymentHistory(Tenant tenant) {
    List<PaymentRecord> payments = [];
    DateTime joiningDate = tenant.joinedDate;
    DateTime currentDate = DateTime.now();
    
    // If tenant joined after 7th of the month, start from next month
    DateTime startMonth;
    if (joiningDate.day > 7) {
      // Joined after rent due date, start from next month
      startMonth = _getNextMonth(DateTime(joiningDate.year, joiningDate.month, 1));
    } else {
      // Joined before or on rent due date, include current month
      startMonth = DateTime(joiningDate.year, joiningDate.month, 1);
    }
    
    DateTime currentMonth = DateTime(currentDate.year, currentDate.month, 1);
    DateTime paymentMonth = startMonth;
    
    while (paymentMonth.isBefore(currentMonth) || paymentMonth.isAtSameMomentAs(currentMonth)) {
      PaymentRecord payment = _createPaymentForMonth(tenant, paymentMonth);
      payments.add(payment);
      paymentMonth = _getNextMonth(paymentMonth);
    }
    
    return payments;
  }
  

  
  // Helper: Get next month
  static DateTime _getNextMonth(DateTime currentMonth) {
    if (currentMonth.month == 12) {
      return DateTime(currentMonth.year + 1, 1, 1);
    } else {
      return DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }
  }
  
  static PaymentRecord _createPaymentForMonth(Tenant tenant, DateTime month) {
    DateTime dueDate = DateTime(month.year, month.month, 7);
    PaymentStatus status = _determinePaymentStatus(tenant, month, dueDate);
    
    return PaymentRecord(
      id: '${tenant.id}_${month.year}_${month.month.toString().padLeft(2, '0')}',
      tenantId: tenant.id,
      monthYear: month,
      dueDate: dueDate,
      amount: tenant.monthlyRent,
      status: status,
      paidDate: status == PaymentStatus.paid ? dueDate : null,
    );
  }
  
  static PaymentStatus _determinePaymentStatus(Tenant tenant, DateTime month, DateTime dueDate) {
    DateTime now = DateTime.now();
    DateTime currentMonth = DateTime(now.year, now.month, 1);
    String monthName = DateFormat('MMMM yyyy').format(month);
    
    // Check if payment exists for this exact month
    bool hasPaymentRecord = tenant.paymentHistory.any((p) {
      return p.month.toLowerCase().trim() == monthName.toLowerCase() && 
             p.status.toLowerCase() == 'paid';
    });
    
    if (hasPaymentRecord) {
      return PaymentStatus.paid;
    }
    
    // For past months (before current month)
    if (month.isBefore(currentMonth)) {
      return PaymentStatus.overdue;
    }
    
    // For current month
    if (month.isAtSameMomentAs(currentMonth)) {
      if (now.isAfter(dueDate)) {
        return PaymentStatus.overdue;
      } else {
        return PaymentStatus.pending;
      }
    }
    
    return PaymentStatus.pending;
  }
}