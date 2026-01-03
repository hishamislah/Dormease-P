import 'package:dormease/translations/locale_keys.g.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/models/tenant.dart';
import 'package:dormease/views/home/tenant_detail_screen.dart';
import 'package:dormease/services/payment_service.dart' as payment_service;
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
            Stats(data: dynamicData),
            const SizedBox(height: 8),
            const UpcomingPayments(),
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
class UpcomingPayments extends StatefulWidget {
  const UpcomingPayments({super.key});

  @override
  State<UpcomingPayments> createState() => _UpcomingPaymentsState();
}

class _UpcomingPaymentsState extends State<UpcomingPayments> {
  bool showUpcoming = true; // true = upcoming, false = overdue

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final now = DateTime.now();
        final tenants = dataProvider.tenants;
        
        // Filter tenants based on selected view
        final filteredTenants = tenants.where((tenant) {
          if (tenant.rentDueDate == null) return false;
          
          // Get payment history for this tenant
          final paymentHistory = payment_service.PaymentService.generatePaymentHistory(tenant);
          final dueDateMonth = DateTime(tenant.rentDueDate!.year, tenant.rentDueDate!.month, 1);
          
          // Find payment for the month of the due date
          final dueMonthPayment = paymentHistory.where((p) => 
            p.monthYear.year == dueDateMonth.year && 
            p.monthYear.month == dueDateMonth.month
          ).firstOrNull;
          
          // If payment exists and is paid, don't show in either list
          if (dueMonthPayment != null && dueMonthPayment.status == payment_service.PaymentStatus.paid) {
            return false;
          }
          
          if (showUpcoming) {
            // Upcoming: future dates within next 7 days (and not paid)
            final daysUntilDue = tenant.rentDueDate!.difference(now).inDays;
            return daysUntilDue >= 0 && daysUntilDue <= 7;
          } else {
            // Overdue: past dates (and not paid)
            return tenant.rentDueDate!.isBefore(now);
          }
        }).toList();

        // Sort by due date
        filteredTenants.sort((a, b) => a.rentDueDate!.compareTo(b.rentDueDate!));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 0.5, color: showUpcoming ? Colors.orange : Colors.red),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: showUpcoming ? Colors.orange : Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Payment Status",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                // Toggle buttons
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => showUpcoming = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: showUpcoming ? Colors.orange : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Upcoming",
                            style: TextStyle(
                              color: showUpcoming ? Colors.white : Colors.black87,
                              fontWeight: showUpcoming ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => showUpcoming = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: !showUpcoming ? Colors.red : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Overdue",
                            style: TextStyle(
                              color: !showUpcoming ? Colors.white : Colors.black87,
                              fontWeight: !showUpcoming ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (filteredTenants.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    showUpcoming 
                        ? "No upcoming payments in the next 7 days"
                        : "No overdue payments",
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ),
              )
            else
              ...filteredTenants.map((tenant) {
                final daysUntilDue = tenant.rentDueDate!.difference(now).inDays;
                final dueDate = DateFormat('dd MMM yyyy').format(tenant.rentDueDate!);
                final badgeColor = showUpcoming ? Colors.orange : Colors.red;
                final bgColor = showUpcoming ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1);
                
                String badgeText;
                if (showUpcoming) {
                  badgeText = daysUntilDue == 0 ? 'TODAY' : '$daysUntilDue\nDAYS';
                } else {
                  final daysOverdue = now.difference(tenant.rentDueDate!).inDays;
                  badgeText = daysOverdue == 0 ? 'TODAY' : '$daysOverdue\nDAYS';
                }
                
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TenantDetailScreen(tenant: tenant),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(width: 0.5, color: badgeColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              badgeText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                'Room ${tenant.roomNumber}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${tenant.monthlyRent.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dueDate,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                );
              }).toList(),
          ],
        ),
      ),
    );
      },
    );
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