// DO NOT EDIT. This is code generated via package:easy_localization/generate.dart

// ignore_for_file: prefer_single_quotes, avoid_renaming_method_parameters, constant_identifier_names

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' show AssetLoader;

class CodegenLoader extends AssetLoader{
  const CodegenLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    return Future.value(mapLocales[locale.toString()]);
  }

  static const Map<String,dynamic> _en = {
  "appName": "DormEase",
  "getStarted": "Get Started",
  "welcomeText": "Welcome to DormEase",
  "optMessage": "We will send you an OTP to verify your number",
  "enterPhoneNo": "Enter Phone Number",
  "invalidPhoneNo": "Invalid phone number",
  "requestOtp": "Request OTP",
  "verificationCode": "Verification Code",
  "verificationDesc": "We sent you an OTP to your number",
  "pleaseEnterValidOtp": "Please enter a valid OTP",
  "verificationSuccess": "Verification Success",
  "verifyOtp": "Verify OTP",
  "resendOtp": "Resend OTP",
  "businessInfo": "Business Information",
  "businessName": "Business Name",
  "error3character": "Can't be less than 3 characters",
  "error4character": "Can't be less than 4 characters",
  "error5character": "Can't be less than 5 characters",
  "businessEmail": "Business Email",
  "invalidEmail": "Invalid email",
  "streetAddress": "Street Address",
  "city": "City",
  "validCityName": "Please enter a valid city name",
  "stateUT": "State",
  "country": "Country",
  "continuee": "Continue",
  "submit": "Submit",
  "dashboard": "Dashboard",
  "rooms": "Rooms",
  "tenants": "Tenants",
  "tickets": "Tickets",
  "editProfile": "Edit Profile",
  "help": "Help",
  "settings": "Settings",
  "logout": "Logout",
  "revenue": "Revenue",
  "fromLastMonth": "From Last Month",
  "rentDetails": "Rent Details",
  "paid": "Paid",
  "notPaid": "Not Paid",
  "remindToPay": "Remind to Pay",
  "stats": "Stats",
  "vacantBeds": "Vacant Beds",
  "total": "Total",
  "noticePeriod": "Notice Period",
  "sureToLogout": "Sure to Logout?",
  "logoutSuccess": "Successfully Logged Out",
  "yes": "Yes",
  "no": "No",
  "search": "Search",
  "addRoom": "Add Room",
  "available": "Available",
  "full": "Full",
  "beds": "Beds",
  "underNotice": "Under Notice",
  "rentDue": "Rent Due",
  "activeTickets": "Active Tickets",
  "roomNo": "Room No",
  "joined": "Joined",
  "active": "Active",
  "closed": "Closed",
  "issue": "Issue"
};
static const Map<String, Map<String,dynamic>> mapLocales = {"en": _en};
}
