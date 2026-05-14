import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; 
import 'config/app_config.dart';
import 'providers/language_provider.dart'; 
import 'screens/splash_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MedicalApp(),
    ),
  );
}
class MedicalApp extends StatelessWidget {
  const MedicalApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, child) {
        return MaterialApp(
          title: 'MediCare Plus',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color(0xFF4C6FFF),
            scaffoldBackgroundColor: const Color(0xFFF8F9FE),
            fontFamily: langProvider.currentLanguage == 'urdu' ? 'UrduFont' : 'Poppins',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4C6FFF),
              primary: const Color(0xFF4C6FFF),
              secondary: const Color(0xFF00D9C1),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}