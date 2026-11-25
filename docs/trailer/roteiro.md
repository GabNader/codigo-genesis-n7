# Trailer cinematográfico — Código Gênesis: O Legado de N-7

Sugestão da professora: um trailer feito com o **Google Flow** (ou ferramenta similar).
Este roteiro combina **cenas cinematográficas geradas com IA** (atmosfera e história) com
**gameplay real** gravado pelo próprio Godot, para o trailer não prometer um jogo
diferente do que existe. Issue: [#6](https://github.com/GabNader/codigo-genesis-n7/issues/6).

| Item | Definição |
|---|---|
| Duração | 60 a 75 s |
| Formato | 16:9, 1920×1080, 24 ou 30 fps |
| Tom | melancolia contemplativa → tensão lógica → esperança (os 3 pilares do GDD §3) |
| Trilha | `assets/audio/trilha.mp3` + sons do jogo (ver "Licenças" antes de publicar) |
| Fonte dos textos | `assets/PixelOperator.ttf` (a mesma da HUD) |

---

## 1. Ferramentas

- **Google Flow** (labs.google/flow): gera clipes curtos com o modelo Veo a partir de texto
  e de imagens de referência. Planos, créditos e limites mudam com frequência: confira na
  conta da equipe antes de começar. Cada clipe custa créditos, então gere poucas variações
  por cena e só depois de fechar o prompt.
- **Alternativas** com o mesmo fluxo (prompt + imagem de referência): Runway, Kling, Luma
  Dream Machine.
- **Edição**: DaVinci Resolve ou CapCut (gratuitos). Os dois importam os clipes `.avi`
  gravados pelo Godot.

## 2. Imagens de referência (pasta `referencias/`)

| Arquivo | Uso no Flow |
|---|---|
| [`n7-frente.png`](referencias/n7-frente.png) | **Sempre** como referência do personagem ("ingredient" / imagem inicial). Sem ela, cada clipe gera um robô diferente |
| [`gameplay-mapa.jpg`](referencias/gameplay-mapa.jpg) | Paleta e clima: hexágonos ciano, setores verde e roxo |
| [`gameplay-trindade.jpg`](referencias/gameplay-trindade.jpg) | Luz dourada do Elevador e da Trindade |

Outras referências que já existem: a concept art do Domo e o mapa de biomas no
[GDD v1](../GDD_Codigo_Genesis_N7_v1.pdf) (§10 e §12).

## 3. Bloco fixo dos prompts

Cole estes dois blocos **no início de todo prompt** de cena com o N-7. Eles mantêm o
personagem e o estilo iguais em todos os clipes.

**Personagem**
> A small boxy utility robot named N-7: a yellow-ochre cube-shaped head and body, a dark
> screen-face with two glowing cyan round eyes, a black camera lens on the right side of
> the head, two black rubber tank treads with yellow wheel hubs. Cute, modular, not
> militaristic. Same design as the reference image.

**Estilo**
> Cinematic, cyber-decay aesthetic: rusted industrial metal, exposed cables, overgrown
> vegetation reclaiming the structure, neon cyan and magenta accents, volumetric light
> through dust, melancholic and quiet atmosphere, shallow depth of field, film grain,
> 24fps, no text, no logos.

Não use nomes de personagens ou filmes com direitos autorais nos prompts: descreva o visual.

## 4. Roteiro cena a cena

Legenda da fonte: **IA** = gerar no Flow · **JOGO** = clipe gravado em `clipes/`.

| # | Tempo | Fonte | Imagem | Texto na tela | Áudio |
|---|---|---|---|---|---|
| 1 | 0–6 s | IA | O Domo Esperança visto de dentro, em colapso lento | *"A humanidade se foi."* | drone grave, sem música |
| 2 | 6–11 s | IA | Olhos ciano do N-7 acendendo no escuro | — | bip de inicialização |
| 3 | 11–15 s | JOGO `01_despertar` (2–6 s) | Visor: "REINICIALIZAÇÃO CONCLUÍDA" | — | entra a trilha |
| 4 | 15–21 s | IA | N-7 atravessando a Zona Industrial | *"Ela deixou um último registro."* | zumbido elétrico |
| 5 | 21–24 s | JOGO `02_lidar` (0,8–3,8 s) | Pulso do LiDAR revelando o grid | *"Escaneie."* | sonar |
| 6 | 24–28 s | JOGO `03_rota` (2–6 s) | Rota com o custo de cada passo | *"Calcule."* | — |
| 7 | 28–33 s | IA | Estufa alagada, raízes metálicas, água escorrendo | — | água |
| 8 | 33–39 s | JOGO `05_natureza` (4,8–10,8 s) | Núcleo da Natureza: escolha, mochila, memória | *"Cada escolha pesa."* | canto de pássaro |
| 9 | 39–43 s | IA | Zona de Degradação: névoa química, neon em curto | *"Cada passo custa."* | vento |
| 10 | 43–52 s | JOGO `06_arte` (5–14 s) | Cofre das Memórias: *Ode à Alegria* recuperada | — | a melodia do jogo, trilha abaixada |
| 11 | 52–58 s | JOGO `07_trindade` (6–12 s) | PROTOCOLO TRINO COMPLETO e a linha dourada | *"Lógica. Natureza. Arte."* | arpejo |
| 12 | 58–65 s | IA | O Elevador Central: coluna de luz subindo no meio do domo, N-7 pequeno diante dela | — | trilha no ápice |
| 13 | 65–70 s | edição | Título e subtítulo | **CÓDIGO GÊNESIS** / *O Legado de N-7* | trilha termina |
| 14 | 70–73 s | edição | Créditos curtos (ver §7) | | silêncio |

Os clipes `04_subestacao` e `08_final` ficam de reserva: subestação com a probabilidade
visível (bom para um corte "probabilidade") e a tela do final Gênesis.

## 5. Prompts das cenas de IA

Use o bloco fixo (§3) + o prompt da cena. Duração alvo de cada clipe: 5–8 s.

**Cena 1 — O Domo**
> Wide establishing shot inside a colossal ruined dome, hexagonal glass panels cracked and
> partly fallen, dust drifting in shafts of pale light, dead industrial towers and vines,
> slow crane shot descending. No characters.

**Cena 2 — Despertar** *(com `n7-frente.png`)*
> Extreme close-up in darkness: the robot's dark screen-face flickers, then two round cyan
> eyes light up and blink once, dust falls from the head, tiny servo movement. Static camera.

**Cena 4 — Zona Industrial** *(com `n7-frente.png`)*
> The robot rolls slowly on its tank treads across a rusted metal floor between silent
> machines and hanging cables, sparks from a broken panel, low tracking shot following it.

**Cena 7 — Setor Eco-Vegetativo** *(com `n7-frente.png`)*
> Inside a collapsed hydroponic greenhouse, metallic roots covering old iron beams, water
> trickling along gutters into puddles, green bioluminescent leaves; the robot stops and
> looks up at falling water droplets. Slow push-in.

**Cena 9 — Zona de Degradação** *(com `n7-frente.png`)*
> A toxic corridor with drifting chemical fog, flickering magenta neon signs short-circuiting,
> cracked floor glowing orange from a thermal leak; the robot hesitates at the edge, its cyan
> eyes scanning. Handheld feel, tense.

**Cena 12 — Elevador Central** *(com `n7-frente.png` e `gameplay-trindade.jpg`)*
> At the center of the dome a towering clean white elevator column emits a golden beam of
> light upward into the darkness; the small robot, carrying three glowing cores (blue, green,
> purple), rolls toward it and stops at its base. Slow pull-back revealing the scale. Hopeful.

**Dicas para o Flow**
- Gere primeiro uma imagem parada da cena (ou use a referência como quadro inicial) e só
  depois anime: sai mais consistente.
- Se o robô "mudar de design", reforce no prompt "same design as the reference image" e
  reduza o movimento de câmera.
- Prefira movimentos lentos de câmera: combinam com o Pilar 2 (melancolia contemplativa) e
  dão menos defeitos.

## 6. Clipes de gameplay (gravados com o Movie Maker do Godot)

Gravados em 1920×1080 a 30 fps com a semente 21, pelo script
[`tools/trailer/gravar_clipes.gd`](../../tools/trailer/gravar_clipes.gd). Os arquivos
`.avi` (35–110 MB cada) **ficam fora do repositório**, na pasta
`codigo-genesis-trailer/clipes` da área de trabalho de quem gravou.

| Arquivo | Duração | O que mostra |
|---|---|---|
| `01_despertar.avi` | 9,6 s | Visor do despertar e início do tutorial |
| `02_lidar.avi` | 5 s | Pulso do LiDAR revelando o raio 3 |
| `03_rota.avi` | 8 s | Rota de 4 hex com o custo por passo e o deslocamento |
| `04_subestacao.avi` | 8 s | Subestação com estabilidade e valor esperado |
| `05_natureza.avi` | 14 s | Jardim Suspenso, mochila e memória (canto de pássaro) |
| `06_arte.avi` | 16 s | Cofre das Memórias e a *Ode à Alegria* |
| `07_trindade.avi` | 16 s | Trindade completa, linha dourada, rota até o Elevador |
| `08_final.avi` | 9 s | Ascensão e a tela do final Gênesis |

**Para regravar** (por exemplo, depois de mudar a interface):

1. Crie um `override.cfg` na raiz do projeto para gravar em 1080p (ele está no `.gitignore`):
   ```ini
   [display]

   window/size/viewport_width=1920
   window/size/viewport_height=1080
   ```
2. Grave um clipe por vez (troque `rota` pelo nome do clipe):
   ```bash
   godot --path . --write-movie ../codigo-genesis-trailer/clipes/03_rota.avi --fixed-fps 30 -s res://tools/trailer/gravar_clipes.gd -- rota
   ```
3. Apague o `override.cfg`.

Os clipes saem com o áudio do jogo (trilha e sons). Na edição, deixe a trilha numa faixa
própria e use o áudio dos clipes só nos momentos marcados no §4.

## 7. Edição, créditos e licenças

**Montagem**
1. Monte primeiro só com os clipes de jogo e a trilha, nos tempos do §4.
2. Encaixe as cenas de IA nos buracos. Se uma cena não ficar boa, troque por um clipe de
   jogo: é melhor um trailer mais curto do que um robô inconsistente.
3. Textos com a fonte PixelOperator, em ciano `#00E6E6`, entrando com fade curto.
4. Correção de cor leve para aproximar as cenas de IA da paleta do jogo (azul e ciano
   escuros, realces dourados no final).

**Créditos (texto final)**
> Código Gênesis: O Legado de N-7 — PAC Extensionista III, Engenharia de Software.
> Gabriel Nader Marini, Izadora de Souza, Larissa dos Santos, Letícia de Abreu.
> Cenas cinematográficas geradas com IA (Google Flow). Gameplay capturado do jogo.
> Ode à Alegria: L. van Beethoven (domínio público), versão sintetizada no jogo.

**Antes de publicar, confirmem:**
- [ ] A origem e a licença de `trilha.mp3`, `beep.mp3` e `move.mp3`. Se forem de terceiros,
      a licença precisa permitir uso em vídeo público (PGCS §13 pede esse registro).
- [ ] Os termos de uso do Flow para o plano da conta (uso público dos vídeos gerados). Os
      vídeos do Veo podem levar marca d'água (visível em alguns planos e o SynthID invisível).
- [ ] Que as cenas de IA não sugerem mecânicas que o jogo não tem. Se for necessário, um
      aviso no início: *"Cenas cinematográficas não representam o gameplay."*
- [ ] Que a professora e a equipe aprovaram o corte final.
