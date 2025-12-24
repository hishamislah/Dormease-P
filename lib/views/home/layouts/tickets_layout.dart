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
    return Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("# $ticketNumber",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                      decoration: BoxDecoration(
                          color: ticket.status == 'Closed' ? Colors.green : 
                                 ticket.status == 'In Progress' ? Colors.orange : Colors.red,
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        child: Text(ticket.status,
                            style: const TextStyle(color: Colors.white)),
                      )),
                  const SizedBox(width: 8),
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
                  )
                ],
              ),
              Text("${ticket.date.day}-${ticket.date.month}-${ticket.date.year}"),
              Row(
                children: [
                  const Text("Raised by: "),
                  Text(ticket.raisedBy,
                      style: const TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.w500)),
                ],
              ),
              Divider(color: Colors.grey[100]),
              Text(
                ticket.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                ticket.description,
                style: const TextStyle(color: Colors.grey),
              )
            ],
          ),
        ));
  }
}
