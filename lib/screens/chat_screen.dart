import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List messages = [];
  final scrollController = ScrollController();
  final controller = TextEditingController();

  Future<void> loadMessages() async {
    final auth = context.read<AuthProvider>();
    final data = await ApiService.getMessages(auth.token!, widget.userId);

    setState(() {
      messages = data.reversed.toList();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      scrollController.jumpTo(0);
    });
  }

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                widget.userName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.userName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                final isMe = msg["sender_id"] != widget.userId;
                final raw = msg["timestamp"];

                final date = raw != null
                    ? DateTime.parse(raw.replaceFirst(" ", "T") + "Z").toLocal()
                    : null;

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg["content"],
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date != null
                              ? "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}"
                              : "",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(controller: controller),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  await ApiService.sendMessage(
                    auth.token!,
                    widget.userId,
                    controller.text,
                  );

                  controller.clear();
                  loadMessages();
                },
              )
            ],
          )
        ],
      ),
    );
  }
}
