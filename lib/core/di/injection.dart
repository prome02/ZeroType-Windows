import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sound_service.dart';
import '../services/speech_recognition_service.dart';
import '../services/hotkey_service.dart';
import '../services/tray_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  final dio = Dio();
  getIt.registerSingleton<Dio>(dio);
  getIt.registerSingleton<SpeechRecognitionService>(
    SpeechRecognitionService(dio: dio),
  );
  getIt.registerSingleton<HotkeyService>(
    HotkeyService(prefs: sharedPreferences),
  );
  getIt.registerSingleton<TrayService>(
    TrayService(),
  );
  getIt.registerSingleton<SoundService>(
    SoundService(prefs: sharedPreferences),
  );
}
