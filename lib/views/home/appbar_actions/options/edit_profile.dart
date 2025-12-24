import 'package:dormease/helper/ui_elements.dart';
import 'package:dormease/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final businessNameController = TextEditingController();
  final businessEmailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  
  var businessNameValid = true;
  var businessEmailValid = true;
  var addressValid = true;
  var cityValid = true;
  var stateValid = true;
  var countryValid = true;
  var isLoading = false;

  @override
  void initState() {
    super.initState();
    final userData = context.read<UserProvider>().userData;
    businessNameController.text = userData['businessName'] ?? '';
    businessEmailController.text = userData['businessEmail'] ?? '';
    addressController.text = userData['address'] ?? '';
    cityController.text = userData['city'] ?? '';
    stateController.text = userData['state'] ?? '';
    countryController.text = userData['country'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      appBar: AppBar(
        title: const Text("Edit Profile"),
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
                    controller: businessNameController,
                    keyboard: TextInputType.text,
                    hint: "Business Name",
                    icon: Icons.business,
                    min: 3,
                    max: 50,
                    valid: businessNameValid,
                    error: "Please enter at least 3 characters",
                    updateValid: (bool isValid) {
                      setState(() {
                        businessNameValid = isValid;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputText(
                    controller: businessEmailController,
                    keyboard: TextInputType.emailAddress,
                    hint: "Business Email",
                    icon: Icons.email,
                    min: 5,
                    max: 50,
                    valid: businessEmailValid,
                    error: "Please enter a valid email",
                    updateValid: (bool isValid) {
                      setState(() {
                        businessEmailValid = isValid;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputText(
                    controller: addressController,
                    keyboard: TextInputType.streetAddress,
                    hint: "Street Address",
                    icon: Icons.location_on,
                    min: 5,
                    max: 100,
                    valid: addressValid,
                    error: "Please enter at least 5 characters",
                    updateValid: (bool isValid) {
                      setState(() {
                        addressValid = isValid;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputText(
                    controller: cityController,
                    keyboard: TextInputType.text,
                    hint: "City",
                    icon: Icons.location_city,
                    min: 2,
                    max: 30,
                    valid: cityValid,
                    error: "Please enter a valid city name",
                    updateValid: (bool isValid) {
                      setState(() {
                        cityValid = isValid;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputText(
                    controller: stateController,
                    keyboard: TextInputType.text,
                    hint: "State/UT",
                    icon: Icons.map,
                    min: 2,
                    max: 30,
                    valid: stateValid,
                    error: "Please enter at least 3 characters",
                    updateValid: (bool isValid) {
                      setState(() {
                        stateValid = isValid;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputText(
                    controller: countryController,
                    keyboard: TextInputType.text,
                    hint: "Country",
                    icon: Icons.public,
                    min: 2,
                    max: 30,
                    valid: countryValid,
                    error: "Please enter at least 4 characters",
                    updateValid: (bool isValid) {
                      setState(() {
                        countryValid = isValid;
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
              label: "Update Profile",
              onPressed: () async {
                setState(() {
                  isLoading = true;
                });
                
                await Future.delayed(const Duration(seconds: 1));
                
                final userData = context.read<UserProvider>().userData;
                context.read<UserProvider>().updateBusinessDetails(
                  phone: userData['phone'],
                  logoUrl: userData['logoUrl'],
                  businessName: businessNameController.text,
                  businessEmail: businessEmailController.text,
                  address: addressController.text,
                  city: cityController.text,
                  state: stateController.text,
                  country: countryController.text,
                );
                
                setState(() {
                  isLoading = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Text("Profile updated successfully!", 
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        SizedBox(width: 8),
                        Icon(Icons.done_all, color: Colors.white)
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                
                Navigator.pop(context);
              },
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
