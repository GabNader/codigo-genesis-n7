# Código Gênesis: O Legado de N-7

Jogo sério de estratégia e sobrevivência por turnos em grid hexagonal, sobre matemática
aplicada (álgebra, geometria analítica, probabilidade e porcentagem), sem quizzes. Você
controla o robô N-7 dentro de um domo em colapso: escaneia a névoa de dados com o LiDAR,
calcula rotas em que cada quilo de carga encarece o passo, e resgata os núcleos da
Natureza e da Arte para levar a Trindade de Dados ao Elevador Central. O que você entrega
define um de **5 finais**.

O design completo está no [GDD v2](docs/GDD.md), que expande o
[GDD v1 original](docs/GDD_Codigo_Genesis_N7_v1.pdf).

## Como jogar

A primeira partida começa com um **tutorial no primeiro turno**: o despertar do N-7
ensina o LiDAR, o primeiro passo e o custo antes de confirmar. Ele pode ser religado no menu.

| Ação | Controle |
|---|---|
| Traçar rota até um hexágono visível | clique esquerdo |
| Estender a rota à mão | clique num vizinho do fim da rota |
| Cortar / limpar a rota | clique num hexágono da rota / clique direito |
| Zoom / mover câmera | roda do mouse / botão do meio arrastando |
| Pausa | Esc |

- **Custo por hexágono = 1,5 × (1 + Carga ÷ 15)** % de bateria. Até 4 hexágonos por turno.
- **LiDAR**: −5% de bateria e escaneia o raio 3. Vazamentos, interferência e gás só aparecem com ele.
- **Subestações** mostram a estabilidade: compare o ganho esperado do sifonamento arriscado com o seguro.
- A partir do turno 15 o domo colapsa de fora para dentro.

## Stack

- **Engine:** Godot **4.6.1** (versão fixada em [`.godot-version`](.godot-version)), renderizador *GL Compatibility*
- **Linguagem:** GDScript
- **Testes:** [GUT 9.6.1](https://github.com/bitwes/Gut) (Godot Unit Test), em [`addons/gut/`](addons/gut)

## Dependências e "lockfile"

O Godot **não tem gerenciador de pacotes** (não existe `npm install` ou `pip install`).
Plugins e bibliotecas são *addons*: pastas copiadas para dentro de `addons/` e
**versionadas no próprio repositório**. Por isso, o equivalente ao lockfile aqui é:

- [`.godot-version`](.godot-version): versão exata da engine (`4.6.1`). Abrir o projeto com
  outra versão pode reimportar ou converter arquivos.
- [`addons/`](addons): código exato de cada addon, com a versão registrada no `plugin.cfg`
  de cada um (ex.: `addons/gut/plugin.cfg` → `version="9.6.1"`).

Para atualizar um addon, substitua a pasta inteira em `addons/` por um Pull Request.

## Como instalar

1. Baixe o **Godot 4.6.1 stable** (edição padrão, não a .NET) em
   <https://godotengine.org/download/archive/4.6.1-stable/>.
2. Clone o repositório:
   ```bash
   git clone https://github.com/GabNader/codigo-genesis-n7.git
   cd codigo-genesis-n7
   ```
3. Não há variáveis de ambiente hoje. Se surgirem, copie `.env.example` para `.env`
   (o `.env` é ignorado pelo Git).

Nos comandos abaixo, `godot` é o executável do Godot 4.6.1. No Windows, use o
`Godot_v4.6.1-stable_win64_console.exe` para ver a saída no terminal.

## Como rodar o jogo

Pelo editor: abra o Godot, **Importar** → selecione `project.godot` → **F5**.

Pela linha de comando:

```bash
godot --path .
```

## Como rodar os testes (headless)

Na primeira vez (ou após um clone limpo), importe os recursos do projeto:

```bash
godot --headless --path . --import
```

Depois rode a suíte do GUT sem abrir janela:

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd
```

A configuração fica em [`.gutconfig.json`](.gutconfig.json) (testes em `tests/unit/`, arquivos
`test_*.gd`). O processo termina com código `0` se todos os testes passarem e diferente de
`0` se algum falhar. Avisos como `ObjectDB instances leaked at exit` no fim da execução
são normais no GUT e não indicam falha.

Também é possível rodar pelo editor: ative o plugin em **Projeto → Configurações do
Projeto → Plugins → Gut** e use o painel **GUT** na parte inferior.

## Estrutura

| Caminho | Conteúdo |
|---|---|
| `scenes/` | cenas: menu, tática (`Main`), HUD, N-7, grid hexagonal e tela final |
| `scripts/core/` | regras puras e testáveis: hex, economia, terrenos, mochila, mapa, eventos, Diretor de IA, finais |
| `scripts/autoload/` | `GameState` (estado e turnos da partida) e `AudioManager` |
| `scripts/game/` | scripts das cenas: jogador, camada de dados do mapa, HUD, mochila, menus |
| `shaders/` | shader da névoa de dados |
| `assets/` | sprites, fontes e áudio |
| `addons/gut/` | framework de testes (dependência versionada) |
| `tests/unit/` | testes automatizados (regras, estado, cenas e partidas completas) |
| `tests/support/` | piloto automático que joga partidas inteiras nos testes |
| `.github/` | templates de PR e Issue, CODEOWNERS |
| `docs/` | GDD, Plano de Gerenciamento de Configuração, ADRs e evidências |

## Gerência de Configuração

O projeto segue o **Plano de Gerenciamento de Configuração — Enfoque DevOps (PGCS)**, que
é item de configuração deste repositório:

- [`docs/PGCS_CodigoGenesis_N7.pdf`](docs/PGCS_CodigoGenesis_N7.pdf) (versão de leitura)
- [`docs/PGCS_CodigoGenesis_N7.docx`](docs/PGCS_CodigoGenesis_N7.docx) (fonte editável)

Evidências: [recusa de push direto na `main`](docs/evidencias/aula-1-push-direto-recusado.md).

## Como contribuir

A `main` é protegida: toda mudança entra por Pull Request com 1 aprovação de outra pessoa e
*squash merge*. Use o template de PR e títulos no padrão Conventional Commits
(ex.: `feat(mapa): adiciona bioma de deserto`).
