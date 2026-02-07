import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/message_model.dart';
import '../../services/message_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../widgets/chat_dialog.dart';

class CommunicationsScreen extends StatefulWidget {
  const CommunicationsScreen({super.key});

  @override
  State<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends State<CommunicationsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;
  final TextEditingController _broadcastController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  MessageType _selectedBroadcastType = MessageType.push;
  String _selectedBroadcastTarget = 'everyone';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _broadcastController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;

        return Padding(
          padding: EdgeInsets.all(
            isMobile ? AppSizes.paddingMD : AppSizes.paddingLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Communications',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMD),
              TabBar(
                controller: _tabController,
                isScrollable: isMobile,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  const Tab(text: 'Broadcast Messages'),
                  StreamBuilder<int>(
                    stream: MessageService.getTotalUnreadCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Individual Chats'),
                            if (count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingMD),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBroadcastTab(isMobile),
                    _buildChatsTab(isMobile),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBroadcastTab(bool isSmallScreen) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              border: Border.all(
                color: AppColors.border.withOpacity(0.5),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send New Broadcast',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  Wrap(
                    spacing: AppSizes.paddingMD,
                    runSpacing: AppSizes.paddingMD,
                    children: [
                      SizedBox(
                        width: isSmallScreen ? double.infinity : 300,
                        child: DropdownButtonFormField<String>(
                          value: _selectedBroadcastTarget,
                          decoration: const InputDecoration(
                            labelText: 'Target Audience',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'everyone',
                              child: Text('Everyone'),
                            ),
                            DropdownMenuItem(
                              value: 'seller',
                              child: Text('All Sellers'),
                            ),
                            DropdownMenuItem(
                              value: 'buyer',
                              child: Text('All Buyers'),
                            ),
                            DropdownMenuItem(
                              value: 'courier',
                              child: Text('All Couriers'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedBroadcastTarget = val!),
                        ),
                      ),
                      SizedBox(
                        width: isSmallScreen ? double.infinity : 200,
                        child: DropdownButtonFormField<MessageType>(
                          value: _selectedBroadcastType,
                          decoration: const InputDecoration(
                            labelText: 'Channel',
                          ),
                          items: MessageType.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedBroadcastType = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  if (_selectedBroadcastType == MessageType.email ||
                      _selectedBroadcastType == MessageType.push)
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Subject / Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: AppSizes.paddingMD),
                  TextField(
                    controller: _broadcastController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Message Content',
                      hintText: 'Type your message here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingLG),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendBroadcast,
                      icon: const Icon(Icons.send),
                      label: const Text('Send Broadcast'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(AppSizes.paddingMD),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingLG),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              border: Border.all(
                color: AppColors.border.withOpacity(0.5),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Broadcast History',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  StreamBuilder<List<MessageModel>>(
                    stream: MessageService.getAllBroadcasts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const CircularProgressIndicator();
                      final broadcasts = snapshot.data ?? [];
                      if (broadcasts.isEmpty)
                        return const Text('No broadcast history found.');
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: broadcasts.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final b = broadcasts[index];
                          return ListTile(
                            leading: Icon(
                              _getChannelIcon(b.type),
                              color: AppColors.primary,
                            ),
                            title: Text(b.title ?? 'No Title'),
                            subtitle: Text(
                              b.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              b.receiverId.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsTab(bool isSmallScreen) {
    return StreamBuilder<List<UserModel>>(
      stream: UserService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final users = snapshot.data ?? [];
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return StreamBuilder<int>(
              stream: MessageService.getUnreadCount(user.id),
              builder: (context, unreadSnapshot) {
                final unreadCount = unreadSnapshot.data ?? 0;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(user.name.isNotEmpty ? user.name : 'Unknown User'),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(user.email),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openChat(user),
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _getChannelIcon(MessageType type) {
    switch (type) {
      case MessageType.chat:
        return Icons.chat;
      case MessageType.email:
        return Icons.email;
      case MessageType.push:
        return Icons.notifications;
      case MessageType.sms:
        return Icons.sms;
    }
  }

  Future<void> _sendBroadcast() async {
    if (_broadcastController.text.isEmpty) return;

    final broadcast = MessageModel(
      id: '',
      senderId: 'admin',
      receiverId: _selectedBroadcastTarget,
      content: _broadcastController.text,
      title: _titleController.text.isNotEmpty
          ? _titleController.text
          : 'Important Update',
      timestamp: DateTime.now(),
      type: _selectedBroadcastType,
      status: MessageStatus.sent,
    );

    try {
      await MessageService.sendBroadcast(broadcast);
      _broadcastController.clear();
      _titleController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send broadcast: $e')));
    }
  }

  void _openChat(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => ChatDialog(user: user),
    );
  }
}
