import 'package:dormease/helper/ui_elements.dart';
import 'package:dormease/translations/locale_keys.g.dart';
import 'package:dormease/views/home/add_tenant_screen.dart';
import 'package:dormease/views/home/tenant_detail_screen.dart';
import 'package:dormease/views/home/edit_tenant_screen.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/providers/user_provider.dart';
import 'package:dormease/models/tenant.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TenantsLayout extends StatefulWidget {
  const TenantsLayout({super.key});

  @override
  State<TenantsLayout> createState() => _TenantsLayoutState();
}

class _TenantsLayoutState extends State<TenantsLayout> {
  final searchController = TextEditingController();
  var filterText = "";
  String selectedRoomFilter = "All Rooms";

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SearchBox(
                      controller: searchController,
                      filterText: filterText,
                      updateFilterText: (String updatedText) {
                        setState(() {
                          filterText = updatedText;
                        });
                      }),
                ),
                const SizedBox(width: 12),
                Button(
                    label: "Add Tenant",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddTenantScreen(),
                        ),
                      );
                    },
                    isLoading: false)
              ],
            ),
            const SizedBox(height: 8),
            Consumer<DataProvider>(
              builder: (context, dataProvider, child) {
                final roomNumbers = ['All Rooms'] +
                    dataProvider.rooms
                        .map((room) => 'Room ${room.roomNumber}')
                        .toList();

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        icon: Icon(Icons.filter_list),
                        border: InputBorder.none,
                        hintText: "Filter by Room",
                      ),
                      value: selectedRoomFilter,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRoomFilter = newValue!;
                        });
                      },
                      items: roomNumbers
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      Expanded(
        child: Consumer<DataProvider>(
          builder: (context, dataProvider, child) {
            var filteredTenants = dataProvider.tenants
                .where((tenant) => tenant.name
                    .toLowerCase()
                    .contains(filterText.toLowerCase()))
                .toList();

            if (selectedRoomFilter != "All Rooms") {
              final roomNumber = selectedRoomFilter.replaceAll('Room ', '');
              filteredTenants = filteredTenants
                  .where((tenant) => tenant.roomNumber == roomNumber)
                  .toList();
            }

            if (filteredTenants.isEmpty) {
              return const Center(
                child: Text("No tenants found",
                    style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              itemCount: filteredTenants.length,
              itemBuilder: (context, index) {
                return TenantCard(tenant: filteredTenants[index]);
              },
            );
          },
        ),
      ),
    ]);
  }
}

class TenantCard extends StatelessWidget {
  final Tenant tenant;

  const TenantCard({super.key, required this.tenant});

  void _showTenantDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tenant Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${tenant.name}"),
            Text("Room: ${tenant.roomNumber}"),
            Text("Phone: ${tenant.phone}"),
            Text(
                "Joined: ${tenant.joinedDate.day}-${tenant.joinedDate.month}-${tenant.joinedDate.year}"),
            Text("Monthly Rent: ₹${tenant.monthlyRent.toStringAsFixed(0)}"),
            Text(
                "Security Deposit: ₹${tenant.securityDeposit.toStringAsFixed(0)}"),
            Text("Under Notice: ${tenant.underNotice ? 'Yes' : 'No'}"),
            Text("Rent Due: ${tenant.rentDue ? 'Yes' : 'No'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _sendRentReminder(BuildContext context) async {
    // Get business details from UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.userData;
    final businessName = userData['businessName'] ?? userData['business_name'] ?? 'Hostel';
    final upiPhone = userData['phone'] ?? '';
    
    final message =
        "Hello ${tenant.name},\n\nThis is a friendly reminder that your rent is Due.\n\nAmount: ₹${tenant.monthlyRent.toStringAsFixed(0)}\nDue Date: ${tenant.nextRentDueDate.day}/${tenant.nextRentDueDate.month}/${tenant.nextRentDueDate.year}\n\nPlease make the payment at your earliest\nUpi $upiPhone\n\nThank you!\n$businessName";

    final phoneNumber = tenant.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final whatsappUrl =
        "https://wa.me/91$phoneNumber?text=${Uri.encodeComponent(message)}";

    final Uri uri = Uri.parse(whatsappUrl);
    try {
      await launchUrl(uri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Could not open WhatsApp. Please check if it's installed."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Tenant"),
        content: Text(
            "Are you sure you want to delete ${tenant.name}? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<DataProvider>().deleteTenant(tenant.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Tenant deleted successfully!"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TenantDetailScreen(tenant: tenant),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  tenant.imagePath,
                  height: 120,
                  width: 120,
                ),
              ),
              Positioned(
                left: 135,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tenant.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w500)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                      child: Container(
                        color: Colors.grey[100],
                        height: 1,
                        width: 150,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.door_back_door,
                          color: Colors.black54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text("Room No:",
                            style: TextStyle(color: Colors.black54)),
                        const SizedBox(width: 4),
                        Text(tenant.roomNumber,
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w500))
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.notes,
                          color: Colors.black54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text("Under Notice:",
                            style: TextStyle(color: Colors.black54)),
                        const SizedBox(width: 4),
                        Text(tenant.underNotice ? "Yes" : "No",
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w500))
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.black54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text("Rent Due:",
                            style: TextStyle(color: Colors.black54)),
                        const SizedBox(width: 4),
                        Text(tenant.rentDue ? "Yes" : "No",
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.date_range,
                          color: Colors.black54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text("Joined:",
                            style: TextStyle(color: Colors.black54)),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "${tenant.joinedDate.day}-${tenant.joinedDate.month}-${tenant.joinedDate.year}",
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w500)),
                            Text(
                                "Due: ${tenant.nextRentDueDate.day}/${tenant.nextRentDueDate.month}",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 40,
                child: IconButton(
                  onPressed: () async {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: tenant.phone,
                    );
                    try {
                      await launchUrl(launchUri);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not open dialer for ${tenant.phone}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.phone,
                    color: Colors.green,
                    size: 28,
                  ),
                  tooltip: 'Call ${tenant.name}',
                ),
              ),
              Positioned(
                right: 0,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'details') {
                      _showTenantDetails(context);
                    } else if (value == 'reminder') {
                      _sendRentReminder(context);
                    } else if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditTenantScreen(tenant: tenant),
                        ),
                      );
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context);
                    } else if (value == 'payment') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TenantDetailScreen(tenant: tenant),
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'reminder',
                        child: Row(
                          children: [
                            Image.asset('assets/images/whatsapp.png', height: 24, width: 24),
                            const SizedBox(width: 8),
                            const Text('Send Reminder'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit Tenant'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'payment',
                        child: Row(
                          children: [
                            Icon(Icons.payment, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Payment History'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Tenant',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
