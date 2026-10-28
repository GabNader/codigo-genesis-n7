# Código Genesis: O Legado de N-7

Jogo 2D de estratégia por turnos em mapa hexagonal. Você controla o robô N-7, explora um
mundo coberto por névoa e administra bateria, integridade e carga enquanto enfrenta
eventos narrativos em busca dos três núcleos (Lógica, Natureza e Arte).

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
| `*.gd`, `*.tscn` | cenas e scripts do jogo (`GameState` e `AudioManager` são autoloads) |
| `assets/` | sprites, fontes e áudio |
| `addons/gut/` | framework de testes (dependência versionada) |
| `tests/unit/` | testes automatizados |
| `.github/` | templates de PR e Issue, CODEOWNERS |

## Como contribuir

A `main` é protegida: toda mudança entra por Pull Request com 1 aprovação de outra pessoa e
*squash merge*. Use o template de PR e títulos no padrão Conventional Commits
(ex.: `feat(mapa): adiciona bioma de deserto`).
