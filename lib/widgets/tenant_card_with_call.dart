import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TenantCardWithCall extends StatelessWidget {
  final String name;
  final String roomNumber;
  final String phone;

  const TenantCardWithCall({
    Key? key,
    required this.name,
    required this.roomNumber,
    required this.phone,
  }) : super(key: key);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left side - Tenant details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Room: $roomNumber',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Right side - Call button
            IconButton(
              onPressed: () => _makePhoneCall(phone),
              icon: const Icon(
                Icons.phone,
                color: Colors.green,
                size: 28,
              ),
              tooltip: 'Call $name',
            ),
          ],
        ),
      ),
    );
  }
}