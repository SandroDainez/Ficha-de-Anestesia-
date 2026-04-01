# Ficha de Anestesia

Aplicativo Flutter para registro de ficha anestésica e consulta pré-anestésica.

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

## Publicação

- GitHub: `https://github.com/SandroDainez/Ficha-de-Anestesia-`
- Produção Vercel: `https://web-three-ivory-51.vercel.app`
- Projeto Vercel vinculado: `anestesia_app`
- Link local do Vercel salvo em `.vercel/` e ignorado no Git

### Deploy web atual

O fluxo validado hoje é:

```bash
flutter build web
vercel deploy build/web --prod --yes
```

### Observação sobre deploy automático

O projeto já está conectado ao GitHub no Vercel, mas o build automático por push ainda não foi configurado com instalação do Flutter no ambiente do Vercel. Então, no estado atual, o caminho confiável continua sendo gerar `build/web` e publicar essa saída.

## Versionamento

Fluxo atual validado:

```bash
git status
git add .
git commit -m "mensagem"
git push -u origin main
```

## Estado atual

O projeto esta funcional localmente e hoje usa analise "IA" simulada por heuristicas em codigo. Nao ha integracao real com backend, LLM ou servico clinico externo.

## Persistência online com Supabase

1. Configure as variáveis de ambiente com:

   ```
   flutter run --dart-define=SUPABASE_URL=https://ekzwbjfimrojujookyhi.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=sb_publishable_m_6gsKJexTpua5tKSWUOxA_I2TuuccE
   ```

   No Vercel, defina as mesmas chaves (Settings → Environment Variables). O app detecta essas variáveis e passa a armazenar/listar casos diretamente no Supabase.

2. Crie a tabela e as políticas com esse SQL:

   ```sql
   create table public.anesthesia_cases (
     id uuid primary key default gen_random_uuid(),
     created_at timestamptz not null default now(),
     updated_at timestamptz not null default now(),
     pre_anesthetic_date text default '',
     anesthesia_date text default '',
     status text not null,
     record jsonb not null
   );
   alter table public.anesthesia_cases enable row level security;
   create policy "allow anon select" on public.anesthesia_cases for select using (true);
   create policy "allow anon insert" on public.anesthesia_cases for insert with check (true);
   create policy "allow anon update" on public.anesthesia_cases for update using (true) with check (true);
   create policy "allow anon delete" on public.anesthesia_cases for delete using (true);
   ```

3. Agora você terá:
   - casos sincronizados no Supabase e acessíveis de qualquer dispositivo com as mesmas chaves
   - fallback para Hive local quando as chaves não estiverem definidas
   - exportação de PDF e também JSON (botão novo no rodapé e na lista de casos) para baixar/enviar por email ou WhatsApp

4. Se precisar de tarefas administrativas (migrations, webhooks etc.) use a `service_role` em scripts separados — jamais exponha essa chave no Flutter/web.

## Pendências conhecidas

- definir escopo de produto e regras clínicas obrigatórias com mais precisão
- ampliar ainda mais testes de fluxo fino das telas principais
- decidir se a análise continuará heurística ou se vira integração real com backend
- configurar, se desejado, um pipeline de build Flutter automático para deploy por push no Vercel

## Observacoes

- este app persiste um unico registro atual localmente
- o README anterior era o padrão do Flutter; este arquivo agora documenta o estado real do projeto
