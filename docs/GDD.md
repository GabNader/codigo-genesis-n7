# GDD v2.0 — Código Gênesis: O Legado de N-7

Documento de design **vigente** do jogo. Ele expande o GDD v1.0
([`GDD_Codigo_Genesis_N7_v1.pdf`](GDD_Codigo_Genesis_N7_v1.pdf), entregue em 11/09/2026)
com tudo o que foi preciso decidir para completar o jogo, e resolve as inconsistências
do v1. Seções do v1 que não aparecem aqui (High Concept, Pilares, Narrativa, Direção de
Arte, Tema Sério) continuam valendo como estão no PDF.

| Data | Versão | Descrição | Autor |
|---|---|---|---|
| 11/09/2026 | 1.0 | GDD do PAC Extensionista III (PDF) | Gabriel Nader Marini, Izadora de Souza, Larissa dos Santos, Letícia de Abreu |
| 23/11/2026 | 2.0 | Regras completas, números finais, 5 finais definidos, eventos e Diretor de IA implementados ([issue #2](https://github.com/GabNader/codigo-genesis-n7/issues/2)) | Gabriel Nader Marini |
| 23/11/2026 | 2.1 | Feedback da professora: primeiro turno guiado, custos gerados dos efeitos, história na exploração, áudio sintetizado, resposta à Trindade ([issue #4](https://github.com/GabNader/codigo-genesis-n7/issues/4)) | Gabriel Nader Marini |

---

## 1. O que mudou em relação ao v1

| Tema | GDD v1 | GDD v2 (implementado) | Por quê |
|---|---|---|---|
| Fórmula de custo | Três versões: `Distância × (1 + Mod. Peso)` (§5), `Distância × Peso` (§18) e 1%→2% por hex (§17) | **Custo por hex = 1,5 × (1 + Carga ÷ 15)** | Unifica as três. Linear de propósito: o jogador consegue prever o gasto exato de cabeça (Pilar 3). Cada núcleo (15 kg) soma +1,0 ao modificador, que é o "dobro do custo" do exemplo da §17 |
| Peso "exponencial" | §1 e §8 falam em impacto exponencial | Linear por kg, em **patamares** de 15 kg | Coincide com o gráfico da §8 (patamares discretos) e mantém a matemática calculável sem quiz |
| Coordenadas do grid | Protótipo gerava o mapa em coordenadas axiais sobre um TileMap "stacked" (offset), o que distorcia distâncias | Grid **axial** (TileSet `DIAMOND_RIGHT`), raio 6 = 127 hexágonos | Distância hexagonal correta: `(|Δq| + |Δq+Δr| + |Δr|) ÷ 2` (Geometria Analítica, §2) |
| Biomas | Só a Zona Industrial era andável ("bloqueado nesta demo") | Os 4 biomas + Elevador Central, gerados por regiões de Voronoi | GDD §10 |
| Inventário | §6 descreve grade 20 slots "estilo Tetris"; §12 diz que o protótipo abandonou inventários complexos | **Mochila 5×4 (20 slots)** com peças de formato fixo, encaixadas com o mouse | É a mecânica que materializa o "fardo" da narrativa (§11) e o exemplo da §17 depende dela |
| 5 finais | Citados, mas o diagrama mostra só 3 + Game Over | **5 finais definidos** (seção 8 deste documento) | Faltava definição |
| Eventos de "inércia" | Esporos Corrosivos disparavam com "inércia > 2 turnos" | Esporos viraram evento de célula com escolha | Num jogo por turnos de ação não existe turno parado |
| Terminal Corrompido | Evento separado das subestações | Toda subestação é um "terminal corrompido" com **estabilidade visível** (50–90%) | Probabilidade explícita e comparação de valor esperado, sem quiz |
| Visibilidade | Névoa sobre tudo além dos vizinhos | Vizinhos saem da névoa; **estruturas físicas** são vistas sem LiDAR; ameaças invisíveis só com LiDAR | Anti-goal "aleatoriedade injusta": o jogador não deve perder para um muro que não viu |

## 2. Recursos e ações

| Recurso / ação | Valor |
|---|---|
| Bateria e Integridade iniciais | 100% / 100% |
| Custo por hexágono | `1,5 × (1 + Carga ÷ 15)` % de bateria |
| Alcance motor | até **4 hexágonos** por movimento confirmado (1 turno) |
| Pulso LiDAR | **5%** fixo, escaneia o **raio 3**; não encerra o turno |
| Pedágio do Elevador | 10% de bateria para ativar a Ascensão |

**Turno.** Cada movimento confirmado encerra um turno. O LiDAR pode ser usado antes de
mover. Não existe "passar a vez".

**Derrota.** Integridade 0, bateria 0, N-7 isolado pelo colapso, ou bateria insuficiente
para qualquer passo sem fonte de energia ao alcance (célula na mochila, subestação,
nódulo, evento ainda não aberto, ou o Elevador com bateria para o pedágio).

## 3. Movimentação e rota (GDD v1 §5, expandido)

1. O jogador clica num hexágono **visível**: o sistema traça a rota conhecida mais barata
   (A*), evitando perigos já escaneados.
2. Clicar num vizinho do fim da rota **estende a rota à mão** (é assim que se escolhe a
   "Rota Alfa" pelo vazamento, como na §17). Clicar num hexágono da rota corta a rota ali;
   clique direito limpa.
3. A prévia mostra o custo acumulado em cada hexágono, o total e o dano previsto. Se o
   total passar da bateria, a confirmação é **bloqueada** ("Reavalie o destino ou reduza a
   carga", fluxograma MOV-ALG-001).
4. O passo é cobrado com o terreno **real**. Se uma leitura estava errada, o jogador
   descobre ao entrar (uma fenda oculta interrompe a rota sem cobrar o passo).

## 4. Sensores e névoa de dados

| O que o N-7 sabe | Como |
|---|---|
| Hexágono atual e os 6 vizinhos saem da névoa | sensores passivos, a cada passo |
| Fenda, firewall, raízes, subestação, nódulo, Elevador | visíveis a olho nu quando vizinhos |
| Vazamento térmico, zona de interferência, pontos de interesse | **só com LiDAR** |
| Elevador Central | sempre visível (farol do domo) |

**Leituras instáveis (Probabilidade).** Hexágonos a até 1 de uma zona de interferência
são marcados como instáveis (contorno magenta) e têm **30%** de chance de mostrar um falso
vazamento ou de esconder um perigo real. Escanear de novo sorteia outra vez: o jogador
decide se vale pagar mais 5% para confirmar.

## 5. Terrenos

| Terreno | Biomas | Efeito |
|---|---|---|
| Fenda estrutural | todos (exceto Nódulos) | intransponível |
| Vazamento térmico | Industrial, Eco, Degradação | entrar: −20 Integridade |
| Zona de interferência EM | Industrial, Degradação | leituras do LiDAR ao redor erram 30% |
| Subestação | Industrial (1 garantida até 4 hex do início) | parar: sifonar energia (ver eventos) |
| Raízes preensoras | Eco | **sair** dela custa o triplo |
| Oásis vegetativo | Eco | parar: +30 Integridade (uma vez) |
| Firewall físico | Nódulos | entrar: −15% de bateria fixo |
| Nódulo puro | Nódulos (1 por mapa) | parar: Sobrecarga Total |
| Bolsão de gás | Degradação | entrar num hexágono **não escaneado**: 20% de chance de −20 Integridade |

O mapa é sempre **solucionável**: o gerador refaz o mapa até existir caminho do início
até os dois núcleos e o Elevador.

## 6. Mochila (GDD v1 §6)

Grade 5×4 = 20 slots. Peças com formato fixo; núcleos **não giram** nem podem ser
descartados.

| Peça | Formato | Peso | Uso |
|---|---|---|---|
| Núcleo da Natureza | 3×2 | 15 kg | — |
| Núcleo da Arte | 2×3 | 15 kg | — |
| Dados da Queda | 2×1 (gira) | 10 kg | define o final Paraíso Perdido |
| Célula de bateria | 1×1 | 2 kg | +20% Bateria |
| Kit de reparo | 2×1 (gira) | 3 kg | +25 Integridade |

Usar ou descartar itens reduz a carga e, portanto, o custo de cada passo.

## 7. Eventos (GDD v1 §16): todos os 25 implementados

**Eventos de célula** aparecem como "?" depois do LiDAR e disparam ao **parar** no hexágono.

| Pool | Evento | Efeito |
|---|---|---|
| Global | Pilar de Sal | −10 Integridade |
| Global | Maná Sintético | +25% Bateria |
| Industrial | O Fruto de Silício | Baixar Dados da Queda (peça 10 kg, −15 Integridade) ou abster-se |
| Industrial | Sucata Magnética | +5 kg por 3 turnos **ou** −8% Bateria para desmagnetizar |
| Industrial | Autômato Caído | −10%: revela raio 5 **ou** −10%: kit de reparo |
| Industrial | Terminal Corrompido | incorporado às subestações (abaixo) |
| Eco | Esporos Corrosivos | −5 Integridade/turno por 3 turnos **ou** −10% para queimar |
| Eco | Estufa Intacta | célula de bateria |
| Degradação | Chuva Ácida | +2 de dano por passo por 5 turnos (também 20% de chance no início da partida) |
| Degradação | Cápsula de Manutenção | kit de reparo |
| Nódulos | Sentinela Defeituosa | 70%: +30% Bateria / 30%: −25 Integridade |
| Nódulos | Célula de Reserva | célula de bateria |

**Pontos fixos**

| Ponto | Opções |
|---|---|
| O Jardim Suspenso (Natureza) | Extrair: peça 3×2, −30% Bateria (exige 30%) |
| O Cofre das Memórias (Arte) | Extrair: peça 2×3, −25 Integridade |
| Subestação (estabilidade *p*) | Sifonar ao máximo: *p* → +35% / 1−*p* → −20 Integridade; **seguro**: +12% garantido. A tela mostra o ganho esperado `p × 35` |
| Sobrecarga Total (nódulo) | +100% Bateria e −40 Integridade, **ou** +20% controlado |
| Compartimento selado | célula de bateria ou kit de reparo |

**Eventos do terreno e do Diretor**: Fenda Estrutural, Vazamento Térmico, Raízes,
Oásis, Firewall, Bolsão de Gás, Falsa Topografia (LiDAR em setor eco: 35% de chance de
esconder fendas e vazamentos eco), Névoa Oxidadora (2º LiDAR no mesmo turno em
Degradação: raio 1), Frequência Harmônica (entrar nos Nódulos com mais de 15 kg:
modificador de peso ÷2 por 3 turnos, uma vez), Tempestade EM, Curto em Cadeia, Miragem
de Dados e Colapso de Setor.

## 8. Diretor de IA (GDD v1 §16)

Máquina de estados avaliada no fim de **cada turno**:
`IDLE → AVALIAÇÃO → (HOSTIL | PADRÃO) → ATUALIZAÇÃO → IDLE`.

- **Limiar do quadrante** = 45% + 5% × distância até o Elevador (75% no início, 55% nos Nódulos).
- **HOSTIL** (bateria ≥ limiar): transforma até 2 hexágonos **ainda não escaneados**, a 2–4
  de distância, em fenda, vazamento ou interferência (raízes ou fenda no setor eco). Nunca
  altera o que o jogador já viu e desfaz qualquer mudança que isolaria um objetivo.
- **Tempestade EM**: bateria < 20% → LiDAR instável em todo o mapa por 3 turnos (recarga de 8 turnos).
- **Curto em Cadeia**: bateria > 80% → até 3 pisos escaneados próximos eletrificados por 1 turno (+15% para entrar).
- **Miragem de Dados**: integridade < 30% → uma subestação falsa aparece (uma vez por partida).
- **Colapso de Setor**: a partir do turno 15, o anel externo desmorona e, a cada 4 turnos,
  o próximo, até o anel 3. Há aviso um turno antes. Núcleos nos anéis perdidos se perdem.

Tudo o que o Diretor faz aparece no **Terminal Logs**, em magenta.

## 9. Os 5 finais (GDD v1 §8 e §11)

Definidos pelo que N-7 leva ao Elevador. O Game Over não é um final: é o colapso do protocolo.

| Final | Condição | Tom |
|---|---|---|
| **Gênesis** | Lógica + Natureza + Arte | verdadeiro |
| **Paraíso Perdido** | Trindade completa + Dados da Queda na mochila | ambíguo: o conhecimento da Queda sobrevive junto |
| **Éden Silencioso** | Lógica + Natureza | médio: vida sem arte |
| **Museu de Cristal** | Lógica + Arte | médio: arte sem vida |
| **Civilização Estéril** | só Lógica | ruim |

O "Fruto de Silício" (§16 do v1) ganha consequência narrativa: carregar os Dados da Queda
custa 10 kg em toda a travessia e muda o desfecho, reforçando o simbolismo da §11.

## 10. Interface (GDD v1 §12)

- **Painel de sistemas**: bateria, integridade, carga, **a fórmula de custo com os números
  atuais** (ex.: `1,5 × (1 + 15/15) = 3,0%`), estados ativos, Protocolo Trino e distância ao Elevador.
- **Terminal Logs**: cada cálculo, sorteio (com a probabilidade) e ação do Diretor.
- **Prévia de rota** e **tooltip** do hexágono sob o mouse.
- Controles só com mouse; Esc abre a pausa.

## 11. Áudio (GDD v1 §15): status atualizado

| Som | Status |
|---|---|
| Trilha ambiente (trilha.mp3) | implementado |
| Trilha dinâmica com filtro passa-baixa abaixo de 15% de bateria | **implementado** (barramento "Musica") |
| Pulso de sonar do LiDAR (beep.mp3) | implementado |
| Servomotores mais graves com a carga (move.mp3) | **implementado**: `pitch = 1 − carga ÷ 90` (mín. 0,55) |
| Bip de erro crítico (dano, rota bloqueada) | **implementado** (sonar em tom grave) |

## 12. Balanceamento

Um piloto automático (`tests/support/autopilot.gd`) joga partidas completas só com a API
pública. Ele anda só por hexágonos revelados e **não procura subestações de propósito**.
Resultado em 100 sementes (0–99):

| Desfecho | Partidas |
|---|---|
| Gênesis | 51 |
| Éden Silencioso | 5 |
| Museu de Cristal | 5 |
| Game Over por falta de energia | 38 |
| Game Over por integridade | 1 |

Todas as 100 partidas terminam (nenhum soft-lock). Um jogador que planeja o sifonamento
e a ordem de coleta deve vencer com mais frequência, que é o efeito pretendido pelo Pilar 3.

## 13. v2.1 — Resposta ao feedback da professora

| Feedback | Como o jogo responde |
|---|---|
| Começar pelo primeiro turno, com o despertar como guia | **Tutorial no 1º turno**: visor de despertar (Domo em colapso, Lógica ativa, missão) → botão do LiDAR pulsando → hexágono vizinho destacado → dica com o custo da rota e a conta `1.5 × (1 + carga ÷ 15)` antes de confirmar → objetivo. Cada etapa avança com a ação real do jogador. Pode ser pulado e ligado de novo no menu |
| "A Natureza anunciava 30 e descontou 45" | O desconto do protótipo somava a carga ao custo da extração. Na v2 a extração desconta um valor fixo, e na v2.1 **o texto de custo de todo botão é gerado a partir dos efeitos** (`EventDB.option_text`): o número lido é, por construção, o número aplicado. Testes cobrem a extração com carga na mochila e a prévia da rota contra o gasto real |
| Contar mais da história na exploração | Trecho no visor na **primeira chegada a cada bioma**; **memórias recuperadas** ao extrair os núcleos: no Cofre, um arquivo da *Ode à Alegria* (Beethoven, 1824, domínio público) tocado no sintetizador; no Jardim, o canto de um sabiá-laranjeira. Mais textos nos eventos (o Autômato Caído "aguardando N-7", o bilhete na Cápsula) |
| Aviso próprio de bateria baixa | Alarme de dois tons ao cruzar 15% e 5%, barra de bateria piscando e trilha abafada |
| Esteira conforme a carga | Tom mais grave **e** passo mais lento: `duração = 0,3 s × (1 + carga ÷ 60)` |
| Sons do cenário | Ambiência sintetizada por bioma com crossfade: **zumbido elétrico** (Industrial), **água** com gotas (Eco, estufas rompidas), **vento** químico (Degradação), drone harmônico (Nódulos) |
| Resposta ao reunir os três núcleos | Visor "PROTOCOLO TRINO COMPLETO", arpejo Dó–Mi–Sol–Dó e uma **linha dourada animada** do N-7 até o Elevador |
| Testar com quem nunca leu o guia | Roteiro de observação e as três perguntas em [`teste-de-usabilidade.md`](teste-de-usabilidade.md). **Depende da equipe aplicar** |

## 14. Fora do escopo desta versão

- Arte isométrica final e animação dedicada de acoplamento (hoje: alerta, som e mochila).
- Atualização das seções 4.3 e 5.3 do PGCS para refletir a estrutura de pastas e os
  testes automatizados (o repositório já segue a estrutura proposta em 4.3).
