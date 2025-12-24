import 'package:dormease/translations/locale_keys.g.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/models/tenant.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  bool showRevenue = false;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        // Calculate dynamic stats
        final totalRooms = dataProvider.rooms.length;
        final totalBeds = dataProvider.rooms.fold(0, (sum, room) => sum + room.totalBeds);
        final occupiedBeds = dataProvider.rooms.fold(0, (sum, room) => sum + room.occupiedBeds);
        final vacantBeds = totalBeds - occupiedBeds;
        final totalTenants = dataProvider.tenants.length;
        final tenantsUnderNotice = dataProvider.tenants.where((t) => t.underNotice).length;
        final tenantsWithRentDue = dataProvider.tenants.where((t) => t.rentDue).length;
        final activeTickets = dataProvider.tickets.where((t) => t.status != 'Closed').length;
        
        // Calculate revenue
        final totalRevenue = dataProvider.tenants.fold(0.0, (sum, tenant) => sum + tenant.monthlyRent);
        final paidPercentage = tenantsWithRentDue == 0 ? 100.0 : 
            ((totalTenants - tenantsWithRentDue) / totalTenants * 100);
        
        final dynamicData = {
          'revenue': totalRevenue.toInt(),
          'dateRange': '01/12/24 - 31/12/24',
          'percentage': '+ 2.5',
          'paidRentPercentage': paidPercentage,
          'vacantBeds': vacantBeds,
          'totalBeds': totalBeds,
          'totalTenant': totalTenants,
          'noticePeroid': tenantsUnderNotice,
          'rentDue': tenantsWithRentDue,
          'activeTickets': activeTickets,
        };
        
        return SingleChildScrollView(
          child: Column(children: [
            // Revenue Toggle Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Show Revenue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Switch(
                      value: showRevenue,
                      onChanged: (value) {
                        setState(() {
                          showRevenue = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Show revenue card only if toggle is on
            if (showRevenue) ...[
              RevenueCard(data: dynamicData, tenants: dataProvider.tenants),
              const SizedBox(height: 8),
            ],
            RentDetails(data: dynamicData, dataProvider: dataProvider),
            const SizedBox(height: 8),
            Stats(data: dynamicData)
          ]),
        );
      },
    );
  }
}

class RevenueCard extends StatefulWidget {
  const RevenueCard({
    super.key,
    required this.data,
    required this.tenants,
  });

  final Map<String, dynamic> data;
  final List<Tenant> tenants;

  @override
  State<RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<RevenueCard> {
  DateTimeRange selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }
  
  double calculateRevenueForDateRange(List<Tenant> tenants) {
    double total = 0.0;
    
    for (var tenant in tenants) {
      for (var payment in tenant.paymentHistory) {
        if (payment.status == 'Paid' && 
            payment.date.isAfter(selectedDateRange.start) && 
            payment.date.isBefore(selectedDateRange.end.add(const Duration(days: 1)))) {
          total += payment.amount;
        }
      }
    }
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate revenue for selected date range
    final rangeRevenue = calculateRevenueForDateRange(widget.tenants);
    
    return Container(
        decoration: BoxDecoration(
            color: Colors.blueGrey,
            border: Border.all(width: 1, color: Colors.white),
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text("REVENUE",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Container(
                      decoration: BoxDecoration(
                          color: Colors.amberAccent,
                          border: Border.all(width: 1, color: Colors.white),
                          borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: GestureDetector(
                          onTap: _selectDateRange,
                          child: Row(
                            children: [
                              Text("${selectedDateRange.start.day}/${selectedDateRange.start.month}/${selectedDateRange.start.year} - ${selectedDateRange.end.day}/${selectedDateRange.end.month}/${selectedDateRange.end.year}"),
                              const SizedBox(width: 8),
                              const Icon(Icons.date_range, size: 20)
                            ],
                          ),
                        ),
                      ))
                ],
              ),
              Text("₹ ${rangeRevenue.toStringAsFixed(0)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text("${widget.data['percentage']}%",
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w500)),
              const Text("for selected date range",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ));
  }
}

class RentDetails extends StatelessWidget {
  const RentDetails({
    super.key,
    required this.data,
    required this.dataProvider,
  });

  final Map<String, dynamic> data;
  final DataProvider dataProvider;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(width: 0.5, color: Colors.cyan),
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Rent Details",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500)),
              const Divider(),
              Row(
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: PieChart(PieChartData(
                      centerSpaceRadius: 30,
                      sections: [
                        PieChartSectionData(
                            value: data['paidRentPercentage'],
                            color: Colors.cyan,
                            radius: 30,
                            title: "${data['paidRentPercentage'].toStringAsFixed(1)}%",
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500)),
                        PieChartSectionData(
                            value: 100.0 - data['paidRentPercentage'],
                            color: Colors.grey[300],
                            radius: 30,
                            title:
                                "${(100.0 - data['paidRentPercentage']).toStringAsFixed(1)}%",
                            titleStyle: const TextStyle(
                                color: Colors.cyan,
                                fontSize: 10,
                                fontWeight: FontWeight.w500)),
                      ],
                    )),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                      color: Colors.cyan,
                                      border: Border.all(width: 1)),
                                ),
                                const SizedBox(width: 8),
                                const Text("Paid",
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500))
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      border: Border.all(width: 1)),
                                ),
                                const SizedBox(width: 8),
                                const Text("Not Paid",
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500))
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          final tenantsWithDue = dataProvider.tenants.where((t) => t.rentDue).toList();
                          if (tenantsWithDue.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("No tenants have pending rent!"),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Image.asset('assets/images/whatsapp.png',
                                        height: 20, width: 20),
                                    const SizedBox(width: 8),
                                    Text("Rent reminders sent to ${tenantsWithDue.length} tenants!",
                                        style: const TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.black87,
                              border: Border.all(width: 1, color: Colors.cyan),
                              borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                            child: Row(
                              children: [
                                Image.asset('assets/images/whatsapp.png',
                                    height: 20, width: 20),
                                const SizedBox(width: 8),
                                const Text("REMIND TO PAY",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              )
            ],
          ),
        ));
  }
}

class Stats extends StatelessWidget {
  const Stats({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(width: 0.5, color: Colors.cyan),
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Text("Stats",
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(width: 0.5, color: Colors.grey),
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text("Vacant Beds",
                            style: TextStyle(
                                color: Colors.black87, fontSize: 17)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(data['vacantBeds'].toString(),
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold)),
                            const Text(" / ",
                                style: TextStyle(
                                    fontSize: 25, fontWeight: FontWeight.bold)),
                            Text(data['totalBeds'].toString(),
                                style: const TextStyle(
                                    fontSize: 25, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(width: 0.5, color: Colors.grey),
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        const Text("Tenants",
                            style: TextStyle(
                                color: Colors.black87, fontSize: 17)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                const Text("Total",
                                    style: TextStyle(
                                        color: Colors.cyan,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                Text(data['totalTenant'].toString(),
                                    style: const TextStyle(
                                        color: Colors.cyan,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Column(
                              children: [
                                const Text("Notice Period",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                Text(data['noticePeroid'].toString(),
                                    style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            )
          ]),
        ));
  }
}