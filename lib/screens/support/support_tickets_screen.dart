import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../services/support_service.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Padding(
          padding: EdgeInsets.all(
            isMobile ? AppSizes.paddingMD : AppSizes.paddingLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support Tickets',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLG),
              Expanded(
                child: StreamBuilder<List<TicketModel>>(
                  stream: SupportService.getAllTickets(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No support tickets found'),
                      );
                    }

                    final tickets = snapshot.data!;
                    return ListView.builder(
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: AppSizes.paddingMD,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMD,
                            ),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.5),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(
                              ticket.subject,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${ticket.category.name.toUpperCase()} - ${ticket.status.name.toUpperCase()}',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            trailing: isMobile
                                ? null
                                : _buildStatusBadge(ticket.status),
                            onTap: () => _showTicketDetails(ticket),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(TicketStatus status) {
    Color color;
    switch (status) {
      case TicketStatus.open:
        color = AppColors.error;
        break;
      case TicketStatus.pending:
        color = AppColors.warning;
        break;
      case TicketStatus.resolved:
        color = AppColors.success;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showTicketDetails(TicketModel ticket) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ticket.subject),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ticket.message),
              const Divider(),
              const Text(
                'Replies:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: ticket.replies.length,
                  itemBuilder: (context, index) {
                    final reply = ticket.replies[index];
                    return ListTile(
                      title: Text(reply.message),
                      subtitle: Text(reply.isAdmin ? 'Admin' : 'User'),
                    );
                  },
                ),
              ),
              TextField(
                controller: replyController,
                decoration: const InputDecoration(
                  hintText: 'Type admin reply...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              await SupportService.addReply(
                ticket.id,
                replyController.text,
                isAdmin: true,
                senderId: 'admin_1',
              );
              Navigator.pop(context);
            },
            child: const Text('Reply'),
          ),
          if (ticket.status != TicketStatus.resolved)
            ElevatedButton(
              onPressed: () async {
                await SupportService.updateTicketStatus(
                  ticket.id,
                  TicketStatus.resolved,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('Resolve'),
            ),
        ],
      ),
    );
  }
}
