import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'upload_vehicle.dart'; // adjust the path if needed


class UploadLicensePage extends StatefulWidget {
  @override
  State<UploadLicensePage> createState() => _UploadLicensePageState();
}

class _UploadLicensePageState extends State<UploadLicensePage> {
  Uint8List? frontWeb, backWeb;
  File? frontFile, backFile;

  Future<void> pickImage(bool isFront) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() => isFront ? frontWeb = bytes : backWeb = bytes);
    } else {
      final file = File(picked.path);
      setState(() => isFront ? frontFile = file : backFile = file);
    }
  }

  Widget imageBox(String label, bool isFront) {
    final imgWeb = isFront ? frontWeb : backWeb;
    final imgFile = isFront ? frontFile : backFile;
    final hasImage = kIsWeb ? imgWeb != null : imgFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: hasImage
              ? Stack(children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => pickImage(isFront),
                child: kIsWeb
                    ? Image.memory(imgWeb!, fit: BoxFit.cover)
                    : Image.file(imgFile!, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() {
                  if (isFront) frontWeb = frontFile = null;
                  else backWeb = backFile = null;
                }),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            )
          ])
              : Center(
            child: TextButton(
              onPressed: () => pickImage(isFront),
              child: Text('Upload Picture', style: TextStyle(color: Colors.black)),
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
            imageBox('License Front', true),
            SizedBox(height: 24),
            imageBox('License Back', false),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UploadVehiclePage()),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1C1C4B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      foregroundColor: Colors.white, 
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
