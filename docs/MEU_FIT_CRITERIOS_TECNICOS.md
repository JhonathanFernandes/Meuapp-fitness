# Meu Fit — requisitos técnicos para sugestões de atividade física

**Status:** critérios iniciais de produto, não validação profissional de uma prescrição individual.
**Público do gerador automático inicial:** adultos de 18 a 64 anos sem limitações relatadas. Para outras idades, dores ou limitações, suspender sugestão personalizada e orientar avaliação individual por profissional habilitado.

## Fontes rastreáveis
1. Ministério da Saúde, *Guia de Atividade Física para a População Brasileira* (2021): https://bvsms.saude.gov.br/bvs/publicacoes/guia_atividade_fisica_populacao_brasileira.pdf
2. Ministério da Saúde, Linha de Cuidado da Obesidade no Adulto: https://linhasdecuidado.saude.gov.br/portal/obesidade-no-adulto/atencao-especializada/planejamento-terapeutico/
3. ACSM, *Resistance Training Prescription for Muscle Function, Hypertrophy, and Physical Performance in Healthy Adults* (2026): https://acsm.org/resistance-training-guidelines-update-2026/
4. ACSM, posição sobre componentes cardiorrespiratórios, musculoesqueléticos e neuromotores: https://acsm.org/education-resources/pronouncements-scientific-communications/position-stands/
5. CONFEF, atuação profissional: https://www.confef.org.br/

O Ministério da Saúde publica diretrizes populacionais; o CONFEF regulamenta o exercício profissional e **não homologa os treinos do app**. ACSM fornece evidências científicas, não aprovação individual.

## Regras funcionais obrigatórias
- **Emagrecimento:** contemplar componente aeróbico de baixo impacto conforme tolerância e fortalecimento; não prometer perda de peso só pelo treino. Referências 1–2.
- **Hipertrofia:** treinamento resistido progressivo, distribuição semanal por grupos musculares, recuperação e volume compatíveis com experiência. A referência 3 discute volume próximo de 10 séries semanais por grupo para hipertrofia em adultos saudáveis; não impor isso como dose universal inicial.
- **Flexibilidade/mobilidade:** sessão específica de mobilidade e alongamento, sem prometer tratar lesões; definir exercícios, amplitude confortável e progressão. Referência 4. Protocolo detalhado requer revisão de profissional de Educação Física.
- **Condicionamento/manutenção:** combinar atividade aeróbica e fortalecimento, progressão gradual. Referência 1.
- Perguntar idade, objetivo, experiência, dias disponíveis, local/equipamentos, limitações e dor antes de oferecer personalização.
- Bloquear **gravação automática** se houver limitações relatadas, dados incompletos, exercício sem correspondência inequívoca no catálogo Wger, ou protocolo não revisado.
- Cada exercício sugerido precisa de nome canônico, objetivo, alternativa segura quando aplicável, justificativa e fonte. Correspondência de nome com catálogo **não** é validação clínica.
- Exibir texto claro: “Sugestão educativa; não substitui avaliação individual de profissional de Educação Física.”
- Nunca gerar progressão de carga automática para pessoas com limitações ou condições clínicas sem avaliação individual.
- Registrar versão da regra e referências; testar cenários de segurança, objetivos, dias, locais, catálogo vazio e exercícios indisponíveis.

## Pendências antes de liberar gravação como rotina
- Revisão e assinatura dos protocolos por profissional de Educação Física registrado no CREF.
- Questionário de segurança mais completo, incluindo sintomas, dor, limitações e condições relevantes, com privacidade adequada.
- Protocolos de aeróbico e flexibilidade, distribuição de dias de descanso e volume semanal por grupo muscular.
- Integração segura com IDs reais de exercícios e séries/repetições do Wger.
- Testes automatizados, análise estática Flutter e teste em aparelho.

**Política atual:** manter as sugestões como prévia educativa e não afirmar validação ou prescrição profissional.
