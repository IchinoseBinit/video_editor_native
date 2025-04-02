import 'package:flutter/material.dart';
import 'package:video_editor_native/video_editor_native.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
  }

  void processVideo() async {
    final inputVideo = "/storage/emulated/0/DCIM/sample.mp4";
    final watermarkImage = "/storage/emulated/0/Download/logo.png";

    final watermarked = await VideoEditorNative.applyWatermark(
      videoPath: inputVideo,
      watermarkPath: watermarkImage,
    );

    final flipped = await VideoEditorNative.flipVideo(inputVideo);

    final trimmed = await VideoEditorNative.trimVideo(
      videoPath: inputVideo,
      startTimeMs: 5000,
      endTimeMs: 15000,
    );

    print("Watermarked: ${watermarked?.path}");
    print("Flipped: ${flipped?.path}");
    print("Trimmed: ${trimmed?.path}");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: InkWell(
            child: Text("Process Video"),
            onTap: processVideo,
          ),
        ),
      ),
    );
  }
}
