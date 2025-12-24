class Room {
  final String id;
  final String roomNumber;
  final String type;
  final int totalBeds;
  final int occupiedBeds;
  final double rent;
  final int underNotice;
  final int rentDue;
  final int activeTickets;
  final String status;
  final String bathroomType; // 'Attached' or 'Non-attached'

  Room({
    required this.id,
    required this.roomNumber,
    required this.type,
    required this.totalBeds,
    required this.occupiedBeds,
    required this.rent,
    this.underNotice = 0,
    this.rentDue = 0,
    this.activeTickets = 0,
    required this.status,
    this.bathroomType = 'Non-attached',
  });

  int get availableBeds => totalBeds - occupiedBeds;
}