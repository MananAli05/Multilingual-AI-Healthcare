import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class XRayAnalysisScreen extends StatefulWidget {
  const XRayAnalysisScreen({super.key});

  @override
  State<XRayAnalysisScreen> createState() => _XRayAnalysisScreenState();
}

class _XRayAnalysisScreenState extends State<XRayAnalysisScreen>
    with TickerProviderStateMixin {
  File? _image;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;

  late AnimationController _scanController;
  late AnimationController _pulseController;
  final ImagePicker _picker =ImagePicker();
  static const _blue = Color(0xFF006A6A);
  static const _blueDark = Color(0xFF004D4D);

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
      });
    }
  }

  Future<void> _analyzeXRay() async {
    if (_image == null) return;
    setState(() => _isAnalyzing = true);

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://10.197.189.171:8000/predict-xray'));
      request.files
          .add(await http.MultipartFile.fromPath('file', _image!.path));

      var response = await request.send().then(http.Response.fromStream);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // --- VIVA HACK: Reject Irrelevant Images ---
        num confidence = data['confidence'] ?? 0;
        String resultText = data['result']?.toString() ?? "";
        
        if (confidence < 75 || resultText == "INVALID" || resultText == "INVALID_IMAGE") {
          setState(() => _isAnalyzing = false);
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [Icon(Icons.error_outline, color: Colors.red), SizedBox(width: 8), Text('Invalid Image')],
                ),
                content: const Text('Unrecognized image detected. The AI confidence is too low. Please upload a clear and valid Chest X-Ray.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(color: Color(0xFF006A6A), fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            );
          }
          return;
        }
        // -------------------------------------------

        setState(() {
          _result = data;
          _isAnalyzing = false;
        });
        _saveToSupabase(data);
      } else {
        setState(() => _isAnalyzing = false);
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _saveToSupabase(Map<String, dynamic> data) async {
    // ── Get stored user phone for record linking ─────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('user_phone') ?? 'unknown';
    final userName = prefs.getString('user_name') ?? 'Me';

    // ── 1. Supabase cloud ────────────────────────────────────────────────────
    try {
      await Supabase.instance.client.from('xray_history').insert({
        'user_phone': userPhone,
        'prediction': data['result'],
        'confidence': data['confidence'],
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ X-Ray saved to Supabase');
    } catch (e) {
      debugPrint('⚠️ Supabase xray_history error (non-critical): $e');
      // Local SQLite save below handles all history — Supabase is optional.
    }

    // ── 2. SQLite local (REQUIRED for History screen) ────────────────────────
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('user_activities', {
        'user_name': userName,
        'age': 0,
        'location': 'Not Provided',
        'selected_symptoms': 'Chest X-Ray Scan',
        'predicted_disease': 'Result: ${data['result']}',
        'severity_score': data['result'] == 'PNEUMONIA' ? 20 : 0,
        'disease_description': 'AI Confidence: ${data['confidence']}%',
        'mcq_answers': '{}',
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ X-Ray activity saved to local history');
    } catch (e) {
      debugPrint('❌ Local history save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          // ── Premium SliverAppBar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _blue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_blue, _blueDark],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Chest X-Ray Analysis',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'AI-Powered Pneumonia Detection',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Info Banner ────────────────────────────────────────
                  _buildInfoBanner(),
                  const SizedBox(height: 24),

                  // ── Image Upload Area ──────────────────────────────────
                  _buildUploadArea(),
                  const SizedBox(height: 24),

                  // ── Action / Result ────────────────────────────────────
                  if (_image != null && _result == null) _buildAnalyzeButton(),
                  if (_result != null) _buildResultCard(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_blue.withOpacity(0.08), _blue.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: _blue, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Upload a clear frontal Chest X-Ray. AI will detect signs of Pneumonia.',
              style: TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _image == null ? _showPickerOptions : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 320,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _image != null ? _blue : Colors.grey.shade300,
            width: _image != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _blue.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            children: [
              if (_image == null) _buildEmptyUpload(),
              if (_image != null)
                Image.file(_image!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity),

              // Scanning overlay
              if (_isAnalyzing) _buildScanOverlay(),

              // Change image button
              if (_image != null && !_isAnalyzing)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _showPickerOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Change',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyUpload() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.08),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.08 + _pulseController.value * 0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_photo_alternate_rounded,
                    size: 52, color: _blue),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Tap to upload X-Ray',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2138))),
          const SizedBox(height: 6),
          Text('Camera or Gallery',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Stack(
      children: [
        // Dark tint
        Container(color: Colors.black38),
        // Scan line
        AnimatedBuilder(
          animation: _scanController,
          builder: (context, child) => Positioned(
            top: _scanController.value * 310,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _blue.withOpacity(0.8),
                    Colors.transparent
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                      color: _blue.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 3)
                ],
              ),
            ),
          ),
        ),
        // Center label
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(height: 16),
              Text('Scanning X-Ray...',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _analyzeXRay,
        icon: const Icon(Icons.biotech_rounded, color: Colors.white),
        label: const Text('Start AI Scan',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: _blue.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final bool isPositive = _result!['result'] == 'PNEUMONIA';
    final Color resultColor = isPositive ? Colors.red : Colors.green;
    final IconData resultIcon =
        isPositive ? Icons.warning_rounded : Icons.check_circle_rounded;

    return Column(
      children: [
        // Result banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPositive
                  ? [Colors.red.shade50, Colors.red.shade100]
                  : [Colors.green.shade50, Colors.green.shade100],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: resultColor.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(resultIcon, color: resultColor, size: 48),
              const SizedBox(height: 12),
              Text(
                isPositive ? 'Pneumonia Detected' : 'Lungs Normal',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: resultColor),
              ),
              const SizedBox(height: 8),
              // Confidence bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_result!['confidence'] as num) / 100,
                  backgroundColor: resultColor.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(resultColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text('AI Confidence: ${_result!['confidence']}%',
                  style: TextStyle(
                      color: resultColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
        ),

        const SizedBox(height: 16),

          // Professional Action Advice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isPositive ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isPositive ? Colors.red.shade200 : Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.health_and_safety, color: isPositive ? Colors.red : Colors.green, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isPositive 
                      ? 'Clinical Warning: Signs of Pneumonia detected. Please consult a pulmonologist or visit the nearest healthcare facility immediately for proper diagnosis.'
                      : 'Screening Clear: No visible signs of Pneumonia. Please maintain a healthy lifestyle and consult your physician if you experience breathing difficulties.',
                    style: TextStyle(fontSize: 13, color: isPositive ? Colors.red.shade900 : Colors.green.shade900, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Scan Again button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => setState(() {
              _image = null;
              _result = null;
            }),
            icon: const Icon(Icons.refresh_rounded, color: _blue),
            label: const Text('Scan Another',
                style: TextStyle(color: _blue, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _blue),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Upload X-Ray',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _pickerOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: _blue,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _pickerOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: const Color(0xFF7C3AED),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
