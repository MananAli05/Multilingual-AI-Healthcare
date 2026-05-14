import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../services/database_helper.dart';
import '../services/medical_data_service.dart';
import '../services/voice_service.dart';
import '../utils/translations.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final _voiceService = VoiceService();
  final _medicalService = MedicalDataService();
  
  // App Language: 'en', 'ur', 'ro'
  String _currentLang = 'en';

  bool _isListening = false;
  String? _listeningField;

  Timer? _micTimer;
  int _micSecondsLeft = 4;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isAnalyzing = false;
  int _severityScore = 0;
  List<Map<String, dynamic>> _finalDiseases = [];

  final List<String> _allSymptoms = [
    'high_fever', 'mild_fever', 'chills', 'shivering', 'sweating', 'cough',
    'breathlessness', 'phlegm', 'chest_pain', 'headache', 'fatigue', 'nausea',
    'vomiting', 'loss_of_appetite', 'abdominal_pain', 'diarrhoea', 'joint_pain',
    'muscle_pain', 'back_pain', 'yellowish_skin', 'yellowing_of_eyes',
    'dark_urine', 'skin_rash', 'itching', 'weight_loss', 'dizziness',
    'stiff_neck', 'excessive_hunger', 'polyuria', 'blurred_and_distorted_vision',
    'continuous_sneezing', 'acidity', 'burning_micturition', 'runny_nose'
  ];

  final List<String> _userSelectedSymptoms = [];
  final Map<String, List<String>> _symptomAnswers = {};

  // Step 3 Variables
  bool _isUrduMode = false;
  bool _isTranslating = false;
  bool _isSpeaking = false;
  Map<String, dynamic>? _translatedResult;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _micTimer?.cancel();
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _pageController.dispose();
    _voiceService.stopSpeaking();
    super.dispose();
  }

  String _t(String text) => Translations.t(text, _currentLang);
  String _s(String symptomKey) {
    if (_currentLang == 'en') return symptomKey.replaceAll('_', ' ').toUpperCase();
    return Translations.t(symptomKey, _currentLang);
  }

  // ── Step 1: Voice Field Handlers (4-Second Timer) ─────────────────────────

  Future<void> _handleFieldVoice(String taskType, TextEditingController controller) async {
    if (_listeningField == taskType) {
      // Manual stop before 4 seconds
      _stopAndProcessFieldVoice(taskType, controller);
    } else {
      // Start listening
      if (_listeningField != null) return; // Prevent multiple recordings
      await _voiceService.startRecording();
      setState(() {
        _listeningField = taskType;
        _micSecondsLeft = 4;
      });
      _pulseController.repeat(reverse: true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t("Listening...")), duration: const Duration(seconds: 1)));
      }

      // Auto stop after 4 seconds
      _micTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_micSecondsLeft > 1) {
          setState(() {
            _micSecondsLeft--;
          });
        } else {
          // Time is up!
          _stopAndProcessFieldVoice(taskType, controller);
        }
      });
    }
  }

  Future<void> _stopAndProcessFieldVoice(String taskType, TextEditingController controller) async {
    _micTimer?.cancel();
    setState(() => _listeningField = null);
    _pulseController.stop();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t("Processing audio...")), duration: const Duration(seconds: 1)));
    }
    
    String? result = await _voiceService.stopAndProcess(taskType);
    if (result != null && result.toLowerCase() != 'unknown' && result.isNotEmpty) {
      setState(() {
        controller.text = result;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t("Could not understand. Please try again or type manually."))));
      }
    }
  }

  // ── Step 2: Voice Symptom Handler (No Time Limit) ─────────────────────────

  Future<void> _handleSymptomVoiceInput() async {
    if (_isListening) {
      setState(() => _isListening = false);
      _pulseController.stop();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t("Processing audio...")), duration: const Duration(seconds: 1)));

      String? mappedSymptom = await _voiceService.stopAndProcess('symptom_manual');
      if (mappedSymptom != null && mappedSymptom.toLowerCase() != 'unknown' && mappedSymptom.isNotEmpty) {
        String match = mappedSymptom.toLowerCase().trim();
        if (_allSymptoms.contains(match)) {
          if (!_userSelectedSymptoms.contains(match)) {
            _showMCQDialog(match);
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Symptom '${_s(match)}' is already selected.")));
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Symptom not recognized from our database.")));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t("Could not understand. Please try again or type manually."))));
      }
    } else {
      await _voiceService.startRecording();
      setState(() => _isListening = true);
      _pulseController.repeat(reverse: true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t("Speak your symptom in Urdu or English... Tap Mic again to stop.")), duration: const Duration(seconds: 2))
        );
      }
    }
  }

  // ── Step 3: Urdu Toggle & TTS ─────────────────────────────────────────────

  Future<void> _toggleUrduTranslation() async {
    if (_isUrduMode) {
      setState(() => _isUrduMode = false);
      return;
    }

    if (_translatedResult != null) {
      setState(() => _isUrduMode = true);
      return;
    }

    if (_finalDiseases.isEmpty) return;

    setState(() => _isTranslating = true);
    
    final primary = _finalDiseases[0];
    final result = await _voiceService.translateAndSummarizeResult(
      primary['name'], 
      primary['description'], 
      List<String>.from(primary['precautions']), 
      "Urdu"
    );

    if (mounted) {
      if (result != null) {
        setState(() {
          _translatedResult = result;
          _isUrduMode = true;
          _isTranslating = false;
        });
      } else {
        setState(() => _isTranslating = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Translation failed. Check network.")));
      }
    }
  }

  Future<void> _toggleTTS() async {
    if (_isSpeaking) {
      await _voiceService.stopSpeaking();
      setState(() => _isSpeaking = false);
    } else {
      String textToSpeak = "";
      if (_isUrduMode && _translatedResult != null) {
        textToSpeak = _translatedResult!['tts_summary'] ?? _translatedResult!['description_translated'] ?? "";
      } else if (_finalDiseases.isNotEmpty) {
        final d = _finalDiseases[0];
        textToSpeak = "You have been diagnosed with ${d['name']}. ${d['description']}. Please consult a doctor if symptoms persist.";
      }

      if (textToSpeak.isNotEmpty) {
        setState(() => _isSpeaking = true);
        await _voiceService.speak(textToSpeak);
      }
    }
  }

  // ── Core Logistics ────────────────────────────────────────────────────────

  Future<void> _getPrediction() async {
    if (_userSelectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t("Please select at least one symptom."))));
      return;
    }
    setState(() {
      _isAnalyzing = true;
      _isUrduMode = false;
      _translatedResult = null;
      _isSpeaking = false;
      _voiceService.stopSpeaking();
    });

    try {
      List<double> inputVector = List.filled(_allSymptoms.length, 0.0);
      for (int i = 0; i < _allSymptoms.length; i++) {
        String symptomKey = _allSymptoms[i].replaceAll(' ', '_').trim().toLowerCase();
        bool isSelected = _userSelectedSymptoms.any(
            (s) => s.replaceAll(' ', '_').trim().toLowerCase() == symptomKey
        );

        if (isSelected) {
          inputVector[i] = 1.0;
          String? originalKey = _symptomAnswers.keys.firstWhere(
            (k) => k.replaceAll(' ', '_').trim().toLowerCase() == symptomKey,
            orElse: () => '',
          );

          if (originalKey.isNotEmpty) {
            bool hasSevereKeyword = _symptomAnswers[originalKey]!.any((ans) {
              String a = ans.toLowerCase();
              return a.contains('severe') || a.contains('high') || a.contains('above 104') || a.contains('yes') || a.contains('shadeed');
            });
            if (hasSevereKeyword) inputVector[i] = 1.5;
          }
        }
      }

      final response = await http.post(
        Uri.parse('http://10.197.189.171:8000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'input_vector': inputVector}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> details = [];

        for (var item in data['results']) {
          final detail = await _medicalService.getDetails(
              item['disease'], _userSelectedSymptoms, _symptomAnswers);
          details.add({
            'name': item['disease'],
            'confidence': "${item['confidence'].toStringAsFixed(1)}%",
            ...detail
          });
        }

        setState(() {
          _finalDiseases = details;
          _severityScore = details.isNotEmpty ? details[0]['score'] : 0;
          _isAnalyzing = false;
          _pageController.jumpToPage(2);
        });

        if (_finalDiseases.isNotEmpty) {
          _saveDataToSupabase(_finalDiseases[0]['name'], _severityScore, _finalDiseases[0]['description']);
        }
      } else {
        setState(() => _isAnalyzing = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Server error. Could not get prediction.")));
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error connecting to AI Backend: $e")));
    }
  }

  Future<void> _saveDataToSupabase(String disease, int score, String description) async {
    try {
      final Map<String, dynamic> dataToSave = {
        'user_name': _nameController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'location': _locationController.text.isEmpty ? 'Not Provided' : _locationController.text,
        'selected_symptoms': _userSelectedSymptoms.join(", "),
        'mcq_answers': _symptomAnswers,
        'predicted_disease': disease,
        'severity_score': score,
        'disease_description': description,
        'created_at': DateTime.now().toIso8601String(),
      };
      await Supabase.instance.client.from('symptom_history').insert(dataToSave);
      final db = await DatabaseHelper.instance.database;
      final localData = Map<String, dynamic>.from(dataToSave);
      localData['mcq_answers'] = jsonEncode(_symptomAnswers);
      await db.insert('user_activities', localData, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      debugPrint("Failed to save history: $_");
    }
  }

  void _showMCQDialog(String symptom) async {
    final questionsData = await loadQuestions();
    List questions = questionsData[symptom] ?? [];
    Map<String, String> selectedAnswers = {};
    
    if (questions.isEmpty) {
      setState(() {
        if (!_userSelectedSymptoms.contains(symptom)) {
          _userSelectedSymptoms.add(symptom);
          _symptomAnswers[symptom] = ['Selected'];
        }
      });
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(_s(symptom), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00478D))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: questions.map<Widget>((q) {
                String translatedQuestion = _t(q['question']);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(translatedQuestion, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: Color(0xFF00478D), size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              String ttsLang = 'ur-PK';
                              if (_currentLang == 'en') {
                                ttsLang = 'en-US';
                              } else if (_currentLang == 'ro') {
                                ttsLang = 'hi-IN'; // Best fallback for Roman Urdu pronunciation
                              }
                              _voiceService.speak(translatedQuestion, lang: ttsLang);
                            },
                          )
                        ],
                      ),
                    ),
                    ...q['options'].map<Widget>((opt) {
                      String translatedOpt = _t(opt);
                      return RadioListTile<String>(
                        title: Text(translatedOpt, style: const TextStyle(fontSize: 14)),
                        value: opt, // keep original english value internally
                        groupValue: selectedAnswers[q['question']],
                        activeColor: const Color(0xFF00478D),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedAnswers[q['question']] = val!;
                          });
                        },
                      );
                    }).toList(),
                    const Divider(),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _userSelectedSymptoms.remove(symptom);
                  _symptomAnswers.remove(symptom);
                });
                Navigator.pop(context);
              },
              child: Text(_t("Cancel"), style: const TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00478D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (selectedAnswers.length == questions.length) {
                  setState(() {
                    if (!_userSelectedSymptoms.contains(symptom)) {
                      _userSelectedSymptoms.add(symptom);
                    }
                    _symptomAnswers[symptom] = selectedAnswers.values.toList();
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_t("Please Answer All Questions to proceed.")))
                  );
                }
              },
              child: Text(_t("Save"), style: const TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  // ── UI BUILDERS ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_t("Symptom Checker"), style: const TextStyle(color: Color(0xFF1A2138), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () {
          _voiceService.stopSpeaking();
          Navigator.pop(context);
        }),
        actions: [
          _buildLanguageToggle(),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildUserInfoStep(),
          _buildSelectionStep(),
          _buildResultStep(),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: PopupMenuButton<String>(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, color: Color(0xFF00478D)),
              const SizedBox(width: 4),
              Text(_currentLang.toUpperCase(), style: const TextStyle(color: Color(0xFF00478D), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        onSelected: (String result) {
          setState(() {
            _currentLang = result;
          });
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: 'en', child: Text('English')),
          const PopupMenuItem<String>(value: 'ur', child: Text('اردو (Urdu)')),
          const PopupMenuItem<String>(value: 'ro', child: Text('Roman Urdu')),
        ],
      ),
    );
  }

  // STEP 1 UI
  Widget _buildUserInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t("Patient Profile"), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A2138))),
            const SizedBox(height: 8),
            Text(_t("Please provide your basic details or tap the mic icon to speak them."), style: const TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 32),
            _buildInput(_t("Full Name"), _nameController, Icons.person, taskType: 'name', validator: (v) => v!.isEmpty ? _t("Enter Name") : null),
            _buildInput(_t("Age"), _ageController, Icons.calendar_month, isNum: true, taskType: 'age', validator: (v) => v!.isEmpty ? _t("Enter Age") : null),
            _buildInput(_t("Location (Optional)"), _locationController, Icons.location_on, taskType: 'location'),
            const SizedBox(height: 40),
            _buildButton(_t("Proceed to Symptoms"), () {
              if (_formKey.currentState!.validate()) {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
              }
            }),
          ],
        ),
      ),
    );
  }

  // STEP 2 UI
  Widget _buildSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t("Select Symptoms"), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2138))),
                    const SizedBox(height: 4),
                    Text(_t("Tap to select or use voice input"), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _handleSymptomVoiceInput,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.red : const Color(0xFF00478D),
                        boxShadow: [
                          if (_isListening)
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 15 * _pulseController.value + 5,
                              spreadRadius: 8 * _pulseController.value,
                            ),
                          if (!_isListening)
                            BoxShadow(
                              color: const Color(0xFF00478D).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_userSelectedSymptoms.isNotEmpty) ...[
            Text(_t("Selected"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _userSelectedSymptoms.map((s) => Chip(
                label: Text(_s(s), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                backgroundColor: const Color(0xFF00478D),
                deleteIcon: const Icon(Icons.close, color: Colors.white, size: 16),
                onDeleted: () => setState(() {
                  _userSelectedSymptoms.remove(s);
                  _symptomAnswers.remove(s);
                }),
              )).toList(),
            ),
            const SizedBox(height: 20),
            const Divider(),
          ],

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(_t("All Symptoms"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: _allSymptoms.map((s) {
                      bool isSelected = _userSelectedSymptoms.contains(s);
                      return InkWell(
                        onTap: () {
                          if (!isSelected) {
                            _showMCQDialog(s);
                          } else {
                            setState(() {
                              _userSelectedSymptoms.remove(s);
                              _symptomAnswers.remove(s);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00478D) : Colors.white,
                            border: Border.all(color: isSelected ? const Color(0xFF00478D) : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              if (!isSelected) BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                            ]
                          ),
                          child: Text(
                            _s(s),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          _buildButton(_isAnalyzing ? _t("Analyzing AI Models...") : _t("Get Diagnosis"), _isAnalyzing ? null : _getPrediction),
        ],
      ),
    );
  }

  // STEP 3 UI
  Widget _buildResultStep() {
    Color sevColor = _getSeverityColor(_severityScore);
    String sevText = _t(_getSeverityText(_severityScore));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t("AI Diagnosis"), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A2138))),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isSpeaking ? Icons.volume_off : Icons.volume_up, color: const Color(0xFF00478D), size: 28),
                    onPressed: _toggleTTS,
                    tooltip: "Read Aloud",
                  ),
                  InkWell(
                    onTap: _isTranslating ? null : _toggleUrduTranslation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isUrduMode ? const Color(0xFF00478D) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _isTranslating 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text("اردو", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _isUrduMode ? Colors.white : Colors.black87)),
                    ),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [sevColor.withOpacity(0.8), sevColor]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: sevColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.health_and_safety, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sevText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
                      Text("${_t('Severity Score')}: $_severityScore", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_finalDiseases.isNotEmpty) ...[
            Text(_t("Primary Prediction"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _isUrduMode && _translatedResult != null ? _translatedResult!['disease_translated'] : _finalDiseases[0]['name'], 
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A2138))
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
                          child: Text(_finalDiseases[0]['confidence'], style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isUrduMode && _translatedResult != null ? _translatedResult!['description_translated'] : _finalDiseases[0]['description'], 
                      style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.5)
                    ),
                    const SizedBox(height: 20),
                    Text(_t("Recommended Precautions:"), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00478D), fontSize: 16)),
                    const SizedBox(height: 10),
                    
                    if (_isUrduMode && _translatedResult != null)
                      ...(_translatedResult!['precautions_translated'] as String).split("|").map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("• ", style: TextStyle(color: Color(0xFF00478D), fontWeight: FontWeight.bold, fontSize: 18)),
                          Expanded(child: Text(p, style: const TextStyle(fontSize: 15, height: 1.4))),
                        ]),
                      ))
                    else
                      ...List<String>.from(_finalDiseases[0]['precautions']).map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("• ", style: TextStyle(color: Color(0xFF00478D), fontWeight: FontWeight.bold, fontSize: 18)),
                          Expanded(child: Text(p, style: const TextStyle(fontSize: 15, height: 1.4))),
                        ]),
                      )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (_finalDiseases.length > 1) ...[
            Text(_t("Other Possible Conditions"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            ..._finalDiseases.skip(1).map((d) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: Text(d['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2138))),
                trailing: Text(d['confidence'], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['description'], style: const TextStyle(color: Colors.black87, height: 1.4)),
                        const SizedBox(height: 12),
                        Text(_t("Precautions:"), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00478D))),
                        const SizedBox(height: 8),
                        ...List<String>.from(d['precautions']).map((p) => Text("• $p", style: const TextStyle(height: 1.4))),
                      ],
                    ),
                  )
                ],
              ),
            )),
          ],

          const SizedBox(height: 24),
          _buildButton(_t("Start New Diagnosis"), () async {
            await _voiceService.stopSpeaking();
            setState(() {
              _userSelectedSymptoms.clear();
              _symptomAnswers.clear();
              _isUrduMode = false;
              _isSpeaking = false;
              _translatedResult = null;
              _pageController.jumpToPage(0);
            });
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── HELPER WIDGETS & FUNCTIONS ────────────────────────────────────────────

  Color _getSeverityColor(int score) {
    if (score > 15) return Colors.red.shade600;
    if (score > 7) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  String _getSeverityText(int score) {
    if (score > 15) return "HIGH RISK";
    if (score > 7) return "MODERATE RISK";
    return "LOW RISK";
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? taskType}) {
    bool isListeningForThis = _listeningField == taskType;
    return InputDecoration(
      labelText: label, 
      prefixIcon: Icon(icon, color: const Color(0xFF00478D)),
      suffixIcon: taskType != null ? IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isListeningForThis 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("$_micSecondsLeft" + "s", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 4),
                  const Icon(Icons.stop_circle, color: Colors.red, size: 28),
                ],
              )
            : const Icon(Icons.mic, color: Color(0xFF00478D), size: 24),
        ),
        onPressed: () => _handleFieldVoice(taskType, taskType == 'name' ? _nameController : (taskType == 'age' ? _ageController : _locationController)),
      ) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00478D), width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon, {bool isNum = false, String? Function(String?)? validator, String? taskType}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: _inputDecoration(label, icon, taskType: taskType),
        validator: validator,
      ),
    );

  Widget _buildButton(String text, VoidCallback? onPressed) => Container(
    width: double.infinity, 
    height: 56, 
    decoration: BoxDecoration(
      boxShadow: [BoxShadow(color: const Color(0xFF00478D).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
    ),
    child: ElevatedButton(
      onPressed: onPressed, 
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00478D), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
    )
  );
}

Future<Map<String, dynamic>> loadQuestions() async {
  final data = await rootBundle.loadString('assets/data/symptom_questions.json');
  return jsonDecode(data);
}
