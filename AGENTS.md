# Regras para agentes de IA — Vale do Orvalho

Projeto feito em **revezamento entre Claude Code e Codex**. Nenhum dos dois vê a conversa
do outro: o que não estiver no GitHub e em `docs/PASSAGEM.md` não existe para quem assume.

## Como o Junior pede as coisas

- **Só a tarefa**: siga o protocolo de início, faça a tarefa e o encerramento.
- **"limite"**: encerramento de emergência na hora.
- **"onde paramos?"**: resuma `docs/PASSAGEM.md` sem alterar nada.

Sem ponto de partida informado, continue de onde `docs/PASSAGEM.md` indica.

## Protocolo de início

1. `git fetch --all` e vá para o branch indicado em `docs/PASSAGEM.md`.
2. Leia `docs/PASSAGEM.md` inteiro. Continue o trabalho em andamento; não desfaça o do outro
   agente sem motivo registrado.
3. Rode o teste automático antes de mexer (anote falhas que já existiam):
   `godot --headless --path . --import` e depois
   `godot --headless --path . res://ferramentas/teste_auto.tscn` (precisa terminar com
   `=== TESTE: 0 falha(s) ===`).
4. Tarefa grande ou ambígua: apresente o plano ao Junior antes.

## Durante o trabalho

- Godot 4.4, GDScript. Evite `:=` com valores sem tipo (dicionários, arrays, `get`): a Godot
  recusa ("Cannot infer the type"). Use `var x: int = ...` ou `var x = ...`.
- Commits pequenos, mensagens em português, push frequente. Nunca `push --force`.
- Textos do jogo e documentação em português do Brasil.
- Partidas salvas devem continuar abrindo: mudança no formato do save exige migração em
  `Jogo.migrar()` e aumento de `VERSAO_SAVE`.
- Sistema novo ganha verificação em `ferramentas/teste_auto.gd`.
- Não recrie jogos existentes (nomes, personagens, mapas ou artes de outro jogo): o conteúdo
  aqui é original.

## Encerramento (toda rodada, mesmo incompleta)

1. Rode o teste automático.
2. Commit e push. Trabalho incompleto vai com prefixo `WIP:`.
3. Reescreva `docs/PASSAGEM.md` seguindo o modelo do arquivo, commit e push.
4. Responda ao Junior com: branch, último commit, resultado do teste e próximo passo.
