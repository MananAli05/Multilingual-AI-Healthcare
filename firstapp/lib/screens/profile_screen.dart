import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userPhone;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userPhone,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _primary = Color(0xFF00478D);

  late String _displayName;
  bool _isLoadingStats = true;
  bool _isSavingName = false;

  // Real counts from SQLite
  int _symptomChecks = 0;
  int _xrayScans = 0;
  int _labReports = 0;

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _loadStats();
  }

  // ── Load real counts from local SQLite ─────────────────────────────────────
  Future<void> _loadStats() async {
    try {
      final activities = await DatabaseHelper.instance.getAllActivities();

      int symptoms = 0, xrays = 0, labs = 0;
      for (final a in activities) {
        final disease = (a['predicted_disease'] ?? '').toString();
        final symptoms_field = (a['selected_symptoms'] ?? '').toString();
        if (disease.startsWith('Result:')) {
          xrays++;
        } else if (disease.startsWith('Lab Report')) {
          labs++;
        } else {
          symptoms++;
        }
      }

      if (mounted) {
        setState(() {
          _symptomChecks = symptoms;
          _xrayScans = xrays;
          _labReports = labs;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  // ── Edit Name Dialog ────────────────────────────────────────────────────────
  void _showEditNameDialog() {
    final controller = TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            prefixIcon: const Icon(Icons.person_outline, color: _primary),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          StatefulBuilder(
            builder: (ctx2, setBtn) => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isSavingName
                  ? null
                  : () async {
                      final newName = controller.text.trim();
                      if (newName.isEmpty) return;

                      setBtn(() => _isSavingName = true);
                      try {
                        // 1. Update Supabase profiles table
                        await Supabase.instance.client
                            .from('profiles')
                            .update({'name': newName}).eq('phone', widget.userPhone);

                        // 2. Update SharedPreferences
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('user_name', newName);

                        if (mounted) {
                          setState(() => _displayName = newName);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Name updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setBtn(() => _isSavingName = false);
                      }
                    },
              child: _isSavingName
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authService = AuthService();
      await authService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_phone');
      await prefs.remove('user_name');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  String _getInitials() {
    if (_displayName.trim().isEmpty) return 'U';
    final parts = _displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _displayName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, child) {
        final lang = langProvider.currentLanguage;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: CustomScrollView(
            slivers: [
              // ── Premium SliverAppBar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                stretch: true,
                backgroundColor: _primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    tooltip: 'Edit Name',
                    onPressed: _showEditNameDialog,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00478D), Color(0xFF0066CC)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background decoration circles
                        Positioned(
                          right: -40,
                          top: -40,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -30,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        // Avatar + name
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 44),
                              // Avatar
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    _getInitials(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: _primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _displayName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.userPhone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Account Info Card ───────────────────────────────
                      _sectionTitle(Translations.get('profile', lang)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: _cardDecor(),
                        child: Column(
                          children: [
                            _infoRow(
                              Icons.person_outline,
                              'Full Name',
                              _displayName,
                              onEdit: _showEditNameDialog,
                            ),
                            const Divider(height: 24),
                            _infoRow(
                              Icons.phone_outlined,
                              Translations.get('phone', lang),
                              widget.userPhone,
                            ),
                            const Divider(height: 24),
                            _infoRow(
                              Icons.language_outlined,
                              'Language',
                              langProvider.currentLanguage == 'ur' ? 'اردو (Urdu)' : 'English',
                              onEdit: () => langProvider.toggleLanguage(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Activity Stats ──────────────────────────────────
                      _sectionTitle(Translations.get('my_activity', lang)),
                      const SizedBox(height: 12),
                      _isLoadingStats
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: _primary),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.healing_rounded,
                                    label: 'Symptom\nChecks',
                                    count: _symptomChecks,
                                    color: _primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.camera_alt_rounded,
                                    label: 'X-Ray\nScans',
                                    count: _xrayScans,
                                    color: const Color(0xFF006A6A),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.description_rounded,
                                    label: 'Lab\nReports',
                                    count: _labReports,
                                    color: const Color(0xFF940010),
                                  ),
                                ),
                              ],
                            ),

                      const SizedBox(height: 24),

                      // ── Settings ────────────────────────────────────────
                      _sectionTitle(Translations.get('settings', lang)),
                      const SizedBox(height: 12),
                      Container(
                        decoration: _cardDecor(),
                        child: Column(
                          children: [
                            _menuTile(
                              Icons.language_outlined,
                              'Change Language',
                              subtitle: langProvider.currentLanguage == 'ur' ? 'اردو' : 'English',
                              onTap: () => langProvider.toggleLanguage(),
                            ),
                            const Divider(height: 1, indent: 56),
                            _menuTile(
                              Icons.edit_outlined,
                              'Edit Name',
                              subtitle: 'Update your display name',
                              onTap: _showEditNameDialog,
                            ),
                            const Divider(height: 1, indent: 56),
                            _menuTile(
                              Icons.history_rounded,
                              'Activity History',
                              subtitle: 'View all past sessions',
                              onTap: () => Navigator.pop(context),
                              iconColor: const Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── App Version ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: _cardDecor(),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.info_outline_rounded, color: _primary, size: 20),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MediCare Plus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('Version 1.0.0  •  FYP 2025', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Logout Button ───────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
                          label: Text(
                            Translations.get('logout', lang),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEBEE),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFFFFCDD2)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  BoxDecoration _cardDecor() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A2138),
        ),
      );

  Widget _infoRow(IconData icon, String label, String value, {VoidCallback? onEdit}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            ],
          ),
        ),
        if (onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined, size: 16, color: _primary),
            ),
          ),
      ],
    );
  }

  Widget _menuTile(IconData icon, String title,
      {String? subtitle, required VoidCallback onTap, Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? _primary).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor ?? _primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.7),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
