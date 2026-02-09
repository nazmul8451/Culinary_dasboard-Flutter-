import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/message_model.dart';
import '../../services/message_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../widgets/chat_dialog.dart';
import '../../services/notification_service.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
    super.build(context);
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Communications Center',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (!isMobile)
                    StreamBuilder<int>(
                      stream: MessageService.getTotalUnreadCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count Unread Messages',
                            style: GoogleFonts.inter(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingMD),
              TabBar(
                controller: _tabController,
                isScrollable: isMobile,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  const Tab(text: 'Broadcasts'),
                  StreamBuilder<int>(
                    stream: MessageService.getTotalUnreadCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Chats'),
                            if (count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
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
                  StreamBuilder<int>(
                    stream: NotificationService.getUnreadCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Notifications'),
                            if (count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
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
                    _buildNotificationsTab(isMobile),
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
                  Center(
                    child: SizedBox(
                      width: 300,
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
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = userSnapshot.data ?? [];
        // Create a modifiable copy for sorting
        final sortedUsers = List<UserModel>.from(users);

        return StreamBuilder<Map<String, DateTime>>(
          stream: MessageService.getLastMessageTimes(),
          builder: (context, timeSnapshot) {
            final lastTimes = timeSnapshot.data ?? {};

            // Sort users descending by last message time
            sortedUsers.sort((a, b) {
              final timeA = lastTimes[a.id];
              final timeB = lastTimes[b.id];

              if (timeA == null && timeB == null) return 0;
              if (timeA == null) return 1;
              if (timeB == null) return -1;

              return timeB.compareTo(timeA);
            });

            return ListView.separated(
              itemCount: sortedUsers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = sortedUsers[index];

                return StreamBuilder<int>(
                  stream: MessageService.getUnreadCount(user.id),
                  builder: (context, unreadSnapshot) {
                    final unreadCount = unreadSnapshot.data ?? 0;
                    final lastMsgTime = lastTimes[user.id];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage:
                            user.profileImage != null &&
                                user.profileImage!.isNotEmpty
                            ? NetworkImage(user.profileImage!)
                            : null,
                        child:
                            user.profileImage != null &&
                                user.profileImage!.isNotEmpty
                            ? null
                            : Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name.isNotEmpty ? user.name : 'Unknown User',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontWeight: unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (lastMsgTime != null)
                            Text(
                              _formatTime(lastMsgTime),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: unreadCount > 0
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                      onTap: () => _openChat(user),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      if (difference.inDays > 7) {
        return '${time.day}/${time.month}';
      }
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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

  Widget _buildNotificationsTab(bool isSmallScreen) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMD),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => NotificationService.markAllAsRead(),
                icon: const Icon(Icons.done_all),
                label: const Text('Mark all as read'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<NotificationModel>>(
            stream: NotificationService.getNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty)
                return const Center(child: Text('No notifications found.'));
              return ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getNotificationColor(
                        n.type,
                      ).withOpacity(0.1),
                      child: Icon(
                        _getNotificationIcon(n.type),
                        color: _getNotificationColor(n.type),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      n.title,
                      style: GoogleFonts.inter(
                        fontWeight: n.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.body),
                        const SizedBox(height: 4),
                        Text(
                          '${n.timestamp.day}/${n.timestamp.month} ${n.timestamp.hour}:${n.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: n.isRead
                        ? null
                        : const Icon(
                            Icons.circle,
                            size: 8,
                            color: AppColors.primary,
                          ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.message;
      case NotificationType.order:
        return Icons.shopping_bag;
      case NotificationType.support:
        return Icons.help;
      case NotificationType.security:
        return Icons.security;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return AppColors.primary;
      case NotificationType.order:
        return AppColors.success;
      case NotificationType.support:
        return AppColors.info;
      case NotificationType.security:
        return AppColors.error;
    }
  }
}
