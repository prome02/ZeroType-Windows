abstract class DictionaryRepository {
  Future<List<String>> loadWords();
  Future<void> addWord(String word);
  Future<void> removeWord(String word);
  Future<String> buildDictionaryPrompt();
}
