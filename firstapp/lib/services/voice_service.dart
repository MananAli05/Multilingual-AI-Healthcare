import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final _audioRecorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();
  final String _apiKey =
      "YOUR_GROQ_API_KEY_HERE"; // TODO: Put your actual key here before running, or use .env

  /// Path of the current recording — stored so stopAndProcess can always find it
  String? _currentRecordingPath;

  VoiceService() {
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage("ur-PK");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
  }

  // ── TTS ──────────────────────────────────────────────────────────────────

  Future<void> speak(String text, {String lang = 'ur-PK'}) async {
    await _tts.stop();
    await _tts.setLanguage(lang);
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  Future<void> speakWelcome(String text) async {
    await _tts.stop();
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.1);
    await _tts.speak(text);
    await Future.delayed(const Duration(seconds: 4));
    await _tts.setPitch(1.0);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  // ── Recording ────────────────────────────────────────────────────────────

  Future<bool> startRecording() async {
    try {
      final hasPerm = await _audioRecorder.hasPermission();
      debugPrint("🎙️ [VoiceService] hasPermission: $hasPerm");

      if (!hasPerm) {
        debugPrint("🎙️ [VoiceService] ❌ Microphone permission denied!");
        return false;
      }

      // Stop any previous recording that may have been left open
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.cancel();
      }

      final directory = await getTemporaryDirectory();
      _currentRecordingPath =
          '${directory.path}/speech_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: _currentRecordingPath!);
      debugPrint("🎙️ [VoiceService] ✅ Recording started → $_currentRecordingPath");
      return true;
    } catch (e) {
      debugPrint("🎙️ [VoiceService] ❌ startRecording error: $e");
      return false;
    }
  }

  /// Stops recording, transcribes speech to text, then extracts
  /// structured data (name / phone) using the LLM.
  ///
  /// Returns the extracted value, or null on failure.
  Future<String?> stopAndProcess(String taskType) async {
    try {
      final path = await _audioRecorder.stop();
      debugPrint("🎙️ [VoiceService] Recording stopped → path: $path");

      if (path == null || path.isEmpty) {
        debugPrint("🎙️ [VoiceService] ❌ No recording path returned");
        return null;
      }

      // Step 1: Transcribe with Whisper
      final rawText = await transcribeAudio(path);
      debugPrint("🎙️ [VoiceService] Whisper rawText: '$rawText'");

      if (rawText == null || rawText.trim().isEmpty) {
        debugPrint("🎙️ [VoiceService] ❌ Transcription returned empty");
        return null;
      }

      // Step 2: Extract structured data with LLM
      final extracted = await extractDataWithAI(rawText, taskType);
      debugPrint("🎙️ [VoiceService] LLM extracted ($taskType): '$extracted'");
      return extracted;
    } catch (e) {
      debugPrint("🎙️ [VoiceService] ❌ stopAndProcess error: $e");
      return null;
    }
  }

  /// Raw transcription only (no LLM extraction).
  Future<String?> stopAndTranscribe() async {
    final path = await _audioRecorder.stop();
    if (path == null) return null;
    return await transcribeAudio(path);
  }

  // ── Groq Whisper ─────────────────────────────────────────────────────────

  Future<String?> transcribeAudio(String path) async {
    debugPrint("🔊 [Whisper] Sending audio to Groq: $path");
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
      );
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.files.add(await http.MultipartFile.fromPath('file', path));
      request.fields['model'] = 'whisper-large-v3';
      // Omit language param → let Whisper auto-detect Urdu/English
      request.fields['response_format'] = 'json';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("🔊 [Whisper] Status: ${response.statusCode}");
      debugPrint("🔊 [Whisper] Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['text'];
      } else {
        debugPrint("🔊 [Whisper] ❌ Non-200 response: ${response.body}");
      }
    } catch (e) {
      debugPrint("🔊 [Whisper] ❌ Exception: $e");
    }
    return null;
  }

  // ── Groq LLM extraction ──────────────────────────────────────────────────

  Future<String?> extractDataWithAI(String rawText, String taskType) async {
    String prompt = "";

    if (taskType == "name") {
      prompt = """The user spoke in Urdu or English (or a mix).
Their speech was transcribed as: "$rawText"
Extract ONLY the person's own name from this sentence.
Examples:
- "mera naam manan hai" → Manan
- "میرا نام احمد ہے" → Ahmad
- "my name is Sara" → Sara
Return ONLY the name in Title Case. No extra words. If no name found, return: Unknown""";
    } else if (taskType == "phone") {
      prompt = """The user spoke their phone number in Urdu or English.
Their speech was transcribed as: "$rawText"
Extract ONLY the 11-digit Pakistani mobile number.
Return ONLY the digits with no spaces, dashes or other characters.
Example output: 03001234567
If no valid number found, return: Unknown""";
    } else if (taskType == "age") {
      prompt = """The user spoke in Urdu or English.
Their speech was transcribed as: "$rawText"
Extract ONLY the numerical age from this sentence.
Example output: 25
If no valid age found, return: Unknown""";
    } else if (taskType == "location") {
      prompt = """The user spoke their city/location in Urdu or English.
Their speech was transcribed as: "$rawText"
Extract ONLY the city or location name.
Return ONLY the name in Title Case. No extra words. Example: Lahore
If no valid location found, return: Unknown""";
    } else if (taskType == "symptom") {
      prompt =
          """User said in Urdu or English: "$rawText". Map these to symptom IDs like 'high_fever', 'headache', 'cough', etc. Return ONLY a comma-separated list of IDs.""";
    } else if (taskType == "symptom_manual") {
      prompt = """The user described a medical symptom in Urdu, Roman Urdu, or English.
Their speech was transcribed as: "$rawText"
Map their described symptom to EXACTLY ONE of the following precise internal symptom IDs.
Valid IDs:
high_fever, mild_fever, chills, shivering, sweating, cough, breathlessness, phlegm, chest_pain, headache, fatigue, nausea, vomiting, loss_of_appetite, abdominal_pain, diarrhoea, joint_pain, muscle_pain, back_pain, yellowish_skin, yellowing_of_eyes, dark_urine, skin_rash, itching, weight_loss, dizziness, stiff_neck, excessive_hunger, polyuria, blurred_and_distorted_vision, continuous_sneezing, acidity, burning_micturition, runny_nose

If it's severe fever or taiz bukhar -> high_fever
If it's halka bukhar -> mild_fever
If it's sardi lagna -> chills
If it's khansi -> cough
If it's saans phoolna -> breathlessness
If it's sar dard -> headache
If it's ulti -> vomiting
If it's matli -> nausea
If it's pait dard -> abdominal_pain
If it's thakawat -> fatigue

Return ONLY the single exact matching ID from the list above. Do NOT return anything else. If you cannot confidently map it to any of these, return: Unknown""";
    }

    debugPrint("🤖 [LLM] Sending prompt for '\$taskType'...");

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",  // updated: llama3-70b-8192 was decommissioned
          "messages": [
            {
              "role": "system",
              "content":
                  "You extract structured data from transcribed speech. Reply with ONLY the requested value, nothing else."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.0,
          "max_tokens": 50,
        }),
      );

      debugPrint("🤖 [LLM] Status: ${response.statusCode}");
      debugPrint("🤖 [LLM] Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        debugPrint("🤖 [LLM] ❌ Non-200: ${response.body}");
      }
    } catch (e) {
      debugPrint("🤖 [LLM] ❌ Exception: $e");
    }
    return null;
  }

  // ── Result Translation & Summary ─────────────────────────────────────────

  Future<Map<String, String>?> translateAndSummarizeResult(
      String disease, String description, List<String> precautions, String language) async {
    
    final targetLang = language.toLowerCase() == 'urdu' ? 'Urdu (in Urdu script)' : 'English';
    
    final prompt = """
You are a medical AI assistant. The user has been diagnosed with:
Disease: $disease
Description: $description
Precautions: ${precautions.join(", ")}

Task 1: Translate the Disease Name, Description, and Precautions into $targetLang.
Task 2: Write a short, natural, conversational summary (2-3 sentences max) in $targetLang that a voice assistant can read aloud to the user. Address the user directly (e.g. "Aap ko...").

Reply strictly in the following JSON format:
{
  "disease_translated": "...",
  "description_translated": "...",
  "precautions_translated": ["...", "..."],
  "tts_summary": "..."
}
""";

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You output ONLY raw valid JSON. No markdown, no code blocks."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'].toString().trim();
        // Remove markdown JSON formatting if the LLM accidentally included it
        final cleanContent = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> parsed = json.decode(cleanContent);
        
        return {
          "disease_translated": parsed["disease_translated"].toString(),
          "description_translated": parsed["description_translated"].toString(),
          "precautions_translated": (parsed["precautions_translated"] as List).join("|"),
          "tts_summary": parsed["tts_summary"].toString(),
        };
      }
    } catch (e) {
      debugPrint("🤖 [LLM Translation] ❌ Exception: $e");
    }
    return null;
  }
}
