import 'package:dormease/helper/ui_elements.dart';
import 'package:dormease/models/tenant.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TenantCheckoutScreen extends StatefulWidget {
  final Tenant tenant;
  
  const TenantCheckoutScreen({super.key, required this.tenant});

  @override
  State<TenantCheckoutScreen> createState() => _TenantCheckoutScreenState();
}

class _TenantCheckoutScreenState extends State<TenantCheckoutScreen> {
  DateTime selectedLeavingDate = DateTime.now();
  final partialRentController = TextEditingController();
  final dailyRateController = TextEditingController();
  var partialRentValid = true;
  var dailyRateValid = true;
  var isLoading = false;
  
  int fullMonths = 0;
  int partialDays = 0;
  double totalRent = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateRent();
  }

  void _calculateRent() {
    final joiningDate = widget.tenant.joinedDate;
    final leavingDate = selectedLeavingDate;
    
    // Calculate full rent cycles (same date to same date next month)
    int months = 0;
    DateTime currentRentDate = DateTime(joiningDate.year, joiningDate.month, joiningDate.day);
    
    while (true) {
      final nextRentDate = DateTime(currentRentDate.year, currentRentDate.month + 1, currentRentDate.day);
      if (nextRentDate.isBefore(leavingDate) || nextRentDate.isAtSameMomentAs(leavingDate)) {
        months++;
        currentRentDate = nextRentDate;
      } else {
        break;
      }
    }
    
    // Calculate remaining partial days after last full month
    final lastFullRentDate = DateTime(currentRentDate.year, currentRentDate.month, currentRentDate.day);
    final remainingDays = leavingDate.difference(lastFullRentDate).inDays;
    
    setState(() {
      fullMonths = months;
      partialDays = remainingDays > 0 ? remainingDays : 0;
      
      double partialAmount = 0;
      if (partialDays > 0 && dailyRateController.text.isNotEmpty) {
        partialAmount = partialDays * double.parse(dailyRateController.text);
      }
      
      totalRent = (fullMonths * widget.tenant.monthlyRent) + partialAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      appBar: AppBar(
        title: Text("Checkout - ${widget.tenant.name}"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            bottom: 80,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTenantInfoCard(),
                  const SizedBox(height: 16),
                  _buildLeavingDateCard(),
                  const SizedBox(height: 16),
                  _buildRentCalculationCard(),
                  if (partialDays > 0) ...[
                    const SizedBox(height: 16),
                    _buildPartialRentCard(),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ExpandedButton(
              label: "Complete Checkout",
              onPressed: _completeCheckout,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantInfoCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tenant Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Name: ${widget.tenant.name}"),
            Text("Room: ${widget.tenant.roomNumber}"),
            Text("Joined: ${widget.tenant.joinedDate.day}/${widget.tenant.joinedDate.month}/${widget.tenant.joinedDate.year}"),
            Text("Monthly Rent: ₹${widget.tenant.monthlyRent.toStringAsFixed(0)}"),
            Text("Deposit: ₹${widget.tenant.securityDeposit.toStringAsFixed(0)}"),
          ],
        ),
      ),
    );
  }

  Widget _buildLeavingDateCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Leaving Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Select Leaving Date"),
              subtitle: Text("${selectedLeavingDate.day}/${selectedLeavingDate.month}/${selectedLeavingDate.year}"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedLeavingDate,
                  firstDate: widget.tenant.joinedDate,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    selectedLeavingDate = date;
                  });
                  _calculateRent();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentCalculationCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Rent Calculation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Full Months: $fullMonths"),
                Text("₹${(fullMonths * widget.tenant.monthlyRent).toStringAsFixed(0)}"),
              ],
            ),
            if (partialDays > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Partial Days: $partialDays"),
                  Text("₹${partialDays > 0 && dailyRateController.text.isNotEmpty ? (partialDays * double.parse(dailyRateController.text)).toStringAsFixed(0) : '0'}"),
                ],
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Rent:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("₹${totalRent.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartialRentCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Partial Month Rent ($partialDays days)", 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 12),
            const Text("Enter daily rate for partial days:", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            InputText(
              controller: dailyRateController,
              keyboard: TextInputType.number,
              hint: "Daily rate (₹ per day)",
              icon: Icons.monetization_on,
              min: 1,
              max: 10,
              valid: dailyRateValid,
              error: "Please enter daily rate",
              updateValid: (bool isValid) {
                setState(() {
                  dailyRateValid = isValid;
                });
                _calculateRent();
              },
            ),
            const SizedBox(height: 8),
            if (dailyRateController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "$partialDays days × ₹${dailyRateController.text} = ₹${(partialDays * (double.tryParse(dailyRateController.text) ?? 0)).toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _completeCheckout() async {
    if (partialDays > 0 && dailyRateController.text.isEmpty) {
      setState(() {
        dailyRateValid = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    // Remove tenant from the system
    context.read<DataProvider>().deleteTenant(widget.tenant.id);

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${widget.tenant.name} checkout completed. Total rent: ₹${totalRent.toStringAsFixed(0)}"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
    Navigator.pop(context);
  }
}