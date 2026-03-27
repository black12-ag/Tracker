import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_soap_tracker/core/config/app_identity.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthContactFooter extends StatelessWidget {
  const AuthContactFooter({super.key});

  Future<void> _openTelegram(BuildContext context) async {
    final appUri = Uri.parse(
      'tg://resolve?domain=${AppIdentity.contactTelegramHandle.replaceFirst('@', '')}',
    );
    final webUri = Uri.parse(AppIdentity.contactTelegramUrl);
    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Telegram right now.')),
      );
    }
  }

  Future<void> _openPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: AppIdentity.contactPhone);
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      await Clipboard.setData(
        const ClipboardData(text: AppIdentity.contactPhone),
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number copied.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Need the same app?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            TextButton.icon(
              onPressed: () => _openTelegram(context),
              icon: const Icon(Icons.send_rounded),
              label: const Text(AppIdentity.contactTelegramHandle),
            ),
            TextButton.icon(
              onPressed: () => _openPhone(context),
              icon: const Icon(Icons.phone_outlined),
              label: const Text(AppIdentity.contactPhone),
            ),
          ],
        ),
      ],
    );
  }
}
