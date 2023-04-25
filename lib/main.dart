import 'dart:async';
import 'dart:convert';
import 'api_service.dart';

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

  final optionsMap = {
    'analiza objeto': [
      'AnalizarObjetos',
      'Se analizará los objetos de la imagen',
    ],
    'detecta rostro': [
      'DetectarRostro',
      'Se detectará el rostro de la imagen',
    ],
    'analiza rostro': [
      'AnalizarRostro',
      'Se analizará los rostros de la imagen',
    ],
  };

  final optionsMap2 = {
    'describe imagen': [
      'DescribirImagen',
      'La imagen se va a describir espere unos segundos para que finalice',
    ],
    'lee texto': [
      'LeerTexto',
      'Se leera el texto de la imagen',
    ],
  };

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
      cameras[0],
      ResolutionPreset.max,
    );
    await cameraController!.initialize();
  }

  Future<void> takePicture() async {
    XFile? picture = await cameraController!.takePicture();
    List<int> bytes = await picture.readAsBytes();
    base64Image = base64Encode(bytes);
    await ApiService.sendImage(base64Image, "image");
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage('es-ES');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.7);
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
      takePicture();
      await speech.listen(
        onResult: resultListener,
        localeId: 'es_CL',
      );
    }
  }

  Future<void> resultListener(SpeechRecognitionResult result) async {
    if (result.finalResult) {
      logger.i(
          'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
      setState(() {
        lastWords = removeDiacritics(result.recognizedWords).toLowerCase();
      });

      // Verificar si las palabras reconocidas están en el mapa de opciones
      final option = optionsMap.keys.firstWhere(
        (key) => key.split(' ').every((word) => lastWords.contains(word)),
        orElse: () => '',
      );

      final option2 = optionsMap2.keys.firstWhere(
        (key) => key.split(' ').every((word) => lastWords.contains(word)),
        orElse: () => '',
      );

      // Si la opción existe, realizar la acción correspondiente
      if (option.isNotEmpty) {
        final action = optionsMap[option]!;
        takePicture();
        await ApiService.sendRequest(action[0]);
        _speak(action[1]);
        await Future.delayed(const Duration(seconds: 5));
        final lastResponse = await ApiService.getLastResponse();
        _speak(lastResponse);
      }
      if (option2.isNotEmpty) {
        String response = await ApiService.getImageDescription();
        _speak(response);
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
