# Meu App Fitness — Aplicativo Flutter

Aplicativo de acompanhamento de treinos, exercícios, alimentação, medidas corporais e peso, baseado no projeto de código aberto [wger](https://github.com/wger-project/flutter).

## Objetivo da personalização

Esta ramificação adapta a experiência para português brasileiro como idioma inicial, mantendo a possibilidade de alternar para inglês pela tela inicial (Home). A preferência de idioma é armazenada no dispositivo.

## Funcionalidades existentes

- Acompanhamento de treinos e exercícios.
- Planejamento e acompanhamento nutricional.
- Registro de peso e medidas corporais.
- Galeria e reprodução de conteúdos multimídia compatíveis.
- Comunicação com o servidor wger pela API REST.

> **Importante:** este repositório contém o aplicativo Flutter. Para usar as funções conectadas, é necessário configurar um servidor wger compatível. O aplicativo ainda precisa ser compilado e testado; a personalização não implica que todas as telas estejam traduzidas ou que exista um APK pronto.

## Executar em desenvolvimento

É necessário ter o Flutter SDK instalado e um ambiente de desenvolvimento configurado.

```bash
flutter pub get
flutter run
```

Para testes, o projeto original documenta o servidor de desenvolvimento `https://dev.wger.de`, cujo banco de dados pode ser redefinido diariamente. Não use esse servidor para guardar informações pessoais importantes.

## Idiomas

Os arquivos de tradução ficam em `lib/l10n/`. O projeto original já inclui traduções `app_pt.arb` e `app_pt_BR.arb`, além de `app_en.arb`. As traduções precisam ser revisadas e completadas para garantir consistência em todas as telas. Os identificadores e comandos técnicos do Flutter continuam em inglês para preservar a compatibilidade.

## Desenvolvimento e contribuições

O projeto original aceita contribuições de código, traduções e documentação. Consulte a [documentação de contribuição do wger](https://wger.readthedocs.io/en/latest/contributing.html) e o [repositório original](https://github.com/wger-project/flutter).

## Licença e créditos

Este aplicativo deriva do **wger Workout Manager**, desenvolvido pela equipe wger e seus colaboradores. O código original é disponibilizado sob a **GNU Affero General Public License, versão 3 ou posterior (AGPL-3.0-or-later)**, com exceção específica para lojas de aplicativos. Os avisos de direitos autorais e a licença original devem ser preservados. Dados de exercícios e ingredientes podem estar sujeitos a licenças Creative Commons próprias. Consulte os arquivos de licença do repositório e as informações de cada conjunto de dados.
