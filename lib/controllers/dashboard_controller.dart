import 'package:get/get.dart';

class DashboardController extends GetxController {
  final _selectedRoute = '/dashboard'.obs;
  String get selectedRoute => _selectedRoute.value;

  void changeRoute(String route) {
    _selectedRoute.value = route;
  }
}
