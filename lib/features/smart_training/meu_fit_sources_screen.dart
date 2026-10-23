import 'package:flutter/material.dart';

/// Apresenta as referências antes da prévia de treinos.
/// As diretrizes fundamentam critérios gerais, não aprovam um treino individual.
class MeuFitSourcesScreen extends StatelessWidget {
  const MeuFitSourcesScreen({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC9F31D);
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: lime),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meu Fit · Como funciona'),
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TREINOS COM CRITÉRIOS TÉCNICOS',
                            style: TextStyle(color: lime, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        Text('Entenda de onde vêm as recomendações',
                            style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
                        SizedBox(height: 20),
                        Text('O Meu Fit usa suas respostas para organizar sugestões '
                            'de atividade física por objetivo, experiência, '
                            'disponibilidade e local de treino. As escolhas não '
                            'são sorteadas nem feitas ao acaso.'),
                        SizedBox(height: 20),
                        Text('Referências utilizadas',
                            style: TextStyle(color: lime, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text('• Ministério da Saúde: Guia de Atividade Física para a '
                            'População Brasileira (2021), com orientações para '
                            'atividade aeróbica e fortalecimento.'),
                        SizedBox(height: 12),
                        Text('• American College of Sports Medicine (ACSM): '
                            'diretrizes científicas sobre exercícios resistidos, '
                            'condicionamento e aptidão física.'),
                        SizedBox(height: 12),
                        Text('• CONFEF/CREF: referências para a atuação dos '
                            'profissionais de Educação Física no Brasil. '
                            'Esses conselhos não aprovaram os treinos do aplicativo.'),
                        SizedBox(height: 20),
                        Text('O que isso significa?',
                            style: TextStyle(color: lime, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text('Os protocolos do Meu Fit ainda estão em desenvolvimento '
                            'e aguardam revisão profissional. As sugestões são '
                            'educativas: não equivalem a uma prescrição individual, '
                            'não garantem resultados e não substituem avaliação '
                            'por profissional habilitado.'),
                        SizedBox(height: 12),
                        Text('Se você informou limitações físicas, o aplicativo '
                            'não apresentará um treino automático personalizado.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: lime,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(17),
                  ),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
