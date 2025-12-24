import 'package:dormease/helper/ui_elements.dart';
import 'package:dormease/models/room.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditRoomScreen extends StatefulWidget {
  final Room room;
  
  const EditRoomScreen({super.key, required this.room});

  @override
  State<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  final roomNumberController = TextEditingController();
  final rentController = TextEditingController();
  
  var roomNumberValid = true;
  var rentValid = true;
  var isLoading = false;
  
  String selectedRoomType = 'Single';
  List<String> roomTypes = ['Single', 'Double', 'Triple', 'Quad'];
  int totalBeds = 1;

  @override
  void initState() {
    super.initState();
    roomNumberController.text = widget.room.roomNumber;
    rentController.text = widget.room.rent.toStringAsFixed(0);
    selectedRoomType = widget.room.type;
    totalBeds = widget.room.totalBeds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      appBar: AppBar(
        title: const Text("Edit Room"),
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
                    controller: roomNumberController,
                    keyboard: TextInputType.text,
                    hint: "Room Number",
                    icon: Icons.door_back_door,
                    min: 1,
                    max: 10,
                    valid: roomNumberValid,
                    error: "Please enter room number",
                    updateValid: (bool isValid) {
                      setState(() {
                        roomNumberValid = isValid;
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
                          icon: Icon(Icons.category),
                          border: InputBorder.none,
                          hintText: "Room Type",
                        ),
                        value: selectedRoomType,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedRoomType = newValue!;
                          });
                        },
                        items: roomTypes.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Number of Beds", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: totalBeds > 1 ? () {
                                  setState(() {
                                    totalBeds--;
                                  });
                                } : null,
                                icon: const Icon(Icons.remove_circle),
                                iconSize: 32,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  totalBeds.toString(),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                onPressed: totalBeds < 10 ? () {
                                  setState(() {
                                    totalBeds++;
                                  });
                                } : null,
                                icon: const Icon(Icons.add_circle),
                                iconSize: 32,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text("Current: $totalBeds beds", 
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
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
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ExpandedButton(
              label: "Update Room",
              onPressed: () async {
                if (roomNumberController.text.isEmpty) {
                  setState(() {
                    roomNumberValid = false;
                  });
                } else if (rentController.text.isEmpty) {
                  setState(() {
                    rentValid = false;
                  });
                } else {
                  setState(() {
                    isLoading = true;
                  });
                  
                  final updatedRoom = Room(
                    id: widget.room.id,
                    roomNumber: roomNumberController.text,
                    type: selectedRoomType,
                    totalBeds: totalBeds,
                    occupiedBeds: widget.room.occupiedBeds > totalBeds ? totalBeds : widget.room.occupiedBeds,
                    rent: double.parse(rentController.text),
                    underNotice: widget.room.underNotice,
                    rentDue: widget.room.rentDue,
                    activeTickets: widget.room.activeTickets,
                    status: widget.room.status,
                  );
                  
                  context.read<DataProvider>().updateRoom(updatedRoom);
                  
                  await Future.delayed(const Duration(seconds: 1));
                  
                  setState(() {
                    isLoading = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Text("Room updated successfully!", 
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