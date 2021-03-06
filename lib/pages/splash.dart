import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:get/get.dart';

import 'package:new_version/new_version.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/api.dart';
import '../helpers/globals.dart' as globals;

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  dynamic vesrion = '';
  dynamic url = 'https://play.google.com/store/apps/details?id=com.mdokon.cabinet';
  bool isRequired = false;

  checkVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String localVersion = packageInfo.version;

    var playMarketVersion = await guestGet('/services/admin/api/get-version?name=com.mdokon.cabinet');
    if (playMarketVersion == null) {
      startTimer();
    }
    print(playMarketVersion);
    if (playMarketVersion['version'] != localVersion) {
      if (playMarketVersion['required']) {
        setState(() {
          isRequired = true;
        });
      }

      await showUpdateDialog();
      return;
    } else {
      startTimer();
    }
  }

  startTimer() {
    var _duration = const Duration(milliseconds: 1500);
    return Timer(_duration, navigate);
  }

  navigate() async {
    Get.offAllNamed('/login');
  }

  @override
  void initState() {
    super.initState();
    checkVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: globals.white,
      body: Center(
        child: Image.asset(
          'images/splash_logo.png',
          height: 200,
          width: 200,
        ),
      ),
    );
  }

  showUpdateDialog() async {
    await showDialog(
        context: context,
        // barrierDismissible: !isRequired,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              insetPadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
              title: Text(
                '???????????????? ???????????????????? moneyBek',
                style: const TextStyle(color: Colors.black),
                // textAlign: TextAlign.center,
              ),
              scrollable: true,
              content: SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      isRequired
                          ? '?????????????????? ???????????????????? ?????????????????? ???????????? ?????????? ???????????????????? ???????????????????????? ???????????????????? moneyBek'
                          : '?????????????????????? ???????????????????? ?????????????????? ???????????? ???????????????????? moneyBek ???? ?????????? ???????????????????? ???????????????????? ???? ????-???????????????? ?????????????? ???? ????????????????????????.',
                      style: const TextStyle(color: Colors.black, height: 1.2),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Container(
                      padding: const EdgeInsets.only(bottom: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          isRequired
                              ? Container()
                              : Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  child: TextButton(
                                    onPressed: () {
                                      Get.back();
                                    },
                                    style: TextButton.styleFrom(primary: const Color(0xFF00865F)),
                                    child: Text(
                                      '??????, ??????????????',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                          ElevatedButton(
                            onPressed: () {
                              launch(url);
                            },
                            style: ElevatedButton.styleFrom(
                              primary: const Color(0xFF00865F),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 0,
                            ),
                            child: Text('????????????????'),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Image.asset(
                        'images/google_play.png',
                        height: 25,
                        fit: BoxFit.cover,
                      ),
                    )
                  ],
                ),
              ),
            );
          });
        });
  }
}
