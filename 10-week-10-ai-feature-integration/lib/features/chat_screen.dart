import 'dart:async';
import 'package:flutter/material.dart';
import '../ai/ai_service.dart';

/// Model pesan dalam ruang percakapan
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class ChatScreen extends StatefulWidget {
  final AiService? aiService;

  const ChatScreen({super.key, this.aiService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final AiService _aiService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  StreamSubscription<String>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiService();
    // Pesan sambutan awal dari AI Assistant
    _messages.add(
      ChatMessage(
        text:
            'Halo! Saya Campus AI Assistant. Ada yang bisa saya bantu seputar perkuliahan atau catatan kampus?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final query = presetText ?? _textController.text.trim();
    if (query.isEmpty || _isLoading) return;

    if (presetText == null) {
      _textController.clear();
    }

    // Tambah pesan user ke list
    setState(() {
      _messages.add(
        ChatMessage(
          text: query,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    // Tambah placeholder respons AI yang akan di-stream
    final aiIndex = _messages.length;
    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Sedang mengetik...',
          isUser: false,
          timestamp: DateTime.now(),
          isStreaming: true,
        ),
      );
    });
    _scrollToBottom();

    try {
      // Mendengarkan streaming chunk respons dari AI
      _streamSubscription = _aiService.askStream(query).listen(
        (chunk) {
          setState(() {
            _messages[aiIndex] = ChatMessage(
              text: chunk,
              isUser: false,
              timestamp: DateTime.now(),
              isStreaming: true,
            );
          });
          _scrollToBottom();
        },
        onDone: () {
          setState(() {
            _messages[aiIndex] = _messages[aiIndex].copyWith(isStreaming: false);
            _isLoading = false;
          });
          _scrollToBottom();
        },
        onError: (err) {
          _handleError(err, aiIndex, query);
        },
      );
    } catch (e) {
      _handleError(e, aiIndex, query);
    }
  }

  void _handleError(dynamic error, int aiIndex, String originalQuery) {
    setState(() {
      _isLoading = false;
      _messages[aiIndex] = ChatMessage(
        text: 'Maaf, terjadi gangguan saat menghubungi layanan AI.',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: false,
      );
    });

    // Menampilkan Fallback AlertDialog sesuai instruksi jobsheet
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Layanan AI Sibuk'),
          ],
        ),
        content: Text(
          'Gagal memproses "$originalQuery".\n\n'
          'Penyebab: ${error.toString().replaceAll("Exception: ", "")}\n\n'
          'Silakan coba lagi nanti atau gunakan mode offline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            onPressed: () {
              Navigator.pop(ctx);
              _sendMessage(originalQuery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showApiKeyDialog() async {
    final currentKey = await _aiService.getApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengaturan API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Google Gemini API Key Anda. Kunci akan disimpan aman menggunakan FlutterSecureStorage.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _aiService.saveApiKey(controller.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API Key berhasil disimpan dengan aman!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _simulateOcrFeature() async {
    setState(() => _isLoading = true);
    try {
      final ocrText = await _aiService.recognizeText(null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ocrText),
            duration: const Duration(seconds: 4),
          ),
        );
        _sendMessage('Tolong jelaskan data dari hasil OCR ini: $ocrText');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal OCR: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _simulateSpeechToText() async {
    setState(() => _isLoading = true);
    try {
      final sttText = await _aiService.speechToText(null);
      _textController.text = sttText.replaceAll('Transkripsi: ', '');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal Speech-to-Text: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campus AI Chat', style: TextStyle(fontSize: 18)),
            Text(
              'Gemini Pro & Flash Integration',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            tooltip: 'Atur API Key',
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Privasi & Keamanan Data (Warning data sensitif)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Privasi terjaga: Jangan kirim NIK, telepon, atau kata sandi. Data sensitif disaring otomatis.',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),

          // Daftar Pesan Chat
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Indikator Loading saat menunggu respons
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI sedang merespons...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Chip Pertanyaan Cepat (Quick Suggestions)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildQuickChip('Jadwal KRS Semester Ini'),
                _buildQuickChip('Tips Belajar Flutter Clean Architecture'),
                _buildQuickChip('Cara Buat Ringkasan Catatan'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Area Input Chat
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  // Tombol OCR (Image / Scan)
                  IconButton(
                    icon: const Icon(Icons.document_scanner),
                    tooltip: 'Scan Dokumen (OCR)',
                    onPressed: _isLoading ? null : _simulateOcrFeature,
                  ),
                  // Tombol Speech to Text (Voice)
                  IconButton(
                    icon: const Icon(Icons.mic),
                    tooltip: 'Input Suara (STT)',
                    onPressed: _isLoading ? null : _simulateSpeechToText,
                  ),
                  // Text Field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Tanyakan sesuatu ke AI...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  // Tombol Kirim
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).primaryColor,
                    onPressed: _isLoading ? null : () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: _isLoading ? null : () => _sendMessage(label),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isUser;
    final theme = Theme.of(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMe ? Icons.person : Icons.auto_awesome,
                  size: 14,
                  color: isMe ? Colors.blue.shade800 : Colors.purple.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  isMe ? 'Anda' : 'Campus AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.blue.shade800 : Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              msg.text,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
