import 'dart:async';
import 'dart:convert';
import 'api_service.dart';
import 'datos.dart';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Vision Auditiva APP'),
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
  final iniciarApi = ApiService.getLastResponse();
  final FlutterTts flutterTts = FlutterTts();
  SpeechToText speech = SpeechToText();
  String lastWords = '';
  String base64Image = Constantes.foto;

  final optionsMap = {
    'analiza objeto': [
      'AnalizarObjetos',
      'Se analizará los objetos de la imagen',
    ],
    'detecta rostro': [
      'DetectarRostro',
      'Se detectará los rostro de la imagen',
    ],
    'analiza rostro': [
      'AnalizarRostro',
      'Se analizará el rostro de la imagen',
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
    setState(() {
      base64Image = base64Encode(bytes);
    });
    await ApiService.sendImage(base64Image, "image");
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage('es-ES');
    await flutterTts.setPitch(0.9);
    await flutterTts.setSpeechRate(0.6);
    await flutterTts.speak(text);
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return _speak('¡Es necesario acceder al microfono');
    }
    return _speak('¡Permiso de micrófono concedido!');
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      return _speak('¡Es necesario acceder a la cámara!');
    }
    return _speak('¡Permiso de cámara concedido!');
  }

  Future<void> _start() async {
    await flutterTts.awaitSpeakCompletion(true);
    await _speak('Hola, Bienvenido a Vision Auditiva');
    await _requestMicrophonePermission();
    _initializeCamera();
    await _requestCameraPermission();
  }

  Future<void> startListening() async {
    lastWords = '';
    bool isAvailable = await speech.initialize();
    if (isAvailable) {
      await takePicture();
      await speech.listen(
        onResult: resultListener,
        localeId: 'es_CL',
      );
    }
  }

  Future<void> resultListener(SpeechRecognitionResult result) async {
    if (!result.finalResult) return;

    final recognizedWords =
        removeDiacritics(result.recognizedWords).toLowerCase();

    if (recognizedWords.contains("vision")) {
      final remainingText = recognizedWords.replaceAll(RegExp(r'vision'), '');
      final response = await ApiService.getResponse(remainingText.trim());
      _speak(response);
      return;
    }

    String? option;

    option = findOption(optionsMap, recognizedWords);
    if (option != null) {
      final action = optionsMap[option]!;
      await getResponsePython(action);
      return;
    }

    option = findOption(optionsMap2, recognizedWords);
    if (option != null) {
      final action = optionsMap2[option]!;
      await getResponseAzure(action);
      return;
    }

    _speak("No se ha detectado ningún método...");
  }

  String? findOption(Map<String, List<String>> map, String recognizedWords) {
    for (final entry in map.entries) {
      final key = entry.key;
      if (key.split(' ').every((word) => recognizedWords.contains(word))) {
        return key;
      }
    }
    return null;
  }

  Future<void> getResponsePython(List<String> action) async {
    if (action[0] == "DetectarRostro") {
      final response = await ApiService.getDetectarRostro();
      _speak(response);
    }
  }

  Future<void> getResponseAzure(List<String> action) async {
    if (action[0] == "DescribirImagen") {
      final response = await ApiService.getImageDescription();
      _speak(response);
    } else if (action[0] == "LeerTexto") {
      final response = await ApiService.getImageTexto();
      _speak(response);
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 200.0, // Alto fijo de la imagen
                child: base64Image != null
                    ? Image.memory(
                        base64Decode(base64Image),
                        fit: BoxFit.cover,
                      )
                    : Container(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 400.0, // Ancho fijo del botón
              height: 500.0, // Alto fijo del botón
              margin: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton(
                onPressed: () {
                  startListening();
                },
                child: const Icon(Icons.mic),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
