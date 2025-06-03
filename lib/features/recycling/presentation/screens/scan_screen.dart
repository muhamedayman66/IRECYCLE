import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'result_screen.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:graduation_project11/features/home/presentation/screen/home_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanScreen> {
  tfl.Interpreter? _interpreter;
  List<String> _labels = [];
  File? _image;
  final int imgSize = 224;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      final interpreterOptions = tfl.InterpreterOptions()..threads = 2;
      _interpreter = await tfl.Interpreter.fromAsset(
        'assets/AI/best_model.tflite',
        options: interpreterOptions,
      );
      String labelsData = await rootBundle.loadString('assets/AI/labels.txt');
      setState(() {
        _labels =
            labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      });
      print("✅ Model loaded successfully!");
    } catch (e) {
      print("❌ Failed to load model: $e");
    }
  }

  Future<void> captureImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;
    setState(() => _image = File(pickedFile.path));
    classifyImage(_image!);
  }

  Future<void> classifyImage(File image) async {
    if (_interpreter == null) {
      print("❌ Model not loaded!");
      return;
    }
    try {
      var input = await preprocessImage(image);
      var output = List.filled(
        _labels.length,
        0.0,
      ).reshape([1, _labels.length]);
      _interpreter!.run(input, output);
      int maxIndex = output[0].indexWhere(
        (val) => val == output[0].reduce((double a, double b) => a > b ? a : b),
      );
      String result = _labels[maxIndex];
      print("🔍 Predicted: $result");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(image: _image!, result: result),
        ),
      );
    } catch (e) {
      print("❌ Error during classification: $e");
    }
  }

  Future<List<List<List<List<double>>>>> preprocessImage(File image) async {
    Uint8List imageData = await image.readAsBytes();
    img.Image? imgData = img.decodeImage(imageData);
    if (imgData == null) {
      throw Exception("❌ Failed to decode image");
    }

    img.Image resizedImg = img.copyResize(
      imgData,
      width: imgSize,
      height: imgSize,
    );

    return List.generate(
      1,
      (_) => List.generate(
        imgSize,
        (y) => List.generate(imgSize, (x) {
          final pixel = resizedImg.getPixel(x, y);
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();
          return [r / 255.0, g / 255.0, b / 255.0];
        }),
      ),
    );
  }

  Widget _buildImageSourceOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => captureImage(ImageSource.camera),
            icon: Icon(Icons.camera_alt),
            label: Text("Take a Photo"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.light.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
              textStyle: TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => captureImage(ImageSource.gallery),
            icon: Icon(
              Icons.photo_library,
              color: AppTheme.light.colorScheme.primary,
            ),
            label: Text(
              "Choose from Gallery",
              style: TextStyle(
                color: AppTheme.light.colorScheme.primary,
                fontSize: 18,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AppTheme.light.colorScheme.primary,
                width: 2,
              ),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: CustomAppBar(
        title: 'Scan',
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined),
          color: AppTheme.light.colorScheme.secondary,
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    _image!,
                    height: 500,
                    width: 400,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => setState(() => _image = null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.light.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text("Scan Again"),
                ),
              ] else
                _buildImageSourceOptions(),
            ],
          ),
        ),
      ),
    );
  }
}
