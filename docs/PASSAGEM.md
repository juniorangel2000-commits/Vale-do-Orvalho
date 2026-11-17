# Passagem de turno

**Atualizado em:** 17/11/2026, por Claude Code
**Continuar a partir de:** branch `claude/gracious-fermi-cc5vee`
**Teste automático:** 32 verificações, 0 falhas (com e sem tela)

## Estado atual

As quatro etapas do plano estão implementadas numa primeira versão jogável:

1. Núcleo: andar, relógio, ferramentas, lavoura, venda, mochila e salvamento.
2. Mundo: estações, clima, vila, 7 lojas, 10 aldeões com rotina, amizade e presentes.
3. Profundidade: animais, construções, fabricação, máquinas, cozinha, pesca, mina com
   combate, habilidades, melhoria de ferramentas, mural de pedidos e festivais.
4. Fim de jogo: namoro, casamento, cônjuge, ampliação da casa, coleções do salão, estufa
   e conquistas.

O LEIA-ME.md descreve tudo e os controles.

## Trabalho em andamento

Nenhum. Tudo está commitado.

## Próximos passos sugeridos

1. Junior testar jogando no próprio computador e listar o que quer mudar.
2. Artes de verdade para plantas, itens, máquinas, animais, monstros e aldeões (hoje são
   desenhos por código em `scripts/desenho.gd`; aldeões usam o corpo da personagem tingido).
3. Música e efeitos sonoros.
4. Exportar executável Windows (criar `export_presets.cfg` e um workflow de Release).
5. Balanceamento: preços, tempo de crescimento, dificuldade da mina e da pesca.
6. Multijogador (não começado).

## Observações

- A Godot 4.4.1 roda no ambiente de nuvem do Claude (baixada para a pasta temporária);
  prints com `xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 res://ferramentas/teste_auto.tscn`.
- O branch `experimento/godot` do repositório `Junior` (After Rain) foi a origem das artes.
