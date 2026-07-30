import 'package:flutter/material.dart';

class BoardingPassScreen extends StatelessWidget {
  const BoardingPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary; // Bleu 15a4e6
    final secondaryColor = Theme.of(context).colorScheme.secondary; // Vert 7bcd4f

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Carte d\'embarquement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false, // On masque le retour arrière pour cet écran final
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () {
              // Retour à l'accueil de l'application (Étape 1)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Le Billet d'avion stylisé
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Partie haute du ticket (Bleue avec Infos du vol)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildAirportCode('DEL', 'Delhi', Colors.white, CrossAxisAlignment.start),
                            Icon(Icons.flight_takeoff_rounded, color: secondaryColor, size: 28),
                            _buildAirportCode('CCU', 'Kolkata', Colors.white, CrossAxisAlignment.end),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTicketMeta('VOL', 'IN-204', Colors.white),
                            _buildTicketMeta('CLASSE', 'Économique', Colors.white),
                            _buildTicketMeta('DATE', '12 Oct 2026', Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Ligne de découpe pointillée physique du ticket
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: List.generate(20, (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Container(height: 1, color: Colors.grey.shade300),
                        ),
                      )),
                    ),
                  ),

                  // Partie basse du ticket (Infos Passager & Code-barres)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTicketMeta('PASSAGER', 'Lorenzo', Colors.black87),
                            _buildTicketMeta('SIÈGE', '12B', Colors.black87),
                            _buildTicketMeta('PORTE', 'T3', Colors.black87),
                          ],
                        ),
                        const SizedBox(height: 36),

                        // Code-barres simulé (Style conteneur graphique minimaliste)
                        Container(
                          height: 70,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/8/84/EAN13.svg'),
                              fit: BoxFit.contain,
                              opacity: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'BOARDING PASS REF: 9847-2026',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Bouton de téléchargement ou partage
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Optionnel : Intégration d'un plugin de partage ou d'impression
                },
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text('Télécharger le PDF', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirportCode(String code, String city, Color textColor, CrossAxisAlignment alignment) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(code, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: textColor)),
        const SizedBox(height: 2),
        Text(city, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14)),
      ],
    );
  }

  Widget _buildTicketMeta(String label, String value, Color baseColor) {
    final isWhite = baseColor == Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isWhite ? Colors.white.withOpacity(0.6) : Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: baseColor)),
      ],
    );
  }
}