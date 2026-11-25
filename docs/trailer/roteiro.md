# Trailer cinematográfico — Código Gênesis: O Legado de N-7

O trailer é um vídeo **separado da apresentação jogada** (que está em
[`apresentacao-jogada.md`](apresentacao-jogada.md)). Ele conta só três coisas:
**quem é N-7, em que mundo ele vive e o que dá início à sua jornada**. Não mostra mecânicas
em detalhe nem o final da história. Issue: [#6](https://github.com/GabNader/codigo-genesis-n7/issues/6).

| Item | Definição |
|---|---|
| Duração | 45 a 55 s |
| Formato | 16:9, 1920×1080, 24 fps |
| Ferramenta | Google Flow (ou Runway, Kling, Luma: mesmo fluxo de prompt + imagem de referência) |
| Edição | DaVinci Resolve ou CapCut |
| Fonte dos textos | `assets/PixelOperator.ttf` (a mesma da HUD), ciano `#00E6E6` |

---

## 1. A história em uma frase

> **Num domo em colapso, o último robô desperta carregando só a lógica humana e precisa
> resgatar a Natureza e a Arte antes que sua energia acabe.**

- **Protagonista:** N-7, um pequeno robô utilitário.
- **O que aconteceu:** a humanidade se foi, e o Domo Esperança está desmoronando.
- **O que ele precisa fazer:** reunir os três núcleos (Lógica, Natureza e Arte) gastando
  com cuidado uma energia que não volta sozinha.

Se uma cena não ajudar a contar esta frase, ela sai do trailer.

## 2. O que levar de cada referência

| Referência | O que a professora pediu para observar | Como aplicamos |
|---|---|---|
| Hollow Knight | Cenários e criaturas apresentam o reino e criam curiosidade sobre o que aconteceu | Cena 1 só mostra o domo, sem explicar: ruínas, natureza crescendo por cima do metal e nenhum humano |
| Ori and the Blind Forest | O mundo ameaçado estabelece o conflito; a música conduz a emoção | Cena 3: o domo treme e o alarme soa. A trilha só entra depois do despertar, e cresce até o título |
| Dead Cells | Uma mecânica vira sequência de ação e humor | Cena 4 transforma a mecânica central (escanear antes de andar, pesar o custo) numa decisão visível, com um respiro de humor no "susto" do N-7 |
| Cuphead: The Delicious Last Course | A nova aventura preserva o estilo visual do jogo | O N-7 do Flow segue o sprite do jogo, e os textos usam a fonte e as cores da HUD |

## 3. Personagem e estilo (repetir em todo prompt)

Use **sempre** [`referencias/n7-frente.png`](referencias/n7-frente.png) como imagem de
referência ("ingredient" ou quadro inicial) e cole estes blocos no começo de cada prompt.
Não mude cores nem acessórios entre as cenas.

**Personagem**
> N-7, a small boxy utility robot: yellow-ochre cube-shaped head and body, a dark screen-face
> with two round glowing cyan eyes, a black camera lens on the right side of the head, two
> black rubber tank treads with yellow wheel hubs. Cute, modular, not militaristic. Same design
> as the reference image.

**Estilo**
> Cinematic cyber-decay world: rusted industrial metal, exposed cables, vegetation reclaiming
> the structure, cyan and magenta neon accents, volumetric light through dust, melancholic
> quiet mood, film grain, 24fps, no text, no logos.

Para manter a paleta, use também [`referencias/gameplay-mapa.jpg`](referencias/gameplay-mapa.jpg)
como referência de cor nas cenas 1 e 5. Não use nomes de personagens ou filmes com direitos
autorais nos prompts.

## 4. Storyboard: 5 cenas, uma ação por plano

Cada plano tem **uma ação clara** e 3 a 6 s. Gere e aprove um plano por vez antes de passar
ao próximo. O som de cada plano está na coluna "Som que conta a história".

### Cena 1 — O mundo (0–10 s)

| Plano | Ação | Som que conta a história | Texto |
|---|---|---|---|
| 1A | A câmera desce devagar pelo interior do domo em ruínas | vento atravessando vidro quebrado: lugar vazio há muito tempo | *"Domo Esperança."* |
| 1B | Uma gota cai de uma raiz metálica numa poça | gotas e água corrente: a natureza está tomando o lugar | *"Trezentos anos depois da Queda."* |

> **1A** — Wide shot inside a colossal ruined dome with cracked hexagonal glass panels, dead
> industrial towers covered by vines and metallic roots, dust in pale light shafts. Slow crane
> shot descending. No characters.
>
> **1B** — Macro shot: a single water drop falls from a metallic root into a dark puddle that
> reflects a flickering cyan neon sign. Static camera.

### Cena 2 — O personagem (10–20 s)

| Plano | Ação | Som que conta a história | Texto |
|---|---|---|---|
| 2A | Os olhos ciano do N-7 acendem no escuro | bip de inicialização (o `beep` do jogo) | — |
| 2B | N-7 levanta a cabeça e olha ao redor | servos rangendo, poeira caindo | — |
| 2C | As esteiras giram pela primeira vez | o som de esteira do jogo, lento: alguém está "chegando" ao mundo | *"N-7. O último guardião da lógica humana."* |

> **2A** — Extreme close-up in darkness: N-7's dark screen-face flickers and two round cyan
> eyes light up. Static camera. *(com `n7-frente.png`)*
>
> **2B** — Medium shot: N-7 slowly raises its head and looks left, dust falling off its yellow
> body. Static camera. *(com `n7-frente.png`)*
>
> **2C** — Low angle close-up of N-7's black tank treads starting to turn on a rusted metal
> floor, kicking up dust. Slow tracking shot. *(com `n7-frente.png`)*

### Cena 3 — O acontecimento que muda tudo (20–30 s)

| Plano | Ação | Som que conta a história | Texto |
|---|---|---|---|
| 3A | Uma viga gigante desaba ao fundo e o domo treme | estrondo seguido do **alarme** do jogo: N-7 percebe o perigo | — |
| 3B | O visor do N-7 mostra o diagnóstico | bips do visor | *"LÓGICA: ATIVA. NATUREZA: AUSENTE. ARTE: AUSENTE."* |

> **3A** — Wide shot: in the background a huge steel beam collapses inside the dome, dust
> cloud rising; in the foreground N-7 turns toward the noise, its cyan eyes flashing red.
> *(com `n7-frente.png`)*
>
> **3B** — Close-up of N-7's screen-face showing three small icons: a blue circle lit, a
> green leaf dark, a purple diamond dark. Static camera. *(com `n7-frente.png`)*
>
> O 3B pode ser feito na edição: sobreponha os três ícones do Protocolo Trino da HUD
> (azul aceso, verde e roxo apagados) sobre o rosto do N-7.

### Cena 4 — A primeira decisão (30–42 s)

| Plano | Ação | Som que conta a história | Texto |
|---|---|---|---|
| 4A | N-7 chega a uma bifurcação: um corredor curto e um longo | chiado de vapor no corredor curto: há um obstáculo ali | — |
| 4B | N-7 emite o pulso do LiDAR | o sonar do jogo | — |
| 4C | O pulso revela um vazamento térmico brilhando no caminho curto | o chiado fica mais alto; N-7 recua um pouco (o respiro de humor) | *"Cada passo custa energia."* |
| 4D | N-7 vira e segue pelo caminho longo | esteira, ritmo firme | *"Cada escolha pesa."* |

> **4A** — Medium wide shot: N-7 stops at a fork between a short corridor filled with hissing
> steam and a long dark corridor curving away. Static camera. *(com `n7-frente.png`)*
>
> **4B** — N-7 emits a circular cyan scanning pulse that expands outward across the floor and
> walls, revealing a hexagonal grid pattern. Static camera. *(com `n7-frente.png`)*
>
> **4C** — The cyan pulse reveals a glowing orange thermal leak on the floor of the short
> corridor; N-7 rolls back a little, startled. *(com `n7-frente.png`)*
>
> **4D** — N-7 turns and rolls into the long dark corridor, seen from behind. Slow tracking
> shot. *(com `n7-frente.png`)*

Esta é a decisão "Rota Alfa ou Rota Beta" do exemplo de gameplay do GDD (§17): o atalho
custa integridade, e o desvio custa bateria.

### Cena 5 — Título (42–52 s)

| Plano | Ação | Som que conta a história | Texto |
|---|---|---|---|
| 5A | Ao longe, a coluna de luz do Elevador Central acende no centro do domo | a trilha (`trilha.mp3`) chega ao ápice | — |
| 5B | Tela escura com o título | a trilha termina num acorde | **CÓDIGO GÊNESIS** · *O Legado de N-7* |

> **5A** — Extreme wide shot from behind N-7, small in the foreground: far away at the center
> of the dome a tall white column lights up with a golden beam rising into the darkness.
> Slow push-in. *(com `n7-frente.png` e `gameplay-trindade.jpg`)*

O trailer **não mostra** N-7 chegando ao Elevador, os núcleos sendo coletados nem nenhum
final: isso é a jornada, e é o jogo que conta.

## 5. Som e texto

**A trilha entra tarde.** Cenas 1 e 2 só com sons do mundo; a trilha começa baixa depois do
alarme (cena 3) e cresce até o título.

**Sons do próprio jogo que o trailer usa:**

| Som | Onde está | Uso |
|---|---|---|
| Bip / sonar | `assets/audio/beep.mp3` | 2A (inicialização) e 4B (LiDAR) |
| Esteira | `assets/audio/move.mp3` | 2C e 4D |
| Alarme de bateria | clipe `09_alarme.avi` (áudio) | 3A |
| Água e gotas | clipe `05_natureza.avi` (ambiência do setor eco) | 1B |
| Trilha | `assets/audio/trilha.mp3` | cena 3 em diante |

O Veo também pode gerar som junto com o vídeo. Use-o como base para estrondos e vapor, mas
prefira os sons do jogo onde houver: eles ligam o trailer ao jogo.

**Tempo de leitura dos textos:** cerca de 1 s a cada 3 palavras, com **mínimo de 2 s** na
tela, mais 0,3 s de fade de entrada e de saída. Nunca dois textos na mesma cena ao mesmo
tempo.

| Texto | Palavras | Tempo mínimo |
|---|---|---|
| Domo Esperança. | 2 | 2 s |
| Trezentos anos depois da Queda. | 5 | 2 s |
| N-7. O último guardião da lógica humana. | 7 | 2,5 s |
| LÓGICA: ATIVA. NATUREZA: AUSENTE. ARTE: AUSENTE. | 6 | 3 s (é lista: dê mais tempo) |
| Cada passo custa energia. | 4 | 2 s |
| Cada escolha pesa. | 3 | 2 s |
| CÓDIGO GÊNESIS · O Legado de N-7 | 6 | 4 s |

## 6. Produção, uma cena por vez

1. Gere os planos da **cena 2** primeiro: se o N-7 não ficar consistente, nada mais funciona.
2. Para cada plano: gere uma imagem parada com a referência, aprove, e só então anime.
3. Se o robô mudar de design, reforce "same design as the reference image" e reduza o
   movimento de câmera.
4. Monte na ordem 1 → 5 e ajuste o áudio por último.
5. Planos, créditos e limites do Flow mudam com frequência: confira a conta antes de começar.
   Cada geração consome créditos.

## 7. Teste com quem não conhece o jogo

Exiba o trailer **uma vez**, sem explicar nada, e pergunte:

> **"Quem é o personagem, o que aconteceu e o que ele vai fazer agora?"**

| Parte da resposta | Resposta esperada | Se ficar confusa, revise |
|---|---|---|
| Quem é o personagem | um robô pequeno, o último que restou | Cena 2 |
| O que aconteceu | o lugar está abandonado e começou a desmoronar | Cenas 1 e 3 |
| O que ele vai fazer agora | procurar algo que falta (natureza e arte) com pouca energia, escolhendo o caminho com cuidado | Cenas 3 e 4 |

Teste com pelo menos 3 pessoas e anote as palavras delas:

| Data | Pessoa | Quem | O que aconteceu | O que vai fazer | Cena a revisar |
|---|---|---|---|---|---|
| | T1 | | | | |
| | T2 | | | | |
| | T3 | | | | |

## 8. Créditos e licenças

**Créditos (tela final, 4 s)**
> Código Gênesis: O Legado de N-7 — PAC Extensionista III, Engenharia de Software.
> Gabriel Nader Marini, Izadora de Souza, Larissa dos Santos, Letícia de Abreu.
> Cenas geradas com IA (Google Flow).

**Antes de publicar, confirmem:**
- [ ] A origem e a licença de `trilha.mp3`, `beep.mp3` e `move.mp3`: se forem de terceiros,
      a licença precisa permitir uso em vídeo público (PGCS §13).
- [ ] Os termos de uso do Flow no plano da conta. Os vídeos do Veo podem levar marca d'água
      (visível em alguns planos e o SynthID invisível).
- [ ] O teste do §7 com pelo menos 3 pessoas.
- [ ] A aprovação da professora e da equipe.
