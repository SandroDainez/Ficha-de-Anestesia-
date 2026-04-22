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

O fluxo seguro hoje é:

```bash
./scripts/deploy_vercel_prod.sh
```

Esse script:

- gera `build/web`
- reaplica no `build/web` o vínculo do projeto salvo na raiz em `.vercel/project.json`
- publica em produção sem criar um projeto acidental novo no Vercel

Se preferir rodar manualmente, o caminho seguro é:

```bash
flutter build web --no-wasm-dry-run
mkdir -p build/web/.vercel
cp .vercel/project.json build/web/.vercel/project.json
vercel deploy --cwd build/web --prod --yes
```

### Deploy automático (Git → Vercel)

O repositório inclui `package.json` e `scripts/vercel_build.sh`: no push para `main`, o Vercel deve executar `npm install` e `npm run build`, que instala o Flutter (clone stable), roda `flutter build web` e publica **`build/web`**.

No painel do projeto Vercel, confira **Settings → General → Build & Development**:

| Campo | Valor esperado |
|--------|----------------|
| Framework Preset | **Other** (ou detectado via `package.json`) |
| Install Command | `npm install` (padrão) |
| Build Command | `npm run build` (ou deixe vazio se o `vercel.json` do repo já define) |
| Output Directory | **`build/web`** |

O arquivo `vercel.json` na raiz define `buildCommand`, `outputDirectory` e rewrites SPA. O primeiro build pode levar vários minutos (download do SDK). Se aparecer **404 NOT_FOUND**, em geral o deploy não gerou `build/web` (build falhou): abra o log do deployment no Vercel.

O fluxo manual continua válido: `./scripts/deploy_vercel_prod.sh` (build local + `vercel deploy --cwd build/web`). O script copia para `build/web` um `vercel.json` só com rewrites e um `package.json` mínimo (o `npm install` / `npm run build` da Vercel não voltam a correr o Flutter dentro dessa pasta). No painel, se **Output Directory** estiver `build/web` e usares só este fluxo CLI, altera para **`.`** ou deixa em branco para o projeto ligado a esta pasta.

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

## Persistência online com Supabase e controle de acesso

1. Configure as variáveis de ambiente com:

   ```
   flutter run --dart-define=SUPABASE_URL=https://ekzwbjfimrojujookyhi.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=sb_publishable_m_6gsKJexTpua5tKSWUOxA_I2TuuccE
   ```

   No Vercel, defina as mesmas chaves (Settings → Environment Variables). O app detecta essas variáveis e habilita o modo compartilhado com login.

2. Crie a tabela de usuários do app, a tabela de casos e as políticas com esse SQL:

   ```sql
   create table public.app_users (
     id uuid primary key references auth.users(id) on delete cascade,
     email text not null unique,
     full_name text not null default '',
     role text not null default 'clinician' check (role in ('admin', 'clinician')),
     status text not null default 'pending' check (status in ('pending', 'active', 'blocked')),
     approved_at timestamptz,
     blocked_at timestamptz,
     created_at timestamptz not null default now(),
     updated_at timestamptz not null default now()
   );

   create table public.anesthesia_cases (
     id uuid primary key default gen_random_uuid(),
     created_at timestamptz not null default now(),
     updated_at timestamptz not null default now(),
     pre_anesthetic_date text default '',
     anesthesia_date text default '',
     status text not null,
     record jsonb not null
   );

   create or replace function public.is_admin_user()
   returns boolean
   language sql
   stable
   as $$
     select exists (
       select 1
       from public.app_users
       where id = auth.uid()
         and role = 'admin'
         and status = 'active'
     );
   $$;

   create or replace function public.touch_updated_at()
   returns trigger
   language plpgsql
   as $$
   begin
     new.updated_at = now();
     return new;
   end;
   $$;

   create trigger touch_app_users_updated_at
   before update on public.app_users
   for each row execute function public.touch_updated_at();

   create trigger touch_anesthesia_cases_updated_at
   before update on public.anesthesia_cases
   for each row execute function public.touch_updated_at();

   alter table public.app_users enable row level security;
   alter table public.anesthesia_cases enable row level security;

   create policy "users can read own profile"
   on public.app_users
   for select
   to authenticated
   using (id = auth.uid());

   create policy "admins can read all profiles"
   on public.app_users
   for select
   to authenticated
   using (public.is_admin_user());

   create policy "users can insert own profile"
   on public.app_users
   for insert
   to authenticated
   with check (id = auth.uid());

   create policy "admins can update profiles"
   on public.app_users
   for update
   to authenticated
   using (public.is_admin_user())
   with check (public.is_admin_user());

   create policy "active users can read cases"
   on public.anesthesia_cases
   for select
   to authenticated
   using (
     exists (
       select 1
       from public.app_users
       where id = auth.uid()
         and status = 'active'
     )
   );

   create policy "active users can insert cases"
   on public.anesthesia_cases
   for insert
   to authenticated
   with check (
     exists (
       select 1
       from public.app_users
       where id = auth.uid()
         and status = 'active'
     )
   );

   create policy "active users can update cases"
   on public.anesthesia_cases
   for update
   to authenticated
   using (
     exists (
       select 1
       from public.app_users
       where id = auth.uid()
         and status = 'active'
     )
   )
   with check (
     exists (
       select 1
       from public.app_users
       where id = auth.uid()
         and status = 'active'
     )
   );

   create policy "active users can delete cases"
   on public.anesthesia_cases
   for delete
   to authenticated
   using (
     exists (
       select 1
       from public.app_users
       where id = auth.uid()
         and status = 'active'
     )
   );
   ```

3. Crie o primeiro administrador no Supabase Auth com:
   - email: `sandrodainez@hotmail.com`
   - senha inicial: `123456` se quiser manter esse padrão inicial

   Observação: a senha **não** fica gravada no código do app. Ela deve ser criada no Supabase Auth para esse email.

4. Agora você terá:
   - login e cadastro de usuários
   - cadastro comum com status `pending`, aguardando aprovação do administrador
   - administrador com acesso para listar usuários, aprovar, bloquear e reativar
   - casos sincronizados no Supabase para todos os usuários ativos
   - fallback para Hive local quando as chaves não estiverem definidas
   - exportação de PDF e também JSON (botão novo no rodapé e na lista de casos) para baixar/enviar por email ou WhatsApp

5. Redefinição de senha por administrador e convite por email/WhatsApp ficam para a próxima etapa. Para redefinir senha de forma segura será necessário usar backend próprio, Edge Function ou script administrativo com `service_role` fora do Flutter/web.

6. Se precisar de tarefas administrativas (migrations, webhooks etc.) use a `service_role` em scripts separados — jamais exponha essa chave no Flutter/web.

## Pendências conhecidas

- definir escopo de produto e regras clínicas obrigatórias com mais precisão
- ampliar ainda mais testes de fluxo fino das telas principais
- decidir se a análise continuará heurística ou se vira integração real com backend
- afinar tempo de build no Vercel (cache do SDK) se o primeiro deploy passar do limite

## Observacoes

- este app persiste um unico registro atual localmente
- o README anterior era o padrão do Flutter; este arquivo agora documenta o estado real do projeto
