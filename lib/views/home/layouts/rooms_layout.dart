import 'package:dormease/helper/ui_elements.dart';
import 'package:dormease/translations/locale_keys.g.dart';
import 'package:dormease/views/home/add_room_screen.dart';
import 'package:dormease/views/home/room_detail_screen.dart';
import 'package:dormease/views/home/edit_room_screen.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/models/room.dart';
import 'package:dormease/views/home/components/room_filter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoomsLayout extends StatefulWidget {
  const RoomsLayout({super.key});

  @override
  State<RoomsLayout> createState() => _RoomsLayoutState();
}

class _RoomsLayoutState extends State<RoomsLayout> {
  final searchController = TextEditingController();
  var filterText = "";

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      RoomFilter(
        onFilter: (value) {
          setState(() {
            filterText = value;
          });
        },
        onAddRoom: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRoomScreen(),
            ),
          );
        },
      ),
      Expanded(
          child: Consumer<DataProvider>(
            builder: (context, dataProvider, child) {
              final filteredRooms = dataProvider.rooms
                  .where((room) => room.roomNumber
                      .toLowerCase()
                      .contains(filterText.toLowerCase()))
                  .toList();
              
              if (filteredRooms.isEmpty) {
                return const Center(
                  child: Text("No rooms found", 
                      style: TextStyle(color: Colors.grey)),
                );
              }
              
              return ListView.builder(
                itemCount: filteredRooms.length,
                itemBuilder: (context, index) {
                  return RoomCard(room: filteredRooms[index]);
                },
              );
            },
          ),
      ),
    ]);
  }
}

class RoomCard extends StatelessWidget {
  final Room room;
  
  const RoomCard({super.key, required this.room});

  void _showRoomDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Room ${room.roomNumber} Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Room Type: ${room.type}"),
            Text("Bathroom: ${room.bathroomType}"),
            Text("Monthly Rent: ₹${room.rent.toStringAsFixed(0)}"),
            Text("Total Beds: ${room.totalBeds}"),
            Text("Occupied Beds: ${room.occupiedBeds}"),
            Text("Available Beds: ${room.availableBeds}"),
            Text("Under Notice: ${room.underNotice}"),
            Text("Rent Due: ${room.rentDue}"),
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Room"),
        content: Text("Are you sure you want to delete Room ${room.roomNumber}? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<DataProvider>().deleteRoom(room.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Room deleted successfully!"),
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
            builder: (context) => RoomDetailScreen(room: room),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          children: [
            Row(
              children: [
                Container(
                    decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(32)),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.door_back_door, color: Colors.white),
                    )),
                const SizedBox(width: 12),
                Text("Room ${room.roomNumber}",
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 17,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                Container(
                    decoration: BoxDecoration(
                        color: room.availableBeds > 0 ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Text(room.availableBeds > 0 ? LocaleKeys.available.tr() : LocaleKeys.full.tr(),
                          style: const TextStyle(color: Colors.white)),
                    )),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditRoomScreen(room: room),
                        ),
                      );
                    } else if (value == 'details') {
                      _showRoomDetails(context);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context);
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
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit Room'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Room', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ];
                  },
                )
              ],
            ),
            Divider(color: Colors.grey[100], height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bed, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(LocaleKeys.beds.tr(),
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(width: 4),
                    Text("${room.totalBeds}",
                        style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 17,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Row(
                      children: List.generate(room.totalBeds, (index) => 
                        Icon(Icons.bed, color: index < room.occupiedBeds ? Colors.red : Colors.green)
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.notes, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(LocaleKeys.underNotice.tr(),
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(width: 4),
                    Text("${room.underNotice}",
                        style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 17,
                            fontWeight: FontWeight.w500))
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(LocaleKeys.rentDue.tr(),
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(width: 4),
                    Text("${room.rentDue}",
                        style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 17,
                            fontWeight: FontWeight.w500))
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.airplane_ticket, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(LocaleKeys.activeTickets.tr(),
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(width: 4),
                    Text("${room.activeTickets}",
                        style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 17,
                            fontWeight: FontWeight.w500))
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}
