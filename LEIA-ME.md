# Vale do Orvalho

Jogo de fazenda e vida no campo feito na **Godot 4.4**. Você herda a fazenda do avô num vale
pequeno, limpa o terreno, planta, cria animais, pesca, desce na mina e faz amizade (e talvez
família) com quem mora ali.

## Abrir e jogar

1. Baixe a **Godot 4.4** (versão "Standard", não a ".NET"): https://godotengine.org/download
2. Na Godot, clique em **Importar**, escolha o arquivo `project.godot` desta pasta e depois
   **Importar e editar**. Na primeira vez ela prepara as imagens.
3. Aperte **F5** (ou o ▶ no canto de cima) para jogar.

## Controles

| Tecla | O que faz |
|---|---|
| WASD ou setas | andar |
| Clique esquerdo ou Espaço | usar o item da mão (ferramenta, semente, colocar objeto) |
| Clique direito ou F | interagir: falar, dar presente, colher, abrir baú, usar máquina, entrar em loja |
| 1 a 0, `-`, `=` ou roda do mouse | escolher o item da barra |
| E | mochila (com abas de fabricação, habilidades, amizades e conquistas) |
| Q | comer o item da mão |
| J | mural de pedidos |
| K | amizades |
| Esc | menu e fechar janelas |

## O que já existe

**Etapa 1 — núcleo**
- Fazenda, casa, caixa de venda (vende à noite), poço
- Relógio (6h às 2h), dias, dormir, desmaiar de cansaço ou de madrugada
- Ferramentas: enxada, regador, machado, picareta, foice, vara de pesca e espada
- Arar, plantar, regar, crescer, colher; 15 culturas, algumas voltam a dar
- Mochila de 36 espaços, barra de 12, salvamento automático ao dormir

**Etapa 2 — o mundo**
- 4 estações de 28 dias, clima (sol, chuva, neve) e previsão do tempo
- Mapas: fazenda, vila, bosque do rio, montanha, casa, estufa, galinheiro/estábulo e mina
- 7 lojas com horário e dia de folga: armazém, forja, carpintaria, rancho, pescaria, taverna e guilda
- 10 aldeões com rotina diária, falas por estação e por amizade, aniversários,
  presentes (ama, gosta e odeia) e corações de amizade

**Etapa 3 — profundidade**
- Galinheiro, estábulo e silo construídos na fazenda; galinha, pato, vaca, cabra e ovelha
- Feno (foice + silo), cocho, carinho, ovos, leite e lã
- Fabricação de 21 receitas liberadas pelos níveis de habilidade
- Máquinas: barril, pote de conserva, fornalha, forno de carvão, prensa de queijo,
  batedeira de maionese, tear e caixa de abelhas
- Cozinha com 9 receitas (compradas na taverna)
- Pesca com minijogo, 10 peixes por lugar, estação, hora e clima
- Mina com 40 andares, minérios, gemas, monstros, combate, escadas e elevador a cada 5 andares
- 5 habilidades com níveis de 0 a 10
- Melhoria de ferramentas (cobre, ferro, ouro) na forja
- Mural de pedidos dos aldeões e 4 festivais (flores, luau, feira da colheita e lanternas)

**Etapa 4 — fim de jogo**
- Namoro (buquê aos 8 corações), casamento (Anel do Orvalho aos 10 corações e casa ampliada)
- Cônjuge morando na fazenda e ajudando (rega, cuida dos animais, faz café da manhã)
- Ampliações da casa, do galinheiro e do estábulo
- Salão da Vila com 6 coleções; completar todas reforma a estufa (planta em qualquer estação)
- 15 conquistas

## Ainda provisório

- Plantas, itens, máquinas, animais e monstros são desenhados por código (formas simples).
  Os aldeões usam o corpo da personagem com outra cor. Tudo pode ser trocado por artes de verdade.
- Ainda sem música e sem efeitos sonoros.
- Sem multijogador.

## Teste automático

`ferramentas/teste_auto.tscn` começa uma partida e passa por todos os sistemas (andar,
portas, lavoura, venda, lojas, aldeões, animais, máquinas, mina, pesca, casamento,
salvar e carregar). Na Godot, abra a cena e aperte **F6**. Pela linha de comando:

```
godot --headless --path . res://ferramentas/teste_auto.tscn
```

Com tela, o teste também salva prints em `ferramentas/prints/`.

## Organização

- `scripts/dados.gd`: tudo que é fixo (itens, culturas, receitas, aldeões, lojas, peixes...)
- `scripts/jogo.gd`: estado da partida, passagem de dia e salvamento
- `scripts/principal.gd`: troca de mapas, controles, câmera, luz, aldeões, mina
- `scripts/geradores.gd`: monta cada mapa
- `scripts/acoes.gd`: o que acontece ao usar e interagir
- `scripts/ui.gd` e `scripts/hud.gd`: menus e interface
- `scripts/desenho.gd`: desenhos provisórios feitos por código
- `arte/`: artes copiadas do After Rain (terreno, objetos e personagem)
