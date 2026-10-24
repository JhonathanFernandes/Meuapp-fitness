# Meu App Fitness 

Aplicativo de acompanhamento de treinos, exercícios, alimentação, medidas corporais e peso, baseado no projeto de código aberto [wger](https://github.com/wger-project/flutter).

## Objetivo da personalização

Esta ramificação adapta a experiência para português brasileiro como idioma inicial, mantendo a possibilidade de alternar para inglês pela tela inicial (Home). A preferência de idioma é armazenada no dispositivo.

## Identidade visual

O aplicativo está sendo personalizado com uma identidade visual escura, inspirada na combinação de preto e verde-limão do site de referência informado para o projeto.

- **Preto principal:** `#101010` — base da identidade visual.
- **Verde-limão:** `#C9F31D` — destaques, botões e indicadores.
- **Branco-gelo:** `#F7F7F5` — textos e elementos de contraste.
- **Verde secundário:** `#0F9D55` — elementos complementares.

A paleta central está definida em `lib/theme/theme.dart`. Novas instalações usam o tema escuro como padrão, preservando as preferências de tema já salvas por usuários existentes. Componentes que usam o tema do Flutter herdam as cores; ajustes específicos por tela continuam em revisão.

**Estado atual:** alterações visuais já foram registradas em telas e componentes de Home, treinos, alimentação, peso, galeria e conquistas. Ainda faltam a auditoria visual completa, a compilação e os testes no Android.

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

Os arquivos de tradução ficam em `lib/l10n/`. O projeto original já inclui traduções `app_pt.arb` e `app_pt_BR.arb`, além de `app_en.arb`. O arquivo `app_pt_BR.arb` foi ampliado para cobrir as 559 chaves do catálogo inglês; a consistência da interface ainda depende de testes. Os identificadores e comandos técnicos do Flutter continuam em inglês para preservar a compatibilidade.

## Desenvolvimento e contribuições

O projeto original aceita contribuições de código, traduções e documentação. Consulte a [documentação de contribuição do wger](https://wger.readthedocs.io/en/latest/contributing.html) e o [repositório original](https://github.com/wger-project/flutter).

## Licença e créditos

Este aplicativo deriva do **wger Workout Manager**, desenvolvido pela equipe wger e seus colaboradores. O código original é disponibilizado sob a **GNU Affero General Public License, versão 3 ou posterior (AGPL-3.0-or-later)**, com exceção específica para lojas de aplicativos. Os avisos de direitos autorais e a licença original devem ser preservados. Dados de exercícios e ingredientes podem estar sujeitos a licenças Creative Commons próprias. Consulte os arquivos de licença do repositório e as informações de cada conjunto de dados.
