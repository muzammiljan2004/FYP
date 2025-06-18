import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2D2F7D)),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF7F7FA),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF2D2F7D),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF2D2F7D),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingList(),
          _buildCompletedList(),
          _buildCancelledList(),
        ],
      ),
    );
  }

  Widget _buildUpcomingList() {
    final rides = [
      {'name': 'Nate', 'car': 'Mustang Shelby GT', 'time': 'Today at 09:20 am'},
      {'name': 'Henry', 'car': 'Mustang Shelby GT', 'time': 'Today at 10:20 am'},
      {'name': 'Willam', 'car': 'Mustang Shelby GT', 'time': 'Tomorrow at 09:20 am'},
      {'name': 'Nate', 'car': 'Mustang Shelby GT', 'time': 'Today at 09:20 am'},
      {'name': 'Henry', 'car': 'Mustang Shelby GT', 'time': 'Today at 10:20 am'},
      {'name': 'Willam', 'car': 'Mustang Shelby GT', 'time': 'Tomorrow at 09:20 am'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rides.length,
      itemBuilder: (context, i) {
        final ride = rides[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2D2F7D), width: 1),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ride['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(ride['car']!, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              Text(ride['time']!, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedList() {
    final rides = [
      {'name': 'Nate', 'car': 'Mustang Shelby GT'},
      {'name': 'Henry', 'car': 'Mustang Shelby GT'},
      {'name': 'Willam', 'car': 'Mustang Shelby GT'},
      {'name': 'Nate', 'car': 'Mustang Shelby GT'},
      {'name': 'Henry', 'car': 'Mustang Shelby GT'},
      {'name': 'Willam', 'car': 'Mustang Shelby GT'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rides.length,
      itemBuilder: (context, i) {
        final ride = rides[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2D2F7D), width: 1),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ride['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(ride['car']!, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const Text('Done', style: TextStyle(color: Color(0xFF2D2F7D), fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCancelledList() {
    final rides = [
      {'name': 'Nate', 'car': 'Mustang Shelby GT'},
      {'name': 'Henry', 'car': 'Mustang Shelby GT'},
      {'name': 'Willam', 'car': 'Mustang Shelby GT'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rides.length,
      itemBuilder: (context, i) {
        final ride = rides[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ride['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(ride['car']!, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const Text('Cancelled', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
} 