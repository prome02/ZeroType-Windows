import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:zero_type/features/model_config/domain/entities/ai_provider.dart';

abstract class ModelConfigRepository {
  Future<ProvidersConfig> loadProvidersConfig();

  Future<String?> getSelectedSpeechProviderId();
  Future<void> saveSelectedSpeechProviderId(String providerId);

  Future<String?> getSelectedSpeechModelId(String providerId);
  Future<void> saveSelectedSpeechModelId(String providerId, String modelId);

  Future<String?> getSpeechApiKey(String providerId);
  Future<void> saveSpeechApiKey(String providerId, String apiKey);

  Future<String?> getCustomEndpoint(String providerId);
  Future<void> saveCustomEndpoint(String providerId, String endpoint);
}
