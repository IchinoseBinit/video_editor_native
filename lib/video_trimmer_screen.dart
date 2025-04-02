import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor_native/video_editor_native.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoTrimmerScreen extends StatefulWidget {
  final File videoFile;

  const VideoTrimmerScreen({super.key, required this.videoFile});

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  late VideoPlayerController _controller;
  final List<File> _thumbnails = [];
  double _startMs = 0;
  double _endMs = 0;
  bool _isTrimming = false;
  Duration? _videoDuration;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) async {
        _videoDuration = _controller.value.duration;
        _endMs = _videoDuration!.inMilliseconds.toDouble();
        await _generateThumbnails();
        setState(() {});
        _controller.play();
      });
    _controller.addListener(_updatePlayhead);
  }

  @override
  void dispose() {
    _controller.removeListener(_updatePlayhead);
    _controller.dispose();
    for (var thumb in _thumbnails) {
      thumb.deleteSync();
    }
    super.dispose();
  }

  double _playheadMs = 0;

  void _updatePlayhead() {
    setState(() {
      _playheadMs = _controller.value.position.inMilliseconds.toDouble();
    });
  }

  Future<void> _generateThumbnails() async {
    final tempDir = await getTemporaryDirectory();
    final durationMs = _controller.value.duration.inMilliseconds;
    final numThumbs = 10;
    final interval = durationMs ~/ numThumbs;

    for (int i = 0; i < numThumbs; i++) {
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: widget.videoFile.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        timeMs: i * interval,
        quality: 75,
      );
      if (thumbPath != null) _thumbnails.add(File(thumbPath));
    }
  }

  Future<void> _trimVideo() async {
    setState(() => _isTrimming = true);
    final trimmed = await VideoEditorNative.trimVideo(
      videoPath: widget.videoFile.path,
      startTimeMs: _startMs.toInt(),
      endTimeMs: _endMs.toInt(),
    );
    setState(() => _isTrimming = false);

    if (trimmed != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Trimmed video saved: ${trimmed.path}"),
      ));
    }
  }

  void _seekTo(double ms) {
    _controller.seekTo(Duration(milliseconds: ms.toInt()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trim Video")),
      body: _controller.value.isInitialized
          ? Column(
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                const SizedBox(height: 10),
                _buildThumbnailStrip(),
                const SizedBox(height: 10),
                _buildRangeSlider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _seekTo(_startMs),
                      icon: const Icon(Icons.skip_previous),
                      label: const Text("To Start"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _seekTo(_endMs),
                      icon: const Icon(Icons.skip_next),
                      label: const Text("To End"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isTrimming ? null : _trimVideo,
                  child: _isTrimming
                      ? const CircularProgressIndicator()
                      : const Text("Trim Video"),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildThumbnailStrip() {
    return _thumbnails.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SizedBox(
            height: 60,
            child: Row(
              children: _thumbnails
                  .map((thumb) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Image.file(thumb, height: 60, width: 40, fit: BoxFit.cover),
                      ))
                  .toList(),
            ),
          );
  }

  Widget _buildRangeSlider() {
    return FlutterSlider(
      values: [_startMs, _endMs],
      max: _controller.value.duration.inMilliseconds.toDouble(),
      min: 0,
      rangeSlider: true,
      trackBar: FlutterSliderTrackBar(
        activeTrackBar: BoxDecoration(color: Colors.blue),
        inactiveTrackBar: BoxDecoration(color: Colors.grey.shade300),
      ),
      handler: FlutterSliderHandler(
        decoration: const BoxDecoration(),
        child: const Icon(Icons.circle, color: Colors.blue),
      ),
      rightHandler: FlutterSliderHandler(
        decoration: const BoxDecoration(),
        child: const Icon(Icons.circle, color: Colors.blue),
      ),
      tooltip: FlutterSliderTooltip(
        alwaysShowTooltip: true,
        format: (val) => "${(int.parse(val) / 1000).toStringAsFixed(1)}s",
      ),
      onDragging: (handlerIndex, lowerValue, upperValue) {
        setState(() {
          _startMs = lowerValue;
          _endMs = upperValue;
          if (_controller.value.isPlaying) _controller.pause();
        });
      },
    );
  }
}
