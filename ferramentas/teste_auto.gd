extends Node
## Teste automático: começa uma partida, visita todos os mapas, usa ferramentas, planta,
## colhe, passa dias, salva e carrega. Tira prints em ferramentas/prints/ (se houver tela).
## Rodar: godot --path . res://ferramentas/teste_auto.tscn

var P: Node
var erros := 0
var prints := true

func _ready() -> void:
	prints = DisplayServer.get_name() != "headless"
	P = load("res://cenas/principal.tscn").instantiate()
	add_child(P)
	await _quadros(5)
	await _print("00_titulo")
	P.ui.call("_comecar", "Teste", "Teste")
	await _quadros(5)
	P.ui.call("fechar")
	await _quadros(35)
	_checar(P.hud._objetivo.visible, "objetivo do primeiro dia aparece")
	await _print("01_casa")
	_checar(P.mapa.nome == "casa", "começa em casa")
	# fazenda
	P.ir_para("fazenda", Vector2i(11, 9))
	await _quadros(5)
	await _print("02_fazenda")
	var m: Mapa = P.mapa
	_checar(m.w == 60, "fazenda tem 60 de largura")
	# andar com o teclado
	var x0: float = P.jogador.position.x
	Input.action_press("direita")
	await _quadros(30)
	Input.action_release("direita")
	_checar(P.jogador.position.x > x0 + 10, "anda com o teclado")
	P.jogador.position = m.centro(Vector2i(11, 8)) + Vector2(0, 12)
	Input.action_press("cima")
	await _quadros(40)
	Input.action_release("cima")
	_checar(P.mapa.nome == "casa", "entra em casa pela porta")
	Input.action_press("baixo")
	await _quadros(60)
	Input.action_release("baixo")
	_checar(P.mapa.nome == "fazenda", "sai de casa pela porta")
	# não atravessa a casa
	m = P.mapa
	P.jogador.position = m.centro(Vector2i(9, 9)) + Vector2(0, 12)
	Input.action_press("cima")
	await _quadros(40)
	Input.action_release("cima")
	_checar(P.jogador.position.y > 7 * 32, "parede da casa bloqueia")
	# arar, plantar, regar, crescer
	var c := Vector2i(12, 12)
	m.remover_objeto(c)
	Jogo.slot = _slot_de("enxada")
	Acoes.usar(P, m, c)
	_checar(not m.solo(c).is_empty(), "enxada ara")
	Jogo.slot = _slot_de("sem_alface")
	Acoes.usar(P, m, c)
	_checar(m.solo(c).has("cultura"), "semente plantada")
	Jogo.slot = _slot_de("regador")
	Acoes.usar(P, m, c)
	_checar(bool(m.solo(c).get("regado", false)), "regador molha")
	for i in 4:
		m.solo(c).regado = true
		Jogo.passar_dia("")
	P.ir_para("fazenda", Vector2i(11, 9))
	m = P.mapa
	await _quadros(3)
	_checar(int(m.solo(c).cultura.dias) >= 4, "alface cresceu")
	var antes := Jogo.contar("alface")
	Acoes.interagir(P, m, c)
	_checar(Jogo.contar("alface") == antes + 1, "colheu alface")
	# machado e picareta
	for k in m.est.objetos.keys():
		var o: Dictionary = m.est.objetos[k]
		if o.tipo == "arvore":
			Jogo.slot = _slot_de("machado")
			for i in 12:
				Acoes.usar(P, m, Jogo.celula(k))
			_checar(m.objeto(Jogo.celula(k)).get("tipo", "") == "toco", "árvore vira toco")
			break
	for k in m.est.objetos.keys():
		if m.est.objetos[k].tipo == "pedra":
			Jogo.slot = _slot_de("picareta")
			var p0 := Jogo.contar("pedra")
			Acoes.usar(P, m, Jogo.celula(k))
			_checar(Jogo.contar("pedra") > p0, "picareta quebra pedra")
			break
	# vender
	Jogo.slot = _slot_de("alface")
	var caixa := Vector2i(14, 8)
	Jogo.adicionar("alface", 3)
	Jogo.slot = _slot_de("alface")
	Acoes.interagir(P, m, caixa)
	var din := Jogo.dinheiro
	var rel := Jogo.passar_dia("")
	_checar(Jogo.dinheiro > din and int(rel.total) > 0, "caixa vende à noite")
	# mapas
	for nome in ["vila", "floresta", "montanha", "casa"]:
		P.ir_para(nome, Vector2i(5, 5))
		await _quadros(4)
		await _print("03_" + nome)
		_checar(P.mapa.nome == nome, "abre " + nome)
	# aldeões
	Jogo.minutos = 600
	P.ir_para("vila", Vector2i(24, 20))
	await _quadros(30)
	_checar(P.npcs.size() > 0, "há aldeões na vila de manhã")
	await _print("04_vila_aldeoes")
	var npc_id: String = P.npcs.keys()[0]
	P.conversar(npc_id)
	await _quadros(2)
	await _print("05_dialogo")
	P.ui.call("fechar")
	_checar(Jogo.amizade[npc_id] >= 20, "conversar dá amizade")
	# loja
	Jogo.minutos = 660
	P.ui.call("abrir_loja", "armazem")
	await _quadros(2)
	await _print("06_loja")
	P.ui.call("fechar")
	Jogo.dinheiro = 100000
	P.ui.call("_comprar", "sem_morango", 100, 1, "armazem", "comprar")
	P.ui.call("fechar")
	_checar(Jogo.contar("sem_morango") == 1, "comprar semente")
	P.ui.call("abrir_inventario", "mochila")
	await _quadros(2)
	await _print("07_mochila")
	P.ui.call("abrir_inventario", "fabricar")
	await _quadros(2)
	await _print("08_fabricar")
	P.ui.call("fechar")
	# construção e animais
	Jogo.adicionar("madeira", 999)
	Jogo.adicionar("pedra", 999)
	Jogo.construcoes.append({"id": Jogo.novo_id(), "tipo": "galinheiro", "x": 30, "y": 14, "nivel": 0, "cocho": 0})
	var casa_id: int = Jogo.construcoes[-1].id
	Jogo.animais.append({"id": Jogo.novo_id(), "tipo": "galinha", "nome": "Pipoca", "casa": casa_id, "amizade": 500, "dias": 0, "produto": "", "carinho": false})
	P.ir_para("fazenda", Vector2i(33, 18))
	await _quadros(3)
	await _print("09_galinheiro_fora")
	P.ir_para("interior_%d" % casa_id, Vector2i(6, 7))
	await _quadros(5)
	_checar(P.animais_nos.size() == 1, "galinha aparece no galinheiro")
	await _print("10_galinheiro")
	Jogo.construcao_por_id(casa_id).cocho = 4
	Jogo.passar_dia("")
	var ovos := 0
	for k in Jogo.estado_mapa("interior_%d" % casa_id).objetos:
		if Jogo.estado_mapa("interior_%d" % casa_id).objetos[k].get("item", "") in ["ovo", "ovo_grande"]:
			ovos += 1
	_checar(ovos >= 1, "galinha bota ovo")
	# máquina
	P.ir_para("fazenda", Vector2i(11, 9))
	m = P.mapa
	Jogo.adicionar("conserveiro", 1)
	Jogo.slot = _slot_de("conserveiro")
	var cm := Vector2i(16, 10)
	m.remover_objeto(cm)
	Acoes.usar(P, m, cm)
	_checar(m.objeto(cm).get("tipo", "") == "conserveiro", "colocar máquina")
	Jogo.adicionar("morango", 1)
	Jogo.slot = _slot_de("morango")
	Acoes.interagir(P, m, cm)
	_checar(m.objeto(cm).get("saida", "") == "geleia", "máquina processa")
	Jogo.minutos += 3100
	Acoes.interagir(P, m, cm)
	_checar(Jogo.contar("geleia") == 1, "pega geleia")
	# mina
	P.entrar_mina(1)
	await _quadros(5)
	await _print("11_mina")
	_checar(P.mapa.andar == 1 and P.monstros.size() > 0, "mina tem monstros")
	P.entrar_mina(25)
	await _quadros(5)
	await _print("12_mina_25")
	# pesca
	P.ir_para("floresta", Vector2i(20, 26))
	await _quadros(3)
	P.ui.call("pescar", "rio")
	await _quadros(5)
	await _print("13_pesca")
	for n in P.ui.get_children():
		if n.get("lugar") != null:
			n.set("fase", "lutando")
	await _quadros(5)
	await _print("14_pesca_luta")
	for n in P.ui.get_children():
		if n.get("lugar") != null:
			n.call("_terminar", true)
	await _quadros(2)
	_checar(int(Jogo.stats.get("peixes", 0)) + Jogo.contar("bota_velha") + Jogo.contar("alga") >= 1, "pesca pega algo")
	# salão, festival, relatório
	P.ui.call("abrir_colecoes")
	await _quadros(2)
	await _print("15_colecoes")
	P.ui.call("fechar")
	# noite e chuva
	Jogo.minutos = 1260
	Jogo.clima = "chuva"
	P.ir_para("fazenda", Vector2i(11, 9))
	await _quadros(30)
	await _print("16_noite_chuva")
	# casamento
	Jogo.amizade["lia"] = 2600
	Jogo.namorando["lia"] = true
	Jogo.nivel_casa = 1
	Jogo.adicionar("anel_orvalho", 1)
	Jogo.slot = _slot_de("anel_orvalho")
	P.presentear("lia")
	P.ui.call("fechar")
	_checar(not Jogo.noivado.is_empty(), "noivado com anel")
	for i in 3:
		Jogo.passar_dia("")
	_checar(Jogo.conjuge == "lia", "casamento acontece")
	# inverno: muda a estação
	Jogo.estacao = 3
	P.ir_para("fazenda", Vector2i(11, 9))
	Jogo.minutos = 700
	Jogo.clima = "neve"
	await _quadros(10)
	await _print("17_inverno")
	# dormir pela cama
	P.ir_para("casa", Vector2i(3, 5))
	await _quadros(3)
	var dia_antes := Jogo.dia
	Acoes.interagir(P, P.mapa, Vector2i(2, 3))
	await _quadros(2)
	for n in P.ui.find_children("*", "Button", true, false):
		if n.text == "Sim":
			n.pressed.emit()
			break
	await _quadros(2)
	await _print("18_relatorio")
	for i in 10:
		if P.ui.call("menu_aberto"):
			P.ui.call("fechar")
			await _quadros(1)
	_checar(Jogo.dia != dia_antes and not Jogo.pausado, "dormir passa o dia")
	# salvar e carregar
	Jogo.salvar()
	var dinheiro_salvo := Jogo.dinheiro
	var inv := Jogo.contar("madeira")
	_checar(Jogo.carregar(), "carregar save")
	_checar(Jogo.dinheiro == dinheiro_salvo and Jogo.contar("madeira") == inv, "save mantém dados")
	P.ir_para("fazenda", Vector2i(11, 9))
	await _quadros(3)
	# árvores
	Jogo.estacao = 0
	P.ir_para("fazenda", Vector2i(11, 9))
	await _quadros(2)
	m = P.mapa
	var ca := Vector2i(20, 14)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			m.remover_objeto(ca + Vector2i(dx, dy))
			m.remover_solo(ca + Vector2i(dx, dy))
	Jogo.adicionar("muda_pessegueiro", 1)
	Jogo.slot = _slot_de("muda_pessegueiro")
	Acoes.usar(P, m, ca)
	_checar(m.objeto(ca).get("tipo", "") == "frutifera", "plantar muda de pessegueiro")
	var cs := Vector2i(24, 14)
	m.remover_objeto(cs)
	m.remover_solo(cs)
	Jogo.adicionar("semente_arvore", 1)
	Jogo.slot = _slot_de("semente_arvore")
	Acoes.usar(P, m, cs)
	_checar(m.objeto(cs).get("tipo", "") == "muda", "plantar semente de árvore")
	Jogo.dia = 1
	for i in 29:
		Jogo.passar_dia("")
	Jogo.estacao = 0
	Jogo.passar_dia("")
	P.ir_para("fazenda", Vector2i(11, 9))
	m = P.mapa
	await _quadros(3)
	_checar(m.objeto(cs).get("tipo", "") == "arvore", "muda vira árvore")
	_checar(int(m.objeto(ca).get("frutos", 0)) >= 1, "pessegueiro dá frutos na primavera")
	var pes := Jogo.contar("pessego")
	Acoes.interagir(P, m, ca)
	_checar(Jogo.contar("pessego") > pes, "colher pêssegos")
	P.jogador.position = m.centro(ca + Vector2i(0, 2)) + Vector2(0, 12)
	await _quadros(3)
	await _print("19_frutifera")
	# cena de amizade
	Jogo.amizade["marina"] = 800
	Jogo.flags.erase("evento_marina_3")
	P.conversar("marina")
	await _quadros(2)
	await _print("20_cena_amizade")
	_checar(Jogo.flags.has("evento_marina_3"), "cena de 3 corações")
	for i in 5:
		if P.ui.call("menu_aberto"):
			P.ui.call("fechar")
			await _quadros(1)
	# mapa
	P.ui.call("abrir_mapa")
	await _quadros(2)
	await _print("21_mapa")
	P.ui.call("fechar")
	# som
	_checar(Som.call("_carregar", "res://som/musica/primavera.ogg") != null, "música carrega")
	_checar(Som.call("_carregar", "res://som/efeitos/enxada.wav") != null, "efeito carrega")
	for nome in ["enxada", "regar", "machado", "picareta", "colher", "moeda", "peixe", "nivel", "chuva"]:
		_checar(ResourceLoader.exists("res://som/efeitos/%s.wav" % nome), "som " + nome)
	# artes
	for id in Dados.itens:
		if Desenho.textura_item(id) == null:
			_checar(false, "arte do item " + id)
	for id in Dados.aldeoes:
		_checar(Desenho.tex("aldeoes/" + id) != null, "arte de " + id)
	print("=== TESTE: %d falha(s) ===" % erros)
	get_tree().quit(1 if erros > 0 else 0)

func _slot_de(id: String) -> int:
	for i in Jogo.inventario.size():
		if Jogo.inventario[i] != null and Jogo.inventario[i].id == id:
			return i
	return 0

func _checar(ok: bool, texto: String) -> void:
	if ok:
		print("ok   - ", texto)
	else:
		print("FALHA- ", texto)
		erros += 1

func _quadros(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _print(nome: String) -> void:
	if not prints:
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ferramentas/prints"))
	img.save_png("res://ferramentas/prints/%s.png" % nome)
