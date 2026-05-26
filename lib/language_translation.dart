import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:country_flags/country_flags.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class LanguageTranslationPage extends StatefulWidget {
  const LanguageTranslationPage({super.key});

  @override
  State<LanguageTranslationPage> createState() => _LanguageTranslationPageState();
}

class LanguageInfo {
  final String languageCode;
  final String countryCode;
  final String voiceName;

  LanguageInfo(this.languageCode, this.countryCode, this.voiceName);
}

class _LanguageTranslationPageState extends State<LanguageTranslationPage> {
  final Map<String, LanguageInfo> languages = {
    'Afrikaans': LanguageInfo('af', 'ZA', 'af-ZA-Standard-A'),
    'Albanian': LanguageInfo('sq', 'AL', 'sq-AL-Standard-A'), // Example voice
    'Arabic': LanguageInfo('ar', 'AE', 'ar-XA-Standard-A'),
    'Armenian': LanguageInfo('hy', 'AM', 'hy-AM-Standard-A'), // Example voice
    'Bengali': LanguageInfo('bn', 'BD', 'bn-IN-Wavenet-A'),
    'Bulgarian': LanguageInfo('bg', 'BG', 'bg-BG-Standard-A'),
    'Catalan': LanguageInfo('ca', 'ES', 'ca-ES-Standard-A'),
    'Chinese (Simplified)': LanguageInfo('zh-CN', 'CN', 'yue-HK-Standard-A'),
    'Chinese (Traditional)': LanguageInfo('zh-TW', 'TW', 'yue-HK-Standard-C'),
    'Czech': LanguageInfo('cs', 'CZ', 'cs-CZ-Wavenet-A'),
    'Danish': LanguageInfo('da', 'DK', 'da-DK-Wavenet-A'),
    'Dutch': LanguageInfo('nl', 'NL', 'nl-NL-Wavenet-A'),
    'English': LanguageInfo('en-US', 'US', 'en-US-Wavenet-A'),
    'Finnish': LanguageInfo('fi', 'FI', 'fi-FI-Wavenet-A'),
    'French': LanguageInfo('fr-FR', 'FR', 'fr-FR-Wavenet-A'),
    'German': LanguageInfo('de', 'DE', 'de-DE-Wavenet-A'),
    'Greek': LanguageInfo('el', 'GR', 'el-GR-Wavenet-A'),
    'Hebrew': LanguageInfo('he', 'IL', 'he-IL-Wavenet-A'),
    'Hindi': LanguageInfo('hi-IN', 'IN', 'hi-IN-Wavenet-A'),
    'Hungarian': LanguageInfo('hu', 'HU', 'hu-HU-Wavenet-A'),
    'Indonesian': LanguageInfo('id', 'ID', 'id-ID-Wavenet-A'),
    'Italian': LanguageInfo('it', 'IT', 'it-IT-Wavenet-A'),
    'Japanese': LanguageInfo('ja-JP', 'JP', 'ja-JP-Wavenet-A'),
    'Korean': LanguageInfo('ko-KR', 'KR', 'ko-KR-Wavenet-A'),
    'Norwegian': LanguageInfo('no', 'NO', 'nb-NO-Wavenet-A'),
    'Polish': LanguageInfo('pl', 'PL', 'pl-PL-Wavenet-A'),
    'Portuguese': LanguageInfo('pt-PT', 'PT', 'pt-PT-Wavenet-A'),
    'Portuguese (Brazilian)': LanguageInfo('pt-BR', 'BR', 'pt-BR-Wavenet-A'),
    'Russian': LanguageInfo('ru', 'RU', 'ru-RU-Wavenet-A'),
    'Slovak': LanguageInfo('sk', 'SK', 'sk-SK-Wavenet-A'),
    'Spanish': LanguageInfo('es-ES', 'ES', 'es-ES-Wavenet-A'),
    'Swedish': LanguageInfo('sv', 'SE', 'sv-SE-Wavenet-A'),
    'Turkish': LanguageInfo('tr', 'TR', 'tr-TR-Wavenet-A'),
    'Ukrainian': LanguageInfo('uk', 'UA', 'uk-UA-Wavenet-A'),
    'Vietnamese': LanguageInfo('vi-VN', 'VN', 'vi-VN-Wavenet-A'),
  };

  final List<String> translationTypes = [
    'General Conversation',
    'Business',
    'Technical',
    'Medical',
    'Legal',
    'Slang',
    'Academic',
  ];

  final Map<String, String> contextInstructions = {
    'General Conversation':
    "Use a natural, conversational tone, as if between friends. Prioritize simple vocabulary, contractions, and informal phrasing for an easygoing, friendly feel.",

    'Business':
    "Adopt a professional and formal tone suitable for workplace communication, such as emails, presentations, and meetings. Avoid technical jargon unless necessary and use clear, polite, and concise language appropriate for a corporate environment.",

    'Technical':
    "Use precise technical language and industry-specific terminology, suitable for professionals in fields such as engineering, IT, and technology. Ensure clarity by using structured sentences to explain complex concepts accurately.",

    'Medical':
    "Use formal and precise medical terminology appropriate for healthcare professionals or patient communications. Maintain a respectful, sensitive tone, adhering to clinical standards and terminology for clarity and accuracy in medical contexts.",

    'Legal':
    "Use a formal, structured tone suitable for legal documents like contracts and agreements. Include appropriate legal terminology and phrasing to minimize ambiguity and ensure enforceability. Maintain a neutral, objective tone throughout.",

    'Slang':
    "Use contemporary slang and casual expressions, prioritizing informal language and idiomatic phrases that reflect current trends. Aim for a tone that feels authentic and relaxed, as commonly used in social settings among friends.",

    'Academic':
    "Use a scholarly and formal tone suitable for academic writing, such as research papers or lectures. Employ complex sentence structures and precise vocabulary, focusing on clarity, formality, and coherence to convey authority and professionalism.",
  };




  String originLanguage = "From";
  String destinationLanguage = "To";
  String selectedTranslationType = 'General Conversation';
  String output = "";
  final TextEditingController languageController = TextEditingController();
  String apiKey = 'AIzaSyDpZG1euMbn06BwIgK4Uptwurv-6luvb_w'; // Replace with your Google API key
  bool isListening = false;

  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    checkPermissions();
    OpenAI.apiKey = "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"; // Replace with your OpenAI API key
    _recorder = FlutterSoundRecorder();
    initRecorder();
  }

  void checkPermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> initRecorder() async {
    await _recorder!.openRecorder();
    PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) throw 'Microphone permission not granted';
  }

  Future<void> recordAudio(String filePath) async {
    try {
      setState(() {
        _isRecording = true;
      });

      await _recorder!.startRecorder(
        toFile: filePath,
        codec: Codec.pcm16WAV,
      );

      // Duration for the recording session (5 seconds in this example)
      await Future.delayed(Duration(seconds: 5));

      await _recorder!.stopRecorder();
    } catch (e) {
      print("Error during recording: $e");
    } finally {
      setState(() {
        _isRecording = false;
      });
    }
  }
  Future<void> startGoogleSpeechToText() async {
    setState(() {
      isListening = true;
    });

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/recorded_audio.wav';

    // Start recording
    await recordAudio(filePath);

    // Check if recording exists and process it
    if (File(filePath).existsSync()) {
      File audioFile = File(filePath);
      String transcript = await transcribeAudioGoogleCloud(audioFile, languages[originLanguage]!.languageCode);
      setState(() {
        languageController.text = transcript;
        isListening = false;
      });
    } else {
      setState(() {
        isListening = false;
      });
    }
  }

  Future<String> transcribeAudioGoogleCloud(File audioFile, String languageCode) async {
    final url = Uri.parse('https://speech.googleapis.com/v1/speech:recognize?key=$apiKey');
    final audioBytes = audioFile.readAsBytesSync();
    final requestPayload = {
      'config': {
        'encoding': 'LINEAR16',
        'sampleRateHertz': 16000,
        'languageCode': languageCode,
      },
      'audio': { 'content': base64Encode(audioBytes) },
    };

    final headers = {'Content-Type': 'application/json'};
    final response = await http.post(url, headers: headers, body: jsonEncode(requestPayload));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData.containsKey('results')) {
        return responseData['results'][0]['alternatives'][0]['transcript'];
      } else {
        return "No speech recognized.";
      }
    } else {
      return "Error: ${response.statusCode} ${response.body}";
    }
  }

  Future<void> generateSpeechGoogleTTS(String text, String languageCode) async {
    final url = Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey');

    String voiceName = languages[destinationLanguage]!.voiceName;

    final requestPayload = {
      'input': { 'text': text },
      'voice': {
        'languageCode': languages[destinationLanguage]!.languageCode,
        'name': voiceName,
      },
      'audioConfig': { 'audioEncoding': 'MP3' },
    };

    final headers = { 'Content-Type': 'application/json' };
    final response = await http.post(url, headers: headers, body: jsonEncode(requestPayload));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData.containsKey('audioContent')) {
        Uint8List audioBytes = base64Decode(responseData['audioContent']);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/output.mp3');
        await file.writeAsBytes(audioBytes);

        AudioPlayer player = AudioPlayer();
        await player.play(DeviceFileSource(file.path));
      }
    } else {
      setState(() { output = "Error generating speech: ${response.body}"; });
    }
  }

  Future<void> translate(String input) async {
    if (originLanguage == "From" || destinationLanguage == "To" || input.isEmpty) {
      setState(() {
        output = "Please select languages, translation type, and enter text to translate.";
      });
      return;
    }

    // Get the context instruction based on the selected translation type
    String contextInstruction = contextInstructions[selectedTranslationType] ?? "Translate the text appropriately.";
    String prompt = '$contextInstruction Translate from $originLanguage to $destinationLanguage: $input';

    try {
      // Wrapping prompt in OpenAIChatCompletionChoiceMessageContentItemModel and sending as a list
      final chat = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        temperature: 0,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
            ],
          ),
        ],
      );

      final message = chat.choices.first.message;

      // Ensure `message.content` is handled correctly as a list
      if (message.content != null && message.content is List) {
        final contentList = message.content as List;
        setState(() {
          output = contentList.map((item) => item.text).join(" ");
        });
      } else if (message.content != null && message.content is String) {
        setState(() {
          output = message.content as String;
        });
      } else {
        setState(() {
          output = "No translation found.";
        });
      }

      if (output.isNotEmpty) {
        generateSpeechGoogleTTS(output, languages[destinationLanguage]!.languageCode);
      }

    } catch (e) {
      setState(() {
        output = "Translation failed: ${e.toString()}";
      });
    }
  }


  void swapLanguages() {
    setState(() {
      String temp = originLanguage;
      originLanguage = destinationLanguage;
      destinationLanguage = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Language Translator"),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFB300),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 40),
              // Language Selection Row
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _buildLanguageDropdown(originLanguage, (value) {
                            setState(() {
                              originLanguage = value!;
                            });
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: swapLanguages,
                          icon: const Icon(Icons.swap_horiz, color: Color(0xFFFFB300), size: 24),
                          tooltip: "Swap languages",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _buildLanguageDropdown(destinationLanguage, (value) {
                            setState(() {
                              destinationLanguage = value!;
                            });
                          }),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              // Input TextField
              TextFormField(
                controller: languageController,
                minLines: 5,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Please enter or speak your text...',
                  labelStyle: TextStyle(fontSize: 16, color: Colors.black),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFB300), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFB300), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
// Mic Icon Row
              Center(
                child: IconButton(
                  icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                  onPressed: isListening ? null : startGoogleSpeechToText,
                  color: const Color(0xFFFFB300),
                  iconSize: 50,
                ),
              ),
              const SizedBox(height: 10),
// Controls Row
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE57F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButton<String>(
                      value: selectedTranslationType,
                      items: translationTypes.map((String type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedTranslationType = newValue!;
                        });
                      },
                      underline: Container(),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                    ),
                    onPressed: () => translate(languageController.text.trim()),
                    child: const Text("Translate"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Output TextField
              TextFormField(
                controller: TextEditingController(text: output),
                readOnly: true,
                minLines: 5,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: output.isEmpty ? 'Translation will appear here' : null,
                  labelStyle: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFB300), width: 2),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFB300), width: 2),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              // Action Buttons
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                    ),
                    onPressed: () {
                      if (output.isNotEmpty) {
                        generateSpeechGoogleTTS(output, destinationLanguage);
                      }
                    },
                    child: const Text("Play Translation"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                    ),
                    onPressed: () {
                      setState(() {
                        languageController.clear();
                        output = '';
                      });
                    },
                    child: const Text("Clear"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(String currentLanguage, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      hint: Row(
        children: [
          if (languages[currentLanguage] != null)
            CountryFlag.fromCountryCode(
              languages[currentLanguage]!.countryCode,
              height: 20,
              width: 20,
            ),
          const SizedBox(width: 8),
          Text(currentLanguage, style: const TextStyle(color: Colors.black)),
        ],
      ),
      dropdownColor: Color(0xFFFFE57F),
      items: languages.keys.map((String languageName) {
        return DropdownMenuItem(
          value: languageName,
          child: Row(
            children: [
              CountryFlag.fromCountryCode(
                languages[languageName]!.countryCode,
                height: 20,
                width: 20,
              ),
              const SizedBox(width: 8),
              Text(languageName),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}