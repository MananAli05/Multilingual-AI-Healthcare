import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import 'profile_screen.dart';
import 'symptom_checker_screen.dart';
import 'xray_analysis_screen.dart';
import 'lab_report_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String userPhone;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.userPhone,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentQuoteIndex = 0;
  late Timer _quoteTimer;
  late AnimationController _quoteAnimController;
  late Animation<double> _quoteFade;

  final List<Map<String, String>> _healthQuotes = [
    {
      'ur': 'گرمیوں میں پانی زیادہ پیئیں',
      'en': 'Drink more water in summer',
    },
    {
      'ur': 'تازہ پھل کھائیں',
      'en': 'Eat fresh fruits daily',
    },
    {
      'ur': 'وقت پر سوئیں',
      'en': 'Sleep on time every night',
    },
    {
      'ur': 'روزانہ ورزش کریں',
      'en': 'Exercise every day',
    },
    {
      'ur': 'ذہنی سکون ضروری ہے',
      'en': 'Mental peace is essential',
    },
  ];

  @override
  void initState() {
    super.initState();

    _quoteAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _quoteFade = CurvedAnimation(
      parent: _quoteAnimController,
      curve: Curves.easeInOut,
    );
    _quoteAnimController.forward();

    _quoteTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _quoteAnimController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentQuoteIndex = (_currentQuoteIndex + 1) % _healthQuotes.length;
            });
            _quoteAnimController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _quoteTimer.cancel();
    _quoteAnimController.dispose();
    super.dispose();
  }

  Future<void> _callNumber(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, child) {
        final lang = langProvider.currentLanguage;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF00478D), Color(0xFF005EB8)]),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(Translations.t('Welcome', lang), style: const TextStyle(fontSize: 13, color: Colors.white70)),
                                const SizedBox(height: 2),
                                Text(widget.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => langProvider.toggleLanguage(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.language, color: Colors.white, size: 18),
                                        const SizedBox(width: 6),
                                        Text(lang == 'ur' ? 'اردو' : 'EN', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userName: widget.userName, userPhone: widget.userPhone))),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.tips_and_updates_outlined, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FadeTransition(
                                  opacity: _quoteFade,
                                  child: Text(_healthQuotes[_currentQuoteIndex][lang] ?? "", style: const TextStyle(fontSize: 13, color: Colors.white)),
                                ),
                              ),
                              Row(
                                children: List.generate(_healthQuotes.length, (index) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    height: 4,
                                    width: _currentQuoteIndex == index ? 12 : 4,
                                    decoration: BoxDecoration(
                                      color: _currentQuoteIndex == index ? Colors.white : Colors.white.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(Translations.t('Our Services', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2138))),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        _ModernServiceCard(
                          icon: Icons.healing_rounded,
                          title: Translations.t('Symptom Checker', lang),
                          subtitle: "Check your symptoms",
                          color: const Color(0xFF00478D),
                          hasVoice: true,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomCheckerScreen())),
                        ),
                        _ModernServiceCard(
                          icon: Icons.camera_alt_rounded,
                          title: "X-Ray Analysis",
                          subtitle: "Analyze images",
                          color: const Color(0xFF006A6A),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const XRayAnalysisScreen())),
                        ),
                        _ModernServiceCard(
                          icon: Icons.description_rounded,
                          title: "Lab Report",
                          subtitle: "Interpret reports",
                          color: const Color(0xFF940010),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabReportScreen())),
                        ),
                        _ModernServiceCard(
                          icon: Icons.history_rounded,
                          title: "History",
                          subtitle: "View activities",
                          color: const Color(0xFF7C3AED),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(Translations.t('Emergency', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2138))),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: _CompactEmergencyCard(icon: Icons.local_hospital, label: "Rescue", number: '1122', color: const Color(0xFF940010), onTap: () => _callNumber('1122'))),
                        const SizedBox(width: 10),
                        Expanded(child: _CompactEmergencyCard(icon: Icons.local_police, label: "Police", number: '15', color: const Color(0xFF00478D), onTap: () => _callNumber('15'))),
                        const SizedBox(width: 10),
                        Expanded(child: _CompactEmergencyCard(icon: Icons.fire_extinguisher, label: "Fire", number: '16', color: const Color(0xFFF59E0B), onTap: () => _callNumber('16'))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Translations.t('Health Tips', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2138))),
                        Text(Translations.t('View All', lang), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00478D))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _HealthTipCard(
                          color: const Color(0xFFE3F2FD),
                          iconColor: const Color(0xFF1E88E5),
                          icon: Icons.water_drop,
                          title: lang == 'ur' ? 'پانی پئیں' : 'Hydration',
                          subtitle: lang == 'ur' ? 'دن میں 8 گلاس پانی پئیں' : 'Drink 8 glasses a day',
                        ),
                        const SizedBox(width: 12),
                        _HealthTipCard(
                          color: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF43A047),
                          icon: Icons.directions_run,
                          title: lang == 'ur' ? 'ورزش' : 'Exercise',
                          subtitle: lang == 'ur' ? 'روزانہ 30 منٹ ورزش کریں' : '30 mins daily',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModernServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool hasVoice;
  final VoidCallback onTap;

  const _ModernServiceCard({required this.icon, required this.title, required this.subtitle, required this.color, this.hasVoice = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2), width: 1.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(child: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))),
                if (hasVoice) Icon(Icons.mic, size: 14, color: const Color(0xFF6B7280)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactEmergencyCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String number;
  final Color color;
  final VoidCallback onTap;

  const _CompactEmergencyCard({required this.icon, required this.label, required this.number, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(number, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text("Tap to Call", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
            )
          ]
        ),
      ),
    );
  }
}

class _HealthTipCard extends StatelessWidget {
  final Color color;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;

  const _HealthTipCard({
    required this.color, 
    required this.iconColor, 
    required this.icon, 
    required this.title, 
    required this.subtitle
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const Spacer(),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: iconColor)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: iconColor.withOpacity(0.8))),
        ],
      ),
    );
  }
}
