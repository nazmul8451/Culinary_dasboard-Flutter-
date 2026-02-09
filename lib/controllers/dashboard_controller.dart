import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/realtime_database_service.dart';
import '../core/constants/app_colors.dart';
import 'dart:async';

class DashboardController extends GetxController {
  final _selectedRoute = '/dashboard'.obs;
  String get selectedRoute => _selectedRoute.value;

  StreamSubscription? _ticketSubscription;
  bool _isFirstLoad = true;

  @override
  void onInit() {
    super.onInit();
    _listenForNewTickets();
  }

  @override
  void onClose() {
    _ticketSubscription?.cancel();
    super.onClose();
  }

  void _listenForNewTickets() {
    // We use onChildAdded to detect new tickets
    _ticketSubscription = RealtimeDatabaseService.ref('support_tickets')
        .onChildAdded
        .listen((event) {
          if (_isFirstLoad) {
            // Skip the initial sync of existing tickets
            return;
          }

          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            final subject = data['subject'] ?? 'New Support Ticket';
            final userName = data['userName'] ?? 'A user';

            Get.snackbar(
              'New Help Request',
              '$userName: $subject',
              snackPosition: SnackPosition.TOP,
              backgroundColor: AppColors.primary,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
              onTap: (_) => changeRoute('/support'),
            );
          }
        });

    // Mark first load as done after a short delay or by waiting for the first batch
    Future.delayed(const Duration(seconds: 2), () {
      _isFirstLoad = false;
    });
  }

  void changeRoute(String route) {
    _selectedRoute.value = route;
  }
}
