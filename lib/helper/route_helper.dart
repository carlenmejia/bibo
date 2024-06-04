import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/splash/screens/splash_screen.dart';

class RouteHelper {
  static const String splash = '/splash';
  static getSplashRoute() => splash;
  static List<GetPage> routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
  ];

}