import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:sensors/sensors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fall Detection App',
      theme: ThemeData(primarySwatch: Colors.lightBlue),
      home: const MyHomePage(title: 'Fall Detection App'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const countDownDuration = Duration(seconds: 60);

  var seconds = 60;
  Duration duration = const Duration(seconds: 60);
  Timer? timer;
  bool hasFallen = false;
  bool isCountDown = true;
  bool contactAuthorities = false;

  @override
  void initState() {
    _startSensorUpdates();
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  int i = 0;
  bool minTreshholdMet = false;
  bool maxTreshholdMet = false;

  void _startSensorUpdates() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      double alpha = 0.8;
      double x_gravity = 0;
      double y_gravity = 0;
      double z_gravity = 0;

      // Low Pass Filter equation.
      x_gravity = alpha * x_gravity + (1 - alpha) * event.x;
      z_gravity = alpha * z_gravity + (1 - alpha) * event.y;
      y_gravity = alpha * y_gravity + (1 - alpha) * event.z;

      double x = event.x - x_gravity;
      double y = event.y - y_gravity;
      double z = event.z - z_gravity;

      double phoneState = sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2));
      print(phoneState);

      if (phoneState <= 1.0) {
        minTreshholdMet = true;
        print("MinTreshold");
      }

      if (minTreshholdMet) {
        i++;
      }

      if (phoneState > 17.5) {
        maxTreshholdMet = true;
        print("MaxTreshold");
      }

      if (minTreshholdMet && maxTreshholdMet) {
        print("Triggering Fall!");
        fallTrigger();
        i = 0;
        minTreshholdMet = false;
        maxTreshholdMet = false;
      }

      if (i > 6) {
        i = 0;
        minTreshholdMet = false;
        maxTreshholdMet = false;
      }
    });
    sleep(Durations.extralong4);
  }

  void startTimer() {
    setState(() {
      timer =
          Timer.periodic(const Duration(seconds: 1), (Timer t) => decrement());
    });
  }

  void decrement() {
    setState(() {
      if (isCountDown) {
        seconds = duration.inSeconds - 1;
        if (seconds < 0) {
          confirmedFall();
        } else {
          duration = Duration(seconds: seconds);
        }
      }
    });
  }

  void resetTimer() {
    timer?.cancel();
    duration = countDownDuration;
    timer = null;
  }

  void resetApp() {
    setState(() {
      hasFallen = false;
      isCountDown = true;
      contactAuthorities = false;
    });
    resetTimer();
  }

  void fallTrigger() {
    setState(() {
      hasFallen = true;
    });
    startTimer();
  }

  void confirmedFall() {
    setState(() {
      contactAuthorities = true;
      isCountDown = false;
      hasFallen = true;
    });
    sendEmail();
    resetTimer();
  }

  void sendEmail() async {
    final Email email = Email(
      body: 'There has been a fall. Please check on the user',
      subject: '[EMERGENCY!] A Fall Has Been Detected!',
      recipients: ['kiptugenchristian@gmail.com'],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Visibility(
              visible: !hasFallen,
              child: const Text(
                "No fall detected \n Enjoy yourself.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Visibility(
              visible: (hasFallen & !contactAuthorities),
              child: const Text(
                'Fall detected \n Are you OK?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Visibility(
              visible: (hasFallen & !contactAuthorities),
              child: const Text(
                "Contacting help in...",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            Visibility(
              visible: (hasFallen & !contactAuthorities),
              child: buildTime(),
            ),
            Visibility(
              visible: contactAuthorities,
              child: const Text("Help is on the way",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  child: ElevatedButton(
                    onPressed: resetApp,
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                      shadowColor: MaterialStateProperty.all<Color>(
                          Colors.green.withOpacity(0.5)),
                      fixedSize:
                          MaterialStateProperty.all<Size>(const Size(100, 50)),
                    ),
                    child: const Text(
                      "Yes",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 9,
                ),
                Visibility(
                    visible: (hasFallen & !contactAuthorities),
                    child: ElevatedButton(
                      onPressed: confirmedFall,
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.red),
                        shadowColor: MaterialStateProperty.all<Color>(
                            Colors.red.withOpacity(0.5)),
                        fixedSize: MaterialStateProperty.all<Size>(
                            const Size(100, 50)),
                      ),
                      child: const Text(
                        "No",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    )),
                Visibility(
                  visible: contactAuthorities,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 9,
                      ),
                      Visibility(
                        visible: contactAuthorities,
                        child: ElevatedButton(
                          onPressed: resetApp,
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.red),
                            shadowColor: MaterialStateProperty.all<Color>(
                                Colors.red.withOpacity(0.5)),
                            fixedSize: MaterialStateProperty.all<Size>(
                                const Size(100, 50)),
                          ),
                          child: const Text(
                            "Reset",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTime() {
    return Text(
      '${duration.inSeconds}',
      style: const TextStyle(fontSize: 20),
    );
  }
}
