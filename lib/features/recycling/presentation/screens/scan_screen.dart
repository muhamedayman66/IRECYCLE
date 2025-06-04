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
  bool _isProcessing = false; // For image classification loading

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanner initialization failed: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> captureImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;
    setState(() {
      _image = File(pickedFile.path);
      _isProcessing = true; // Start processing HERE
    });
    await classifyImage(_image!);
  }

  Future<void> classifyImage(File image) async {
    if (_interpreter == null) {
      print("❌ Model not loaded!");
      if (mounted) {
        // Ensure mounted before setState
        setState(() => _isProcessing = false);
      }
      return;
    }
    // _isProcessing is already true from captureImage
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

      if (!mounted) return;
      // _isProcessing remains true until ResultScreen is popped or error occurs
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(image: _image!, result: result),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _image = null;
            _isProcessing = false; // Reset after ResultScreen is popped
          });
        }
      });
    } catch (e) {
      print("❌ Error during classification: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during classification: ${e.toString()}'),
          ),
        );
        setState(() => _isProcessing = false); // Stop processing on error
      }
    }
    // No finally block needed here to set _isProcessing to false,
    // as it's handled by the .then() or the catch block.
    // If navigation is successful, _isProcessing becomes false when ResultScreen is popped.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Scan',
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_outlined,
            color: AppTheme.light.colorScheme.secondary,
          ),
          color: AppTheme.light.colorScheme.primary,
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Column(
                  children: [
                    Text(
                      "Scan Your Item",
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.light.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Use your camera or upload an image to identify recyclable materials.",
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      _image == null
                          ? _buildInitialScanUI()
                          : _buildImagePreviewUI(),
                ),
              ),
              SizedBox(height: 20),
              if (_image == null && !_isProcessing)
                _buildInitialActionButtons()
              else if (_image != null && !_isProcessing)
                _buildChangePhotoButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialScanUI() {
    return Column(
      key: ValueKey('initialScanUI'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.center_focus_strong_outlined,
          size: 120,
          color: AppTheme.light.colorScheme.primary,
        ),
        SizedBox(height: 24),
        Text(
          "Point, Scan, Recycle!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: AppTheme.light.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Let's identify what you're recycling today.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildImagePreviewUI() {
    return Column(
      key: ValueKey('imagePreviewUI'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Image.file(_image!, fit: BoxFit.contain),
            ),
          ),
        ),
        if (_isProcessing) ...[
          // This is the loading indicator you want
          SizedBox(height: 16),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.light.colorScheme.primary,
            ),
            strokeWidth: 3.0,
          ),
          SizedBox(height: 12),
          Text(
            "Analyzing...",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: AppTheme.light.colorScheme.primary,
            ),
          ),
          SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildInitialActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed:
              _isProcessing ? null : () => captureImage(ImageSource.camera),
          icon: Icon(Icons.camera_alt_outlined, size: 22, color: Colors.white),
          label: Text("Open Camera"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.light.colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(vertical: 13),
          ),
        ),
        SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed:
              _isProcessing ? null : () => captureImage(ImageSource.gallery),
          icon: Icon(Icons.photo_library_outlined, size: 22),
          label: Text("Upload from Gallery"),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.light.colorScheme.primary,
            side: BorderSide(
              color: AppTheme.light.colorScheme.primary,
              width: 1.5,
            ),
            minimumSize: Size(double.infinity, 50),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildChangePhotoButton() {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _image = null;
          _isProcessing = false;
        });
      },
      icon: Icon(Icons.refresh_outlined, size: 22),
      label: Text("Choose Different Photo"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.light.colorScheme.secondary.withOpacity(0.85),
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 50),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(vertical: 13),
      ),
    );
  }
}
