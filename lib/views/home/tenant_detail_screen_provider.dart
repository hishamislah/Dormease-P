import 'package:dormease/models/tenant.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/services/payment_service.dart' as payment_service;
import 'package:dormease/views/home/edit_tenant_screen.dart';
import 'package:dormease/views/home/tenant_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TenantDetailScreenProvider extends StatelessWidget {
  final Tenant tenant;
  
  const TenantDetailScreenProvider({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      appBar: AppBar(
        title: Text(tenant.name),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTenantScreen(tenant: tenant),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TenantCheckoutScreen(tenant: tenant),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          // Get the latest tenant data
          final latestTenant = dataProvider.tenants.firstWhere(
            (t) => t.id == tenant.id,
            orElse: () => tenant,
          );
          
          // Generate payment history with latest data
          final paymentHistory = payment_service.PaymentService.generatePaymentHistory(latestTenant);
          
          // Get current month payment
          DateTime now = DateTime.now();
          payment_service.PaymentRecord? currentMonthPayment;
          try {
            currentMonthPayment = paymentHistory.firstWhere(
              (p) => p.monthYear.year == now.year && p.monthYear.month == now.month,
            );
          } catch (e) {
            currentMonthPayment = null;
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileCard(latestTenant),
                const SizedBox(height: 16),
                _buildRentStatusCard(context, currentMonthPayment),
                const SizedBox(height: 16),
                _buildPaymentHistoryCard(context, paymentHistory),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(Tenant tenant) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(tenant.imagePath),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text("Room ${tenant.roomNumber}"),
                      Text(tenant.phone),
                      Text(tenant.email),
                      if (tenant.emergencyContact.isNotEmpty)
                        Text("Emergency: ${tenant.emergencyContact}"),
                      if (tenant.description.isNotEmpty)
                        Text(tenant.description, style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem("Monthly Rent", "₹${tenant.monthlyRent.toStringAsFixed(0)}"),
                _buildInfoItem("Security Deposit", "₹${tenant.securityDeposit.toStringAsFixed(0)}"),
                _buildInfoItem("Joined", "${tenant.joinedDate.day}/${tenant.joinedDate.month}/${tenant.joinedDate.year}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentStatusCard(BuildContext context, payment_service.PaymentRecord? currentMonthPayment) {
    if (currentMonthPayment == null) {
      return const SizedBox.shrink();
    }
    
    Color alertColor = currentMonthPayment.status == payment_service.PaymentStatus.overdue ? Colors.red : Colors.orange;
    Color bgColor = currentMonthPayment.status == payment_service.PaymentStatus.paid 
        ? Colors.green.withOpacity(0.1)
        : alertColor.withOpacity(0.1);
    
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Current Rent Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    currentMonthPayment.status == payment_service.PaymentStatus.paid 
                        ? Icons.check_circle
                        : Icons.warning,
                    color: currentMonthPayment.status == payment_service.PaymentStatus.paid 
                        ? Colors.green 
                        : alertColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${currentMonthPayment.monthYearString} - ₹${currentMonthPayment.amount.toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Due: ${DateFormat('d/M/yyyy').format(currentMonthPayment.dueDate)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (currentMonthPayment.status != payment_service.PaymentStatus.paid)
                    ElevatedButton(
                      onPressed: () => _markPaymentAsPaid(context, currentMonthPayment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mark Paid'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryCard(BuildContext context, List<payment_service.PaymentRecord> paymentHistory) {
    if (paymentHistory.isEmpty) {
      return Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Payment History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.history, color: Colors.grey),
                    SizedBox(width: 12),
                    Text("No payment history available", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    List<payment_service.PaymentRecord> sortedPayments = List.from(paymentHistory);
    sortedPayments.sort((a, b) => b.monthYear.compareTo(a.monthYear));
    
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Payment History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${sortedPayments.length} payments", style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedPayments.map((payment) => _buildPaymentItem(context, payment)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentItem(BuildContext context, payment_service.PaymentRecord payment) {
    IconData statusIcon;
    Color statusColor;
    String statusText;
    
    switch (payment.status) {
      case payment_service.PaymentStatus.paid:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = 'Paid';
        break;
      case payment_service.PaymentStatus.pending:
        statusIcon = Icons.schedule;
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case payment_service.PaymentStatus.overdue:
        statusIcon = Icons.error;
        statusColor = Colors.red;
        statusText = 'Overdue';
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.monthYearString,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (payment.paidDate != null)
                  Text(
                    '${DateFormat('d/M/yyyy').format(payment.paidDate!)} • ${payment.paymentMethod}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  )
                else
                  Text(
                    'Due: ${DateFormat('d/M/yyyy').format(payment.dueDate)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${payment.amount.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (payment.status != payment_service.PaymentStatus.paid)
            IconButton(
              icon: const Icon(Icons.payment, color: Colors.blue),
              onPressed: () => _markPaymentAsPaid(context, payment),
            ),
        ],
      ),
    );
  }

  void _markPaymentAsPaid(BuildContext context, payment_service.PaymentRecord payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Payment as Paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${payment.monthYearString}\n₹${payment.amount.toInt()}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: 'Cash',
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: ['Cash', 'Bank Transfer', 'UPI', 'Cheque', 'Card']
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Mark payment as paid - Provider will automatically update UI
              await context.read<DataProvider>().markRentPaid(tenant.id, payment.monthYearString);
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${payment.monthYearString} rent marked as paid')),
              );
            },
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}