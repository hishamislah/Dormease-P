import 'package:dormease/helper/ui_elements.dart';
import 'package:dormease/models/tenant.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditTenantScreen extends StatefulWidget {
  final Tenant tenant;
  
  const EditTenantScreen({super.key, required this.tenant});

  @override
  State<EditTenantScreen> createState() => _EditTenantScreenState();
}

class _EditTenantScreenState extends State<EditTenantScreen> {
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
  
  bool underNotice = false;
  bool rentDue = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.tenant.name;
    phoneController.text = widget.tenant.phone;
    emergencyContactController.text = widget.tenant.emergencyContact;
    descriptionController.text = widget.tenant.description;
    roomController.text = widget.tenant.roomNumber;
    rentController.text = widget.tenant.monthlyRent.toStringAsFixed(0);
    depositController.text = widget.tenant.securityDeposit.toStringAsFixed(0);
    underNotice = widget.tenant.underNotice;
    rentDue = widget.tenant.rentDue;
  }

  void _updateTenant() {
    if (!mounted) return;
    
    final updatedTenant = Tenant(
      id: widget.tenant.id,
      name: nameController.text,
      phone: phoneController.text,
      email: widget.tenant.email,
      emergencyContact: emergencyContactController.text,
      description: descriptionController.text,
      roomNumber: roomController.text,
      joinedDate: widget.tenant.joinedDate,
      monthlyRent: double.parse(rentController.text),
      securityDeposit: double.parse(depositController.text),
      underNotice: underNotice,
      rentDue: rentDue,
      imagePath: widget.tenant.imagePath,
      rentDueDate: widget.tenant.rentDueDate,
      paymentHistory: widget.tenant.paymentHistory,
    );
    
    Provider.of<DataProvider>(context, listen: false).updateTenant(updatedTenant);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Tenant updated successfully!"),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 235, 235, 245),
        appBar: AppBar(
          title: const Text("Edit Tenant"),
          backgroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Stack(
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
                              hintText: "Description",
                              prefixIcon: Icon(Icons.description),
                            ),
                          ),
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
                        },
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
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text("Under Notice"),
                                subtitle: const Text("Tenant has given notice to leave"),
                                value: underNotice,
                                activeColor: Colors.orange,
                                onChanged: (value) {
                                  setState(() {
                                    underNotice = value;
                                  });
                                },
                              ),
                              const Divider(),
                              SwitchListTile(
                                title: const Text("Rent Due"),
                                subtitle: const Text("Tenant has pending rent payment"),
                                value: rentDue,
                                activeColor: Colors.red,
                                onChanged: (value) {
                                  setState(() {
                                    rentDue = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: isLoading ? null : () {
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
                      
                      // Use a simple timer instead of Future.delayed
                      Future.microtask(_updateTenant);
                    }
                  },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Update Tenant",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}