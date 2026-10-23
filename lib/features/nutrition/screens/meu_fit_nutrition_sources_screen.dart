import 'package:material_ui/material_ui.dart';

/// Referências para consulta; nenhuma tabela é copiada ou sincronizada aqui.
class MeuFitNutritionSourcesScreen extends StatelessWidget {
  const MeuFitNutritionSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC9F31D);
    return Scaffold(
      appBar: AppBar(title: const Text('Fontes da alimentação')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('ALIMENTAÇÃO BRASILEIRA',
            style: TextStyle(color: lime, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('De onde vêm os dados?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('As referências abaixo orientam a futura integração de alimentos brasileiros. '
            'Os ingredientes cadastrados atualmente no wger não foram automaticamente '
            'validados contra essas tabelas.'),
          SizedBox(height: 16),
          _SourceCard(
            title: 'TBCA · Universidade de São Paulo',
            url: 'https://www.tbca.net.br/',
            description: 'Tabela Brasileira de Composição de Alimentos. '
              'Referência para energia, macronutrientes e micronutrientes por alimento e preparo.'),
          _SourceCard(
            title: 'TACO · Unicamp',
            url: 'https://www.nepa.unicamp.br/taco/',
            description: 'Tabela Brasileira de Composição de Alimentos. '
              'Fonte complementar, respeitando as condições de uso dos dados.'),
          _SourceCard(
            title: 'Guia Alimentar · Ministério da Saúde',
            url: 'https://www.gov.br/saude/pt-br/assuntos/saude-brasil/publicacoes-para-promocao-a-saude/guia_alimentar_populacao_brasileira_2ed.pdf',
            description: 'Orientações sobre alimentação adequada, alimentos in natura, '
              'minimamente processados e ultraprocessados. Não é uma tabela de nutrientes.'),
          SizedBox(height: 16),
          Text('Como serão montadas as sugestões?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('O plano deverá considerar objetivo, preferências, restrições, '
            'rotina e porções em gramas e medidas caseiras brasileiras. '
            'Cada alimento deverá indicar sua fonte, versão e porção utilizada. '
            'Cálculos energéticos e metas individuais só serão exibidos quando '
            'os dados necessários estiverem disponíveis e validados.'),
          SizedBox(height: 12),
          Text('Importante: este painel documenta as fontes. '
            'Ele ainda não importa a base TBCA/TACO nem gera uma dieta individual.',
            style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.title, required this.url, required this.description});
  final String title;
  final String url;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF242424),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
              color: Color(0xFFC9F31D), fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(description),
            const SizedBox(height: 8),
            SelectableText(url, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
