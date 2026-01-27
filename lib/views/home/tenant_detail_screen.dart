import 'package:dormease/models/tenant.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/providers/user_provider.dart';
import 'package:dormease/services/payment_service.dart' as payment_service;
import 'package:dormease/views/home/edit_tenant_screen.dart';
import 'package:dormease/views/home/tenant_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TenantDetailScreen extends StatefulWidget {
  final Tenant tenant;
  
  const TenantDetailScreen({super.key, required this.tenant});
  
  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  List<payment_service.PaymentRecord> paymentHistory = [];
  payment_service.PaymentRecord? currentMonthPayment;
  
  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }
  
  void _loadPaymentData() {
    final dataProvider = context.read<DataProvider>();
    final latestTenant = dataProvider.tenants.firstWhere(
      (t) => t.id == widget.tenant.id,
      orElse: () => widget.tenant,
    );
    
    paymentHistory = payment_service.PaymentService.generatePaymentHistory(latestTenant);
    
    DateTime now = DateTime.now();
    try {
      currentMonthPayment = paymentHistory.firstWhere(
        (p) => p.monthYear.year == now.year && p.monthYear.month == now.month,
      );
    } catch (e) {
      currentMonthPayment = null;
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final tenant = dataProvider.tenants.firstWhere(
          (t) => t.id == widget.tenant.id,
          orElse: () => widget.tenant,
        );
        
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
                  ).then((_) {
                    if (mounted) {
                      _loadPaymentData();
                    }
                  });
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileCard(tenant),
                const SizedBox(height: 16),
                _buildRentStatusCard(context),
                const SizedBox(height: 16),
                _buildPaymentHistoryCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $launchUri');
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
    }
  }

  Future<void> _sendRentReminder(BuildContext context) async {
    // Get business details from UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.userData;
    final businessName = userData['businessName'] ?? userData['business_name'] ?? 'Hostel';
    final upiPhone = userData['phone'] ?? '';
    
    // Get current tenant data
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final tenant = dataProvider.tenants.firstWhere(
      (t) => t.id == widget.tenant.id,
      orElse: () => widget.tenant,
    );
    
    final message =
        "Hello ${tenant.name},\n\nThis is a friendly reminder that your rent is Due.\n\nAmount: ₹${tenant.monthlyRent.toStringAsFixed(0)}\nDue Date: ${tenant.nextRentDueDate.day}/${tenant.nextRentDueDate.month}/${tenant.nextRentDueDate.year}\n\nPlease make the payment at your earliest\nUpi $upiPhone\n\nThank you!\n$businessName";

    final phoneNumber = tenant.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final whatsappUrl =
        "https://wa.me/91$phoneNumber?text=${Uri.encodeComponent(message)}";

    final Uri uri = Uri.parse(whatsappUrl);
    try {
      await launchUrl(uri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not open WhatsApp. Please check if it's installed."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                      GestureDetector(
                        onTap: () => _makePhoneCall(tenant.phone),
                        child: Text(
                          tenant.phone,
                          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                        ),
                      ),
                      if (tenant.emergencyContact.isNotEmpty)
                        GestureDetector(
                          onTap: () => _makePhoneCall(tenant.emergencyContact),
                          child: Text(
                            "Emergency: ${tenant.emergencyContact}",
                            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          ),
                        ),
                      if (tenant.description.isNotEmpty)
                        Text(tenant.description, style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    InkWell(
                      onTap: () => _sendRentReminder(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF25D366)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.chat, size: 14, color: Color(0xFF25D366)),
                            SizedBox(width: 4),
                            Text("Remind", style: TextStyle(fontSize: 11, color: Color(0xFF25D366), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildRentStatusCard(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (currentMonthPayment == null) {
          return const SizedBox.shrink();
        }
        
        Color alertColor = currentMonthPayment!.status == payment_service.PaymentStatus.overdue ? Colors.red : Colors.orange;
        Color bgColor = currentMonthPayment!.status == payment_service.PaymentStatus.paid 
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
                        currentMonthPayment!.status == payment_service.PaymentStatus.paid 
                            ? Icons.check_circle
                            : Icons.warning,
                        color: currentMonthPayment!.status == payment_service.PaymentStatus.paid 
                            ? Colors.green 
                            : alertColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${currentMonthPayment!.monthYearString} - ₹${currentMonthPayment!.amount.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Due: ${DateFormat('d/M/yyyy').format(currentMonthPayment!.dueDate)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (currentMonthPayment!.status != payment_service.PaymentStatus.paid)
                        ElevatedButton(
                          onPressed: () => _markPaymentAsPaid(currentMonthPayment!),
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
      },
    );
  }

  Widget _buildPaymentHistoryCard(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
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
                ...sortedPayments.map((payment) => _buildPaymentItem(payment)),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPaymentItem(payment_service.PaymentRecord payment) {
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
              onPressed: () => _markPaymentAsPaid(payment),
              tooltip: 'Mark as Paid',
            )
          else
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.orange),
              onPressed: () => _markPaymentAsUnpaid(payment),
              tooltip: 'Revert Payment',
            ),
        ],
      ),
    );
  }

  void _markPaymentAsUnpaid(payment_service.PaymentRecord payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revert Payment'),
        content: Text(
          'Are you sure you want to mark ${payment.monthYearString} as unpaid?\n\nThis will remove the payment record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                
                await context.read<DataProvider>().markRentUnpaid(widget.tenant.id, payment.monthYearString);
                
                Navigator.pop(context); // Close loading
                Navigator.pop(context); // Close dialog
                
                // Reload payment data
                _loadPaymentData();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${payment.monthYearString} payment reverted'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                Navigator.of(context, rootNavigator: true).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error reverting payment: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revert'),
          ),
        ],
      ),
    );
  }

  void _markPaymentAsPaid(payment_service.PaymentRecord payment) {
    String selectedMethod = 'Cash';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Mark Payment as Paid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${payment.monthYearString}\n₹${payment.amount.toInt()}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: ['Cash', 'Bank Transfer', 'UPI', 'Cheque', 'Card']
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ))
                    .toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedMethod = value!;
                  });
                },
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
                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );
                  
                  await context.read<DataProvider>().markRentPaid(widget.tenant.id, payment.monthYearString, selectedMethod);
                  
                  Navigator.pop(context); // Close loading
                  Navigator.pop(context); // Close dialog
                  
                  setState(() {
                    for (int i = 0; i < paymentHistory.length; i++) {
                      if (paymentHistory[i].monthYearString == payment.monthYearString) {
                        paymentHistory[i] = payment_service.PaymentRecord(
                          id: paymentHistory[i].id,
                          tenantId: paymentHistory[i].tenantId,
                          monthYear: paymentHistory[i].monthYear,
                          dueDate: paymentHistory[i].dueDate,
                          amount: paymentHistory[i].amount,
                          status: payment_service.PaymentStatus.paid,
                          paidDate: DateTime.now(),
                          paymentMethod: selectedMethod,
                        );
                        break;
                      }
                    }
                    
                    if (currentMonthPayment?.monthYearString == payment.monthYearString) {
                      currentMonthPayment = payment_service.PaymentRecord(
                        id: currentMonthPayment!.id,
                        tenantId: currentMonthPayment!.tenantId,
                        monthYear: currentMonthPayment!.monthYear,
                        dueDate: currentMonthPayment!.dueDate,
                        amount: currentMonthPayment!.amount,
                        status: payment_service.PaymentStatus.paid,
                        paidDate: DateTime.now(),
                        paymentMethod: selectedMethod,
                      );
                    }
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${payment.monthYearString} rent marked as paid and saved'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving payment: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Mark Paid'),
            ),
          ],
        ),
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