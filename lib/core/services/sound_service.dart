import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zero_type/core/constants/app_constants.dart';

/// 系統音效清單（路徑 → 顯示名稱）
Map<String, String> get kSystemSoundLabels {
  if (Platform.isMacOS) {
    return {
      '/System/Library/PrivateFrameworks/SpeechObjects.framework/Versions/A/Frameworks/DictationServices.framework/Versions/A/Resources/DefaultRecognitionSound.aiff':
          '語音輸入',
      '/System/Library/Sounds/Basso.aiff': 'Basso',
      '/System/Library/Sounds/Blow.aiff': 'Blow',
      '/System/Library/Sounds/Bottle.aiff': 'Bottle',
      '/System/Library/Sounds/Frog.aiff': 'Frog',
      '/System/Library/Sounds/Funk.aiff': 'Funk',
      '/System/Library/Sounds/Glass.aiff': 'Glass',
      '/System/Library/Sounds/Hero.aiff': 'Hero',
      '/System/Library/Sounds/Morse.aiff': 'Morse',
      '/System/Library/Sounds/Ping.aiff': 'Ping',
      '/System/Library/Sounds/Pop.aiff': 'Pop',
      '/System/Library/Sounds/Purr.aiff': 'Purr',
      '/System/Library/Sounds/Sosumi.aiff': 'Sosumi',
      '/System/Library/Sounds/Submarine.aiff': 'Submarine',
      '/System/Library/Sounds/Tink.aiff': 'Tink',
    };
  } else if (Platform.isWindows) {
    return {
      'C:\\Windows\\Media\\notify.wav': 'Notify',
      'C:\\Windows\\Media\\chimes.wav': 'Chimes',
      'C:\\Windows\\Media\\ding.wav': 'Ding',
      'C:\\Windows\\Media\\tada.wav': 'Tada',
      'C:\\Windows\\Media\\Speech On.wav': 'Speech On',
      'C:\\Windows\\Media\\Speech Off.wav': 'Speech Off',
      'C:\\Windows\\Media\\Alarm01.wav': 'Alarm01',
    };
  }
  return {};
}

String get kDefaultStartSound => Platform.isMacOS
    ? '/System/Library/PrivateFrameworks/SpeechObjects.framework/Versions/A/Frameworks/DictationServices.framework/Versions/A/Resources/DefaultRecognitionSound.aiff'
    : 'C:\\Windows\\Media\\notify.wav';
String get kDefaultStopSound =>
    Platform.isMacOS ? '/System/Library/Sounds/Submarine.aiff' : 'C:\\Windows\\Media\\chimes.wav';
String get kDefaultCancelSound =>
    Platform.isMacOS ? '/System/Library/Sounds/Basso.aiff' : 'C:\\Windows\\Media\\ding.wav';

class SoundService {
  final SharedPreferences _prefs;

  SoundService({required SharedPreferences prefs}) : _prefs = prefs;

  bool get soundEnabled =>
      _prefs.getBool(AppConstants.soundEnabledKey) ?? true;

  String get startSoundPath =>
      _prefs.getString(AppConstants.startSoundKey) ?? kDefaultStartSound;

  String get stopSoundPath =>
      _prefs.getString(AppConstants.stopSoundKey) ?? kDefaultStopSound;

  Future<void> playStartSound() async {
    if (!soundEnabled) return;
    await _play(startSoundPath);
  }

  Future<void> playStopSound() async {
    if (!soundEnabled) return;
    await _play(stopSoundPath);
  }

  Future<void> playCancelSound() async {
    if (!soundEnabled) return;
    await _play(kDefaultCancelSound);
  }

  /// 播放任意路徑的音效（供設定頁預覽使用）
  Future<void> playPreview(String path) async {
    await _play(path);
  }

  /// 暫停背景音樂 (Apple Music & Spotify)
  Future<void> pauseMusic() async {
    if (Platform.isMacOS) {
      const script = '''
        tell application "Music"
          if it is running then pause
        end tell
        tell application "Spotify"
          if it is running then pause
        end tell
      ''';
      await Process.run('osascript', ['-e', script]);
    } else if (Platform.isWindows) {
      // Windows 媒體控制：模擬 Media Play/Pause 按鍵
      // 0xB3 是 VK_MEDIA_PLAY_PAUSE
      await Process.run('powershell', [
        '-Command',
        '(New-Object -ComObject WScript.Shell).SendKeys([char]179)'
      ]);
    }
  }

  /// 恢復背景音樂 (Apple Music & Spotify)
  Future<void> resumeMusic() async {
    if (Platform.isMacOS) {
      const script = '''
        tell application "Music"
          if it is running then play
        end tell
        tell application "Spotify"
          if it is running then play
        end tell
      ''';
      await Process.run('osascript', ['-e', script]);
    } else if (Platform.isWindows) {
      // 同樣模擬按鍵，因為是切換行為。
      // 若要精確控制 Play/Pause，Windows API 較複雜，通常模擬按鍵為最簡實作。
      await Process.run('powershell', [
        '-Command',
        '(New-Object -ComObject WScript.Shell).SendKeys([char]179)'
      ]);
    }
  }

  static Future<void> _play(String path) async {
    if (Platform.isMacOS) {
      try {
        await Process.run('afplay', [path]);
      } catch (_) {}
    } else if (Platform.isWindows) {
      try {
        // 使用 PowerShell 播放 wav
        await Process.run('powershell', [
          '-Command',
          '(New-Object Media.SoundPlayer "$path").PlaySync();'
        ]);
      } catch (_) {}
    }
  }
}
