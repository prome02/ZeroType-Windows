abstract class PromptRepository {
  Future<String> getSpeechPrompt();
  Future<String> saveSpeechPrompt(String prompt);

  Future<String> getDefaultSpeechPrompt();

  Future<String> resetSpeechPrompt();
}
