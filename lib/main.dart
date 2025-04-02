// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'api.dart';

const MODELS = {
  1: "gpt-4o",
  2: "gpt-4o-mini",
  3: "gemini-2-0-flash-thinking",
  4: "claude-3.7-sonnet",
  5: "deepseek-r1",
  6: "grok-3-r1",
  7: "evil"
};

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Gossip',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
        ),
        fontFamily: 'Langar', // Используем шрифт из Windows 11 стиля
      ),
      home: const ChatScreen(),
    );
  }
}

// Модель сообщения
class Message {
  final String text;
  final bool isUser;
  const Message({required this.text, required this.isUser});
}

// Экран чата
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  String _selectedModel = 'gpt-4o';
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _messages.insert(0, Message(text: _controller.text, isUser: true));
    });
    final userInput = _controller.text;
    _controller.clear();

    try {
      final response = await sendQuery(userInput, _selectedModel);
      setState(() {
        _messages.insert(0, Message(text: response, isUser: false));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(0);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Gossip'),
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          // Панель ввода
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Выбор модели
                DropdownButton<String>(
                  value: _selectedModel,
                  items: MODELS.values.map((model) {
                    return DropdownMenuItem(
                      value: model,
                      child: Text(model),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedModel = value);
                    }
                  },
                ),
                const SizedBox(width: 8),
                // Кнопка прикрепления (заглушка)
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {}, // Ничего не делает
                ),
                // Поле ввода
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Кнопка отправки
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Виджет сообщения
class MessageBubble extends StatelessWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: MarkdownBody(
          data: message.text,
          selectable: true,
          builders: {
            'latex': LatexElementBuilder(
              textStyle: const TextStyle(fontWeight: FontWeight.w100),
              textScaleFactor: 1.2,
            ),
          },
          extensionSet: md.ExtensionSet(
            [LatexBlockSyntax()],
            [LatexInlineSyntax()],
          ),
        ),
      ),
    );
  }
}