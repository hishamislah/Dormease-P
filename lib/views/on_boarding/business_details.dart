// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:dormease/helper/ui_elements.dart';
import 'package:dormease/translations/locale_keys.g.dart';
import 'package:dormease/views/home/home_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_business_info_service.dart';

class BusinessDetails extends StatefulWidget {
  const BusinessDetails({super.key, required this.email});

  final String email;

  @override
  State<BusinessDetails> createState() => _BusinessDetailsState();
}

class _BusinessDetailsState extends State<BusinessDetails> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  var nameValid = true;
  var addressValid = true;
  var cityValid = true;
  var stateValid = true;
  var countryValid = true;
  var imagePath = "null";
  File? imageFile;
  var isLoading = false;

  void getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final croppedImage = await cropImageFile(pickedFile);
      setState(() {
        imageFile = File(croppedImage.path);
        imagePath = croppedImage.path;
      });
    }
  }

  Future<CroppedFile> cropImageFile(XFile image) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Image Cropper',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: 'Image Cropper',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
      ],
    );
    return croppedFile!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Image.asset('assets/images/logo.png')),
            const SizedBox(width: 8),
            Text(LocaleKeys.businessInfo.tr()),
          ],
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Stack(children: [
        Positioned(
          left: 16,
          top: 16,
          right: 16,
          bottom: 80,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    getImage();
                  },
                  child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                          child: imagePath == "null"
                              ? Image.asset('assets/images/business_logo.png')
                              : Image.file(imageFile!))),
                ),
                const SizedBox(height: 16),
                InputText(
                    controller: nameController,
                    keyboard: TextInputType.text,
                    hint: LocaleKeys.businessName.tr(),
                    icon: Icons.business,
                    min: 5,
                    max: 25,
                    valid: nameValid,
                    error: LocaleKeys.error5character.tr(),
                    updateValid: (bool isValid) {
                      setState(() {
                        nameValid = isValid;
                      });
                    }),
                const SizedBox(height: 16),
                // Email is already provided from login
                Text("Email: ${widget.email}", 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                InputText(
                    controller: addressController,
                    keyboard: TextInputType.streetAddress,
                    hint: LocaleKeys.streetAddress.tr(),
                    icon: Icons.pin_drop_outlined,
                    min: 5,
                    max: 50,
                    valid: addressValid,
                    error: LocaleKeys.error5character.tr(),
                    updateValid: (bool isValid) {
                      setState(() {
                        addressValid = isValid;
                      });
                    }),
                const SizedBox(height: 16),
                InputText(
                    controller: cityController,
                    keyboard: TextInputType.text,
                    hint: LocaleKeys.city.tr(),
                    icon: Icons.location_city_rounded,
                    min: 1,
                    max: 30,
                    valid: cityValid,
                    error: LocaleKeys.validCityName.tr(),
                    updateValid: (bool isValid) {
                      setState(() {
                        cityValid = isValid;
                      });
                    }),
                const SizedBox(height: 16),
                InputText(
                    controller: stateController,
                    keyboard: TextInputType.text,
                    hint: LocaleKeys.stateUT.tr(),
                    icon: Icons.map,
                    min: 3,
                    max: 30,
                    valid: stateValid,
                    error: LocaleKeys.error3character.tr(),
                    updateValid: (bool isValid) {
                      setState(() {
                        stateValid = isValid;
                      });
                    }),
                const SizedBox(height: 16),
                InputText(
                    controller: countryController,
                    keyboard: TextInputType.text,
                    hint: LocaleKeys.country.tr(),
                    icon: Icons.public,
                    min: 4,
                    max: 30,
                    valid: countryValid,
                    error: LocaleKeys.error4character.tr(),
                    updateValid: (bool isValid) {
                      setState(() {
                        countryValid = isValid;
                      });
                    }),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: ExpandedButton(
              label: LocaleKeys.continueButton.tr(),
              onPressed: () async {
                if (!nameValid || !addressValid || !cityValid || !stateValid || !countryValid) {
                  return;
                }
                
                setState(() {
                  isLoading = true;
                });
                
                try {
                  final authService = SupabaseAuthService();
                  final prefs = await SharedPreferences.getInstance();
                  
                  // Check if user is signed in
                  if (authService.isSignedIn()) {
                    // Save business info to Supabase
                    try {
                      final businessInfoService = SupabaseBusinessInfoService();
                      await businessInfoService.setBusinessInfo({
                        'phone': '',
                        'logoUrl': imagePath,
                        'businessName': nameController.text,
                        'businessEmail': widget.email,
                        'address': addressController.text,
                        'city': cityController.text,
                        'state': stateController.text,
                        'country': countryController.text,
                      });
                    } catch (supabaseError) {
                      debugPrint('Supabase error, using local storage: $supabaseError');
                      // Save business info locally
                      await prefs.setString('businessName', nameController.text);
                      await prefs.setString('businessEmail', widget.email);
                      await prefs.setString('address', addressController.text);
                      await prefs.setString('city', cityController.text);
                      await prefs.setString('state', stateController.text);
                      await prefs.setString('country', countryController.text);
                    }
                    
                    // Save in SharedPreferences
                    await prefs.setBool('hasCompletedBusinessInfo', true);
                    await prefs.setBool('isLoggedIn', true);
                  }
                  
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              isLoading: isLoading),
        )
      ]),
    );
  }
}