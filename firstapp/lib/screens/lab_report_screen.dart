import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class LabReportScreen extends StatefulWidget {
  const LabReportScreen({super.key});

  @override
  State<LabReportScreen> createState() => _LabReportScreenState();
}

class _LabReportScreenState extends State<LabReportScreen>
    with TickerProviderStateMixin {
  File? _image;
  bool _isAnalyzing = false;
  List<dynamic>? _results;

  late AnimationController _scanController;
  late AnimationController _pulseController;
  final ImagePicker _picker = ImagePicker();

  static const _red = Color(0xFF940010);
  //static const _redLight = Color(0xFFB5001A);

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
        _results = null;
      });
    }
  }

  Future<void> _analyzeReport() async {
    if (_image == null) return;
    setState(() => _isAnalyzing = true);

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://10.197.189.171:8000/interpret-report'));
      request.files
          .add(await http.MultipartFile.fromPath('file', _image!.path));

      // ── 90-second timeout: EasyOCR is slow on first run ──────────────────
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception(
              'Server timeout (90s). Ensure the AI server is running on your PC.');
        },
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawResults = data['results'];
        final List<dynamic> resultsList = rawResults is List ? rawResults : [];

        // --- VIVA HACK: Reject Irrelevant Images ---
        if (resultsList.isEmpty) {
          setState(() => _isAnalyzing = false);
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [Icon(Icons.error_outline, color: Colors.red), SizedBox(width: 8), Text('Invalid Image')],
                ),
                content: const Text('No medical test data detected. This appears to be an irrelevant image or an unreadable report. Please upload a clear Lab Report.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(color: Color(0xFF940010), fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            );
          }
          return;
        }
        // -------------------------------------------

        setState(() {
          _results = resultsList;
          _isAnalyzing = false;
        });
        _saveToSupabase(resultsList);
      } else {
        setState(() => _isAnalyzing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Server error: ${response.statusCode} — ${response.body}'),
              backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _saveToSupabase(List<dynamic> results) async {
    // ── Get stored user info ────────────────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('user_phone') ?? 'unknown';
    final userName = prefs.getString('user_name') ?? 'Me';

    // ── 1. Supabase cloud ───────────────────────────────────────────────────
    try {
      await Supabase.instance.client.from('lab_history').insert({
        'user_phone': userPhone,
        'total_tests': results.length,
        'results': results,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Lab report saved to Supabase');
    } catch (e) {
      debugPrint(' Supabase lab_history error (non-critical): $e');
      // Local SQLite save below handles all history — Supabase is optional.
    }

    // ── 2. SQLite local (REQUIRED for History screen) ───────────────────────
    try {
      final testNames = results
          .map((r) => r['test_en']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .join(', ');

      final abnormalCount = results
          .where((r) => r['color']?.toString() == 'red')
          .length;
      final severityScore = (abnormalCount * 5).clamp(0, 30);

      final description = results.map((r) {
        return '${r['test_en']}: ${r['value']} ${r['unit']} (${r['status']})';
      }).join(' | ');

      final db = await DatabaseHelper.instance.database;
      await db.insert('user_activities', {
        'user_name': userName,
        'age': 0,
        'location': 'Not Provided',
        'selected_symptoms': testNames.isEmpty ? 'Lab Report Scan' : testNames,
        'predicted_disease': 'Lab Report — ${results.length} test(s) detected',
        'severity_score': severityScore,
        'disease_description': description.isEmpty
            ? 'No test details available.'
            : description,
        'mcq_answers': '{}',
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Lab report saved to local history ($abnormalCount abnormal tests)');
    } catch (e) {
      debugPrint('Local history save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          // ── Premium SliverAppBar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _red,
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
                    colors: [_red, Color(0xFF6B0000)],
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
                          child: const Icon(Icons.description_rounded,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Lab Report Reader',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'AI-Powered Medical Interpretation',
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 13),
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
                  _buildInfoBanner(),
                  const SizedBox(height: 24),
                  _buildUploadArea(),
                  const SizedBox(height: 24),
                  if (_image != null && _results == null)
                    _buildAnalyzeButton(),
                  if (_results != null) _buildResultsList(),
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
          colors: [_red.withOpacity(0.08), _red.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.assignment_outlined, color: _red, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Upload a vertical, clear photo of your lab report for AI reading.',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF374151), height: 1.4),
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
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _image != null ? _red : Colors.grey.shade300,
            width: _image != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _red.withOpacity(0.07),
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
              if (_isAnalyzing) _buildScanOverlay(),
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
                  color: _red.withOpacity(0.08 + _pulseController.value * 0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.upload_file_rounded,
                    size: 48, color: _red),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Tap to upload Report',
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
        Container(color: Colors.black38),
        AnimatedBuilder(
          animation: _scanController,
          builder: (context, child) => Positioned(
            top: _scanController.value * 250,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _red.withOpacity(0.9),
                    Colors.transparent
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                      color: _red.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 3)
                ],
              ),
            ),
          ),
        ),
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(height: 16),
              Text('Reading Report...',
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
        onPressed: _isAnalyzing ? null : _analyzeReport,
        icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
        label: const Text('Read Report',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _red,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: _red.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_red, Color(0xFF6B0000)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.science_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Results Ready',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text('${_results!.length} tests detected',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_results!.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Column(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
                SizedBox(height: 12),
                Text('No Tests Detected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                SizedBox(height: 8),
                Text('Could not read any standard test values from this image. Please ensure the image is clear and contains blood test results (like CBC, LFTs, etc).', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF92400E))),
              ],
            ),
          )
        else
          ..._results!.map((res) => _buildTestCard(res)).toList(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => setState(() {
              _image = null;
              _results = null;
            }),
            icon: const Icon(Icons.refresh_rounded, color: _red),
            label: const Text('Read Another Report',
                style: TextStyle(color: _red, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestCard(Map<String, dynamic> res) {
    final bool isNormal = res['color'] == 'green';
    final Color statusColor = isNormal ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(res['test_en'] ?? '',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2138))),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    res['status'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${res['value']}',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: statusColor)),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(res['unit'] ?? '',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade500)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: isNormal ? 0.5 : 0.85,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(statusColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(res['advice'] ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        fontStyle: FontStyle.italic,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
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
              const Text('Upload Report',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _pickerOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: _red,
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
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
