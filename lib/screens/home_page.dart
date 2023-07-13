import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:see_signal/services/api_service.dart';
import 'package:see_signal/utils/datos.dart';

import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService apiService =
      // Acceso Personal de nuestra base de datos
      ApiService(username: '[user]', password: '[pass]');

  final FlutterTts flutterTts = FlutterTts();
  SpeechToText speech = SpeechToText();
  String lastWords = '';
  String base64Image = Constantes.foto;

  bool isListening = false;
  final AudioCache audioCache = AudioCache();
  bool isSpeaking = false;

  final optionsMap = {
    'detecta rostro': [
      'DetectarRostro',
      'Se detectará los rostro de la imagen',
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
    'analiza objeto': [
      'AnalizarObjetos',
      'Se analizará los objetos de la imagen',
    ],
  };

  CameraController? cameraController;
  late List<CameraDescription> cameras;

  @override
  void initState() {
    super.initState();
    _start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Gracias por descargar la App'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Esta aplicación fue diseñada por 2 estudiantes de la Universidad Privada del Norte, Perú.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Siéntase libre de utilizar todas las funciones de la aplicación sin problemas.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              InkWell(
                child: const Text(
                  'Link del codigo en Github con los metodos explicados',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTap: () {
                  // ignore: deprecated_member_use
                  launch('https://github.com/xstefano/vision_auditiva_flutter');
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    });
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.max,
    );
    await cameraController!.initialize();
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage('es-ES');
    await flutterTts.setPitch(0.9);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return _speak('¡Es necesario acceder al micrófono!');
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
    await _speak('Hola, bienvenido a See Signal');
    await _requestMicrophonePermission();
    _initializeCamera();
    await _requestCameraPermission();
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

  Future<void> takePicture() async {
    XFile? picture = await cameraController!.takePicture();
    List<int> bytes = await picture.readAsBytes();
    setState(() {
      base64Image = base64Encode(bytes);
    });
    await apiService.sendImage(base64Image, "image");
  }

  Future<void> resultListener(SpeechRecognitionResult result) async {
    if (!result.finalResult) return;

    final recognizedWords =
        removeDiacritics(result.recognizedWords).toLowerCase();

    if (recognizedWords.contains("visión")) {
      final remainingText = recognizedWords.replaceAll(RegExp(r'visión'), '');
      final response = await apiService.getResponse(remainingText.trim());
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
      final response = await apiService.getDetectarRostro();
      _speak(response);
    }
  }

  Future<void> getResponseAzure(List<String> action) async {
    if (action[0] == "DescribirImagen") {
      final response = await apiService.getImageDescription();
      _speak(response);
    } else if (action[0] == "LeerTexto") {
      final response = await apiService.getImageTexto();
      _speak(response);
    } else if (action[0] == "AnalizarObjetos") {
      final response = await apiService.getAnalizarObjetos();
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

  void playSound() {
    audioCache.play('sound.mp3');
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
                height: 250.0,
                // ignore: unnecessary_null_comparison
                child: base64Image != null
                    ? Image.memory(
                        base64Decode(base64Image),
                        fit: BoxFit.cover,
                      )
                    : Container(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: FractionallySizedBox(
              widthFactor: 0.9,
              heightFactor: 0.5,
              child: Container(
                margin:
                    const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 4.0),
                child: FloatingActionButton(
                  onPressed: () {
                    playSound();
                    takePicture();
                  },
                  backgroundColor: const Color.fromARGB(255, 204, 86, 40),
                  child: const Icon(Icons.photo),
                ),
              ),
            ),
          ),
          Flexible(
            child: FractionallySizedBox(
              widthFactor: 0.9,
              heightFactor: 0.5,
              child: Container(
                margin:
                    const EdgeInsets.only(bottom: 16.0, left: 4.0, right: 16.0),
                child: GestureDetector(
                  onTapDown: (_) {
                    flutterTts.stop();
                    playSound();
                    startListening();
                  },
                  onTapUp: (_) {
                    flutterTts.stop();
                  },
                  child: FloatingActionButton(
                    onPressed: () {},
                    backgroundColor: isListening ? Colors.green : Colors.green,
                    child: const Icon(Icons.mic),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
