import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OfflineMLService {
  bool _isModelLoaded = false;
  List<String>? _vocabulary;

  // Pre-trained responses database for better offline experience
  final Map<String, List<String>> _knowledgeBase = {
    'science': [
      'Science is the systematic study of the natural world through observation and experimentation.',
      'The scientific method involves hypothesis, experimentation, and analysis.',
      'Physics, chemistry, and biology are major branches of science.'
    ],
    'history': [
      'History is the study of past events and human activities.',
      'Ancient civilizations like Egypt, Greece, and Rome shaped modern society.',
      'The Industrial Revolution changed how people work and live.'
    ],
    'technology': [
      'Technology refers to the application of scientific knowledge for practical purposes.',
      'Artificial Intelligence is revolutionizing many industries.',
      'Mobile computing has transformed how we access information.'
    ],
    'health': [
      'Regular exercise and balanced diet are essential for good health.',
      'Mental health is as important as physical health.',
      'Prevention is better than cure in healthcare.'
    ],
    'education': [
      'Education is the process of acquiring knowledge, skills, and values.',
      'Learning is a lifelong process that extends beyond formal schooling.',
      'Critical thinking and problem-solving are key educational goals.'
    ],
    'environment': [
      'Environmental conservation is crucial for future generations.',
      'Climate change is one of the biggest challenges facing humanity.',
      'Renewable energy sources help reduce environmental impact.'
    ],
    'space': [
      'Space exploration has led to many technological advances.',
      'The universe is vast, containing billions of galaxies.',
      'Mars is the most studied planet for potential human colonization.'
    ],
    'programming': [
      'Programming is the process of creating instructions for computers.',
      'Popular programming languages include Python, Java, and JavaScript.',
      'Software development involves planning, coding, testing, and maintenance.'
    ]
  };

  // Singleton pattern
  static final OfflineMLService _instance = OfflineMLService._internal();
  factory OfflineMLService() => _instance;
  OfflineMLService._internal();

  /// Initialize the service
  Future<bool> initialize() async {
    try {
      if (_isModelLoaded) return true;

      // Load vocabulary
      await _loadVocabulary();

      _isModelLoaded = true;
      return true;

    } catch (e) {
      print('Initialization failed: $e');
      return false;
    }
  }

  /// Initialize the offline ML model (alias for initialize)
  Future<bool> initializeModel() async {
    return await initialize();
  }

  /// Load vocabulary from assets
  Future<void> _loadVocabulary() async {
    try {
      final vocabData = await rootBundle.loadString('assets/models/vocab.txt');
      _vocabulary = vocabData.split('\n').where((line) => line.isNotEmpty).toList();
      print('✅ Vocabulary loaded: ${_vocabulary!.length} words');
    } catch (e) {
      print('Vocabulary file not found: $e');
      _vocabulary = null;
    }
  }

  /// Generate response using enhanced fallback
  Future<String> generateResponse(String input) async {
    try {
      if (!_isModelLoaded) {
        await initialize();
      }

      // Use enhanced rule-based system with knowledge base
      return _generateEnhancedResponse(input);

    } catch (e) {
      print('Error generating response: $e');
      return _generateEnhancedResponse(input);
    }
  }

  /// Enhanced rule-based response system with knowledge base
  String _generateEnhancedResponse(String input) {
    final lowerInput = input.toLowerCase().trim();

    // Try knowledge base search first
    final knowledgeResponse = _searchKnowledgeBase(lowerInput);
    if (knowledgeResponse != null) {
      return "🧠 **Knowledge Base Response:**\n\n$knowledgeResponse\n\n_Retrieved from local AI knowledge base_";
    }

    // Enhanced conversation patterns
    if (_containsAny(lowerInput, ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening', 'namaste'])) {
      final greetings = [
        "Hello! I'm your offline AI assistant. I have local knowledge about science, technology, history, and more!",
        "Hi there! I'm running on-device with enhanced capabilities. How can I help you today?",
        "Namaste! I'm your local AI with built-in knowledge. Ask me about various topics!"
      ];
      return greetings[DateTime.now().millisecond % greetings.length];
    }

    // Enhanced capability questions
    if (_containsAny(lowerInput, ['what can you do', 'capabilities', 'help', 'features', 'kya kar sakte ho'])) {
      return """🤖 **Enhanced Offline AI Capabilities:**

🧠 **Knowledge Base Topics:**
• Science & Technology
• History & Geography  
• Health & Medicine
• Programming & Computing
• Environment & Space
• Education & Learning

💡 **General Features:**
• Mathematical calculations
• Date and time information
• Basic conversations
• Question answering
• Multi-language support

🔒 **Privacy Benefits:**
• Complete offline operation
• No data sent to servers
• Instant responses
• Works without internet

Try asking: "Tell me about science" or "What is artificial intelligence?"
""";
    }

    // Math operations (existing functionality)
    if (_containsAny(lowerInput, ['calculate', '+', '-', '*', '/', 'math']) || RegExp(r'\d').hasMatch(lowerInput)) {
      return _handleAdvancedMath(lowerInput);
    }

    // Time and date (existing functionality)
    if (_containsAny(lowerInput, ['time', 'date', 'today', 'now', 'current', 'samay', 'tarikh'])) {
      return _getCurrentDateTime();
    }

    // Question patterns
    if (_startsWithAny(lowerInput, ['what is', 'what are', 'tell me about', 'explain', 'kya hai', 'batao'])) {
      return _handleQuestionPattern(lowerInput);
    }

    // How questions
    if (_startsWithAny(lowerInput, ['how to', 'how can', 'how does', 'kaise', 'kaise kar'])) {
      return _handleHowQuestions(lowerInput);
    }

    // Why questions
    if (_startsWithAny(lowerInput, ['why', 'kyun', 'kyu'])) {
      return _handleWhyQuestions(lowerInput);
    }

    // Default intelligent response
    return _generateContextualResponse(input);
  }

  /// Search knowledge base for relevant information
  String? _searchKnowledgeBase(String query) {
    for (final topic in _knowledgeBase.keys) {
      if (query.contains(topic) ||
          _containsAny(query, _getTopicKeywords(topic))) {
        final responses = _knowledgeBase[topic]!;
        return responses[DateTime.now().millisecond % responses.length];
      }
    }
    return null;
  }

  /// Get keywords for each topic
  List<String> _getTopicKeywords(String topic) {
    switch (topic) {
      case 'science':
        return ['physics', 'chemistry', 'biology', 'experiment', 'research', 'scientific', 'vigyan'];
      case 'history':
        return ['historical', 'ancient', 'civilization', 'war', 'empire', 'itihas'];
      case 'technology':
        return ['tech', 'computer', 'software', 'internet', 'digital', 'taknik'];
      case 'health':
        return ['medical', 'medicine', 'doctor', 'fitness', 'exercise', 'swasthya'];
      case 'education':
        return ['learning', 'study', 'school', 'college', 'university', 'shiksha'];
      case 'environment':
        return ['nature', 'climate', 'pollution', 'earth', 'green', 'paryavaran'];
      case 'space':
        return ['astronomy', 'planet', 'star', 'galaxy', 'universe', 'antariksh'];
      case 'programming':
        return ['coding', 'developer', 'app', 'website', 'algorithm', 'programming'];
      default:
        return [];
    }
  }

  /// Handle advanced mathematical operations
  String _handleAdvancedMath(String input) {
    // ...existing math code...
    try {
      final patterns = [
        RegExp(r'(\d+(?:\.\d+)?)\s*\+\s*(\d+(?:\.\d+)?)'),
        RegExp(r'(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)'),
        RegExp(r'(\d+(?:\.\d+)?)\s*\*\s*(\d+(?:\.\d+)?)'),
        RegExp(r'(\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)'),
        RegExp(r'(\d+(?:\.\d+)?)\s*\^\s*(\d+(?:\.\d+)?)'), // Power
        RegExp(r'sqrt\s*\(\s*(\d+(?:\.\d+)?)\s*\)'), // Square root
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(input);
        if (match != null) {
          return _calculateAdvanced(match, input);
        }
      }

      return "🔢 Enhanced Calculator Available!\n\nSupported operations:\n• Basic: +, -, *, /\n• Advanced: ^(power), sqrt()\n• Example: '5^2' or 'sqrt(25)'";
    } catch (e) {
      return "🔢 Math calculation error. Try: '5 + 3' or 'sqrt(25)'";
    }
  }

  String _calculateAdvanced(RegExpMatch match, String input) {
    try {
      if (input.contains('sqrt')) {
        final num = double.parse(match.group(1)!);
        final result = math.sqrt(num);
        return "🔢 **Square Root:**\n\nsqrt($num) = ${result.toStringAsFixed(2)}";
      } else if (input.contains('^')) {
        final base = double.parse(match.group(1)!);
        final exp = double.parse(match.group(2)!);
        final result = math.pow(base, exp);
        return "🔢 **Power:**\n\n$base^$exp = $result";
      } else {
        // Regular operations
        final num1 = double.parse(match.group(1)!);
        final num2 = double.parse(match.group(2)!);
        final operator = input.contains('+') ? '+' :
                        input.contains('-') ? '-' :
                        input.contains('*') ? '*' : '/';

        double result;
        switch (operator) {
          case '+': result = num1 + num2; break;
          case '-': result = num1 - num2; break;
          case '*': result = num1 * num2; break;
          case '/':
            if (num2 == 0) return "❌ Cannot divide by zero!";
            result = num1 / num2;
            break;
          default: return "Unknown operation";
        }

        return "🔢 **Calculation:**\n\n$num1 $operator $num2 = ${result % 1 == 0 ? result.toInt() : result.toStringAsFixed(2)}";
      }
    } catch (e) {
      return "🔢 Calculation error: $e";
    }
  }

  String _getCurrentDateTime() {
    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    return """📅 **Current Date & Time:**

📆 **Date:** ${dayNames[now.weekday - 1]}, ${monthNames[now.month - 1]} ${now.day}, ${now.year}
⏰ **Time:** ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}
🌍 **Day of Year:** ${now.difference(DateTime(now.year, 1, 1)).inDays + 1}
📊 **Week:** ${((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).ceil()}

_Local device time_""";
  }

  String _handleQuestionPattern(String input) {
    final topics = ['science', 'technology', 'history', 'health', 'space', 'environment', 'programming', 'education'];

    for (final topic in topics) {
      if (input.contains(topic) || _containsAny(input, _getTopicKeywords(topic))) {
        final response = _searchKnowledgeBase(topic);
        if (response != null) {
          return "💡 **About ${topic.toUpperCase()}:**\n\n$response\n\n_From local AI knowledge base_";
        }
      }
    }

    return "🤔 That's an interesting question! While I have knowledge about science, technology, history, health, and more topics, I couldn't find a specific match. Try asking about these topics directly!";
  }

  String _handleHowQuestions(String input) {
    if (_containsAny(input, ['learn', 'study', 'programming', 'code'])) {
      return """📚 **How to Learn Programming:**

1️⃣ **Start with basics:** Choose a language (Python recommended for beginners)
2️⃣ **Practice daily:** Code for at least 30 minutes daily
3️⃣ **Build projects:** Create small applications
4️⃣ **Join communities:** Connect with other developers
5️⃣ **Never stop learning:** Technology evolves rapidly

_Offline guidance from AI knowledge base_""";
    }

    return "🛠️ **How-to Questions:** I can help with learning programming, staying healthy, studying effectively, and more! Ask specific 'how to' questions for detailed guidance.";
  }

  String _handleWhyQuestions(String input) {
    if (_containsAny(input, ['important', 'study', 'learn', 'education'])) {
      return "🎯 **Why Learning is Important:** Education develops critical thinking, opens opportunities, and helps us understand the world better. It's an investment in your future!";
    }

    return "🤔 **Why Questions:** I can explain the reasoning behind many concepts in science, technology, and life. Ask specific 'why' questions for detailed explanations!";
  }

  String _generateContextualResponse(String input) {
    return """🤖 **AI Response for:** "${input.length > 50 ? input.substring(0, 50) + '...' : input}"

I'm your enhanced offline AI assistant with built-in knowledge about:
• Science & Technology
• History & Education  
• Health & Programming
• Mathematics & General Knowledge

💡 **Try asking:**
• "What is artificial intelligence?"
• "Tell me about space exploration"
• "How to stay healthy?"
• "Calculate 25 * 4"

🔒 **100% Offline & Private** - All responses generated on your device!""";
  }

  /// Helper function to check if input contains any of the given keywords
  bool _containsAny(String input, List<String> keywords) {
    return keywords.any((keyword) => input.contains(keyword));
  }

  /// Helper function to check if input starts with any of the given words
  bool _startsWithAny(String input, List<String> words) {
    return words.any((word) => input.startsWith(word));
  }

  /// Check if the model is loaded and available
  bool get isModelLoaded => _isModelLoaded;

  /// Get model status information
  Map<String, dynamic> getModelStatus() {
    return {
      'isLoaded': _isModelLoaded,
      'hasVocabulary': _vocabulary != null,
      'vocabularySize': _vocabulary?.length ?? 0,
      'knowledgeBaseTopics': _knowledgeBase.length,
      'mode': 'Enhanced Rule-based + Knowledge Base'
    };
  }

  /// Dispose resources
  void dispose() {
    _isModelLoaded = false;
  }
}
