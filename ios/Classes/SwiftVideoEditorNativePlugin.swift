import Flutter
import UIKit
import AVFoundation
import Photos

public class SwiftVideoEditorNativePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "video_editor_native", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "video_editor_native_progress", binaryMessenger: registrar.messenger())

    let instance = SwiftVideoEditorNativePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "trimVideo":
      guard let args = call.arguments as? [String: Any],
            let videoPath = args["videoPath"] as? String,
            let startTimeMs = args["startTimeMs"] as? Int,
            let endTimeMs = args["endTimeMs"] as? Int
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid args", details: nil))
        return
      }
      trimVideo(videoPath: videoPath, startMs: startTimeMs, endMs: endTimeMs, result: result)

    case "flipVideo":
      guard let args = call.arguments as? [String: Any],
            let videoPath = args["videoPath"] as? String
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing video path", details: nil))
        return
      }
      flipVideoHorizontally(videoPath: videoPath, result: result)

    case "applyWatermark":
      guard let args = call.arguments as? [String: Any],
            let videoPath = args["videoPath"] as? String,
            let watermarkPath = args["watermarkPath"] as? String
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
        return
      }
      applyWatermark(videoPath: videoPath, watermarkPath: watermarkPath, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  private func getOutputURL(fileName: String = "output_trimmed.mp4") -> URL {
    let tempDir = FileManager.default.temporaryDirectory
    return tempDir.appendingPathComponent(fileName)
  }

  private func trimVideo(videoPath: String, startMs: Int, endMs: Int, result: @escaping FlutterResult) {
    let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
    let start = CMTime(milliseconds: startMs)
    let end = CMTime(milliseconds: endMs)
    let timeRange = CMTimeRange(start: start, end: end)

    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
      result(FlutterError(code: "EXPORT_FAILED", message: "Could not create export session", details: nil))
      return
    }

    let outputURL = getOutputURL(fileName: "output_trimmed.mp4")
    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mp4
    exportSession.timeRange = timeRange

    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
      if exportSession.status == .exporting {
        DispatchQueue.main.async {
          self.eventSink?(Double(exportSession.progress))
        }
      } else {
        timer.invalidate()
      }
    }

    exportSession.exportAsynchronously {
      if exportSession.status == .completed {
        result(outputURL.path)
      } else {
        result(FlutterError(code: "TRIM_FAILED", message: exportSession.error?.localizedDescription, details: nil))
      }
    }
  }

  private func flipVideoHorizontally(videoPath: String, result: @escaping FlutterResult) {
    let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality),
          let videoTrack = asset.tracks(withMediaType: .video).first else {
      result(FlutterError(code: "FLIP_FAILED", message: "Failed to access video track", details: nil))
      return
    }

    let composition = AVMutableComposition()
    guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
      result(FlutterError(code: "FLIP_FAILED", message: "Failed to add composition track", details: nil))
      return
    }

    do {
      try compositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
    } catch {
      result(FlutterError(code: "FLIP_FAILED", message: error.localizedDescription, details: nil))
      return
    }

    compositionTrack.preferredTransform = videoTrack.preferredTransform.concatenating(CGAffineTransform(scaleX: -1, y: 1))

    let outputURL = getOutputURL(fileName: "output_flipped.mp4")
    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mp4
    exportSession.videoComposition = AVVideoComposition(propertiesOf: composition)

    exportSession.exportAsynchronously {
      if exportSession.status == .completed {
        result(outputURL.path)
      } else {
        result(FlutterError(code: "FLIP_FAILED", message: exportSession.error?.localizedDescription, details: nil))
      }
    }
  }

  private func applyWatermark(videoPath: String, watermarkPath: String, result: @escaping FlutterResult) {
    let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality),
          let videoTrack = asset.tracks(withMediaType: .video).first else {
      result(FlutterError(code: "WATERMARK_FAILED", message: "Unable to access video track", details: nil))
      return
    }

    let composition = AVMutableComposition()
    guard let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
      result(FlutterError(code: "WATERMARK_FAILED", message: "Failed to add video track", details: nil))
      return
    }

    do {
      try videoCompositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
    } catch {
      result(FlutterError(code: "WATERMARK_FAILED", message: error.localizedDescription, details: nil))
      return
    }

    let size = videoTrack.naturalSize
    let videoLayer = CALayer()
    videoLayer.frame = CGRect(origin: .zero, size: size)

    let watermarkLayer = CALayer()
    let image = UIImage(contentsOfFile: watermarkPath)
    watermarkLayer.contents = image?.cgImage
    watermarkLayer.frame = CGRect(x: 20, y: 20, width: 100, height: 100)
    watermarkLayer.opacity = 0.9

    let parentLayer = CALayer()
    let compositionLayer = CALayer()
    parentLayer.frame = CGRect(origin: .zero, size: size)
    compositionLayer.frame = CGRect(origin: .zero, size: size)
    parentLayer.addSublayer(videoLayer)
    parentLayer.addSublayer(watermarkLayer)

    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = size
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)

    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)

    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    instruction.layerInstructions = [layerInstruction]
    videoComposition.instructions = [instruction]

    exportSession.videoComposition = videoComposition
    let outputURL = getOutputURL(fileName: "output_watermarked.mp4")
    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mp4

    exportSession.exportAsynchronously {
      if exportSession.status == .completed {
        result(outputURL.path)
      } else {
        result(FlutterError(code: "WATERMARK_FAILED", message: exportSession.error?.localizedDescription, details: nil))
      }
    }
  }
}

fileprivate extension CMTime {
  init(milliseconds: Int) {
    self = CMTime(value: CMTimeValue(milliseconds), timescale: 1000)
  }
}