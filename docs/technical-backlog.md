# Backlog Tecnico

## Prioridade alta

- Quebrar [`lib/screens/anesthesia_screen.dart`](/Users/sandrodainez/anestesia_app/lib/screens/anesthesia_screen.dart) em modulos menores. O arquivo tem mais de 11 mil linhas e mistura tela, dialogs, regras de estado e persistencia.
- Extrair logica hemodinamica para uma camada testavel. Hoje calculos de marcadores, tempos e migracao de dados legados ficam acoplados ao `State`.
- Criar testes de widget para os fluxos criticos da ficha principal: time-out, tecnica anestesica, balanco hidrico, eventos e analise final.

## Prioridade media

- Introduzir chaves semanticas (`Key`) nos botoes e secoes principais para deixar os testes menos frageis.
- Separar dialogs em arquivos dedicados por dominio: via aerea, cirurgia, drogas, eventos, adjuvantes, balanco e anestesiologista.
- Padronizar o formato dos itens estruturados salvos como `String` com `|`, hoje usado em eventos, drogas e adjuvantes.

## Prioridade media/baixa

- Melhorar o isolamento da persistencia de casos para facilitar testes sem Hive/Supabase real e reduzir dependencia de singletons.
- Decidir se a "analise com IA" continua heuristica local ou passa a ser uma integracao real com backend.
- Melhorar o isolamento entre regras clinicas e apresentacao para permitir validacao mais formal no futuro.
