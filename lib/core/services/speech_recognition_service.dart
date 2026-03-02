import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

class SpeechRecognitionService {
  SpeechRecognitionService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<String> transcribe({
    required String audioFilePath,
    required String apiKey,
    required String provider,
    required String model,
    required String prompt,
    String? customEndpoint,
  }) async {
    print('[SpeechRecognition] Transcribing with $provider ($model)... Custom Endpoint: ${customEndpoint ?? "None"}');
    
    switch (provider) {
      case 'openai':
        return _transcribeWithOpenAI(
          audioFilePath: audioFilePath,
          apiKey: apiKey,
          model: model,
          prompt: prompt,
          customEndpoint: customEndpoint,
        );
      case 'gemini':
        return _transcribeWithGemini(
          audioFilePath: audioFilePath,
          apiKey: apiKey,
          model: model,
          prompt: prompt,
          customEndpoint: customEndpoint,
        );
      default:
        throw Exception('不支援的語音辨識服務商：$provider');
    }
  }

  Future<String> _transcribeWithOpenAI({
    required String audioFilePath,
    required String apiKey,
    required String model,
    required String prompt,
    String? customEndpoint,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        audioFilePath,
        filename: File(audioFilePath).uri.pathSegments.last,
      ),
      'model': model,
      'response_format': 'text',
      if (prompt.isNotEmpty) 'prompt': prompt,
    });

    final url = (customEndpoint != null && customEndpoint.isNotEmpty) 
        ? customEndpoint 
        : 'https://api.openai.com/v1/audio/transcriptions';

    final response = await _dio.post<String>(
      url,
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $apiKey'},
        responseType: ResponseType.plain,
      ),
    );

    return (response.data ?? '').trim();
  }

  Future<String> _transcribeWithGemini({
    required String audioFilePath,
    required String apiKey,
    required String model,
    required String prompt,
    String? customEndpoint,
  }) async {
    print('[Gemini] Start direct transcription: $audioFilePath');
    
    final fileToUpload = File(audioFilePath);
    if (!fileToUpload.existsSync()) {
      throw Exception('找不到音檔：$audioFilePath');
    }

    // Gemini supports AAC (m4a) directly if sent as audio/mp4 or audio/aac
    final mimeType = audioFilePath.endsWith('.m4a') ? 'audio/mp4' : (audioFilePath.endsWith('.mp3') ? 'audio/mpeg' : 'audio/mp4');
    final audioBytes = await fileToUpload.readAsBytes();
    final base64Audio = base64Encode(audioBytes);
    print('[Gemini] Audio prepared. Base64 Length: ${base64Audio.length}');

    final finalPrompt = prompt.isEmpty ? 'Generate a transcript of the speech.' : prompt;
    
    // For Gemini, customEndpoint might be the full model URL prefix
    final url = (customEndpoint != null && customEndpoint.isNotEmpty)
        ? '$customEndpoint/$model:generateContent'
        : 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
    
    try {
      print('[Gemini] Sending generateContent request to: $url (inlineData)');
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: {
          'contents': [
            {
              'parts': [
                {'text': finalPrompt},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Audio,
                  }
                },
              ],
            },
          ],
        },
        options: Options(
          headers: {
            'x-goog-api-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
      );


      final candidates = response.data?['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        print('[Gemini] Error: No candidates. Response: ${response.data}');
        throw Exception('Gemini 轉譯失敗：無候選回應');
      }

      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        print('[Gemini] Error: No parts. Candidate: ${candidates[0]}');
        throw Exception('Gemini 轉譯失敗：內容為空');
      }

      final result = (parts[0]['text'] as String? ?? '').trim();
      print('[Gemini] Success! Result length: ${result.length}');
      return result;

    } on DioException catch (e) {
      print('[Gemini] DioException: ${e.message}');
      print('[Gemini] Status: ${e.response?.statusCode}');
      print('[Gemini] Response Body: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('[Gemini] Unexpected error: $e');
      rethrow;
    }
  }
}
