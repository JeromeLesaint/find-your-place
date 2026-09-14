import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class InfosScreen extends StatefulWidget {
  
  const InfosScreen({super.key});

  @override
  State<InfosScreen> createState() => _InfosScreenState();
}

class _InfosScreenState extends State<InfosScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.infosScreenTitle),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.infosScreenContent,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}