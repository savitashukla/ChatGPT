import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../widgets/three_dots.dart';
import '../../chat_history/views/chat_history_view.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're on mobile or desktop/web
        bool isMobile = constraints.maxWidth < 768;
        bool isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        bool isDesktop = constraints.maxWidth >= 1024;

        if (isMobile) {
          return _buildMobileLayout(context);
        } else if (isTablet) {
          return _buildTabletLayout(context);
        } else {
          return _buildDesktopLayout(context);
        }
      },
    );
  }

  // Mobile Layout (< 768px)
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildMobileAppBar(),
      drawer: _buildMobileDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildMobileKnowledgeBaseStatusBar(),
            Expanded(child: _buildMobileChatArea()),
            _buildMobileTypingIndicator(),
            _buildMobileChatInput(),
          ],
        ),
      ),
    );
  }

  // Tablet Layout (768px - 1024px)
  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildTabletAppBar(),
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar for tablet
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: _buildSidebar(),
            ),
            // Main chat area
            Expanded(
              child: Column(
                children: [
                  _buildKnowledgeBaseStatusBar(),
                  Expanded(child: _buildChatArea()),
                  _buildTypingIndicator(),
                  _buildDesktopChatInput(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desktop Layout (>= 1024px)
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Row(
          children: [
            // Left Sidebar
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: _buildSidebar(),
            ),
            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  _buildDesktopHeader(),
                  _buildKnowledgeBaseStatusBar(),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: _buildChatArea(),
                    ),
                  ),
                  _buildTypingIndicator(),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: _buildDesktopChatInput(),
                  ),
                ],
              ),
            ),
            // Right Sidebar (for larger screens)
            if (MediaQuery.of(context).size.width > 1400)
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: Colors.grey.shade300)),
                ),
                child: _buildRightSidebar(),
              ),
          ],
        ),
      ),
    );
  }

  // Mobile AppBar
  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: Builder(
        builder: (context) => InkWell(
          onTap: () => Scaffold.of(context).openDrawer(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "HelpAI",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Obx(() => _buildAnimatedDots(
                  isActive: controller.isTyping.value ||
                            controller.isListening.value ||
                            !controller.connectionService.isConnected,
                )),
              ],
            ),
          ),
        ),
      ),
      actions: [
        _buildRAGStatusIndicator(compact: true),
        const SizedBox(width: 8),
        _buildMobileMenu(),
      ],
    );
  }

  // Animated dots indicator (WhatsApp style)
  Widget _buildAnimatedDots({required bool isActive}) {
    return SizedBox(
      height: 24,
      child: isActive
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnimatedDot(delay: 0),
              const SizedBox(width: 4),
              _buildAnimatedDot(delay: 200),
              const SizedBox(width: 4),
              _buildAnimatedDot(delay: 400),
            ],
          )
        : Icon(
            Icons.keyboard_arrow_down_sharp,
            color: Colors.grey.shade600,
            size: 24,
          ),
    );
  }

  // Single animated dot
  Widget _buildAnimatedDot({required int delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return FutureBuilder(
          future: Future.delayed(Duration(milliseconds: delay)),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              );
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              width: 6,
              height: 6 + (4 * (0.5 - (value - 0.5).abs()) * 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
              ),
            );
          },
        );
      },
      onEnd: () {
        // Rebuild to restart animation
        Future.delayed(const Duration(milliseconds: 100), () {
          if (controller.isTyping.value ||
              controller.isListening.value ||
              !controller.connectionService.isConnected) {
            // Animation continues
          }
        });
      },
    );
  }

  // Mobile Drawer Menu
  Widget _buildMobileDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.purple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'HelpAI with RAG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    controller.isRAGEnabled.value ? '🧠 Smart AI Active' : '💬 Chat Mode',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  )),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),

                  // Status Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'STATUS',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  _buildDrawerTile(
                    icon: Icons.wifi,
                    title: 'Connection Status',
                    subtitle: Obx(() => Text(
                      controller.getCurrentModeStatus(),
                      style: TextStyle(
                        color: controller.connectionService.isConnected
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    )),
                    trailing: Obx(() => Icon(
                      controller.connectionService.isConnected
                        ? Icons.check_circle
                        : Icons.error,
                      color: controller.connectionService.isConnected
                        ? Colors.green
                        : Colors.red,
                      size: 20,
                    )),
                  ),
                  _buildDrawerTile(
                    icon: Icons.auto_awesome,
                    title: 'RAG System',
                    subtitle: Obx(() => Text(
                      controller.isRAGEnabled.value ? 'Enabled' : 'Disabled',
                      style: TextStyle(
                        color: controller.isRAGEnabled.value
                          ? Colors.green.shade600
                          : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    )),
                    trailing: Obx(() => Switch(
                      value: controller.isRAGEnabled.value,
                      onChanged: (value) {
                        controller.toggleRAG();
                        Get.back();
                      },
                      activeColor: Colors.green,
                    )),
                  ),
                  _buildDrawerTile(
                    icon: Icons.folder,
                    title: 'Knowledge Base',
                    subtitle: Obx(() => Text(
                      '${controller.documentsCount.value} documents loaded',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    )),
                  ),

                  const Divider(height: 24),

                  // Actions Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'ACTIONS',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  _buildDrawerTile(
                    icon: Icons.add_circle,
                    title: 'New Chat',
                    subtitle: const Text(
                      'Start fresh conversation',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Get.back();
                      _startNewChat();
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.history,
                    title: 'Chat History',
                    subtitle: const Text(
                      'View past conversations',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Get.back();
                      _viewChatHistory(Get.context!);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.upload_file,
                    title: 'Upload Document',
                    subtitle: const Text(
                      'PDF or TXT files',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Get.back();
                      controller.uploadDocument();
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.add,
                    title: 'Add Knowledge',
                    subtitle: const Text(
                      'Add text manually',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Get.back();
                      controller.addTextKnowledge();
                    },
                  ),

                  const Divider(height: 24),

                  // Settings Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'SETTINGS',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  _buildDrawerTile(
                    icon: Icons.swap_horiz,
                    title: 'Toggle Mode',
                    subtitle: Obx(() => Text(
                      'Switch to ${controller.connectionService.isOnlineMode ? 'Offline' : 'Online'}',
                      style: const TextStyle(fontSize: 12),
                    )),
                    onTap: () {
                      Get.back();
                      controller.toggleConnectionMode();
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.info_outline,
                    title: 'Model Status',
                    subtitle: const Text(
                      'View AI model info',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Get.back();
                      controller.showModelStatus();
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.analytics_outlined,
                    title: 'Knowledge Stats',
                    subtitle: const Text(
                      'View database info',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Get.back();
                      controller.showKnowledgeBaseStats();
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.download_outlined,
                    title: 'Download Models',
                    subtitle: const Text(
                      'Manage TensorFlow Lite models',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Get.back();
                      controller.showTFLiteModelsDialog();
                    },
                  ),

                  const Divider(height: 24),

                  // Danger Zone
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'DANGER ZONE',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  _buildDrawerTile(
                    icon: Icons.clear_all,
                    title: 'Clear Chat',
                    subtitle: const Text(
                      'Delete all messages',
                      style: TextStyle(fontSize: 12),
                    ),
                    iconColor: Colors.red,
                    onTap: () {
                      Get.back();
                      _clearChat();
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer Tile Widget
  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    Widget? subtitle,
    Widget? trailing,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.blue.shade600,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // Tablet AppBar
  PreferredSizeWidget _buildTabletAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.smart_toy,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "HelpAI with RAG",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        _buildConnectionStatusIndicator(),
        _buildRAGStatusIndicator(),
      ],
    );
  }

  // Desktop Header
  Widget _buildDesktopHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.smart_toy,
              color: Colors.blue.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            "HelpAI with RAG - Web Interface",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          _buildConnectionStatusIndicator(),
          const SizedBox(width: 12),
          _buildRAGStatusIndicator(),
          const SizedBox(width: 12),
          _buildDesktopActions(),
        ],
      ),
    );
  }

  // Sidebar for tablet and desktop
  Widget _buildSidebar() {
    return Column(
      children: [
        // Sidebar Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Icon(Icons.menu_book, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        // Quick Action Buttons
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSidebarButton(
                icon: Icons.upload_file,
                title: 'Upload Document',
                subtitle: 'PDF or TXT files',
                color: Colors.blue,
                onTap: controller.uploadDocument,
              ),
              const SizedBox(height: 12),
              _buildSidebarButton(
                icon: Icons.add_circle,
                title: 'Add Knowledge',
                subtitle: 'Add text manually',
                color: Colors.green,
                onTap: controller.addTextKnowledge,
              ),
              const SizedBox(height: 12),
              Obx(() => _buildSidebarButton(
                icon: controller.isRAGEnabled.value ? Icons.toggle_on : Icons.toggle_off,
                title: '${controller.isRAGEnabled.value ? 'Disable' : 'Enable'} RAG',
                subtitle: 'Toggle smart responses',
                color: controller.isRAGEnabled.value ? Colors.green : Colors.grey,
                onTap: controller.toggleRAG,
              )),
              const SizedBox(height: 12),
              _buildSidebarButton(
                icon: Icons.info,
                title: 'Model Status',
                subtitle: 'View AI model info',
                color: Colors.orange,
                onTap: controller.showModelStatus,
              ),
              const SizedBox(height: 12),
              _buildSidebarButton(
                icon: Icons.analytics,
                title: 'Knowledge Stats',
                subtitle: 'View database info',
                color: Colors.purple,
                onTap: controller.showKnowledgeBaseStats,
              ),
              const SizedBox(height: 12),
              _buildSidebarButton(
                icon: Icons.download,
                title: 'Download Models',
                subtitle: 'Manage TensorFlow Lite models',
                color: Colors.indigo,
                onTap: controller.showTFLiteModelsDialog,
              ),
              const SizedBox(height: 12),
              _buildSidebarButton(
                icon: Icons.history,
                title: 'Chat History',
                subtitle: 'View past conversations',
                color: Colors.blue,
                onTap: () => _viewChatHistory(Get.context!),
              ),
              const SizedBox(height: 12),
              _buildSidebarButton(
                icon: Icons.add_circle,
                title: 'New Chat',
                subtitle: 'Start fresh conversation',
                color: Colors.green,
                onTap: _startNewChat,
              ),
              const SizedBox(height: 12),
              _buildSidebarButton(
                icon: Icons.clear_all,
                title: 'Clear Chat',
                subtitle: 'Delete all messages',
                color: Colors.red,
                onTap: _clearChat,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Right Sidebar for very large screens
  Widget _buildRightSidebar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Model Information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => _buildInfoCard(
            'Connection Status',
            controller.getCurrentModeStatus(),
            controller.connectionService.isConnected ? Icons.wifi : Icons.wifi_off,
            controller.connectionService.isConnected ? Colors.green : Colors.red,
          )),
          const SizedBox(height: 12),
          Obx(() => _buildInfoCard(
            'RAG System',
            controller.isRAGEnabled.value ? 'Enabled' : 'Disabled',
            Icons.auto_awesome,
            controller.isRAGEnabled.value ? Colors.purple : Colors.grey,
          )),
          const SizedBox(height: 12),
          Obx(() => _buildInfoCard(
            'Documents',
            '${controller.documentsCount.value} uploaded',
            Icons.folder,
            Colors.blue,
          )),
        ],
      ),
    );
  }

  // Sidebar button widget
  Widget _buildSidebarButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Info card for right sidebar
  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Connection status indicator
  Widget _buildConnectionStatusIndicator({bool compact = false}) {
    return Obx(() => Container(
      margin: const EdgeInsets.only(right: 8.0),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: controller.connectionService.isConnected
          ? (controller.connectionService.isOnlineMode ? Colors.green : Colors.blue)
          : Colors.red,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (controller.connectionService.isConnected
              ? (controller.connectionService.isOnlineMode ? Colors.green : Colors.blue)
              : Colors.red).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            controller.connectionService.isConnected
              ? (controller.connectionService.isOnlineMode ? Icons.cloud : Icons.offline_bolt)
              : Icons.cloud_off,
            color: Colors.white,
            size: compact ? 12 : 14,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              controller.getCurrentModeStatus().split(' ')[1],
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 8 : 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    ));
  }

  // RAG status indicator
  Widget _buildRAGStatusIndicator({bool compact = false}) {
    return Obx(() => Container(
      margin: const EdgeInsets.only(right: 8.0),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: controller.isRAGEnabled.value ? Colors.purple : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (controller.isRAGEnabled.value ? Colors.purple : Colors.grey.shade400).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            controller.isRAGEnabled.value ? Icons.auto_awesome : Icons.chat_outlined,
            color: Colors.white,
            size: compact ? 12 : 14,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              controller.isRAGEnabled.value ? 'RAG' : 'CHAT',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 8 : 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    ));
  }

  // Mobile menu
  Widget _buildMobileMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'clear_chat':
            _clearChat();
            break;
          case 'chat_history':
            _viewChatHistory(Get.context!);
            break;
          case 'new_chat':
            _startNewChat();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'new_chat',
          child: ListTile(
            leading: Icon(Icons.add_circle, color: Colors.green),
            title: Text('New Chat'),
            subtitle: Text('Start fresh conversation'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'chat_history',
          child: ListTile(
            leading: Icon(Icons.history, color: Colors.blue),
            title: Text('Chat History'),
            subtitle: Text('View past conversations'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'clear_chat',
          child: ListTile(
            leading: Icon(Icons.clear_all, color: Colors.red),
            title: Text('Clear Chat'),
            subtitle: Text('Delete all messages'),
          ),
        ),
      ],
    );
  }

  // Desktop actions
  Widget _buildDesktopActions() {
    return Row(
      children: [
        IconButton(
          onPressed: () => _viewChatHistory(Get.context!),
          icon: const Icon(Icons.history),
          tooltip: 'Chat History',
        ),
        IconButton(
          onPressed: _startNewChat,
          icon: const Icon(Icons.add),
          tooltip: 'New Chat',
        ),
        IconButton(
          onPressed: _clearChat,
          icon: const Icon(Icons.clear_all),
          tooltip: 'Clear Chat',
        ),
      ],
    );
  }

  // Knowledge base status bar (shared across layouts)
  Widget _buildKnowledgeBaseStatusBar() {
    return Obx(() => controller.documentsCount.value > 0
      ? Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.purple.shade50],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome, size: 16, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${controller.documentsCount.value} document(s) in knowledge base',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (controller.isRAGEnabled.value)
                      Text(
                        '🧠 Smart responses active',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        )
      : const SizedBox.shrink());
  }

  // Mobile-specific Knowledge base status bar
  Widget _buildMobileKnowledgeBaseStatusBar() {
    return Obx(() => controller.documentsCount.value > 0
      ? Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.purple.shade50],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, size: 20, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${controller.documentsCount.value} documents loaded',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (controller.isRAGEnabled.value)
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Smart AI active',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 18,
                ),
              ),
            ],
          ),
        )
      : const SizedBox.shrink());
  }

  // Chat area (shared across layouts)
  Widget _buildChatArea() {
    return Obx(() => controller.messages.isEmpty
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smart_toy,
                  size: 50,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Start a conversation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask me anything or upload documents for smart responses',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      : ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: controller.messages.length,
          itemBuilder: (context, index) {
            return controller.messages[index];
          },
        ));
  }

  // Mobile-specific Chat Area
  Widget _buildMobileChatArea() {
    return Obx(() => controller.messages.isEmpty
      ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.purple.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100,
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    size: 60,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to HelpAI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Start a conversation with AI',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask me anything or upload documents for smart responses',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Quick action buttons for mobile
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildQuickActionChip(
                      icon: Icons.upload_file,
                      label: 'Upload PDF',
                      color: Colors.blue,
                      onTap: controller.uploadDocument,
                    ),
                    _buildQuickActionChip(
                      icon: Icons.add_circle,
                      label: 'Add Knowledge',
                      color: Colors.green,
                      onTap: controller.addTextKnowledge,
                    ),
                    _buildQuickActionChip(
                      icon: Icons.history,
                      label: 'History',
                      color: Colors.purple,
                      onTap: () => _viewChatHistory(Get.context!),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      : ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: controller.messages.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: controller.messages[index],
            );
          },
        ));
  }

  // Quick action chip for mobile
  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Typing indicator (shared across layouts)
  Widget _buildTypingIndicator() {
    return Obx(() => controller.isTyping.value
      ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const ThreeDots(),
              ),
            ],
          ),
        )
      : const SizedBox.shrink());
  }

  // Mobile chat input
  Widget _buildMobileChatInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            // Microphone button
            Obx(() => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: controller.isListening.value
                  ? Colors.red.shade400
                  : Colors.grey.shade400,
                boxShadow: controller.isListening.value
                  ? [BoxShadow(
                      color: Colors.red.shade200,
                      blurRadius: 8,
                      spreadRadius: 2,
                    )]
                  : null,
              ),
              child: IconButton(
                icon: Icon(
                  controller.isListening.value ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: controller.toggleListening,
              ),
            )),
            const SizedBox(width: 12),
            // Text field
            Expanded(
              child: Obx(() => TextField(
                controller: controller.textController,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    controller.sendMessage();
                  }
                },
                textInputAction: TextInputAction.send,
                maxLines: null,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration.collapsed(
                  hintText: controller.isListening.value
                    ? "🎤 Listening..."
                    : "Type your message...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                  ),
                ),
              )),
            ),
            const SizedBox(width: 12),
            // Send button
            Obx(() => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: controller.isListening.value
                  ? null
                  : LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                color: controller.isListening.value ? Colors.transparent : null,
              ),
              child: controller.isListening.value
                ? const SizedBox(width: 40, height: 40)
                : IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: controller.sendMessage,
                  ),
            )),
          ],
        ),
      ),
    );
  }

  // Desktop chat input
  Widget _buildDesktopChatInput() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            // Microphone button
            Obx(() => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: controller.isListening.value
                  ? Colors.red.shade400
                  : Colors.grey.shade400,
                boxShadow: controller.isListening.value
                  ? [BoxShadow(
                      color: Colors.red.shade200,
                      blurRadius: 8,
                      spreadRadius: 2,
                    )]
                  : null,
              ),
              child: IconButton(
                icon: Icon(
                  controller.isListening.value ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: controller.toggleListening,
              ),
            )),
            const SizedBox(width: 16),
            // Text field
            Expanded(
              child: Obx(() => TextField(
                controller: controller.textController,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    controller.sendMessage();
                  }
                },
                textInputAction: TextInputAction.send,
                maxLines: null,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration.collapsed(
                  hintText: controller.isListening.value
                    ? "🎤 Listening..."
                    : "Type your message here...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                  ),
                ),
              )),
            ),
            const SizedBox(width: 16),
            // Send button
            Obx(() => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: controller.isListening.value
                  ? null
                  : LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                color: controller.isListening.value ? Colors.transparent : null,
              ),
              child: controller.isListening.value
                ? const SizedBox(width: 48, height: 48)
                : IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: controller.sendMessage,
                  ),
            )),
          ],
        ),
      ),
    );
  }

  // Mobile-specific Typing Indicator
  Widget _buildMobileTypingIndicator() {
    return Obx(() => controller.isTyping.value
      ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.smart_toy,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const ThreeDots(),
                  ],
                ),
              ),
            ],
          ),
        )
      : const SizedBox.shrink());
  }

  // Helper methods (existing functionality)
  void _copyAllMessages() {
    if (controller.messages.isEmpty) {
      Get.showSnackbar(
        GetSnackBar(
          title: "No Messages",
          message: "There are no messages to copy",
          icon: const Icon(Icons.info, color: Colors.white),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        ),
      );
      return;
    }

    String allMessages = controller.messages
        .reversed
        .map((msg) => "${msg.sender == 'user' ? 'You' : 'HelpAI'}: ${msg.text}")
        .join('\n\n');

    Clipboard.setData(ClipboardData(text: allMessages));
    Get.showSnackbar(
      GetSnackBar(
        title: "Copied!",
        message: "All messages copied to clipboard",
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      ),
    );
  }

  void _clearChat() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to delete all messages? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(closeOverlays: false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.messages.clear();
              Get.back(closeOverlays: false);
              Get.showSnackbar(
                GetSnackBar(
                  title: "Chat Cleared",
                  message: "All messages have been deleted",
                  icon: const Icon(Icons.delete_sweep, color: Colors.white),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.red,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 8,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void _viewChatHistory(context1) {
    Navigator.of(context1).push(
      MaterialPageRoute(
        builder: (context) => const ChatHistoryScreen(),
      ),
    );
  }

  void _startNewChat() {
    controller.clearCurrentChat();
  }
}
