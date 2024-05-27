import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/auth/sign_in_screen.dart';
import 'package:booking_system_flutter/screens/booking/booking_detail_screen.dart';
import 'package:booking_system_flutter/screens/category/category_screen.dart';
import 'package:booking_system_flutter/screens/chat/chat_list_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/booking_fragment.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/dashboard_fragment.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/profile_fragment.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../utils/firebase_messaging_utils.dart';

class DashboardScreen extends StatefulWidget {
  final bool? redirectToBooking;

  DashboardScreen({this.redirectToBooking});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.redirectToBooking.validate(value: false)) {
      currentIndex = 1;
    }

    afterBuildCreated(() async {
      /// Changes System theme when changed
      if (getIntAsync(THEME_MODE_INDEX) == THEME_MODE_SYSTEM) {
        appStore.setDarkMode(context.platformBrightness() == Brightness.dark);
      }

      View.of(context).platformDispatcher.onPlatformBrightnessChanged =
          () async {
        if (getIntAsync(THEME_MODE_INDEX) == THEME_MODE_SYSTEM) {
          appStore.setDarkMode(
              MediaQuery.of(context).platformBrightness == Brightness.light);
        }
      };
    });

    /// Handle Firebase Notification click and redirect to that Service & BookDetail screen
    LiveStream().on(LIVESTREAM_FIREBASE, (value) {
      if (value == 3) {
        currentIndex = 3;
        setState(() {});
      }
    });

    //When the app is in the background and opened directly from the push notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      //Handle onClick Notification
      log("data 1 ==> ${message.data}");
      handleNotificationClick(message);
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      //Handle onClick Notification
      if (message != null) {
        log("data 2 ==> ${message.data}");
        handleNotificationClick(message);
      }
    });

    init();
  }

  void init() async {
    if (isMobile && appStore.isLoggedIn) {
      /// Handle Notification click and redirect to that Service & BookDetail screen
      OneSignal.Notifications.addClickListener((notification) async {
        if (notification.notification.additionalData == null) return;

        if (notification.notification.additionalData!.containsKey('id')) {
          String? notId =
              notification.notification.additionalData!["id"].toString();
          if (notId.validate().isNotEmpty) {
            BookingDetailScreen(bookingId: notId.toString().toInt())
                .launch(context);
          }
        } else if (notification.notification.additionalData!
            .containsKey('service_id')) {
          String? notId =
              notification.notification.additionalData!["service_id"];
          if (notId.validate().isNotEmpty) {
            ServiceDetailScreen(serviceId: notId.toInt()).launch(context);
          }
        } else if (notification.notification.additionalData!
            .containsKey('sender_uid')) {
          String? notId =
              notification.notification.additionalData!["sender_uid"];
          if (notId.validate().isNotEmpty) {
            currentIndex = 3;
            setState(() {});
          }
        }
      });
    }

    await 3.seconds.delay;
    if (getIntAsync(FORCE_UPDATE_USER_APP).getBoolInt()) {
      showForceUpdateDialog(context);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
    LiveStream().dispose(LIVESTREAM_FIREBASE);
  }

  @override
  Widget build(BuildContext context) {
    return DoublePressBackWidget(
      message: language.lblBackPressMsg,
      child: Scaffold(
        body: [
          DashboardFragment(),
          Observer(
              builder: (context) => appStore.isLoggedIn
                  ? BookingFragment()
                  : SignInScreen(isFromDashboard: true)),
          CategoryScreen(),
          ProfileFragment(),
        ][currentIndex],
        bottomNavigationBar: Blur(
          blur: 30,
          borderRadius: radius(0),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: context.primaryColor.withOpacity(0.02),
              indicatorColor: context.primaryColor.withOpacity(0.1),
              labelTextStyle:
                  MaterialStateProperty.all(primaryTextStyle(size: 12)),
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              destinations: [
                NavigationDestination(
                  icon: ic_home.iconImage(color: appTextSecondaryColor),
                  selectedIcon: ic_home.iconImage(color: context.primaryColor),
                  label: language.home,
                ),
                NavigationDestination(
                  icon: ic_ticket.iconImage(color: appTextSecondaryColor),
                  selectedIcon:
                      ic_ticket.iconImage(color: context.primaryColor),
                  label: language.booking,
                ),
                NavigationDestination(
                  icon: ic_category.iconImage(color: appTextSecondaryColor),
                  selectedIcon:
                      ic_category.iconImage(color: context.primaryColor),
                  label: language.category,
                ),
                NavigationDestination(
                  icon: ic_profile2.iconImage(color: appTextSecondaryColor),
                  selectedIcon:
                      ic_profile2.iconImage(color: context.primaryColor),
                  label: language.profile,
                ),
              ],
              onDestinationSelected: (index) {
                currentIndex = index;
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }
}
