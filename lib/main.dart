import 'dart:async';
import 'package:wakelock/wakelock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.teal,
      brightness: Brightness.dark,
    ),
    home: MyHomePage(),
  ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static var maxSeconds = 60;
  static var maxRestSeconds = 10;
  static var sets = 20;

  bool screenLock = false;
  int seconds = maxSeconds;
  int restCount = sets;
  Timer? timer;
  bool isRest = false;

  Widget insertNumber({isSets = false, isTimer = false, isRestTime = false}) {
    return TextField(
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: 30),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
      onChanged: (text) {
        var num = int.parse(text);
        if (isSets) {
          setState(() {
            sets = num;
          });
        }
        if (isTimer) {
          if (num != 0)
            setState(() {
              maxSeconds = num;
              seconds = maxSeconds;
            });
        }
        if (isRestTime) {
          setState(() {
            maxRestSeconds = num;
          });
        }
      },
    );
  }

  void addTime(int value) {
    setState(() {
      maxSeconds = maxSeconds + value;
      seconds = maxSeconds;
    });
  }

  void timerReset() {
    setState(() {
      seconds = maxSeconds;
      restCount = 0;
      isRest = false;
      Wakelock.toggle(enable: screenLock);
    });
  }

  void startTimer() {
    screenLock = true;
    Wakelock.toggle(enable: screenLock);

    timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (seconds > 0 && restCount > 0) {
        setState(() {
          seconds--;
        });
      } else if (seconds == 0 && isRest == false) {
        playLocalAsset();
        seconds = maxRestSeconds;
        isRest = true;
        restCount--;
      } else if (seconds == 0 && isRest == true) {
        playLocalAsset();
        seconds = maxSeconds;
        isRest = false;
      } else {
        setState(() {
          screenLock = false;
          timer?.cancel();
          timerReset();
        });
      }
    });
  }

  void stopTimer({bool reset = true}) {
    screenLock = false;
    Wakelock.toggle(enable: screenLock);
    if (reset) {
      timerReset();
    }

    setState(() => timer?.cancel());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'WORKOUT TIMER',
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 50,
                  ),
                  buildTimer(),
                  SizedBox(
                    height: 45,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.accessibility_new),
                          Text('$maxSeconds secs'),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.timelapse),
                          Text('$maxRestSeconds secs'),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.history),
                          Text('$restCount'),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Expanded(
                      child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(30),
                          topLeft: Radius.circular(30)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text('Work:'),
                                SizedBox(
                                    width: 35,
                                    child: insertNumber(isTimer: true)),
                              ],
                            ),
                            Column(
                              children: [
                                Text('Rest:'),
                                SizedBox(
                                    width: 35,
                                    child: insertNumber(isRestTime: true)),
                              ],
                            ),
                            Column(
                              children: [
                                Text('Sets:'),
                                SizedBox(
                                    width: 35,
                                    child: insertNumber(isSets: true)),
                              ],
                            ),
                          ],
                        ),
                        toggleButton(),
                      ],
                    ),
                  )),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<AudioPlayer> playLocalAsset() async {
    AudioCache cache = new AudioCache();
    //At the next line, DO NOT pass the entire reference such as assets/yes.mp3. This will not work.
    //Just pass the file name only.
    return await cache.play("TimesUp.MP3");
  }

  Widget toggleButton() {
    final isRunning = timer == null ? false : timer!.isActive;
    final isCompleted = seconds == 0 || seconds == maxSeconds;

    return isRunning || !isCompleted
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () {
                    if (isRunning) {
                      stopTimer(reset: false);
                    } else {
                      startTimer();
                    }
                  },
                  child: Text(isRunning ? 'pause' : 'resume')),
              SizedBox(
                width: 5,
              ),
              ElevatedButton(
                  onPressed: () {
                    stopTimer();
                  },
                  child: Text('cancel'))
            ],
          )
        : ElevatedButton(
            onPressed: () {
              setState(() => restCount = sets);
              startTimer();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Text('Start Timer'),
            ));
  }

  Widget buildTimer() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: isRest ? seconds / maxRestSeconds : seconds / maxSeconds,
            strokeWidth: 12,
            backgroundColor: Colors.white10,
          ),
          Center(
            child: buildTime(),
          )
        ],
      ),
    );
  }

  Widget buildTime() {
    //bool isDone = true;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isRest ? 'Rest Time' : 'Work Time'),
        Text(
          '$seconds',
          style: TextStyle(fontSize: 80),
        ),
        Icon(isRest ? Icons.timelapse : Icons.accessibility_new),
      ],
    );
  }
}
