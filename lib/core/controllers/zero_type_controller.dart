import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zero_type/core/di/injection.dart';
import 'package:zero_type/core/services/recording_service.dart';
import 'package:zero_type/core/services/sound_service.dart';
import 'package:zero_type/core/services/speech_recognition_service.dart';
import 'package:zero_type/core/state/zero_type_state.dart';
import 'package:zero_type/features/model_config/presentation/controllers/model_config_controller.dart';
import 'package:zero_type/features/prompt/presentation/controllers/prompt_controller.dart';
import 'package:zero_type/features/dictionary/presentation/controllers/dictionary_controller.dart';

part 'zero_type_controller.g.dart';

@Riverpod(keepAlive: true)
class ZeroTypeController extends _$ZeroTypeController {
  late final RecordingService _recordingService;
  bool _cancelled = false;

  @override
  ZeroTypeState build() {
    _recordingService = RecordingService();
    ref.onDispose(() => _recordingService.dispose());

    // Listen for cancel signals from the native overlay (X button or ESC)
    const controlChannel = MethodChannel('com.zerotype.app/control');
    controlChannel.setMethodCallHandler((call) async {
      if (call.method == 'cancel') await cancel();
    });

    return const ZeroTypeState();
  }

  Future<void> toggleRecording() async {
    print('[ZeroTypeController] Hotkey triggered! Current status: ${state.status}');
    if (state.status == ZeroTypeStatus.recording) {
      await _stopAndProcess();
    } else if (state.status == ZeroTypeStatus.idle) {
      await _startRecording();
    } else {
      await cancel();
    }
  }

  Future<void> cancel() async {
    _cancelled = true;
    if (state.status == ZeroTypeStatus.recording) {
      await _recordingService.cancelRecording();
    }
    await getIt<SoundService>().playCancelSound();
    await getIt<SoundService>().resumeMusic(); // Resume music if cancelled
    state = const ZeroTypeState();
    await _hideNativeOverlay();
  }

  Future<void> _startRecording() async {
    _cancelled = false;
    
    // Pre-check configuration
    final config = await ref.read(speechProviderControllerProvider.future);
    if (config.providerId == null || config.providerId!.isEmpty || 
        config.apiKey == null || config.apiKey!.isEmpty || 
        config.modelId == null || config.modelId!.isEmpty) {
      await _showNativeOverlay('error', '請先完成語音辨識模型設定');
      await getIt<SoundService>().playCancelSound();
      await Future.delayed(const Duration(seconds: 3));
      if (ref.mounted && !_cancelled) {
        state = const ZeroTypeState();
        await _hideNativeOverlay();
      }
      return;
    }

    // Check accessibility permission
    const permissionChannel = MethodChannel('com.zerotype.app/permission');
    bool isAccessibilityOk = false;
    try {
      isAccessibilityOk =
          await permissionChannel.invokeMethod<bool>('checkAccessibility') ??
              false;
    } catch (_) {}
    if (!ref.mounted || _cancelled) return;
    if (!isAccessibilityOk) {
      await _showNativeOverlay('error', '請先授權輔助使用權限');
      await getIt<SoundService>().playCancelSound();
      await Future.delayed(const Duration(seconds: 3));
      if (ref.mounted && !_cancelled) {
        state = const ZeroTypeState();
        await _hideNativeOverlay();
      }
      return;
    }

    final hasPermission = await _recordingService.requestPermission();
    if (!ref.mounted || _cancelled) return;
    if (!hasPermission) {
      await _showNativeOverlay('error', '請先授權麥克風權限');
      await getIt<SoundService>().playCancelSound();
      await Future.delayed(const Duration(seconds: 3));
      if (ref.mounted && !_cancelled) {
        state = const ZeroTypeState();
        await _hideNativeOverlay();
      }
      return;
    }

    await getIt<SoundService>().pauseMusic(); // Pause background music
    await getIt<SoundService>().playStartSound();
    if (!ref.mounted || _cancelled) return;
    state = state.copyWith(status: ZeroTypeStatus.recording, amplitude: 0.0);
    await _showNativeOverlay('recording', '錄音中');

    try {
      await _recordingService.startRecording(
        onAmplitude: (amp) {
          if (ref.mounted && !_cancelled) {
            state = state.copyWith(amplitude: amp);
            _updateNativeAmplitude(amp);
          }
        },
      );
    } catch (e) {
      if (!ref.mounted || _cancelled) return;
      state = state.copyWith(
        status: ZeroTypeStatus.error,
        errorMessage: '錄音啟動失敗：$e',
      );
      await _showNativeOverlay('error', '錄音啟動失敗');
      await Future.delayed(const Duration(seconds: 3));
      if (ref.mounted && !_cancelled) {
        state = const ZeroTypeState();
        await _hideNativeOverlay();
      }
    }
  }

  Future<String?> _transcribe(String filePath) async {
    final config = await ref.read(speechProviderControllerProvider.future);
    final prompt = await ref.read(speechPromptControllerProvider.future);
    final dictionaryPrompt = await ref.read(dictionaryRepositoryProvider).buildDictionaryPrompt();

    if (config.providerId == null || config.apiKey == null || config.modelId == null) {
      throw Exception('請先完成語音辨識模型設定');
    }

    final finalPrompt = dictionaryPrompt.isEmpty ? prompt : '$prompt\n\n$dictionaryPrompt';

    final service = getIt<SpeechRecognitionService>();
    return service.transcribe(
      audioFilePath: filePath,
      apiKey: config.apiKey!,
      provider: config.providerId!,
      model: config.modelId!,
      prompt: finalPrompt,
      customEndpoint: config.customEndpoint,
    );
  }

  Future<void> _stopAndProcess() async {
    // Immediately show "擷取中" so the user sees instant feedback
    state = state.copyWith(status: ZeroTypeStatus.saving);
    await _showNativeOverlay('saving', '擷取中');

    try {
      // 1. Finalize the audio file (may take a moment)
      final stopFuture = _recordingService.stopRecording();

      // 2. Play stop sound in parallel
      final soundFuture = getIt<SoundService>().playStopSound();
      getIt<SoundService>().resumeMusic();

      final filePath = await stopFuture;
      await soundFuture;

      if (!ref.mounted || _cancelled || filePath == null) {
        state = const ZeroTypeState();
        await _hideNativeOverlay();
        return;
      }

      // 3. Switch to transcribing now that the file is ready
      state = state.copyWith(status: ZeroTypeStatus.transcribing);
      await _showNativeOverlay('transcribing', '辨識中');
      final transcribedText = await _transcribe(filePath);
      await _recordingService.deleteFile(filePath);
      
      if (transcribedText == null || transcribedText.isEmpty) {
        throw Exception('未能辨識出任何文字');
      }

      final finalResult = transcribedText;

      // 3. Output
      state = state.copyWith(status: ZeroTypeStatus.done, result: finalResult);
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: finalResult));
      
      // Small delay to ensure clipboard is synchronized and native keys (like the hotkey) are released
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Simulate paste
      print('[ZeroType] Simulating paste...');
      const channel = MethodChannel('com.zerotype.app/keyboard');
      await channel.invokeMethod('simulatePaste');

      await _showNativeOverlay('done', '已完成');
      await Future.delayed(const Duration(seconds: 2));
      
      if (ref.mounted && !_cancelled) {
        state = const ZeroTypeState();
        await _hideNativeOverlay();
      }
    } catch (e, st) {
      print('[ZeroType] ERROR in _stopAndProcess: $e\n$st');
      if (!ref.mounted || _cancelled) return;
      state = state.copyWith(
        status: ZeroTypeStatus.error,
        errorMessage: e.toString(),
      );
      await _showNativeOverlay('error', '處理失敗：$e');
      await getIt<SoundService>().resumeMusic(); // Ensure music resumes on error
      await Future.delayed(const Duration(seconds: 3));
      if (ref.mounted && !_cancelled) {
        state = const ZeroTypeState();
        await _hideNativeOverlay();
      }
    }
  }

  Future<void> showOverlay(String status, String message) =>
      _showNativeOverlay(status, message);

  Future<void> hideOverlay() => _hideNativeOverlay();

  Future<void> _showNativeOverlay(String status, String message) async {
    const channel = MethodChannel('com.zerotype.app/overlay');
    try {
      await channel.invokeMethod<void>('show', {
        'status': status,
        'message': message,
      });
    } catch (_) {}
  }

  Future<void> _hideNativeOverlay() async {
    const channel = MethodChannel('com.zerotype.app/overlay');
    try {
      await channel.invokeMethod<void>('hide');
    } catch (_) {}
  }

  Future<void> _updateNativeAmplitude(double amplitude) async {
    const channel = MethodChannel('com.zerotype.app/overlay');
    try {
      await channel.invokeMethod<void>('updateAmplitude', {
        'amplitude': amplitude,
      });
    } catch (_) {}
  }
}
