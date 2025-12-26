import 'package:dormease/helper/ui_elements.dart';
import 'package:dormease/views/home/add_ticket_screen.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/models/ticket.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TicketsLayout extends StatefulWidget {
  const TicketsLayout({super.key});

  @override
  State<TicketsLayout> createState() => _TicketsLayoutState();
}

class _TicketsLayoutState extends State<TicketsLayout> {
  final searchController = TextEditingController();
  var filterText = "";

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Row(
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
                label: "Add Ticket",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTicketScreen(),
                    ),
                  );
                },
                isLoading: false)
          ],
        ),
      ),
      Expanded(
          child: Consumer<DataProvider>(
            builder: (context, dataProvider, child) {
              final filteredTickets = dataProvider.tickets
                  .where((ticket) => ticket.title
                      .toLowerCase()
                      .contains(filterText.toLowerCase()))
                  .toList();
              
              if (filteredTickets.isEmpty) {
                return const Center(
                  child: Text("No tickets found", 
                      style: TextStyle(color: Colors.grey)),
                );
              }
              
              return ListView.builder(
                itemCount: filteredTickets.length,
                itemBuilder: (context, index) {
                  return TicketCard(
                    ticket: filteredTickets[index],
                    ticketNumber: index + 1,
                  );
                },
              );
            },
          ),
      ),
    ]);
  }
}

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final int ticketNumber;
  
  const TicketCard({super.key, required this.ticket, required this.ticketNumber});

  void _showTicketDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ticket #$ticketNumber Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Title: ${ticket.title}"),
            Text("Raised by: ${ticket.raisedBy}"),
            Text("Room: ${ticket.roomNumber}"),
            Text("Date: ${ticket.date.day}-${ticket.date.month}-${ticket.date.year}"),
            Text("Status: ${ticket.status}"),
            Text("Priority: ${ticket.priority}"),
            const SizedBox(height: 8),
            const Text("Description:"),
            Text(
              ticket.description,
              style: const TextStyle(color: Colors.grey),
            ),
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

  void _updateTicketStatus(BuildContext context) {
    String selectedStatus = ticket.status;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Update Status"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text("Open"),
                value: "Open",
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text("In Progress"),
                value: "In Progress",
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text("Closed"),
                value: "Closed",
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                context.read<DataProvider>().updateTicketStatus(ticket.id, selectedStatus);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Ticket status updated!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Ticket"),
        content: Text("Are you sure you want to delete ticket #$ticketNumber? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<DataProvider>().deleteTicket(ticket.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Ticket deleted successfully!"),
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
    // Define colors based on priority and status
    Color priorityColor = ticket.priority == 'High' 
        ? Colors.red 
        : ticket.priority == 'Medium' 
            ? Colors.orange 
            : Colors.green;
    
    Color statusColor = ticket.status == 'Closed' 
        ? Colors.green 
        : ticket.status == 'In Progress' 
            ? Colors.blue 
            : Colors.red;
    
    IconData statusIcon = ticket.status == 'Closed' 
        ? Icons.check_circle 
        : ticket.status == 'In Progress' 
            ? Icons.autorenew 
            : Icons.error_outline;

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: priorityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header with ticket number and status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Ticket icon with number
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "Ticket #$ticketNumber",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: priorityColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, color: priorityColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        ticket.priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        ticket.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'details') {
                      _showTicketDetails(context);
                    } else if (value == 'status') {
                      _updateTicketStatus(context);
                    } else if (value == 'priority') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Priority update functionality coming soon!"),
                          backgroundColor: Colors.blue,
                        ),
                      );
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
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(Icons.update),
                            SizedBox(width: 8),
                            Text('Update Status'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'priority',
                        child: Row(
                          children: [
                            Icon(Icons.priority_high),
                            SizedBox(width: 8),
                            Text('Set Priority'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Ticket', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  ticket.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  ticket.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Footer with meta info
                Row(
                  children: [
                    // Room number
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.door_back_door, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            "Room ${ticket.roomNumber}",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Raised by
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            ticket.raisedBy,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Date
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          "${ticket.date.day}-${ticket.date.month}-${ticket.date.year}",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
