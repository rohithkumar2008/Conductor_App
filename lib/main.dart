import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/splash_screen.dart';
import 'services/translation_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        return MaterialApp(
          key: ValueKey(lang),
          title: 'Qurbay Conductor',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2962FF)),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
