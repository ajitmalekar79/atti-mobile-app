import 'package:get/get.dart';
import 'auth/login_screen.dart';
import 'auth/sign_up_screen.dart';
import 'base_screen.dart';
import 'splash_screen.dart';

final routes = [
  GetPage(
    name: SplashScreen.splashRoute,
    page: () => const SplashScreen(),
  ),
  GetPage(
    name: BaseScreen.baseRouteName,
    page: () => const BaseScreen(),
    transition: Transition.fade,
    transitionDuration: const Duration(milliseconds: 500),
  ),
  GetPage(
    name: '/logingScreen',
    page: () => LoginScreen(),
    transition: Transition.fade,
    transitionDuration: const Duration(milliseconds: 500),
  ),
  GetPage(
    name: '/signUp',
    page: () => const SignUpScreen(),
    transition: Transition.fade,
    transitionDuration: const Duration(milliseconds: 500),
  ),
];
