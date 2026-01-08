import 'package:dormease/models/room.dart';
import 'package:dormease/models/tenant.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/views/home/tenant_detail_screen.dart';
import 'package:dormease/views/home/edit_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  
  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late List<bool> bedOccupancy;

  @override
  void initState() {
    super.initState();
    bedOccupancy = List.generate(widget.room.totalBeds, (index) => index < widget.room.occupiedBeds);
  }

  void _updateBedOccupancyFromRoom(Room room) {
    if (bedOccupancy.length != room.totalBeds) {
      bedOccupancy = List.generate(room.totalBeds, (index) => index < room.occupiedBeds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final room = dataProvider.rooms.firstWhere(
          (r) => r.id == widget.room.id,
          orElse: () => widget.room,
        );
        
        _updateBedOccupancyFromRoom(room);
        
        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 235, 235, 245),
          appBar: AppBar(
            title: Text("Room ${room.roomNumber}"),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditRoomScreen(room: room),
                    ),
                  );
                },
              ),
              TextButton(
                onPressed: () => _saveBedOccupancy(room),
                child: const Text("Save"),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRoomInfoCard(room),
                const SizedBox(height: 16),
                _buildBedManagementCard(room),
                const SizedBox(height: 16),
                _buildTenantListCard(room),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomInfoCard(Room room) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Room ${room.roomNumber}", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem("Type", room.type),
                _buildInfoItem("Monthly Rent", "₹${room.rent.toStringAsFixed(0)}"),
                _buildInfoItem("Total Beds", "${room.totalBeds}"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem("Occupied", "${bedOccupancy.where((b) => b).length}"),
                _buildInfoItem("Available", "${bedOccupancy.where((b) => !b).length}"),
                _buildInfoItem("Status", room.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBedManagementCard(Room room) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bed Management", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("Tap beds to toggle occupancy status:", 
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: room.totalBeds,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      bedOccupancy[index] = !bedOccupancy[index];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bedOccupancy[index] ? Colors.red.shade100 : Colors.green.shade100,
                      border: Border.all(
                        color: bedOccupancy[index] ? Colors.red : Colors.green,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bed,
                          size: 32,
                          color: bedOccupancy[index] ? Colors.red : Colors.green,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Bed ${index + 1}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          bedOccupancy[index] ? "Occupied" : "Available",
                          style: TextStyle(
                            fontSize: 12,
                            color: bedOccupancy[index] ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLegendItem(Colors.green, "Available"),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red, "Occupied"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTenantListCard(Room room) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tenant List",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<DataProvider>(
              builder: (context, dataProvider, child) {
                // Get all tenants in this room
                final roomTenants = dataProvider.tenants
                    .where((tenant) => tenant.roomNumber == room.roomNumber)
                    .toList();

                if (roomTenants.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            "No tenants in this room",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: roomTenants.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tenant = roomTenants[index];
                    return _buildTenantListItem(tenant);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantListItem(Tenant tenant) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TenantDetailScreen(tenant: tenant),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Tenant avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : 'T',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tenant details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tenant.phone,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Call button
            IconButton(
              onPressed: () => _makePhoneCall(tenant.phone),
              icon: const Icon(
                Icons.phone,
                color: Colors.green,
                size: 26,
              ),
              tooltip: 'Call ${tenant.name}',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch phone call to $phoneNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveBedOccupancy(Room room) {
    final occupiedCount = bedOccupancy.where((b) => b).length;
    
    // Update room with new occupancy data
    final updatedRoom = Room(
      id: room.id,
      roomNumber: room.roomNumber,
      type: room.type,
      totalBeds: room.totalBeds,
      occupiedBeds: occupiedCount,
      rent: room.rent,
      underNotice: room.underNotice,
      rentDue: room.rentDue,
      activeTickets: room.activeTickets,
      status: occupiedCount == room.totalBeds ? 'Full' : 'Available',
    );
    
    context.read<DataProvider>().updateRoom(updatedRoom);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Bed occupancy updated successfully!"),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context);
  }
}