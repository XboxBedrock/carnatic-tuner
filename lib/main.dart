import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'util.dart';
import 'package:pitchupdart/instrument_type.dart';
import 'package:pitchupdart/pitch_handler.dart';
import 'custom_switch.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fftea/fftea.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';

const int tSampleRate = 44100;
typedef _Fn = void Function();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carnatic Tuner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        fontFamily: "MusGlyphs",
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Carnatic Tuner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int activeShruti = 5;
  int tonicOctave = 4;
  bool melakarta = false;
  FlutterSoundRecorder myRecorder = FlutterSoundRecorder();
  final pitchDetectorDart = PitchDetector(44100, 2000);
  final pitchUp = PitchHandler(InstrumentType.guitar);
  List<CarnaticNote> carnaticNote = [CarnaticNote("S", 0, "Shadjam", null)];
  int carnaticOctave = 0;
  double centsOff = 0.0;
  bool noteTimeout = true;
  Timer? _delay;

  List<String> showNotes = [
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B"
  ];

  late Map<String , dynamic> ragas = {};

  Future<void> loadRagas() async {
    var data = await rootBundle.loadString("assets/ragas.json");
    setState(() {
      ragas = json.decode(data);
    });
  }



  List<List<CarnaticNote>> relatives = [
    [CarnaticNote("S", 0, "Shadjam", null)],
    [CarnaticNote("R", 1, "Suddha Rishabham", 1)],
    [
      CarnaticNote("R", 2, "Chatusruti Rishabham", 2),
      CarnaticNote("G", 3, "Suddha Gandharam", 1)
    ],
    [
      CarnaticNote("R", 2, "ShatSruti Rishabham", 3),
      CarnaticNote("G", 3, "Sadharana Gandharam", 2)
    ],
    [CarnaticNote("G", 4, "Antara Gandharam", 3)],
    [CarnaticNote("M", 5, "Suddha Madhyamam", 1)],
    [CarnaticNote("M", 6, "Prati Madhyamam", 2)],
    [CarnaticNote("P", 7, "Panchamam", null)],
    [CarnaticNote("D", 8, "Suddha Dhaivatam", 1)],
    [
      CarnaticNote("D", 9, "Chatusruti Dhaivatam", 2),
      CarnaticNote("N", 9, "Suddha Nishadam", 1)
    ],
    [
      CarnaticNote("D", 9, "ShatSruti Dhaivatam", 3),
      CarnaticNote("N", 10, "Kaisiki Nishadam", 2)
    ],
    [CarnaticNote("N", 11, "Kakali Nishadam", 3)]
  ];
  final _audioRecorder = FlutterAudioCapture();

  void onError(err) {
    print("oops");
  }

  late String status;

  Future<void> _startCapture() async {
    await _audioRecorder.start(listener, onError,
        sampleRate: 44100, bufferSize: 3000);
  }

  Future<void> _stopCapture() async {
    await _audioRecorder.stop();
  }

  void listener(dynamic obj) {
    //Gets the audio sample
    var buffer = Float64List.fromList(obj.cast<double>());
    final List<double> audioSample = buffer.toList();

    //Uses pitch_detector_dart library to detect a pitch from the audio sample
    final result = pitchDetectorDart.getPitch(audioSample);

    //If there is a pitch - evaluate it
    if (result.pitched) {
      final res = pitchUp.handlePitch(result.pitch);
      if (res.expectedFrequency.roundToDouble() != 0.0) {
        print(res.expectedFrequency);
        int octave = getOctave(truncDouble(res.expectedFrequency, 2));
        int relHalfs =
            relativeHalfSteps(octave, res.note, activeShruti, tonicOctave);

        setState(() {
          carnaticNote = relatives[wrap(relHalfs)];

          double tOctave = relHalfs / 12;
          if (tOctave < 0) {
            carnaticOctave = tOctave.floor();
          }
          else {
            carnaticOctave = tOctave.toInt();
          }


          centsOff = res.diffCents;
          noteTimeout = false;

        });

        _delay?.cancel();

        _delay = Timer(const Duration(seconds: 1, milliseconds: 75), () {
          setState(() {
            noteTimeout = true;
          });
        });

        print("${res.note} ${relHalfs} $carnaticOctave ${carnaticNote}");
      }
    }
  }

  void setMelakarta(bool swap) {
    setState(() {
      melakarta = swap;
    });
  }

  void setShruti(int shruti) {
    setState(() {
      activeShruti = shruti;
    });
  }

  void Function() shrutiFunction(int shruti) {
    return () {
      setShruti(shruti);
    };
  }

  List<Widget> createUpperDots() {
    return [
      Container(
        child: Positioned(bottom: SizeConfig.screenHeight * 0.0248, child: RichText(

              text: TextSpan(
                  style: TextStyle(
                    color: noteTimeout? Colors.white.withOpacity(0): (carnaticOctave > 0 ? Colors.blue : Colors.white.withOpacity(0)),
                    fontSize: SizeConfig.screenHeight * 0.11,
                    fontFamily: 'Arial',

                  ),
                  children: [
            TextSpan(
              text: carnaticOctave > 1? "¨": "˙",

            ),
                    WidgetSpan(
                      child:
                       Text(
                          carnaticNote.every((e) {return e.subscript == null;})? "": "1",
                          style: TextStyle(
                              fontSize: SizeConfig.screenHeight * 0.045,
                              fontFamily: 'RobotoMono',
                              color: Colors.white),
                        ),
                    )
          ]))))
    ];

  }

  List<Widget> createLowerDots() {
    return [
      Container(
          child: Positioned(bottom: SizeConfig.screenHeight * -0.0951, child: RichText(

              text: TextSpan(
                  style: TextStyle(
                    color: noteTimeout? Colors.white.withOpacity(0): (carnaticOctave < 0 ? Colors.blue : Colors.white.withOpacity(0)),
                    fontSize: SizeConfig.screenHeight * 0.11,
                    fontFamily: 'Arial',

                  ),
                  children: [
                    TextSpan(
                      text: carnaticOctave < -1? "¨": "˙",

                    ),
                    WidgetSpan(
                      child:
                      Text(
                        carnaticNote.every((e) {return e.subscript == null;})? "": "1",
                        style: TextStyle(
                            fontSize: SizeConfig.screenHeight * 0.045,
                            fontFamily: 'RobotoMono',
                            color: Colors.white),
                      ),
                    )
                  ]))))
    ];

  }

  List<Widget> createNoteDisplay() {
    List<Widget> widgets = [];
    List<Widget> noteWidgets = [];
    int cnt = 0;
    for (CarnaticNote note in carnaticNote) {
      if (cnt == 1) {
        noteWidgets.add(RichText(
            text: TextSpan(
                style: TextStyle(
                  color: noteTimeout? Colors.white.withOpacity(0): Colors.grey,
                  fontSize: SizeConfig.screenHeight * 0.11,
                  fontFamily: 'Arial',
                ),
                children: const [
              TextSpan(
                text: "/",
              )
            ])));
      }
      noteWidgets
          .add(Stack( alignment: Alignment.center, clipBehavior: Clip.none, children: [
        ...createUpperDots(),
        RichText(
            text: TextSpan(
                style: TextStyle(
                  color: noteTimeout? Colors.white.withOpacity(0): Colors.blue,
                  fontSize: SizeConfig.screenHeight * 0.11,
                  fontFamily: 'Arial',
                ),
                children: [
              TextSpan(
                text: note.note,
              ),
              WidgetSpan(
                child: Transform.translate(
                  offset: Offset(0.0, SizeConfig.screenHeight * -0.0102),
                  child: Text(
                    note.subscript != null ? note.subscript.toString() : "",
                    style: TextStyle(
                        fontSize: SizeConfig.screenHeight * 0.045,
                        fontFamily: 'RobotoMono',
                        color: noteTimeout? Colors.white.withOpacity(0): Colors.grey),
                  ),
                ),
              )
            ])),
        ...createLowerDots()
      ]));
      cnt++;
    }

    widgets.add(SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: noteTimeout? Colors.grey :  centsColor(centsOff),
          inactiveTrackColor: noteTimeout? Colors.grey : centsColor(centsOff),
          trackShape: CustomTrackShape(),
          trackHeight: SizeConfig.screenHeight * 0.038,
          thumbColor: noteTimeout? Colors.grey : centsColor(centsOff),
          thumbShape:
              CustomSliderThumbCircle(thumbRadius: SizeConfig.screenHeight * 0.022, max: 50, min: -50),
          overlayColor: Colors.red.withAlpha(32),
          overlayShape: RoundSliderOverlayShape(overlayRadius: SizeConfig.screenHeight * 0.0409),
        ),
        child: Slider(
          min: 0.0,
          max: 100.0,
          value: noteTimeout? 50.0: (50.0 - centsOff),
          onChanged: (value) {},
        )));

    widgets.add(Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: noteWidgets,
    ));

    return widgets;
  }

  Widget createButtonGrid() {
    List<Widget> children = [];
    List<List<String>> noteGrid = [
      ["C", "C#", "D", "D#"],
      ["E", "F", "F#", "G"],
      ["G#", "A", "A#", "B"],
    ];

    int noteCounter = 0;
    for (List<String> notes in noteGrid) {
      List<Widget> rowChildren = [];
      for (String note in notes) {
        rowChildren.add(SizedBox(
            height: SizeConfig.screenHeight * 0.1,
            width: SizeConfig.screenHeight * 0.1,

            child: FloatingActionButton(
          onPressed: shrutiFunction(noteCounter),
          foregroundColor: Colors.blue,
          child: SizedBox(

              child: Text(note,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: SizeConfig.screenHeight * 0.0366,
                      fontFamily: "MusGlyphs"))),
        )));
        noteCounter++;
      }
      children.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rowChildren));
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    _startCapture();
    loadRagas();
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text("${widget.title} - ${showNotes[activeShruti]}"),
        ),
        body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...createNoteDisplay(),
              Center(
                  // Center is a layout widget. It takes a single child and positions it
                  // in the middle of the parent.
                  child: Container(
                      height: SizeConfig.screenHeight * 0.4, //or whatever you want
                      width: SizeConfig.screenWidth * 0.95, //or whatever you want
                      padding: EdgeInsets.all(SizeConfig.screenWidth * 0.01),
                      child: createButtonGrid())),
              //Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children:[CustomSwitch(
                //  key: const Key("slider"),
                  //activeColor: Colors.blue,
                  //value: melakarta,
                  //onChanged: setMelakarta), DropdownMenu(dropdownMenuEntries: [new DropdownMenuEntry(value: "e", label: "e")])])
            ]));
  }

  @override
  void dispose() {
    super.dispose();
    _delay?.cancel();
  }
}
