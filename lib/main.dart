import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'screens/home_shell.dart';

Future<void> main() async {                          
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');               
  runApp(const MelatiApp());
}

class MelatiApp extends StatelessWidget {
  const MelatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Melati',
      themeMode: ThemeMode.system,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadBlueColorScheme.light(
          primary: Color(0xFF005FB6),
          ring: Color(0xFF005FB6),
        ),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadBlueColorScheme.dark(
          primary: Color(0xFF005FB6),
          primaryForeground: Color(0xFFFFFFFF),
          ring: Color(0xFF005FB6),
        ),
      ),
      home: const HomeShell(),
      builder: (context, child) {
        return ShadSonner(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
