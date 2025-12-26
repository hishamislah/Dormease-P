import 'package:dormease/helper/ui_elements.dart';
import 'package:dormease/translations/locale_keys.g.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/models/room.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final roomNumberController = TextEditingController();
  final bedsController = TextEditingController();
  final rentController = TextEditingController();
  
  var roomNumberValid = true;
  var bedsValid = true;
  var rentValid = true;
  var isLoading = false;
  
  String selectedRoomType = 'Single';
  List<String> roomTypes = ['Single', '2 Sharing', '3 Sharing', '4 Sharing'];
  
  String selectedBathroomType = 'Non-attached';
  List<String> bathroomTypes = ['Attached', 'Non-attached'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      appBar: AppBar(
        title: Text(LocaleKeys.addRoom.tr()),
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
                    hint: "Room Number (e.g., 101)",
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
                  InputText(
                    controller: bedsController,
                    keyboard: TextInputType.number,
                    hint: "Number of Beds",
                    icon: Icons.bed,
                    min: 1,
                    max: 2,
                    valid: bedsValid,
                    error: "Please enter number of beds",
                    updateValid: (bool isValid) {
                      setState(() {
                        bedsValid = isValid;
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          icon: Icon(Icons.bathroom),
                          border: InputBorder.none,
                          hintText: "Bathroom Type",
                        ),
                        value: selectedBathroomType,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedBathroomType = newValue!;
                          });
                        },
                        items: bathroomTypes.map<DropdownMenuItem<String>>((String value) {
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
              label: "Add Room",
              onPressed: () async {
                if (roomNumberController.text.isEmpty) {
                  setState(() {
                    roomNumberValid = false;
                  });
                } else if (bedsController.text.isEmpty) {
                  setState(() {
                    bedsValid = false;
                  });
                } else if (rentController.text.isEmpty) {
                  setState(() {
                    rentValid = false;
                  });
                } else {
                  setState(() {
                    isLoading = true;
                  });
                  
                  final room = Room(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    roomNumber: roomNumberController.text,
                    type: selectedRoomType,
                    totalBeds: int.parse(bedsController.text),
                    occupiedBeds: 0,
                    rent: double.parse(rentController.text),
                    status: 'Available',
                    bathroomType: selectedBathroomType,
                  );
                  
                  context.read<DataProvider>().addRoom(room);
                  
                  await Future.delayed(const Duration(seconds: 1));
                  
                  setState(() {
                    isLoading = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Text("Room added successfully!", 
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