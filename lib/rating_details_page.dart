import 'package:flutter/material.dart';

class RatingDetailsPage extends StatelessWidget {
  const RatingDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final starCounts = [50, 10, 5, 2, 1]; // Example data for 5,4,3,2,1 stars
    final maxCount = starCounts.reduce((a, b) => a > b ? a : b);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2D2F7D),
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: Text('Rating Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[200],
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Text(
              'Your current rating based on passenger feedback. Maintain high ratings by being safe, punctual, and courteous. High performance builds trust and attracts more ride requests."',
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          Text('Current Star Rating', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          SizedBox(height: 8),
          Text('4.91', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(5, (i) {
                int star = 5 - i;
                int count = starCounts[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Row(
                    children: [
                      Text('$star', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.yellow[700],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          width: (count / (maxCount == 0 ? 1 : maxCount)) * 180,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(count.toString(), style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
} 