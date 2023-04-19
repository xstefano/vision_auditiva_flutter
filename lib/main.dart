import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'package:logger/logger.dart';
import 'package:camera/camera.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'SeeSignal Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterTts flutterTts = FlutterTts();
  SpeechToText speech = SpeechToText();
  final logger = Logger();
  String lastWords = '';
  String base64Image = '';

  CameraController? cameraController;
  late List<CameraDescription> cameras;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(
      cameras[0], // You can select the camera that you want to use here
      ResolutionPreset.veryHigh,
    );
    await cameraController!.initialize();
  }

  Future<void> takePicture() async {
    XFile? picture = await cameraController!.takePicture();
    List<int> bytes = await picture.readAsBytes();
    base64Image = base64Encode(bytes);
    sendImageToAPI("TomaFoto");
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage('es-ES');
    await flutterTts.setPitch(1.1);
    await flutterTts.setSpeechRate(0.9);
    await flutterTts.speak(text);
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return _speak('¡Es necesario acceder al microfono');
    }
    return _speak('¡Permiso de micrófono concedido!');
  }

  Future<void> _start() async {
    await flutterTts.awaitSpeakCompletion(true);
    await _speak('Hola, Bienvenido a See Signal');
    await _requestMicrophonePermission();
    _initializeCamera();
  }

  Future<void> startListening() async {
    lastWords = '';
    bool isAvailable = await speech.initialize();
    if (isAvailable) {
      await speech.listen(
        onResult: resultListener,
        localeId: 'es_CL',
      );
    }
  }

  void resultListener(SpeechRecognitionResult result) {
    // ignore: avoid_print
    if (result.finalResult) {
      logger.i(
          'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
      setState(() {
        lastWords = '${result.recognizedWords} - ${result.finalResult}';
      });

      if (removeDiacritics(result.recognizedWords.toLowerCase())
          .contains("hola aplicacion")) {
        _speak('Hola usuario');
      }

      if (removeDiacritics(result.recognizedWords.toLowerCase())
          .contains("toma foto")) {
        _speak('La foto se tomara');
        takePicture();
        _speak('Se ha tomado la foto');
      }
    }
  }

  String removeDiacritics(String str) {
    var withDia =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }

    return str;
  }

  void sendImageToAPI(String filename) async {
    Uri apiUrl = Uri.parse("https://apivideofetcher.azurewebsites.net/Image");
    Map<String, String> headers = {"Content-Type": "application/json"};

    String jsonBody =
        jsonEncode({"imageBase64": base64Image, "filename": filename});

    http.Response response =
        await http.post(apiUrl, headers: headers, body: jsonBody);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: startListening,
        backgroundColor: null,
        child: const Icon(Icons.mic),
      ),
    );
  }
}
