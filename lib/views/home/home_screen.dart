import 'dart:io';
import 'package:dormease/providers/user_provider.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/views/home/loading_screen.dart';
import 'package:dormease/views/home/connection_error_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'appbar_actions/actions.dart';
import 'layouts/home_layout.dart';
import 'layouts/rooms_layout.dart';
import 'layouts/tenants_layout.dart';
import 'layouts/tickets_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var selectedTab = "Dashboard";
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserData();
    });
  }
  
  Future<void> _reconnect() async {
    setState(() {
      _isReconnecting = true;
    });
    
    await context.read<DataProvider>().reconnect();
    
    setState(() {
      _isReconnecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
                backgroundColor: Colors.transparent,
                child: ClipOval(
                    child: context.watch<UserProvider>().userData['logoUrl'] ==
                            "null" || context.watch<UserProvider>().userData['logoUrl'] == null
                        ? Image.asset('assets/images/logo.png')
                        : Image.file(File(context
                            .watch<UserProvider>()
                            .userData['logoUrl'])))),
            const SizedBox(width: 16),
            Text(
                (context.watch<UserProvider>().userData['businessName'] ?? 'DormEase').toString().length <=
                        20
                    ? (context.watch<UserProvider>().userData['businessName'] ?? 'DormEase').toString()
                    : (context.watch<UserProvider>().userData['businessName'] ?? 'DormEase')
                        .toString()
                        .substring(0, 20)),
          ],
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          Consumer<DataProvider>(
            builder: (context, dataProvider, _) {
              return IconButton(
                icon: Icon(
                  dataProvider.isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: dataProvider.isConnected ? Colors.green : Colors.red,
                ),
                onPressed: _reconnect,
              );
            },
          ),
          const AppbarActions(),
        ],
      ),
      body: Stack(
        children: [
          Consumer<DataProvider>(
            builder: (context, dataProvider, child) {
              if (_isReconnecting) {
                return const LoadingScreen(isConnecting: true);
              }
              
              if (dataProvider.isLoading) {
                return const LoadingScreen();
              }
              
              if (!dataProvider.isConnected) {
                return ConnectionErrorScreen(onRetry: _reconnect);
              }
              
              // Calculate dynamic stats for dashboard
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
              
              final dashboardData = {
                'revenue': totalRevenue.toInt(),
                'dateRange': '01/${DateTime.now().month}/${DateTime.now().year} - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                'percentage': '+ 0.6',
                'paidRentPercentage': paidPercentage,
                'vacantBeds': vacantBeds,
                'totalBeds': totalBeds,
                'totalTenant': totalTenants,
                'noticePeroid': tenantsUnderNotice,
                'rentDue': tenantsWithRentDue,
                'activeTickets': activeTickets,
              };
              
              return Positioned(
                left: 8,
                top: 8,
                right: 8,
                bottom: 90,
                child: Builder(builder: (context) {
                  if (selectedTab == "Dashboard") {
                    return HomeLayout(data: dashboardData);
                  } else if (selectedTab == "Rooms") {
                    return const RoomsLayout();
                  } else if (selectedTab == "Tenants") {
                    return const TenantsLayout();
                  } else if (selectedTab == "Tickets") {
                    return const TicketsLayout();
                  } else {
                    return const SizedBox();
                  }
                }),
              );
            },
          ),
          Toolbar(
              selectedTab: selectedTab,
              updateTab: (String tab) {
                setState(() {
                  selectedTab = tab;
                });
              }),
        ],
      ),
    );
  }
}

class Toolbar extends StatelessWidget {
  const Toolbar(
      {super.key, required this.selectedTab, required this.updateTab});

  final String selectedTab;
  final Function(String) updateTab;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Spacer(),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.black87, borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    updateTab("Dashboard");
                  },
                  child: TabOption(
                      icon: Icons.bar_chart,
                      label: "Dashboard",
                      selectedTab: selectedTab),
                ),
                GestureDetector(
                  onTap: () {
                    updateTab("Rooms");
                  },
                  child: TabOption(
                      icon: Icons.door_back_door,
                      label: "Rooms",
                      selectedTab: selectedTab),
                ),
                GestureDetector(
                  onTap: () {
                    updateTab("Tenants");
                  },
                  child: TabOption(
                      icon: Icons.person,
                      label: "Tenants",
                      selectedTab: selectedTab),
                ),
                GestureDetector(
                  onTap: () {
                    updateTab("Tickets");
                  },
                  child: TabOption(
                      icon: Icons.airplane_ticket,
                      label: "Tickets",
                      selectedTab: selectedTab),
                ),
              ],
            ),
          ),
        ),
      )
    ]);
  }
}

class TabOption extends StatelessWidget {
  const TabOption(
      {super.key,
      required this.icon,
      required this.label,
      required this.selectedTab});

  final IconData icon;
  final String label;
  final String selectedTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon,
            color: label == selectedTab ? Colors.amberAccent : Colors.white70),
        Text(label,
            style: TextStyle(
                color:
                    label == selectedTab ? Colors.amberAccent : Colors.white70,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}