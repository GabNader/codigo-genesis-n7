# Apresentação jogada — clipes de gameplay

Vídeo **separado do trailer** ([`roteiro.md`](roteiro.md)). Aqui o objetivo é o oposto: mostrar
como o jogo funciona e onde está a matemática, com gameplay real.

Os clipes são gravados pelo próprio Godot (Movie Maker) com o script
[`tools/trailer/gravar_clipes.gd`](../../tools/trailer/gravar_clipes.gd), em 1920×1080 a 30 fps,
semente 21. Os `.avi` (35–110 MB cada) **ficam fora do repositório**, na pasta
`codigo-genesis-trailer/clipes` da área de trabalho de quem gravou.

## Ordem sugerida e o que narrar

| # | Clipe | Duração | O que narrar |
|---|---|---|---|
| 1 | `01_despertar.avi` | 9,6 s | O primeiro turno é o tutorial: o despertar do N-7 apresenta a missão |
| 2 | `02_lidar.avi` | 5 s | Os sensores só veem os vizinhos; o LiDAR custa 5% e revela o raio 3 |
| 3 | `03_rota.avi` | 8 s | A rota mostra o custo antes de confirmar: `1.5 × (1 + carga ÷ 15)` por hexágono |
| 4 | `04_subestacao.avi` | 8 s | Probabilidade sem quiz: estabilidade, valor esperado, risco × garantido |
| 5 | `05_natureza.avi` | 14 s | Acoplar o núcleo na mochila (formato fixo) dobra o custo de cada passo |
| 6 | `09_alarme.avi` | 5 s | O alarme e a barra piscando avisam a bateria baixa; a trilha fica abafada |
| 7 | `06_arte.avi` | 16 s | A história contada na exploração: a *Ode à Alegria* recuperada no Cofre |
| 8 | `07_trindade.avi` | 16 s | A resposta à Trindade completa e o caminho até o Elevador |
| 9 | `08_final.avi` | 9 s | Um dos 5 finais: Gênesis, com o relatório da partida |

## Regravar os clipes

1. Crie um `override.cfg` na raiz do projeto para gravar em 1080p (ele está no `.gitignore`):
   ```ini
   [display]

   window/size/viewport_width=1920
   window/size/viewport_height=1080
   ```
2. Grave um clipe por vez (troque `rota` pelo nome do clipe: `despertar`, `lidar`, `rota`,
   `subestacao`, `natureza`, `arte`, `trindade`, `final`, `alarme`):
   ```bash
   godot --path . --write-movie ../codigo-genesis-trailer/clipes/03_rota.avi --fixed-fps 30 -s res://tools/trailer/gravar_clipes.gd -- rota
   ```
3. Apague o `override.cfg`.

Os clipes saem com o áudio do jogo. O áudio do `09_alarme` e a ambiência de água do
`05_natureza` também são usados no trailer (ver §5 do roteiro).
