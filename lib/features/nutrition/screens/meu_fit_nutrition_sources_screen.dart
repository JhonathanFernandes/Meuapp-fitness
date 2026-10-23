import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wger/features/nutrition/screens/meu_fit_taco_food_search_screen.dart';

/// Consulta a base oficial da TBCA sem copiar nem redistribuir seus dados.
class MeuFitNutritionSourcesScreen extends StatefulWidget {
  const MeuFitNutritionSourcesScreen({super.key});

  @override
  State<MeuFitNutritionSourcesScreen> createState() =>
      _MeuFitNutritionSourcesScreenState();
}

class _MeuFitNutritionSourcesScreenState
    extends State<MeuFitNutritionSourcesScreen> {
  final _searchController = TextEditingController();
  static const _tbcaSearchUrl =
      'https://www.tbca.net.br/base-dados/composicao_alimentos_calculaveis.php';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchTbca() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome de um alimento.')),
      );
      return;
    }

    final uri = Uri.parse(_tbcaSearchUrl).replace(
      queryParameters: {'produto': query},
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a consulta da TBCA.')),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o endereço.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC9F31D);
    return Scaffold(
      appBar: AppBar(title: const Text('Fontes nutricionais')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('ALIMENTAÇÃO',
              style: TextStyle(color: lime, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Consultar alimentos brasileiros',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Pesquise na base oficial da TBCA por nome ou tipo de preparo. '
            'A consulta abre os resultados publicados pela Universidade de São Paulo.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MeuFitTacoFoodSearchScreen(),
                ),
              ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Pesquisar nutrientes no aplicativo'),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _searchTbca(),
            decoration: InputDecoration(
              labelText: 'Nome do alimento',
              hintText: 'Ex.: arroz, feijão, frango cozido',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Limpar',
                icon: const Icon(Icons.close),
                onPressed: _searchController.clear,
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _searchTbca,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Consultar na TBCA'),
          ),
          const SizedBox(height: 8),
          const Text(
            'A consulta é feita no site oficial. Os valores exibidos dependem '
            'do alimento e do preparo selecionados; confira a porção e a unidade.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),
          const Text('Outras referências',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _SourceCard(
            title: 'TBCA · Universidade de São Paulo',
            description: 'Tabela Brasileira de Composição de Alimentos, '
                'com composição nutricional e opções de alimentos preparados.',
            actionLabel: 'Abrir TBCA',
            onTap: () => _openUrl('https://www.tbca.net.br/'),
          ),
          _SourceCard(
            title: 'TACO · Unicamp',
            description: 'Tabela Brasileira de Composição de Alimentos, '
                '4ª edição. Referência complementar.',
            actionLabel: 'Abrir TACO',
            onTap: () => _openUrl(
              'https://nepa.unicamp.br/tabela-brasileira-de-composicao-de-alimentos-4a-edicao/',
            ),
          ),
          _SourceCard(
            title: 'Guia Alimentar · Ministério da Saúde',
            description: 'Orientações sobre alimentação adequada e o consumo '
                'de alimentos in natura e minimamente processados.',
            actionLabel: 'Abrir guia',
            onTap: () => _openUrl(
              'https://www.gov.br/saude/pt-br/assuntos/saude-brasil/publicacoes-para-promocao-a-saude/guia_alimentar_populacao_brasileira_2ed.pdf',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Importante: esta etapa conecta o app à consulta oficial da TBCA, '
            'mas ainda não sincroniza os nutrientes para dentro do diário do Meu Fit. '
            'Os alimentos do wger não são automaticamente equivalentes aos registros '
            'da TBCA ou TACO.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

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
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.open_in_new),
                label: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
