import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../models/chat_history_model.dart';
import '../../../services/chat_history_service.dart';


class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<ChatHistoryMessage> chatHistory = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    setState(() => isLoading = true);
    try {
      final history = await ChatHistoryService.getChatHistory();
      setState(() {
        chatHistory = history;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('Error', 'Failed to load chat history');
    }
  }

  List<ChatHistoryMessage> get filteredMessages {
    if (searchQuery.isEmpty) return chatHistory;
    return chatHistory
        .where((msg) => msg.text.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Chat History',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportHistory();
                  break;
                case 'clear':
                  _showClearConfirmation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download, color: Colors.blue),
                  title: Text('Export Chat'),
                  subtitle: Text('Copy all messages'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('Clear History'),
                  subtitle: Text('Delete all messages'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Searching: "$searchQuery"',
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => searchQuery = ''),
                  ),
                ],
              ),
            ),

          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '${filteredMessages.length} messages',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Chat history list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMessages.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadChatHistory,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isNotEmpty ? Icons.search_off : Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty ? 'No messages found' : 'No chat history yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Start chatting to see your message history here',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final groupedMessages = _groupMessagesByDate(filteredMessages);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: groupedMessages.length,
      itemBuilder: (context, index) {
        final entry = groupedMessages.entries.elementAt(index);
        final date = entry.key;
        final messages = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formatDateHeader(date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),

            // Messages for this date
            ...messages.map((message) => _buildMessageCard(message)),
          ],
        );
      },
    );
  }

  Widget _buildMessageCard(ChatHistoryMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showMessageDetails(message),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.blue.shade100 : Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    message.isUser ? Icons.person : Icons.smart_toy,
                    size: 16,
                    color: message.isUser ? Colors.blue.shade700 : Colors.purple.shade700,
                  ),
                ),
                const SizedBox(width: 12),

                // Message content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sender and time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            message.isUser ? 'You' : 'HelpAI',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: message.isUser ? Colors.blue.shade700 : Colors.purple.shade700,
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(message.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Message preview
                      Text(
                        message.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Copy button
                IconButton(
                  icon: Icon(Icons.copy, size: 16, color: Colors.grey.shade600),
                  onPressed: () => _copyMessage(message),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<DateTime, List<ChatHistoryMessage>> _groupMessagesByDate(List<ChatHistoryMessage> messages) {
    final Map<DateTime, List<ChatHistoryMessage>> grouped = {};

    for (final message in messages) {
      final date = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );

      grouped.putIfAbsent(date, () => []).add(message);
    }

    return grouped;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Messages'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => searchQuery = _searchController.text);
              _searchController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showMessageDetails(ChatHistoryMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              message.isUser ? Icons.person : Icons.smart_toy,
              color: message.isUser ? Colors.blue : Colors.purple,
            ),
            const SizedBox(width: 8),
            Text(message.isUser ? 'You' : 'HelpAI'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('MMM dd, yyyy • HH:mm').format(message.timestamp),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(message.text),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _copyMessage(message),
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _copyMessage(ChatHistoryMessage message) {
    Clipboard.setData(ClipboardData(text: message.text));
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

  void _exportHistory() {
    if (filteredMessages.isEmpty) {
      Get.showSnackbar(
        GetSnackBar(
          title: "No Messages",
          message: "No messages to export",
          backgroundColor: Colors.orange,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        ),
      );
      return;
    }

    final exportText = filteredMessages
        .reversed
        .map((msg) {
      final time = DateFormat('yyyy-MM-dd HH:mm').format(msg.timestamp);
      return "[$time] ${msg.isUser ? 'You' : 'HelpAI'}: ${msg.text}";
    }).join('\n\n');

    Clipboard.setData(ClipboardData(text: exportText));
    Get.showSnackbar(
      GetSnackBar(
        title: "Exported!",
        message: "Chat history copied to clipboard",
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to delete all chat history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ChatHistoryService.clearChatHistory();
              await _loadChatHistory();
              Get.showSnackbar(
                GetSnackBar(
                  title: "Cleared!",
                  message: "Chat history has been cleared",
                  backgroundColor: Colors.red,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 8,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
