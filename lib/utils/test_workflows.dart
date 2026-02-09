import '../services/message_service.dart';
import '../services/payment_service.dart';
import '../services/fcm_service.dart';
import '../models/message_model.dart';

class TestWorkflows {
  /// Run this to verify the new workflows (Moderation, Payment, FCM)
  static Future<void> runChecks() async {
    print('\n--- 🧪 STARTING WORKFLOW CHECKS ---\n');

    // 1. Check Message Moderation (Contact Blocking)
    print('1. Checking Message Moderation...');
    try {
      final msg = MessageModel(
        id: 'test_msg',
        senderId: 'admin',
        receiverId: 'test_user',
        content: 'Call me at 01711223344 for details', // Contains phone number
        timestamp: DateTime.now(),
        type: MessageType.chat,
        status: MessageStatus.sent,
      );

      // Attempt to send
      await MessageService.sendMessage(msg);
      print(
        '❌ Moderation FAILED: Message with phone number was sent successfully (Should be blocked).',
      );
    } catch (e) {
      if (e.toString().contains('blocked')) {
        print('✅ Moderation PASSED: System correctly blocked the message.');
        print('   Error Message: $e');
      } else {
        print('⚠️ Moderation Warning: Caught unexpected error: $e');
      }
    }

    // 2. Check Payment Service (Refund Simulation)
    print('\n2. Checking Payment Service...');
    try {
      await PaymentService.processRefund(
        'ORDER_TEST_123',
        150.0,
        'Item damaged',
      );
      await PaymentService.releaseEscrow('ORDER_TEST_456', 200.0, 'VENDOR_999');
      print(
        '✅ Payment Service simulation executed successfully (Check logs for "💰").',
      );
    } catch (e) {
      print('❌ Payment Service Failed: $e');
    }

    // 3. Check FCM Notifications
    print('\n3. Checking FCM Service...');
    try {
      await FcmService.sendNotificationToUser(
        userId: 'USER_001',
        title: 'Test Notification',
        body: 'Verifying notification workflow.',
        type: 'test',
        data: {'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
      );
      print(
        '✅ FCM Service simulation executed successfully (Check logs for "🚀").',
      );
    } catch (e) {
      print('❌ FCM Service Failed: $e');
    }

    print('\n--- 🏁 WORKFLOW CHECKS COMPLETE ---\n');
  }
}
