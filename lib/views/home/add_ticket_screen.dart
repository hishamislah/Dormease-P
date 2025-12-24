import 'package:dormease/helper/ui_elements.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/models/ticket.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddTicketScreen extends StatefulWidget {
  const AddTicketScreen({super.key});

  @override
  State<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends State<AddTicketScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final raisedByController = TextEditingController();
  final roomController = TextEditingController();
  
  var titleValid = true;
  var descriptionValid = true;
  var raisedByValid = true;
  var roomValid = true;
  var isLoading = false;
  
  String selectedPriority = 'Medium';
  List<String> priorities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      appBar: AppBar(
        title: const Text("Add Ticket"),
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
                    controller: titleController,
                    keyboard: TextInputType.text,
                    hint: "Issue Title",
                    icon: Icons.title,
                    min: 3,
                    max: 50,
                    valid: titleValid,
                    error: "Please enter issue title",
                    updateValid: (bool isValid) {
                      setState(() {
                        titleValid = isValid;
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
                        maxLines: 4,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Describe the issue in detail...",
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputText(
                    controller: raisedByController,
                    keyboard: TextInputType.text,
                    hint: "Raised By (Tenant Name)",
                    icon: Icons.person,
                    min: 2,
                    max: 50,
                    valid: raisedByValid,
                    error: "Please enter tenant name",
                    updateValid: (bool isValid) {
                      setState(() {
                        raisedByValid = isValid;
                      });
                    },
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          icon: Icon(Icons.priority_high),
                          border: InputBorder.none,
                          hintText: "Priority",
                        ),
                        value: selectedPriority,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedPriority = newValue!;
                          });
                        },
                        items: priorities.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
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
              label: "Add Ticket",
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  setState(() {
                    titleValid = false;
                  });
                } else if (descriptionController.text.isEmpty) {
                  setState(() {
                    descriptionValid = false;
                  });
                } else if (raisedByController.text.isEmpty) {
                  setState(() {
                    raisedByValid = false;
                  });
                } else if (roomController.text.isEmpty) {
                  setState(() {
                    roomValid = false;
                  });
                } else {
                  setState(() {
                    isLoading = true;
                  });
                  
                  final ticket = Ticket(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descriptionController.text,
                    raisedBy: raisedByController.text,
                    roomNumber: roomController.text,
                    date: DateTime.now(),
                    status: 'Open',
                    priority: selectedPriority,
                  );
                  
                  context.read<DataProvider>().addTicket(ticket);
                  
                  await Future.delayed(const Duration(seconds: 1));
                  
                  setState(() {
                    isLoading = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Text("Ticket added successfully!", 
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