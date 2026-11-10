import 'package:flutter/material.dart';
import 'strings.dart';

/// Fontes de arte e informação usadas no app.
const _credits = '''
Arte: toda desenhada em código para o Burgo (original). Nenhum pacote de imagens de terceiros é usado.
Pacotes livres (como os da Kenney, CC0) serviram só de inspiração de estilo.

Referências de cenário (nomes e conceitos, sem reproduzir texto de livros):
• Tormenta20 — Jambô Editora. • Tales from the Loop — Free League / Simon Stålenhag.
• Call of Cthulhu — Chaosium. • Ordem Paranormal — Jambô / Cellbit.
• Cyberpunk RED — R. Talsorian Games. • D&D 5e — Wizards of the Coast.
Marcas pertencem aos seus donos; o Burgo não é afiliado a eles.
''';

Future<void> showCreditsDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Strings.credits),
        content: const SingleChildScrollView(child: Text(_credits)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'))
        ],
      ),
    );
