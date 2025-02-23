import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(SmartVoiceAssistantApp());
}

class SmartVoiceAssistantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Voice Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VoiceAssistantScreen(),
    );
  }
}

class VoiceAssistantScreen extends StatefulWidget {
  @override
  _VoiceAssistantScreenState createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcribedText = "";
  List<String> _extractedActions = [];
  List<String> _extractedDates = [];
  
  final url = "http://172.22.133.208:5000/process"; // Replace with your PC's IP


  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
  bool available = await _speech.initialize();
  if (available) {
    setState(() => _isListening = true);
    _speech.listen(onResult: (result) async {
      setState(() => _transcribedText = result.recognizedWords);
      
      // Extract actions from backend
      Map<String, dynamic> extractedData = await extractActions(_transcribedText);
      
      setState(() {
        _extractedActions = List<String>.from(extractedData['tasks'] ?? []);
        _extractedDates = List<String>.from(extractedData['dates'] ?? []);
      });
    });
  }
}


  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<Map<String, dynamic>> extractActions(String text) async {
    final response = await http.post(
      Uri.parse(url), // Replace with local IP
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to process text");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart Voice Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _transcribedText,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 20),
                    Text("Extracted Actions:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._extractedActions.map((action) => Text("- $action")),
                    SizedBox(height: 10),
                    Text("Extracted Dates:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._extractedDates.map((date) => Text("- $date")),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            FloatingActionButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Icon(_isListening ? Icons.mic_off : Icons.mic),
            ),
          ],
        ),
      ),
    );
  }
}
