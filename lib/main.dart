import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String text = "";
  File image;

  final String finalKey = "AIzaSyASVSN-ZVkFuw1Fp70APGxgNM-jD1IY-KI";

  final picker = ImagePicker();

  bool isLoaded = false;

  Future<File> pickImage() async {
    try {
      final pickedImage = await picker.getImage(source: ImageSource.gallery);
      return File(pickedImage.path);
    } catch (e) {}
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
    isLoaded = true;
  }

  Future<String> process(File image) async {
    var output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 2,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5);

    return output[0]["label"];
  }

  Future visionAPICall(File _image) async {
    List<int> imageBytes = _image.readAsBytesSync();
    print(imageBytes);
    String base64Image = base64Encode(imageBytes);
    var request_str = {
      "requests": [
        {
          "image": {"content": "$base64Image"},
          "features": [
            {"type": "LABEL_DETECTION", "maxResults": 1}
          ]
        }
      ]
    };
    var url = 'https://vision.googleapis.com/v1/images:annotate?key=$finalKey';
    var response = await http.post(url, body: json.encode(request_str));
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    var responseJson = json.decode(response.body);
    var str ='${responseJson["responses"][0]["labelAnnotations"][0]["description"]}:${responseJson["responses"][0]["labelAnnotations"][0]["score"].toStringAsFixed(3)}';
    setState(() {
      text = str;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.photo),
          tooltip: "Pick Image",
          onPressed: () async {
            try {
              if(!isLoaded){
              await loadModel();
              }

              image = await pickImage();

              if (image != null) {
                // visionAPICall(image);
                String ans = await process(image);
                print(ans);
                setState(() {
                text=ans;
                });
              }
            } catch (e) {}
          },
        ),
        body: SafeArea(
          child: Container(
            child: Text(text),
          ),
        ),
      ),
    );
  }
}
