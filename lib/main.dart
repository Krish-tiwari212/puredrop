import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:google_fonts/google_fonts.dart';
import "package:http/http.dart" as http;
import 'package:camera_windows/camera_windows.dart';
import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  final firstCamera = cameras.first;
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (Platform.isWindows) {
    WindowManager.instance.setMinimumSize(const Size(1060, 750));
    WindowManager.instance.setMaximumSize(const Size(1060, 750));
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "PureDrop",
      theme: ThemeData.light(useMaterial3: true),
      home: TakePictureScreen(
        camera: firstCamera,
      ),
    ),
  );
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  Future<String> onUploadImage(File selectedImage) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://127.0.0.1:5000/"),
    );
    Map<String, String> headers = {"Content-type": "multipart/form-data"};
    request.files.add(
      http.MultipartFile(
        'image',
        selectedImage.readAsBytes().asStream(),
        selectedImage.lengthSync(),
        filename: selectedImage.path.split('/').last,
      ),
    );
    request.headers.addAll(headers);
    print("request: " + request.toString());
    var res = await request.send();
    http.Response response = await http.Response.fromStream(res);
    Map<String, dynamic> jsonResponse = json.decode(response.body);
    String result = jsonResponse["message"];
    return result;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/images/background.png"),
                      fit: BoxFit.cover)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          const Text(
                            "Do You Know Only\n2.5% Fresh Water\nIs Available?",
                            style: TextStyle(
                                height: 1,
                                color: Color(0xFF1A4547),
                                fontFamily: 'rox',
                                fontSize: 55,
                                fontWeight: FontWeight.w500),
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(0, 70, 0, 20),
                            child: SizedBox(
                              width: 350,
                              height: 200,
                              child: CameraPreview(_controller),
                            ),
                          )
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(60, 0, 20, 0),
                          child: Container(
                            height: 0.5,
                            width: 300.0,
                            color: const Color(0xFF1A4547),
                          ),
                        ),
                        const Text(
                          "Calculate Water Footprint",
                          style: TextStyle(
                              fontSize: 15,
                              fontFamily: "dm",
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A4547)),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 40),
                          child: TextButton(
                              style: TextButton.styleFrom(
                                  fixedSize: const Size(162, 40),
                                  shape: const BeveledRectangleBorder(
                                      borderRadius: BorderRadius.zero),
                                  side: const BorderSide(
                                    width: 0.3,
                                    color: Color(0xFF1A4547),
                                  )),
                              onPressed: () async {
                                try {
                                  await _initializeControllerFuture;

                                  final image = await _controller.takePicture();

                                  if (!mounted) return;

                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DisplayPictureScreen(
                                              imagePath: image.path,
                                              responseText: onUploadImage(
                                                  File(image.path))),
                                    ),
                                  );
                                } catch (e) {
                                  print(e);
                                }
                              },
                              child: const Text("Click",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: "dm",
                                    color: Colors.black,
                                  ))),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 20),
                          child: TextButton(
                              style: TextButton.styleFrom(
                                  fixedSize: const Size(162, 40),
                                  shape: const BeveledRectangleBorder(
                                      borderRadius: BorderRadius.zero),
                                  side: const BorderSide(
                                    width: 0.3,
                                    color: Color(0xFF1A4547),
                                  )),
                              onPressed: () async {
                                try {
                                  final image = await ImagePicker()
                                      .pickImage(source: ImageSource.gallery);

                                  if (image == null) {
                                    return;
                                  }
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DisplayPictureScreen(
                                              imagePath: image.path,
                                              responseText: onUploadImage(
                                                  File(image.path))),
                                    ),
                                  );
                                } catch (e) {
                                  print(e);
                                }
                              },
                              child: const Text("Upload",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: "dm",
                                    color: Colors.black,
                                  ))),
                        )
                      ],
                    ),
                    const Center(
                      child: Text(
                        "PUREDROP",
                        style: TextStyle(
                            fontSize: 175,
                            fontFamily: "rox",
                            color: Color(0xFF1A4547)),
                      ),
                    )
                  ],
                ),
              ),
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final Future<String> responseText;

  const DisplayPictureScreen({
    super.key,
    required this.imagePath,
    required this.responseText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Displaying the Result',
          style: TextStyle(
              fontFamily: "rox", fontSize: 50, color: Color(0xFF1A4547)),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/background.png"),
                fit: BoxFit.cover)),
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 100,
              ),
              SizedBox(height: 200, child: Image.file(File(imagePath))),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: FutureBuilder<String>(
                  future: responseText,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      // If the future is complete, display the responseText.
                      return Text(
                        snapshot.data!,
                        style: GoogleFonts.getFont('Lato',
                            textStyle: const TextStyle(fontSize: 25)),
                      );
                    } else {
                      // Otherwise, display a loading indicator.
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
