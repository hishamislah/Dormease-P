class Ticket {
  final String id;
  final String title;
  final String description;
  final String raisedBy;
  final String roomNumber;
  final DateTime date;
  final String status;
  final String priority;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.raisedBy,
    required this.roomNumber,
    required this.date,
    required this.status,
    this.priority = 'Medium',
  });
}