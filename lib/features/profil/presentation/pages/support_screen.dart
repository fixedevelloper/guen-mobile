import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Coordonnées reprises de frontend/src/components/site-footer.tsx — aucun
/// module "support" côté backend, ce sont les canaux de contact réels de
/// l'entreprise, statiques côté web comme ici.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Support client', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(Icons.support_agent_rounded, size: 56, color: primaryColor),
            const SizedBox(height: 12),
            const Text(
              'Une question sur une réservation, un paiement ou votre compte ? Notre équipe vous répond.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _ContactTile(
              icon: Icons.support_agent_outlined,
              title: 'Support',
              subtitle: 'support@guenstravelandtours.com',
              onTap: () => _launchEmail('support@guenstravelandtours.com'),
            ),
            _ContactTile(
              icon: Icons.mail_outline_rounded,
              title: 'Contact général',
              subtitle: 'contact@guenstravelandtours.com',
              onTap: () => _launchEmail('contact@guenstravelandtours.com'),
            ),
            _ContactTile(
              icon: Icons.phone_outlined,
              title: 'Téléphone',
              subtitle: '+237 6 83 43 71 57',
              onTap: () => _launchPhone('+237683437157'),
            ),
          ],
        ),
      ),
    );
  }

  static void _launchEmail(String email) {
    launchUrl(Uri(scheme: 'mailto', path: email));
  }

  static void _launchPhone(String phone) {
    launchUrl(Uri(scheme: 'tel', path: phone));
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }
}
