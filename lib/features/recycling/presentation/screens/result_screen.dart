import 'package:flutter/material.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/recycling/presentation/screens/recycle_bag_screen.dart';
import 'dart:io';

class ResultScreen extends StatefulWidget {
  final File? image;
  final String result;

  const ResultScreen({super.key, required this.image, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  File? _image;
  String materialType = "Unknown";
  int quantity = 5;

  @override
  void initState() {
    super.initState();
    _image = widget.image;
    materialType = widget.result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Result',
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined),
          color: AppTheme.light.colorScheme.secondary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: 16 / 18,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child:
                    _image == null
                        ? const Text("No image selected.")
                        : Image.file(
                          _image!,
                          width: double.infinity,
                          height: double.infinity,
                        ),
              ),
            ),
          ),
          Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: AppTheme.light.colorScheme.secondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      materialType,
                      style: TextStyle(
                        color: AppTheme.light.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.recycling,
                      color: AppTheme.light.colorScheme.primary,
                      size: 25,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.light.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildInfoColumn('Material', materialType),
                      buildInfoColumn('Quantity', '$quantity Piece'),
                      buildQuantityController(),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Scan again?',
                      style: TextStyle(
                        color: AppTheme.light.colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_image != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => RecycleBagScreen(
                                newItem: {
                                  'item_type': materialType,
                                  'quantity': quantity,
                                  'imagePath': _image!.path,
                                },
                              ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.light.colorScheme.primary,
                    foregroundColor: AppTheme.light.colorScheme.secondary,
                    minimumSize: const Size(200, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Add to recycle bag',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Column buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.light.colorScheme.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget buildQuantityController() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.light.colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: AppTheme.light.colorScheme.primary),
            onPressed: () {
              if (quantity > 5) {
                setState(() => quantity -= 1);
              }
            },
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              quantity.toString().padLeft(2, '0'),
              style: TextStyle(
                color: AppTheme.light.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.light.colorScheme.primary),
            onPressed: () => setState(() => quantity += 1),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }
}
