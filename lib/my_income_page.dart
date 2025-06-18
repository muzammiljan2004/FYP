import 'package:flutter/material.dart';

class MyIncomePage extends StatelessWidget {
  const MyIncomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rides = [
      {
        'date': '26 May, 9:02 PM',
        'from': 'F10 Round About',
        'to': 'G11- Markaz',
        'fare': 'Rs. 30',
      },
      {
        'date': '26 May, 9:02 PM',
        'from': '9th Avenue',
        'to': 'G10 – Markaz',
        'fare': 'Rs. 30',
      },
      {
        'date': '26 May, 9:02 PM',
        'from': 'G10 – Markaz',
        'to': 'G13',
        'fare': 'Rs. 30',
      },
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2D2F7D),
        elevation: 0,
        title: Text('My Income', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: rides.length,
        separatorBuilder: (_, __) => Divider(height: 1),
        itemBuilder: (context, i) {
          final ride = rides[i];
          return Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ride['date']!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 18),
                    SizedBox(width: 4),
                    Expanded(child: Text(ride['from']!, style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green, size: 18),
                    SizedBox(width: 4),
                    Expanded(child: Text(ride['to']!, style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(ride['fare']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 