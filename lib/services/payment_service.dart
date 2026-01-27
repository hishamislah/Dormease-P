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
  bool get isOverdue =>
      DateTime.now().isAfter(dueDate) && status != PaymentStatus.paid;
}

class PaymentService {
  static List<PaymentRecord> generatePaymentHistory(Tenant tenant) {
    List<PaymentRecord> payments = [];
    DateTime joiningDate = tenant.joinedDate;
    DateTime currentDate = DateTime.now();

    // Calculate the due day (1 day before joining day)
    int dueDayOfMonth = joiningDate.day - 1;
    if (dueDayOfMonth == 0) dueDayOfMonth = 28;

    // If tenant joined after the due date of the month, start from next month
    DateTime startMonth;
    if (joiningDate.day > dueDayOfMonth) {
      // Joined after rent due date, start from next month
      startMonth =
          _getNextMonth(DateTime(joiningDate.year, joiningDate.month, 1));
    } else {
      // Joined before or on rent due date, include current month
      startMonth = DateTime(joiningDate.year, joiningDate.month, 1);
    }

    DateTime currentMonth = DateTime(currentDate.year, currentDate.month, 1);
    DateTime paymentMonth = startMonth;

    while (paymentMonth.isBefore(currentMonth) ||
        paymentMonth.isAtSameMomentAs(currentMonth)) {
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
    // Calculate due date as 1 day before the joining day
    // For example, if joined on 24th, rent is due on 23rd of each month
    int dueDayOfMonth = tenant.joinedDate.day - 1;

    // Handle edge case where joining date is 1st (due would be 0th/last day of previous month)
    if (dueDayOfMonth == 0) {
      dueDayOfMonth = 28; // Default to 28th for safety
    }

    DateTime dueDate = DateTime(month.year, month.month, dueDayOfMonth);
    String monthName = DateFormat('MMMM yyyy').format(month);

    // Check if payment exists for this month and get the paid amount
    final existingPayment = tenant.paymentHistory
        .where((p) =>
            p.month.toLowerCase().trim() == monthName.toLowerCase() &&
            p.status.toLowerCase() == 'paid')
        .firstOrNull;

    PaymentStatus status = _determinePaymentStatus(tenant, month, dueDate);

    // For paid months, use the actual paid amount from payment history
    // For overdue/pending, use current monthly rent
    double amount = existingPayment?.amount ?? tenant.monthlyRent;
    DateTime? paidDate = existingPayment != null ? existingPayment.date : null;

    return PaymentRecord(
      id: '${tenant.id}_${month.year}_${month.month.toString().padLeft(2, '0')}',
      tenantId: tenant.id,
      monthYear: month,
      dueDate: dueDate,
      amount: amount,
      status: status,
      paidDate: paidDate,
    );
  }

  static PaymentStatus _determinePaymentStatus(
      Tenant tenant, DateTime month, DateTime dueDate) {
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
