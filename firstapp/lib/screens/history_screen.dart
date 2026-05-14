import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../services/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await DatabaseHelper.instance.getAllActivities();
    setState(() {
      _activities = data;
      _isLoading = false;
    });
  }

  Color _severityColor(int score) {
    if (score > 15) return Colors.red;
    if (score > 7) return Colors.orange;
    return const Color(0xFF16A34A);
  }

  String _severityLabel(int score) {
    if (score > 15) return 'High Risk';
    if (score > 7) return 'Moderate';
    return 'Low Risk';
  }

  IconData _severityIcon(int score) {
    if (score > 15) return Icons.warning_rounded;
    if (score > 7) return Icons.info_rounded;
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── Premium SliverAppBar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF7C3AED),
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
                    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
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
                          child: const Icon(Icons.history_rounded,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Activity History',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_activities.length} session${_activities.length != 1 ? 's' : ''} recorded',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Refresh button
                        IconButton(
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _loadHistory();
                          },
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7C3AED),
                ),
              ),
            )
          else if (_activities.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildHistoryCard(_activities[index]),
                  childCount: _activities.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded,
                size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text('No History Yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2138))),
          const SizedBox(height: 8),
          Text('Your symptom check sessions will\nappear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final DateTime date = DateTime.parse(item['created_at']);
    final String formattedDate =
        DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    final int score = item['severity_score'] ?? 0;
    final Color sColor = _severityColor(score);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Severity Color Bar
              Container(width: 5, color: sColor),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item['predicted_disease'] ?? 'Unknown Diagnosis',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A2138)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: sColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_severityIcon(score),
                                    color: sColor, size: 12),
                                const SizedBox(width: 4),
                                Text(_severityLabel(score),
                                    style: TextStyle(
                                        color: sColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      // Date
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(formattedDate,
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Severity score bar
                      Row(
                        children: [
                          Text('Severity: $score',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: sColor,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (score / 30).clamp(0.0, 1.0),
                                backgroundColor: Colors.grey.shade200,
                                valueColor:
                                    AlwaysStoppedAnimation(sColor),
                                minHeight: 5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Symptoms chips
                      const Text('SYMPTOMS',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      _buildSymptomChips(
                          item['selected_symptoms'] ?? 'None'),

                      // View Details
                      if (item['disease_description'] != null) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showDetails(item),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('View Full Details',
                                  style: TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios,
                                  size: 12, color: Color(0xFF7C3AED)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomChips(String symptoms) {
    final List<String> items = symptoms
        .split(',')
        .map((s) => s.trim().replaceAll('_', ' '))
        .where((s) => s.isNotEmpty)
        .toList();

    if (items.isEmpty || (items.length == 1 && items.first == 'None')) {
      return Text('None',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .take(5)
          .map((s) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.2)),
                ),
                child: Text(s,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w500)),
              ))
          .toList()
        ..addAll(items.length > 5
            ? [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('+${items.length - 5} more',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                )
              ]
            : []),
    );
  }

  void _showDetails(Map<String, dynamic> item) {
    final int score = item['severity_score'] ?? 0;
    final Color sColor = _severityColor(score);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 24),

              // Disease + score
              Row(
                children: [
                  Expanded(
                    child: Text(item['predicted_disease'],
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Score: $score',
                        style: TextStyle(
                            color: sColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                  'For ${item['user_name']}, Age ${item['age']} · ${item['location'] ?? ''}',
                  style: TextStyle(color: Colors.grey.shade600)),

              const Divider(height: 32),

              const Text('Description',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  item['disease_description'] ??
                      'No description available.',
                  style: const TextStyle(
                      color: Color(0xFF475569), height: 1.6)),

              const SizedBox(height: 24),
              const Text('Symptoms Reported',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildSymptomChips(item['selected_symptoms'] ?? 'None'),

              const SizedBox(height: 24),
              const Text('MCQ Answers',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildMcqSummary(item['mcq_answers']),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMcqSummary(String? jsonStr) {
    if (jsonStr == null) {
      return Text('No specific answers recorded.',
          style: TextStyle(color: Colors.grey.shade500));
    }
    try {
      final Map<String, dynamic> answers = jsonDecode(jsonStr);
      return Column(
        children: answers.entries
            .map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle,
                          size: 6, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            '${e.key.replaceAll('_', ' ')}: ${(e.value as List).join(', ')}',
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );
    } catch (_) {
      return const Text('Data format error.');
    }
  }
}
