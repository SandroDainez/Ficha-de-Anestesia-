# anestesia_app

Aplicativo Flutter para registro de ficha anestesica e consulta pre-anestesica.

## Objetivo

O projeto organiza dois fluxos principais:

- inicio rapido de uma ficha anestesica para casos de urgencia ou emergencia
- consulta pre-anestesica com dados que podem ser reutilizados na ficha intraoperatoria

O app tambem possui:

- modelos de dominio para paciente, via aerea, balanco hidrico e registro anestesico
- persistencia local simples com Hive
- analise local baseada em regras para apontar campos faltantes e inconsistencias

## Fluxo atual

1. A tela inicial permite abrir uma nova ficha anestesica ou iniciar pela consulta pre-anestesica.
2. A consulta pre-anestesica retorna dados do paciente e avaliacao para a ficha principal.
3. A ficha anestesica concentra identificacao, via aerea, tecnica, hemodinamica, eventos, drogas e balanco.
4. A analise final revisa campos obrigatorios e gera orientacoes com base em regras locais.

## Estrutura

```text
lib/
  main.dart
  models/       modelos de dominio e serializacao
  screens/      telas principais e dialogs
  services/     persistencia, validacao e analise
  widgets/      componentes reutilizaveis
test/
  testes de widget, modelos e servicos
```

## Stack

- Flutter
- Dart 3
- Hive
- path_provider

## Como rodar

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Estado atual

O projeto esta funcional localmente e hoje usa analise "IA" simulada por heuristicas em codigo. Nao ha integracao real com backend, LLM ou servico clinico externo.

## Pendencias conhecidas

- definir escopo de produto e regras clinicas obrigatorias com mais precisao
- ampliar testes de fluxo e testes de widget das telas principais
- decidir se a analise continuara heuristica ou se vira integracao real com backend
- conectar esta pasta a um repositorio Git ativo, caso o projeto tenha origem remota

## Observacoes

- este app persiste um unico registro atual localmente
- o README anterior era o padrao do Flutter; este arquivo agora documenta o estado real do projeto
