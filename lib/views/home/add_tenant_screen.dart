import 'package:dormease/helper/ui_elements.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/models/tenant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddTenantScreen extends StatefulWidget {
  const AddTenantScreen({super.key});

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final descriptionController = TextEditingController();
  final roomController = TextEditingController();
  final rentController = TextEditingController();
  final depositController = TextEditingController();
  
  var nameValid = true;
  var phoneValid = true;
  var emergencyContactValid = true;
  var descriptionValid = true;
  var roomValid = true;
  var rentValid = true;
  var depositValid = true;
  var isLoading = false;
  
  DateTime selectedJoiningDate = DateTime.now();
  double calculatedRent = 0.0;
  
  void _calculateRent() {
    if (rentController.text.isNotEmpty) {
      final monthlyRent = double.parse(rentController.text);
      calculatedRent = monthlyRent; // Full month rent
      setState(() {});
    }
  }

  String _getMonthName(int month) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month];
  }

  // Calculate rent due date (1 day before next month's same day)
  DateTime _calculateRentDueDate(DateTime joiningDate) {
    // Get the next month's same day
    DateTime nextMonth;
    if (joiningDate.month == 12) {
      nextMonth = DateTime(joiningDate.year + 1, 1, joiningDate.day);
    } else {
      nextMonth = DateTime(joiningDate.year, joiningDate.month + 1, joiningDate.day);
    }
    
    // Subtract 1 day to get the day before
    return nextMonth.subtract(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    // Calculate rent due date for display
    final rentDueDate = _calculateRentDueDate(selectedJoiningDate);
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      appBar: AppBar(
        title: const Text("Add Tenant"),
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
                  const SizedBox(height: 16),
                  InputText(
                    controller: nameController,
                    keyboard: TextInputType.text,
                    hint: "Full Name",
                    icon: Icons.person,
                    min: 2,
                    max: 50,
                    valid: nameValid,
                    error: "Please enter valid name",
                    updateValid: (bool isValid) {
                      setState(() {
                        nameValid = isValid;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputText(
                    controller: phoneController,
                    keyboard: TextInputType.phone,
                    hint: "Phone Number",
                    icon: Icons.phone,
                    min: 10,
                    max: 15,
                    valid: phoneValid,
                    error: "Please enter valid phone number",
                    updateValid: (bool isValid) {
                      setState(() {
                        phoneValid = isValid;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputText(
                    controller: emergencyContactController,
                    keyboard: TextInputType.phone,
                    hint: "Emergency Contact",
                    icon: Icons.emergency,
                    min: 10,
                    max: 15,
                    valid: emergencyContactValid,
                    error: "Please enter emergency contact",
                    updateValid: (bool isValid) {
                      setState(() {
                        emergencyContactValid = isValid;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Description (optional)",
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text("Joining Date"),
                      subtitle: Text("${selectedJoiningDate.day}/${selectedJoiningDate.month}/${selectedJoiningDate.year}"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedJoiningDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedJoiningDate = date;
                          });
                          _calculateRent();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputText(
                    controller: roomController,
                    keyboard: TextInputType.text,
                    hint: "Room Number",
                    icon: Icons.door_back_door,
                    min: 1,
                    max: 10,
                    valid: roomValid,
                    error: "Please enter room number",
                    updateValid: (bool isValid) {
                      setState(() {
                        roomValid = isValid;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputText(
                    controller: rentController,
                    keyboard: TextInputType.number,
                    hint: "Monthly Rent (₹)",
                    icon: Icons.monetization_on,
                    min: 1,
                    max: 10,
                    valid: rentValid,
                    error: "Please enter rent amount",
                    updateValid: (bool isValid) {
                      setState(() {
                        rentValid = isValid;
                      });
                      _calculateRent();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (calculatedRent > 0)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calculate, color: Colors.blue),
                                SizedBox(width: 8),
                                Text("Rent Calculation", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Joining Date: ${selectedJoiningDate.day}/${selectedJoiningDate.month}/${selectedJoiningDate.year}"),
                            Text("Rent Due Date: ${rentDueDate.day}/${rentDueDate.month}/${rentDueDate.year}"),
                            const SizedBox(height: 4),
                            const Text("Period: Full Month", style: TextStyle(color: Colors.blue)),
                            const Divider(),
                            Text("Monthly Rent: ₹${calculatedRent.toStringAsFixed(0)}", 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  InputText(
                    controller: depositController,
                    keyboard: TextInputType.number,
                    hint: "Security Deposit (₹)",
                    icon: Icons.account_balance_wallet,
                    min: 1,
                    max: 10,
                    valid: depositValid,
                    error: "Please enter deposit amount",
                    updateValid: (bool isValid) {
                      setState(() {
                        depositValid = isValid;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ExpandedButton(
              label: "Add Tenant",
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  setState(() {
                    nameValid = false;
                  });
                } else if (phoneController.text.isEmpty) {
                  setState(() {
                    phoneValid = false;
                  });
                } else if (roomController.text.isEmpty) {
                  setState(() {
                    roomValid = false;
                  });
                } else if (rentController.text.isEmpty) {
                  setState(() {
                    rentValid = false;
                  });
                } else if (depositController.text.isEmpty) {
                  setState(() {
                    depositValid = false;
                  });
                } else {
                  setState(() {
                    isLoading = true;
                  });
                  
                  // Calculate rent due date
                  final rentDueDate = _calculateRentDueDate(selectedJoiningDate);
                  
                  final tenant = Tenant(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    phone: phoneController.text,
                    email: "tenant@example.com", // Default email
                    emergencyContact: emergencyContactController.text,
                    description: descriptionController.text,
                    roomNumber: roomController.text,
                    joinedDate: selectedJoiningDate,
                    monthlyRent: double.parse(rentController.text),
                    securityDeposit: double.parse(depositController.text),
                    rentDueDate: rentDueDate,
                    paymentHistory: [
                      PaymentRecord(
                        id: '1',
                        date: rentDueDate,
                        amount: double.parse(rentController.text),
                        status: 'Pending',
                        month: '${_getMonthName(rentDueDate.month)} ${rentDueDate.year}',
                      ),
                    ],
                  );
                  
                  context.read<DataProvider>().addTenant(tenant);
                  
                  await Future.delayed(const Duration(seconds: 1));
                  
                  setState(() {
                    isLoading = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Text("Tenant added successfully!", 
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          SizedBox(width: 8),
                          Icon(Icons.done_all, color: Colors.white)
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  Navigator.pop(context);
                }
              },
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}