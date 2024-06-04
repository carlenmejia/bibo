import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/maintainance_mode/maintainance_screen.dart';
import 'package:ride_sharing_user_app/features/onboard/screens/onboarding_screen.dart';
import 'package:ride_sharing_user_app/features/trip/controllers/trip_controller.dart';
import 'package:ride_sharing_user_app/helper/pusher_helper.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/screens/sign_in_screen.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/location/view/access_location_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/screens/edit_profile_screen.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  StreamSubscription<ConnectivityResult>? _onConnectivityChanged;

  late AnimationController _controller;
  late Animation _animation;


  @override
  void initState() {
    super.initState();

    Get.find<TripController>().getOngoingAndAcceptedCancellationCauseList();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });


    _controller.repeat(max: 1);
    _controller.forward();
    bool firstTime = true;
    Connectivity connectivity = Connectivity();
    connectivity.checkConnectivity();
    _onConnectivityChanged = connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if(!firstTime) {
        bool isNotConnected = result != ConnectivityResult.wifi && result != ConnectivityResult.mobile;
        if(!isNotConnected) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: isNotConnected ? Colors.red : Colors.green,
          duration: Duration(seconds: isNotConnected ? 6000 : 3),
          content: Text(
            isNotConnected ? 'no_connection'.tr : 'connected'.tr,
            textAlign: TextAlign.center,
          ),
        ));
        if(!isNotConnected) {
          _route();
        }
      }else {
        firstTime = false;
      }
    });

    Get.find<ConfigController>().initSharedData();
    _route();

  }
  @override
  void dispose() {
    _controller.dispose();
    _onConnectivityChanged?.cancel();
    super.dispose();
  }

  void _route() async {
    await Get.find<ConfigController>().getConfigData().then((value) {
      if(value.statusCode == 200) {

        if(Get.find<AuthController>().getUserToken().isNotEmpty){
          PusherHelper.initilizePusher();
        }

        Future.delayed(const Duration(milliseconds: 100), () {
          if(Get.find<ConfigController>().config!.maintenanceMode != null && Get.find<ConfigController>().config!.maintenanceMode!){
            Get.offAll(() => const MaintenanceScreen());
          }else{
            if(Get.find<AuthController>().isLoggedIn()) {
              if(Get.find<LocationController>().getUserAddress() != null
                  && Get.find<LocationController>().getUserAddress()!.address != null
                  && Get.find<LocationController>().getUserAddress()!.address!.isNotEmpty) {

                Get.find<ProfileController>().getProfileInfo().then((value) {
                  if(value.statusCode == 200) {
                    Get.find<AuthController>().updateToken();
                    if(value.body['data']['is_profile_verified'] == 1) {
                      Get.find<AuthController>().remainingFindingRideTime();
                      Get.offAll(()=> const DashboardScreen());
                     // Get.find<RideController>().getCurrentRideStatus();
                    }else {
                      Get.offAll(() => const EditProfileScreen(fromLogin: true));
                    }
                  }
                });

              }else{
                Get.offAll(() => const AccessLocationScreen());
              }

            }else{
              if (Get.find<ConfigController>().showIntro()) {
                Get.offAll(() => const OnBoardingScreen());
              } else {
                Get.offAll(() => const SignInScreen());
              }
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Theme.of(context).primaryColorDark),
        alignment: Alignment.bottomCenter,
        child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [

          Stack(alignment: AlignmentDirectional.bottomCenter, children: [

            Container(
              transform: Matrix4.translationValues(0, 320 - (320 * double.tryParse(_animation.value.toString())!), 0),
              child: Column(children: [
                Opacity(
                  opacity: _animation.value,
                  child: Padding(
                    padding: EdgeInsets.only(left: 120 - ((120 * double.tryParse(_animation.value.toString())!))),
                    child: Image.asset(Images.splashLogo,width: 160),
                  ),
                ),
                const SizedBox(height: 50),
                Image.asset(Images.splashBackgroundOne, width: Get.width, height: Get.height/2, fit: BoxFit.cover)]),
            ),

            Container(
              transform: Matrix4.translationValues(0, 20, 0),
              child: Padding(
                padding:EdgeInsets.symmetric(horizontal:(70 * double.tryParse(_animation.value.toString())!)),
                child: Image.asset(Images.splashBackgroundTwo, width: Get.size.width),
              ),
            ),

          ]),

        ]),
      ),
    );
  }
}
