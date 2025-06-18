import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_completed.dart';  // Import the new page at the top


class UploadVehiclePage extends StatefulWidget {
  @override
  _UploadVehiclePageState createState() => _UploadVehiclePageState();
}

class _UploadVehiclePageState extends State<UploadVehiclePage> {
  Uint8List? vehicleWeb;
  File? vehicleFile;

  Future<void> pickVehicleImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() => vehicleWeb = bytes);
    } else {
      final file = File(picked.path);
      setState(() => vehicleFile = file);
    }
  }

  Widget vehicleImageBox() {
    final hasImage = kIsWeb ? vehicleWeb != null : vehicleFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Center(
          child: Container(
            height: 370, // Increased height
            width: 300,  // Decreased width
            decoration: BoxDecoration(
              color: Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: hasImage
                ? Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: pickVehicleImage,
                    child: kIsWeb
                        ? Image.memory(vehicleWeb!, fit: BoxFit.cover)
                        : Image.file(vehicleFile!, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      vehicleWeb = vehicleFile = null;
                    }),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
                : Center(
              child: TextButton(
                onPressed: pickVehicleImage,
                child: Text('Upload Picture', style: TextStyle(color: Colors.black)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Upload Documents', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            vehicleImageBox(),
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Back'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Here you can add any validation or upload logic before navigation

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileCompleted()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1C1C4B),
                      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
