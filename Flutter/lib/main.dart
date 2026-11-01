import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'notebooklm_api.dart';
import 'overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SkyOSAssistantApp());
}

class SkyOSAssistantApp extends StatelessWidget {
  const SkyOSAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyOS Fernbedienung',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF3B82F6),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF8B5CF6),
        ),
      ),
      home: const MainAssistantScreen(),
    );
  }
}

class MainAssistantScreen extends StatefulWidget {
  const MainAssistantScreen({super.key});

  @override
  State<MainAssistantScreen> createState() => _MainAssistantScreenState();
}

enum AppMode {
  chatNotebooks,
  overlayAssistant,
  avatarStreaming,
  socialMediaStudio,
  codeEditor,
}

class MessageItem {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  MessageItem({required this.text, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class _MainAssistantScreenState extends State<MainAssistantScreen> {
  AppMode _currentMode = AppMode.chatNotebooks;
  final TextEditingController _messageController = TextEditingController();
  final List<MessageItem> _messages = [];
  
  late NotebookLMApiClient _apiClient;
  late stt.SpeechToText _speech;
  late FlutterTts _tts;

  bool _isListening = false;
  bool _isLoading = false;
  bool _isOverlayActive = false;
  String _selectedNotebookId = "default_notebook";

  @override
  void initState() {
    super.initState();
    _apiClient = NotebookLMApiClient(baseUrl: 'http://localhost:8000');
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initVoice();
    _setupOverlayListener();

    _messages.add(MessageItem(
      text: "SkyOS Fernbedienung aktiv. Wähle oben den Modus oder stelle eine Frage zu deinen Notizbüchern.",
      isUser: false,
    ));
  }

  void _initVoice() async {
    await _speech.initialize();
    await _tts.setLanguage("de-DE");
  }

  void _setupOverlayListener() {
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data == "START_LISTEN") {
        _startListening();
      } else if (data == "STOP_LISTEN") {
        _stopListening();
      }
    });
  }

  void _toggleListening() async {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          setState(() {
            _messageController.text = val.recognizedWords;
          });
          if (val.finalResult) {
            _stopListening();
            _sendMessage();
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _speak(String text) async {
    await _tts.speak(text);
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(MessageItem(text: text, isUser: true));
      _messageController.clear();
      _isLoading = true;
    });

    try {
      final response = await _apiClient.askQuestion(
        notebookId: _selectedNotebookId,
        prompt: text,
      );

      final answer = response['answer'] ?? response['response'] ?? "Keine Antwort erhalten.";

      setState(() {
        _messages.add(MessageItem(text: answer, isUser: false));
        _isLoading = false;
      });

      _speak(answer);
    } catch (e) {
      setState(() {
        _messages.add(MessageItem(
          text: "Hinweis: REST Bridge nicht erreichbar. Nachricht lokal verarbeitet.\nDetails: $e",
          isUser: false,
        ));
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleOverlayService() async {
    bool permission = await FlutterOverlayWindow.isPermissionGranted();
    if (!permission) {
      permission = (await FlutterOverlayWindow.requestPermission()) ?? false;
    }

    if (permission) {
      if (_isOverlayActive) {
        await FlutterOverlayWindow.closeOverlay();
        setState(() => _isOverlayActive = false);
      } else {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          overlayTitle: "SkyOS Assistant",
          overlayContent: "Assistent aktiv",
          flag: OverlayFlag.defaultFlag,
          height: 180,
          width: 180,
        );
        setState(() => _isOverlayActive = true);
      }
    }
  }

  String _getModeTitle(AppMode mode) {
    switch (mode) {
      case AppMode.chatNotebooks:
        return "💬 Chat & Notizbücher";
      case AppMode.overlayAssistant:
        return "🎙️ Overlay-Assistent";
      case AppMode.avatarStreaming:
        return "🎭 Avatar & Streaming";
      case AppMode.socialMediaStudio:
        return "📱 Social Media Studio";
      case AppMode.codeEditor:
        return "💻 Code-Bearbeitung";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hub, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AppMode>(
                  value: _currentMode,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  onChanged: (newMode) {
                    if (newMode != null) {
                      setState(() => _currentMode = newMode);
                    }
                  },
                  items: AppMode.values.map((mode) {
                    return DropdownMenuItem<AppMode>(
                      value: mode,
                      child: Text(_getModeTitle(mode)),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isOverlayActive ? Icons.layers_clear : Icons.layers,
              color: _isOverlayActive ? Colors.greenAccent : Colors.grey,
            ),
            tooltip: 'System Overlay Umschalten',
            onPressed: _toggleOverlayService,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBodyContent()),
            _buildBottomInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_currentMode) {
      case AppMode.chatNotebooks:
      case AppMode.overlayAssistant:
        return _buildChatListView();
      case AppMode.avatarStreaming:
        return _buildAvatarStreamingView();
      case AppMode.socialMediaStudio:
        return _buildSocialMediaStudioView();
      case AppMode.codeEditor:
        return _buildCodeEditorView();
    }
  }

  Widget _buildChatListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: msg.isUser
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF334155),
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
                bottomLeft: !msg.isUser ? Radius.zero : const Radius.circular(16),
              ),
            ),
            child: Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarStreamingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 240,
            width: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent, width: 2),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle, size: 80, color: Colors.blueAccent),
                SizedBox(height: 12),
                Text("🎭 Live Avatar WebRTC Stream",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text("Streaming-Status: Verbundens (Sub-100ms Latenz)",
                    style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaStudioView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📱 Social Media Studio & Artefakt-Generierung",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _triggerArtifactGeneration('audio_overview'),
            icon: const Icon(Icons.podcasts),
            label: const Text("Audio-Overview (Podcast) generieren"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.purpleAccent,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _triggerArtifactGeneration('slide_deck'),
            icon: const Icon(Icons.slideshow),
            label: const Text("Präsentations-Deck (Slides) erstellen"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.indigoAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeEditorView() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF020617),
      child: const TextField(
        maxLines: null,
        style: TextStyle(fontFamily: 'monospace', color: Colors.greenAccent),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "// MCP Code-Editor für SkyOS Agenten...",
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  void _triggerArtifactGeneration(String type) async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.generateArtifact(
        notebookId: _selectedNotebookId,
        artifactType: type,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Artefakt erstellt: ${res['status'] ?? 'Erfolgreich'}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildBottomInputField() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.graphic_eq : Icons.mic,
              color: _isListening ? Colors.redAccent : Colors.blueAccent,
            ),
            onPressed: _toggleListening,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Befehl oder Frage eingeben...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }
}
