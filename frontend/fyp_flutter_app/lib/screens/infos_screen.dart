import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/donation_service.dart';


class InfosScreen extends StatefulWidget {
  
  const InfosScreen({super.key});

  @override
  State<InfosScreen> createState() => _InfosScreenState();
}

class _InfosScreenState extends State<InfosScreen> {
  
  @override
  Widget build(BuildContext context) {
    final tips = context.watch<TipService>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.infosScreenTitle),
      ),
      body: Builder(builder: (_) {
        if (tips.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!tips.available || tips.products.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context)!.infosScreenContent+"\n\n"+
                AppLocalizations.of(context)!.buyingNotAvailable,
                textAlign: TextAlign.justify,
              ),
            ),
          );
        }
        return ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)!.infosScreenContent,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            for (final p in tips.products)
              ListTile(
                title: Text(p.title),
                subtitle: Text(p.description),
                trailing: tips.buyingId == p.id
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(p.price),
                enabled: tips.buyingId == null,
                onTap: () => tips.buy(p),
              ),
          ],
        );
      }),
    );
  }
}