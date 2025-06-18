import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectRouteSheet extends StatefulWidget {
  final void Function(Map<String, dynamic>?) onRouteSelected;
  final bool showCancelButton;
  const SelectRouteSheet({required this.onRouteSelected, this.showCancelButton = false, Key? key}) : super(key: key);

  @override
  State<SelectRouteSheet> createState() => _SelectRouteSheetState();
}

class _SelectRouteSheetState extends State<SelectRouteSheet> {
  int? selectedRouteIndex;
  List<Map<String, dynamic>> routes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    final snapshot = await FirebaseFirestore.instance.collection('routes').get();
    setState(() {
      routes = snapshot.docs.map((doc) => doc.data()).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Select Route", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 24),
                    ...List.generate(routes.length, (index) {
                      final route = routes[index];
                      final stops = (route['stops'] as List).map((s) => s['name']).join(' → ');
                      return ListTile(
                        leading: Icon(Icons.alt_route, color: selectedRouteIndex == index ? Color(0xFF2D2F7D) : Colors.grey),
                        title: Text(route["name"] ?? ''),
                        subtitle: Text(stops),
                        selected: selectedRouteIndex == index,
                        onTap: () => setState(() => selectedRouteIndex = index),
                      );
                    }),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: selectedRouteIndex != null
                          ? () {
                              widget.onRouteSelected(routes[selectedRouteIndex!]);
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedRouteIndex != null ? Color(0xFF2D2F7D) : Colors.grey,
                        minimumSize: Size(double.infinity, 48),
                      ),
                      child: Text("Confirm", style: TextStyle(color: Colors.white)),
                    ),
                    if (widget.showCancelButton)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onRouteSelected(null);
                            Navigator.pop(context, null);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 48),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
} 