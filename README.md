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
- Produção Vercel: `https://anestesiaapp.vercel.app`
- Aliases Vercel atuais:
  `https://anestesiaapp-sandro-rogerio-dainezs-projects.vercel.app`
  `https://anestesiaapp-sandrodainez-sandro-rogerio-dainezs-projects.vercel.app`
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

O fluxo manual continua válido: `./scripts/deploy_vercel_prod.sh` (build local + `vercel deploy --cwd build/web`). Agora ele também puxa `SUPABASE_URL` e `SUPABASE_ANON_KEY` do ambiente de produção do Vercel quando essas variáveis não estiverem definidas localmente, e passa ambas ao `flutter build web` via `--dart-define`. O script copia para `build/web` um `vercel.json` só com rewrites e um `package.json` mínimo (o `npm install` / `npm run build` da Vercel não voltam a correr o Flutter dentro dessa pasta). No painel, se **Output Directory** estiver `build/web` e usares só este fluxo CLI, altera para **`.`** ou deixa em branco para o projeto ligado a esta pasta.

## Versionamento

Fluxo atual validado:

```bash
git status
git add .
git commit -m "mensagem"
git push -u origin main
```

## Estado atual

O projeto esta funcional localmente, usa analise "IA" simulada por heuristicas em codigo e possui integracao opcional com Supabase para login, aprovacao de usuarios e banco compartilhado. Nao ha integracao real com LLM ou servico clinico externo.

## Persistencia online com Supabase e controle de acesso

1. Configure as variaveis de ambiente para habilitar login e banco compartilhado:

   ```bash
   flutter run --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=sua-chave-anon
   ```

   No Vercel, defina `SUPABASE_URL` e `SUPABASE_ANON_KEY` em Settings -> Environment Variables. O app nao traz mais fallback com chaves hardcoded; sem essas variaveis, o modo local usa Hive em plataformas desktop/mobile. Para web publicado, essas variaveis precisam entrar no `flutter build web`; o deploy manual e o build remoto agora fazem isso automaticamente quando o ambiente estiver configurado.

2. Aplique as migrations em `supabase/migrations/`. Elas criam as tabelas, policies RLS e a funcao `register_current_user_profile`, que registra o perfil do usuario autenticado sem permitir que o Flutter escolha `role` ou `status` diretamente.

3. O primeiro administrador continua sendo o email `sandrodainez@hotmail.com`. Crie esse usuario no Supabase Auth e execute as migrations; a migration de seguranca promove esse perfil para `admin`/`active`.

4. Com Supabase ativo, o app oferece login/cadastro, cadastro comum como `pending`, aprovacao/bloqueio/reativacao por administrador, casos compartilhados entre usuarios ativos e exportacao de PDF/JSON.

5. Redefinicao de senha por administrador e convite por email/WhatsApp ficam para uma etapa com backend proprio, Edge Function ou script administrativo com `service_role`. Nunca exponha `service_role` no Flutter/web.

## Pendências conhecidas

- definir escopo de produto e regras clínicas obrigatórias com mais precisão
- ampliar ainda mais testes de fluxo fino das telas principais
- decidir se a análise continuará heurística ou se vira integração real com backend
- afinar tempo de build no Vercel (cache do SDK) se o primeiro deploy passar do limite

## Observacoes

- este app persiste multiplos casos localmente com Hive quando Supabase nao esta configurado e a plataforma permite armazenamento local
- no web, use Supabase para persistencia confiavel entre sessoes e usuarios
- o README anterior era o padrão do Flutter; este arquivo agora documenta o estado real do projeto
