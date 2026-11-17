# Passagem de turno

**Atualizado em:** 17/11/2026, por Claude Code
**Continuar a partir de:** branch `claude/gracious-fermi-cc5vee`
**Teste automático:** 0 falhas (com e sem tela)

## Estado atual

As quatro etapas do plano estão implementadas numa primeira versão jogável:

1. Núcleo: andar, relógio, ferramentas, lavoura, venda, mochila e salvamento.
2. Mundo: estações, clima, vila, 7 lojas, 10 aldeões com rotina, amizade e presentes.
3. Profundidade: animais, construções, fabricação, máquinas, cozinha, pesca, mina com
   combate, habilidades, melhoria de ferramentas, mural de pedidos e festivais.
4. Fim de jogo: namoro, casamento, cônjuge, ampliação da casa, coleções do salão, estufa
   e conquistas.

Rodada de melhorias (pedido "vamos melhorar tudo", prioridades do Junior: artes, som,
jogabilidade): pixel art gerada por código, aldeões com paleta própria, efeitos e músicas
sintetizados, objetivos do 1º dia, cursor de alvo, árvores frutíferas, sementes de árvore,
cenas de amizade (3 e 6 corações), mapa (M) e boia na pesca.

O LEIA-ME.md descreve tudo e os controles.

## Trabalho em andamento

Nenhum. Tudo está commitado.

## Próximos passos sugeridos

1. Junior testar jogando no próprio computador e listar o que quer mudar
   (especialmente ouvir as músicas e efeitos: foram conferidos só por medição, não de ouvido).
2. Exportar executável Windows (criar `export_presets.cfg` e um workflow de Release).
3. Mais cenas de amizade (8 e 10 corações), filhos depois do casamento.
4. Balanceamento: preços, tempo de crescimento, dificuldade da mina e da pesca.
5. Multijogador (não começado).

## Observações

- A Godot 4.4.1 roda no ambiente de nuvem do Claude (baixada para a pasta temporária);
  prints com `xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 res://ferramentas/teste_auto.tscn`.
- O branch `experimento/godot` do repositório `Junior` (After Rain) foi a origem das artes.
