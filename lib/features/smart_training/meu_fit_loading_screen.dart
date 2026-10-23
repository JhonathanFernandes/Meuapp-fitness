import 'package:flutter/material.dart';

/// Tela visual enquanto o próximo passo do fluxo é preparado.
/// A navegação é controlada pelo fluxo de cadastro, não por esta tela.
class MeuFitLoadingScreen extends StatelessWidget {
  const MeuFitLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC9F31D);
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: lime),
              SizedBox(height: 28),
              Text(
                'Carregando o seu treino...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: lime,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
