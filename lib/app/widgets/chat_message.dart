import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.text,
    required this.sender,
    this.timestamp,
  });

  final String text;
  final String sender;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    final bool isUser = sender == "user";
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: isUser
                ? theme.primaryColor.withValues(alpha: 0.1)
                : Colors.grey.shade100,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: Border.all(
                color: isUser
                  ? theme.primaryColor.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message header
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUser ? Icons.person : Icons.smart_toy,
                        size: 16,
                        color: isUser ? theme.primaryColor : Colors.deepPurple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isUser ? "You" : "HelpAI",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isUser ? theme.primaryColor : Colors.deepPurple,
                        ),
                      ),
                      if (timestamp != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(timestamp!),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Copy button
                      InkWell(
                        onTap: () => _copyToClipboard(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Message content
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SelectableText(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    textAlign: isUser ? TextAlign.left : TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    Get.showSnackbar(
      GetSnackBar(
        title: "Copied!",
        message: "Message copied to clipboard",
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    } else {
      return "${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
  }
}
