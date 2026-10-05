import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class AnbuMatrimonyApp extends StatelessWidget {
  const AnbuMatrimonyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B1E3F)),
        useMaterial3: true,
      ),
      home: const _PhaseOneShell(),
    );
  }
}

class _PhaseOneShell extends StatelessWidget {
  const _PhaseOneShell();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(strings.appName)),
      body: Center(child: Text(strings.profile)),
    );
  }
}
