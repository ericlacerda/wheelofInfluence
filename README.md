# Jogo de Estratégia

Este é um jogo de estratégia baseado em turnos desenvolvido com Godot Engine 4.4.

## Descrição

Neste jogo, os jogadores competem para conquistar regiões distribuindo unidades estrategicamente. Cada unidade é representada por uma carta com uma imagem única, além de valores de ataque e defesa. Quando duas unidades ocupam a mesma região, ocorre uma batalha onde o atacante vence se seu valor de ataque for maior que a defesa do defensor.

## Como Jogar

1. O jogo começa com 10 regiões dispostas em um círculo, cada uma com 3 unidades aleatórias.
2. Em seu turno, clique em uma região para selecionar unidades para distribuir.
3. No painel de distribuição, clique nas cartas de unidades que deseja distribuir (a ordem de seleção é importante).
4. As unidades serão distribuídas no sentido anti-horário, uma região por unidade.
5. Quando duas unidades ocupam a mesma região, ocorre uma batalha:
   - Se o ataque do atacante for maior que a defesa do defensor, o atacante vence.
   - Caso contrário, ambas as unidades permanecem na região.
6. O jogador ganha um ponto por cada batalha vencida.
7. O jogo continua até que um jogador alcance a pontuação desejada.

## Cartas de Unidades

- Cada unidade é representada por uma carta visual.
- As cartas exibem:
  - Uma imagem única da unidade (64x64 pixels)
  - Um valor de ataque (vermelho)
  - Um valor de defesa (azul)
- A borda da carta é colorida de acordo com o jogador:
  - Azul para o Jogador 1
  - Vermelho para o Jogador 2
- Quando selecionada, a carta tem um destaque amarelo e mostra a ordem de seleção.

## Estratégias

- Escolha cuidadosamente quais unidades distribuir e em qual ordem.
- Unidades com alto ataque são boas para conquistar regiões.
- Unidades com alta defesa são boas para proteger suas regiões.
- Lembre-se que a ordem de seleção das unidades determina em quais regiões elas serão colocadas.

## Requisitos Técnicos

- Godot Engine 4.4
- Resolução mínima recomendada: 1024x600
