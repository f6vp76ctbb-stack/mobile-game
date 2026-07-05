import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/audio.dart';
import 'services/storage.dart';
import 'ui/screens/home_screen.dart';
import 'ui/state/game_controller.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await Storage.create();

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        audioProvider.overrideWithValue(AudioplayersAudio()),
      ],
      child: const GridPopApp(),
    ),
  );
}

class GridPopApp extends StatelessWidget {
  const GridPopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GridPop',
      debugShowCheckedModeBanner: false,
      theme: buildGridTheme(),
      home: const HomeScreen(),
    );
  }
}
