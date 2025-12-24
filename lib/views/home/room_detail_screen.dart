import 'package:dormease/models/room.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      appBar: AppBar(
        title: Text("Room ${widget.room.roomNumber}"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveBedOccupancy,
            child: const Text("Save"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRoomInfoCard(),
            const SizedBox(height: 16),
            _buildBedManagementCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Room ${widget.room.roomNumber}", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem("Type", widget.room.type),
                _buildInfoItem("Monthly Rent", "₹${widget.room.rent.toStringAsFixed(0)}"),
                _buildInfoItem("Total Beds", "${widget.room.totalBeds}"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem("Occupied", "${bedOccupancy.where((b) => b).length}"),
                _buildInfoItem("Available", "${bedOccupancy.where((b) => !b).length}"),
                _buildInfoItem("Status", widget.room.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBedManagementCard() {
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
              itemCount: widget.room.totalBeds,
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

  void _saveBedOccupancy() {
    final occupiedCount = bedOccupancy.where((b) => b).length;
    
    // Update room with new occupancy data
    final updatedRoom = Room(
      id: widget.room.id,
      roomNumber: widget.room.roomNumber,
      type: widget.room.type,
      totalBeds: widget.room.totalBeds,
      occupiedBeds: occupiedCount,
      rent: widget.room.rent,
      underNotice: widget.room.underNotice,
      rentDue: widget.room.rentDue,
      activeTickets: widget.room.activeTickets,
      status: occupiedCount == widget.room.totalBeds ? 'Full' : 'Available',
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