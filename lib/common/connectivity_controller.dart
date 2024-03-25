import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ConnectivityController extends GetxController {
  // 0 = No Internet, 1 = connected to WIFI, 2 = connected to Mobile Data.
  int connectionType = 0;

  final Connectivity _connectivity = Connectivity();

  late StreamSubscription _streamSubscription;

  @override
  void onInit() {
    super.onInit();
    getConnectionType();
    _streamSubscription =
        _connectivity.onConnectivityChanged.listen(_updateState);
  }

  Future<void> getConnectionType() async {
    ConnectivityResult connectivityResult = ConnectivityResult.none;
    try {
      connectivityResult = await (_connectivity.checkConnectivity());
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }

    return _updateState(connectivityResult);
  }

  _updateState(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        connectionType = 1;
        update();
        // if (Get.isSnackbarOpen) Get.back();
        break;
      case ConnectivityResult.mobile:
        connectionType = 2;
        update();
        // if (Get.isSnackbarOpen) Get.back();
        break;
      case ConnectivityResult.none:
        connectionType = 0;
        update();
        if (Get.currentRoute != '/splash') {
          Get.snackbar(
            '',
            '',
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            messageText: const Text(
              'You are offline. Please check your internet connection.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.redAccent,
            icon: const Icon(
              Icons.info,
              size: 20,
              color: Colors.white,
            ),
            colorText: Colors.white,
            titleText: const SizedBox(
              height: 0,
            ),
            isDismissible: false,
            // duration: const Duration(hours: 24),
            // mainButton: TextButton(
            //   onPressed: () {
            //     Get.back();
            //   },
            //   child: const Icon(
            //     FSAIcons.cancel,
            //     size: 12,
            //     color: FSAColors.kcWhite,
            //   ),
            // ),
          );
        }
        break;
      default:
        Get.snackbar(
          'Network Error',
          'Failed to get Network Status',
          backgroundColor: Colors.redAccent,
        );
        break;
    }
  }

  @override
  void onClose() {
    _streamSubscription.cancel();
  }
}
