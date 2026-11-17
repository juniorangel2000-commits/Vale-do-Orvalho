extends Node2D
## Liga tudo: tela de título, troca de mapas, controles, câmera, luz do dia, clima,
## aldeões, animais, monstros e a passagem de dia.

const ALCANCE := 1.6   # em blocos: até onde o clique do mouse alcança

var mundo: Node2D
var mapa: Mapa
var jogador: Jogador
var camera: Camera2D
var hud: CanvasLayer
var ui: CanvasLayer
var luz: CanvasModulate
var lanterna: PointLight2D
var clima_no: Node2D
var astar: AStarGrid2D
var npcs := {}
var monstros: Array = []
var animais_nos: Array = []
var escada_achada := false
var pedras_quebradas := 0
var _mapa_atual := ""
var construindo := ""
var cursor: Node2D
var _usando_mouse := false
var _alvo_cursor := Vector2i.ZERO
var _fantasma: Node2D

func _ready() -> void:
	mundo = Node2D.new()
	add_child(mundo)
	luz = CanvasModulate.new()
	add_child(luz)
	camera = Camera2D.new()
	camera.zoom = Vector2(2, 2)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	add_child(camera)
	jogador = Jogador.new()
	jogador.principal = self
	lanterna = PointLight2D.new()
	var grad := GradientTexture2D.new()
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.fill_from = Vector2(0.5, 0.5)
	grad.fill_to = Vector2(1.0, 0.5)
	grad.width = 256
	grad.height = 256
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.9, 0.7, 1))
	g.set_color(1, Color(1, 0.9, 0.7, 0))
	grad.gradient = g
	lanterna.texture = grad
	lanterna.texture_scale = 1.6
	lanterna.energy = 0.9
	lanterna.position = Vector2(0, -20)
	jogador.add_child(lanterna)
	clima_no = Node2D.new()
	clima_no.set_script(preload("res://scripts/clima.gd"))
	var camada_clima := CanvasLayer.new()
	camada_clima.layer = 1
	camada_clima.add_child(clima_no)
	add_child(camada_clima)
	hud = CanvasLayer.new()
	hud.set_script(preload("res://scripts/hud.gd"))
	hud.layer = 2
	add_child(hud)
	ui = CanvasLayer.new()
	ui.set_script(preload("res://scripts/ui.gd"))
	ui.layer = 3
	ui.set("principal", self)
	add_child(ui)
	hud.set("principal", self)
	Jogo.hora_mudou.connect(_ao_mudar_hora)
	Jogo.desmaiou.connect(_desmaiou)
	hud.visible = false
	ui.call("mostrar_titulo")

# ---------------------------------------------------------------- início de partida

func iniciar_novo(nome: String, fazenda: String) -> void:
	Jogo.novo_jogo(nome, fazenda)
	Jogo.flags["agua"] = 40
	_comecar_dia()

func continuar() -> void:
	if Jogo.carregar():
		_comecar_dia()

func _comecar_dia() -> void:
	hud.visible = true
	Jogo.pausado = false
	ir_para("casa", Vector2i(3, 5))
	jogador.direcao = "south"
	if not Jogo.cartas.is_empty():
		ui.call("mostrar_cartas")
	_avisos_do_dia()

func _avisos_do_dia() -> void:
	var climas := {"sol": "Ensolarado", "chuva": "Chuva", "neve": "Neve"}
	Jogo.mensagem.emit("%s. Previsão para amanhã: %s." % [Jogo.texto_data(), String(climas[Jogo.clima_amanha]).to_lower()])
	if not Jogo.festival_hoje().is_empty():
		Jogo.mensagem.emit("Hoje: %s na vila (9h às 14h)!" % Jogo.festival_hoje().nome)

# ---------------------------------------------------------------- troca de mapa

func ir_para(destino: String, entrada: Vector2i, extra := {}) -> void:
	for m in monstros:
		m.queue_free()
	monstros = []
	for a in animais_nos:
		a.queue_free()
	animais_nos = []
	for n in npcs.values():
		n.queue_free()
	npcs = {}
	if mapa:
		if jogador.get_parent() == mapa.objetos:
			mapa.objetos.remove_child(jogador)
		mapa.queue_free()
	mapa = Mapa.new(destino)
	mundo.add_child(mapa)
	mapa.construir(extra)
	if _mapa_atual != "" and _mapa_atual != destino:
		Som.tocar("porta", 0.7)
	_mapa_atual = destino
	jogador.mapa = mapa
	mapa.objetos.add_child(jogador)
	var c := entrada
	if mapa.has_meta("inicio"):
		c = mapa.get_meta("inicio")
	jogador.position = Vector2(c.x * Mapa.T + Mapa.T / 2.0, c.y * Mapa.T + Mapa.T - 4)
	# mapas menores que a tela ficam centralizados
	var visivel := get_viewport_rect().size / camera.zoom
	var sobra_x: float = max(0.0, (visivel.x - mapa.w * Mapa.T) / 2.0)
	var sobra_y: float = max(0.0, (visivel.y - mapa.h * Mapa.T) / 2.0)
	camera.limit_left = int(-sobra_x)
	camera.limit_top = int(-sobra_y)
	camera.limit_right = int(mapa.w * Mapa.T + sobra_x)
	camera.limit_bottom = int(mapa.h * Mapa.T + sobra_y)
	RenderingServer.set_default_clear_color(Color("#140e0c"))
	camera.global_position = jogador.global_position
	camera.reset_smoothing()
	cursor = Node2D.new()
	cursor.z_index = 30
	cursor.draw.connect(func():
		cursor.draw_rect(Rect2(1, 1, Mapa.T - 2, Mapa.T - 2), Color(1, 1, 1, 0.55), false, 2.0)
		cursor.draw_rect(Rect2(3, 3, Mapa.T - 6, Mapa.T - 6), Color(1, 1, 1, 0.08)))
	mapa.add_child(cursor)
	_montar_astar()
	_atualizar_luz()
	_atualizar_npcs(true)
	_criar_animais()
	_criar_monstros()
	hud.call("atualizar")
	_atualizar_musica()

func _atualizar_musica() -> void:
	if mapa == null:
		return
	var h := Jogo.hora()
	var nome: String = ["primavera", "verao", "outono", "inverno"][Jogo.estacao]
	if mapa.andar > 0:
		nome = "mina"
	elif mapa.interior:
		nome = "casa"
	elif mapa.nome == "vila" and not Jogo.festival_hoje().is_empty() and h >= 9 and h < 14:
		nome = "festa"
	elif Jogo.clima == "chuva":
		nome = "casa"
	Som.musica(nome)
	Som.abafar(h >= 20 or Jogo.clima == "chuva")
	Som.chuva(Jogo.clima == "chuva" and not mapa.interior and mapa.andar == 0)

func _montar_astar() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, mapa.w, mapa.h)
	astar.cell_size = Vector2(Mapa.T, Mapa.T)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for x in mapa.w:
		for y in mapa.h:
			if mapa.solido(Vector2i(x, y)):
				astar.set_point_solid(Vector2i(x, y))

func caminho_entre(de: Vector2i, ate: Vector2i) -> Array:
	if astar == null or not astar.is_in_boundsv(de) or not astar.is_in_boundsv(ate):
		return []
	if astar.is_point_solid(ate):
		return []
	var solido_antes := astar.is_point_solid(de)
	astar.set_point_solid(de, false)
	var r := astar.get_id_path(de, ate)
	astar.set_point_solid(de, solido_antes)
	return Array(r)

func ao_mover() -> void:
	var s := mapa.saida_em(jogador.celula())
	if not s.is_empty():
		var destino: String = s.destino
		if destino == "estufa" and not Jogo.flags.has("estufa"):
			return
		ir_para(destino, s.entrada)

func _process(_delta: float) -> void:
	if jogador and jogador.is_inside_tree():
		camera.global_position = jogador.global_position
	if cursor and is_instance_valid(cursor) and mapa:
		var s = Jogo.selecionado() if Jogo.em_partida else null
		var mostra := s != null and not Jogo.pausado and construindo == ""
		if mostra:
			var tipo: String = Dados.item(s.id).tipo
			mostra = tipo == "ferramenta" or tipo == "semente" or tipo == "muda" or bool(Dados.item(s.id).get("colocavel", false)) or s.id == "fertilizante"
		cursor.visible = mostra
		if mostra:
			var alvo := _alvo_mouse() if _usando_mouse else jogador.celula_alvo()
			cursor.position = Vector2(alvo * Mapa.T)
	if Jogo.em_partida and Engine.get_process_frames() % 30 == 0:
		_checar_objetivo()
	if mapa and Engine.get_process_frames() % 20 == 0:
		_atualizar_luz()

# ---------------------------------------------------------------- controles

func _unhandled_input(ev: InputEvent) -> void:
	if not Jogo.em_partida or mapa == null:
		return
	if ui.call("menu_aberto"):
		return
	if construindo != "":
		_input_construcao(ev)
		return
	if ev.is_action_pressed("inventario"):
		ui.call("abrir_inventario")
		return
	if ev.is_action_pressed("menu"):
		ui.call("abrir_inventario", "opcoes")
		return
	if ev.is_action_pressed("diario"):
		ui.call("abrir_mural")
		return
	if ev.is_action_pressed("social"):
		ui.call("abrir_inventario", "social")
		return
	if ev.is_action_pressed("mapa"):
		ui.call("abrir_mapa")
		return
	if ev is InputEventMouseMotion:
		_usando_mouse = true
	elif ev is InputEventKey and (ev.is_action_pressed("cima") or ev.is_action_pressed("baixo") or ev.is_action_pressed("esquerda") or ev.is_action_pressed("direita")):
		_usando_mouse = false
	for i in 12:
		if ev.is_action_pressed("slot%d" % i):
			Jogo.slot = i
			Jogo.inventario_mudou.emit()
	if ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			Jogo.slot = (Jogo.slot + 11) % 12
			Jogo.inventario_mudou.emit()
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			Jogo.slot = (Jogo.slot + 1) % 12
			Jogo.inventario_mudou.emit()
		elif ev.button_index == MOUSE_BUTTON_LEFT:
			_usar(_alvo_mouse())
		elif ev.button_index == MOUSE_BUTTON_RIGHT:
			_interagir(_alvo_mouse())
	if Jogo.pausado or jogador.acao_tempo > 0:
		return
	if ev.is_action_pressed("usar"):
		_usar(jogador.celula_alvo())
	elif ev.is_action_pressed("interagir"):
		_interagir(jogador.celula_alvo())
	elif ev.is_action_pressed("comer"):
		_comer()

func _alvo_mouse() -> Vector2i:
	var p := mapa.get_global_mouse_position()
	var c := mapa.celula_de(p)
	var d := Vector2(c - jogador.celula())
	if d.length() <= ALCANCE:
		return c
	return jogador.celula_alvo()

func _usar(c: Vector2i) -> void:
	if Jogo.pausado or jogador.acao_tempo > 0:
		return
	jogador.virar_para(c)
	Acoes.usar(self, mapa, c)
	hud.call("atualizar")

func _interagir(c: Vector2i) -> void:
	if Jogo.pausado:
		return
	jogador.virar_para(c)
	# aldeão perto?
	for id in npcs:
		var n = npcs[id]
		if n.global_position.distance_to(mapa.centro(c) + Vector2(0, 12)) < 26 or n.global_position.distance_to(jogador.global_position) < 30:
			falar(id)
			return
	for a in animais_nos:
		if a.global_position.distance_to(mapa.centro(c) + Vector2(0, 12)) < 26:
			a.interagir()
			return
	if Acoes.interagir(self, mapa, c):
		return
	if Acoes.interagir(self, mapa, jogador.celula()):
		return

func _comer() -> void:
	var s = Jogo.selecionado()
	if s == null or not Dados.comestivel(s.id):
		return
	var d: Dictionary = Dados.item(s.id)
	ui.call("confirmar", "Comer %s?" % Dados.nome_item(s.id, String(s.get("origem", ""))), func():
		Jogo.recuperar(float(d.energia) * (1.0 + int(s.get("q", 0)) * 0.4))
		Jogo.curar(int(d.get("vida", int(d.energia) / 2)))
		Jogo.remover_do_slot(Jogo.slot)
		Som.tocar("comer")
		Jogo.mensagem.emit("Que delícia!"))

# ---------------------------------------------------------------- luz e clima

func _atualizar_luz() -> void:
	var cor := Color.WHITE
	var h := Jogo.minutos / 60.0
	if mapa.escuro:
		cor = Color(0.42, 0.4, 0.48)
	elif mapa.interior:
		cor = Color(1.0, 0.96, 0.9) if h < 20 else Color(0.75, 0.68, 0.62)
	else:
		if h >= 18.0:
			var t := clampf((h - 18.0) / 3.0, 0.0, 1.0)
			cor = Color.WHITE.lerp(Color(0.95, 0.7, 0.55), clampf(t * 2.0, 0.0, 1.0)).lerp(Color(0.32, 0.34, 0.55), clampf(t * 1.4 - 0.4, 0.0, 1.0))
		if Jogo.clima != "sol":
			cor = cor * Color(0.78, 0.8, 0.88)
	luz.color = cor
	lanterna.enabled = mapa.escuro or (not mapa.interior and h >= 19.5)
	clima_no.set("tipo", "" if mapa.interior or mapa.escuro else Jogo.clima)

func _ao_mudar_hora() -> void:
	if mapa == null:
		return
	_atualizar_npcs(false)
	hud.call("atualizar")
	if Jogo.minutos % 60 == 0:
		_atualizar_musica()
	if Jogo.minutos == 1440:
		Jogo.mensagem.emit("Já é meia-noite. Melhor ir dormir!")
	if Jogo.minutos == 1500:
		Jogo.mensagem.emit("Você está muito cansado...")

# ---------------------------------------------------------------- dia e noite

func dormir() -> void:
	Jogo.pausado = true
	Som.tocar("dormir", 1.0, false)
	var rel := Jogo.passar_dia("")
	hud.call("atualizar")
	ui.call("mostrar_relatorio", rel, _comecar_dia)

func _desmaiou(motivo: String) -> void:
	if not Jogo.em_partida or Jogo.pausado:
		return
	if motivo == "ferido":
		Jogo.pausado = true
		var perdeu: int = min(int(Jogo.dinheiro * 0.05), 500)
		Jogo.dinheiro -= perdeu
		Jogo.vida = int(Jogo.vida_max * 0.5)
		Jogo.avancar_minutos(120)
		ui.call("mostrar_texto", "Você desmaiou na mina. Caio te carregou para fora e cuidou dos ferimentos.\nPerdeu %d moedas." % perdeu, func():
			Jogo.pausado = false
			ir_para("montanha", Vector2i(24, 6)))
		return
	Jogo.pausado = true
	var rel := Jogo.passar_dia(motivo)
	ui.call("mostrar_relatorio", rel, _comecar_dia)

# ---------------------------------------------------------------- aldeões

func _onde_esta(id: String) -> Array:
	var d: Dictionary = Dados.aldeoes[id]
	var h := Jogo.hora()
	if Jogo.conjuge == id:
		if h < 9 or h >= 18:
			return ["casa", 8, 6]
		return ["fazenda", 15, 10]
	if not Jogo.festival_hoje().is_empty() and h >= 9 and h < 14:
		var i := Dados.aldeoes.keys().find(id)
		return ["vila", 24 + (i % 5) * 3, 14 + int(i / 5.0) * 3]
	var agenda: Array = d.agenda
	var ponto: Array = agenda[0]
	if Jogo.clima == "sol":
		for p in agenda:
			if h >= int(p[0]):
				ponto = p
	if h >= 23 and id != "lia":
		return []
	if h >= 24:
		return []
	return [ponto[1], ponto[2], ponto[3]]

func _atualizar_npcs(inicio: bool) -> void:
	for id in Dados.aldeoes:
		var onde := _onde_esta(id)
		var aqui := not onde.is_empty() and String(onde[0]) == _mapa_atual
		if aqui:
			var alvo := Vector2i(int(onde[1]), int(onde[2]))
			if not npcs.has(id):
				var n := Npc.new()
				n.id = id
				n.principal = self
				mapa.objetos.add_child(n)
				var c := alvo
				if mapa.solido(c):
					c = _livre_perto(c)
				n.position = mapa.centro(c) + Vector2(0, 12)
				npcs[id] = n
			npcs[id].ir_para(alvo)
		elif npcs.has(id):
			npcs[id].queue_free()
			npcs.erase(id)

func _livre_perto(c: Vector2i) -> Vector2i:
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if not mapa.solido(c + Vector2i(dx, dy)):
					return c + Vector2i(dx, dy)
	return c

func falar(id: String) -> void:
	var s = Jogo.selecionado()
	if s != null and Dados.item(s.id).tipo != "ferramenta" and not Jogo.presente_hoje.has(id):
		ui.call("confirmar", "Dar %s para %s?" % [Dados.nome_item(s.id, String(s.get("origem", ""))), Dados.aldeoes[id].nome],
			func(): presentear(id), func(): conversar(id))
		return
	conversar(id)

func conversar(id: String) -> void:
	for n in [3, 6]:
		var chave := "evento_%s_%d" % [id, n]
		if Jogo.coracoes(id) >= n and not Jogo.flags.has(chave) and Dados.eventos.has(id):
			Jogo.flags[chave] = true
			Jogo.conversou_hoje[id] = true
			Jogo.mudar_amizade(id, 100)
			if id == "nonato" and n == 3:
				Jogo.adicionar("dourado", 1)
			elif id == "celeste" and n == 6:
				Jogo.adicionar("fertilizante", 10)
			elif id == "bento" and n == 6:
				Jogo.adicionar("barra_ferro", 5)
			_cena(id, Dados.eventos[id][n], 0)
			return
	var d: Dictionary = Dados.aldeoes[id]
	var falas: Dictionary = d.falas
	var opcoes: Array = Array(falas.geral).duplicate()
	var est := Dados.estacao_chave(Jogo.estacao)
	if falas.has(est):
		opcoes.append_array(falas[est])
	var co := Jogo.coracoes(id)
	for n in [4, 6, 8]:
		if co >= n and falas.has("coracao%d" % n):
			opcoes.append_array(falas["coracao%d" % n])
	if Jogo.conjuge == id and falas.has("casado"):
		opcoes = Array(falas.casado).duplicate()
	var texto: String = opcoes[(Jogo.dia_absoluto() * 7 + id.length()) % opcoes.size()]
	if Jogo.aniversario_hoje(id):
		texto = "Hoje é meu aniversário! Você lembrou?"
	if not Jogo.pedido.is_empty() and String(Jogo.pedido.npc) == id:
		texto += "\n\n(Pedido no mural: %d %s.)" % [int(Jogo.pedido.qtd), Dados.nome_item(Jogo.pedido.item)]
	if not Jogo.festival_hoje().is_empty() and Jogo.hora() >= 9 and Jogo.hora() < 14:
		if id == "augusto":
			ui.call("abrir_festival")
			return
		texto = ["Que festa linda!", "Adoro esse dia do ano.", "Você já falou com o prefeito? Ele organiza tudo."][id.length() % 3]
	if not Jogo.conversou_hoje.has(id):
		Jogo.conversou_hoje[id] = true
		Jogo.mudar_amizade(id, 20)
	ui.call("mostrar_dialogo", id, texto)

func _cena(id: String, linhas: Array, i: int) -> void:
	if i >= linhas.size():
		return
	var proxima := Callable()
	if i + 1 < linhas.size():
		proxima = func(): _cena(id, linhas, i + 1)
	ui.call("mostrar_dialogo", id, String(linhas[i]), proxima)

# ---------------------------------------------------------------- objetivos do começo

const OBJETIVOS := [
	"Escolha a enxada (tecla 1) e clique na grama perto de casa para arar a terra.",
	"Escolha as sementes de alface (tecla 8) e plante na terra arada.",
	"Regue as sementes com o regador (tecla 2). Encha no poço ou no lago quando esvaziar.",
	"Junte material: corte galhos com o machado (3) ou quebre pedras com a picareta (4).",
	"Siga a estrada para a direita até a vila. O Armazém vende mais sementes.",
	"Converse com alguém da vila (clique direito ou F perto da pessoa).",
	"Coloque algo para vender na caixa de madeira ao lado da sua casa.",
	"Quando cansar, durma na sua cama: o dia termina e o jogo é salvo.",
]

func _checar_objetivo() -> void:
	if Jogo.flags.has("objetivos_fim"):
		hud.call("mostrar_objetivo", "")
		return
	var etapa := int(Jogo.flags.get("objetivo", 0))
	var feito := false
	var faz: Dictionary = Jogo.estado_mapa("fazenda")
	match etapa:
		0: feito = not faz.solo.is_empty()
		1:
			for k in faz.solo:
				if faz.solo[k].has("cultura"):
					feito = true
		2:
			for k in faz.solo:
				if faz.solo[k].has("cultura") and bool(faz.solo[k].get("regado", false)):
					feito = true
		3: feito = Jogo.contar("madeira") > 0 or Jogo.contar("pedra") > 0
		4: feito = _mapa_atual == "vila"
		5: feito = not Jogo.conversou_hoje.is_empty()
		6: feito = not Jogo.caixa_envio.is_empty() or Jogo.total_ganho > 0
		7: feito = Jogo.dia_absoluto() > 0
	if feito:
		etapa += 1
		Jogo.flags["objetivo"] = etapa
		Som.tocar("pegar", 0.8, false)
		if etapa >= OBJETIVOS.size():
			Jogo.flags["objetivos_fim"] = true
			Jogo.mensagem.emit("Você já sabe o básico. Agora o vale é seu!")
			hud.call("mostrar_objetivo", "")
			return
	hud.call("mostrar_objetivo", OBJETIVOS[etapa] if etapa < OBJETIVOS.size() else "")

func presentear(id: String) -> void:
	var s = Jogo.selecionado()
	if s == null:
		return
	var d: Dictionary = Dados.aldeoes[id]
	var item: String = s.id
	var nome: String = d.nome
	if Jogo.pedido.get("npc", "") == id and Jogo.pedido.item == item:
		if Jogo.contar(item) >= int(Jogo.pedido.qtd):
			Jogo.remover(item, int(Jogo.pedido.qtd))
			Jogo.ganhar(int(Jogo.pedido.recompensa))
			Jogo.mudar_amizade(id, 150)
			ui.call("mostrar_dialogo", id, "Ah, você trouxe! Muito obrigado(a). Aqui está sua recompensa: %d moedas." % int(Jogo.pedido.recompensa))
			Jogo.pedido = {}
			return
	if item == "buque":
		if not d.casavel:
			ui.call("mostrar_dialogo", id, "Que flores bonitas... mas acho que não é pra mim.")
		elif Jogo.coracoes(id) < 8:
			ui.call("mostrar_dialogo", id, "Um buquê? Ainda não nos conhecemos tão bem...")
		elif Jogo.conjuge != "" or not Jogo.noivado.is_empty():
			ui.call("mostrar_dialogo", id, "Você já tem alguém, não tem?")
		else:
			Jogo.remover_do_slot(Jogo.slot)
			Jogo.namorando[id] = true
			Jogo.mudar_amizade(id, 50)
			ui.call("mostrar_dialogo", id, "Pra mim? Isso quer dizer o que eu acho que quer dizer? ...Sim. Vamos namorar!")
		return
	if item == "anel_orvalho":
		if not Jogo.namorando.has(id) or Jogo.coracoes(id) < 10:
			ui.call("mostrar_dialogo", id, "Um anel...? Acho que ainda é cedo pra isso.")
		elif Jogo.nivel_casa < 1:
			ui.call("mostrar_dialogo", id, "Eu adoraria! Mas sua casa é pequena demais pra nós dois. Que tal ampliá-la com a Rosa?")
		elif Jogo.conjuge != "" or not Jogo.noivado.is_empty():
			ui.call("mostrar_dialogo", id, "...")
		else:
			Jogo.remover_do_slot(Jogo.slot)
			Jogo.noivado = {"npc": id, "dia": Jogo.dia_absoluto() + 3}
			ui.call("mostrar_dialogo", id, "SIM! Mil vezes sim! Vou falar com o prefeito. O casamento vai ser daqui a três dias!")
		return
	if Jogo.presente_hoje.has(id):
		ui.call("mostrar_dialogo", id, "Você já me deu um presente hoje.")
		return
	var aniversario := Jogo.aniversario_hoje(id)
	if int(Jogo.presentes_semana.get(id, 0)) >= 2 and not aniversario and Jogo.conjuge != id:
		ui.call("mostrar_dialogo", id, "Você já me deu dois presentes esta semana! Assim fico sem graça.")
		return
	var pontos := 20
	var reacao := "Obrigado(a)! Que gentileza."
	if item in d.ama:
		pontos = 80
		reacao = "Nossa! É o meu preferido! Como você sabia?"
	elif item in d.gosta:
		pontos = 45
		reacao = "Que legal, eu gosto muito disso!"
	elif item in d.odeia:
		pontos = -40
		reacao = "Ugh... por que você me daria isso?"
	if aniversario:
		pontos *= 8
		reacao += " E ainda no meu aniversário!"
	Jogo.remover_do_slot(Jogo.slot)
	Jogo.presente_hoje[id] = true
	Jogo.presentes_semana[id] = int(Jogo.presentes_semana.get(id, 0)) + 1
	Jogo.mudar_amizade(id, pontos)
	Jogo.somar_stat("presentes")
	ui.call("mostrar_dialogo", id, reacao)

# ---------------------------------------------------------------- animais

func _criar_animais() -> void:
	if mapa.construcao_id == 0:
		return
	var i := 0
	for a in Jogo.animais:
		if int(a.casa) != mapa.construcao_id:
			continue
		var n := Animal.new()
		n.dados = a
		n.mapa = mapa
		n.position = mapa.centro(Vector2i(3 + (i * 2) % (mapa.w - 5), 4 + int(i / 4.0))) + Vector2(0, 12)
		mapa.objetos.add_child(n)
		animais_nos.append(n)
		i += 1

# ---------------------------------------------------------------- mina

func entrar_mina_menu() -> void:
	if Jogo.mina_andar_max >= 5:
		ui.call("abrir_elevador")
	else:
		entrar_mina(1)

func entrar_mina(andar: int) -> void:
	andar = clampi(andar, 1, 40)
	escada_achada = false
	pedras_quebradas = 0
	ir_para("mina", Vector2i(20, 15), {"andar": andar})
	if andar > Jogo.mina_andar_max:
		Jogo.mina_andar_max = andar
		Jogo.somar_stat("andares", 0)
		if andar % 5 == 0:
			Jogo.mensagem.emit("Elevador liberado até o andar %d!" % andar)
	Jogo.mensagem.emit("Mina — andar %d" % andar)
	if andar >= 40 and not Jogo.flags.has("premio_mina"):
		Jogo.mensagem.emit("Você chegou ao fundo da mina! Há um baú aqui...")

func _criar_monstros() -> void:
	if not mapa.has_meta("monstros"):
		return
	for d in mapa.get_meta("monstros"):
		var n := Monstro.new()
		n.tipo = d.tipo
		n.mapa = mapa
		n.principal = self
		n.andar = mapa.andar
		n.position = mapa.centro(d.c) + Vector2(0, 12)
		mapa.objetos.add_child(n)
		monstros.append(n)

func atacar(arma: String) -> void:
	var dano := 1
	match arma:
		"espada": dano = Jogo.rng.randi_range(3, 6)
		"espada_aco": dano = Jogo.rng.randi_range(8, 13)
		"foice": dano = 1
	dano += int(Jogo.nivel_habilidade("combate") / 2.0)
	if arma != "foice":
		Jogo.cansar(0.5)
	if arma != "foice":
		Som.tocar("foice", 0.8)
	var ponto := jogador.global_position + Vector2(jogador.olhando) * 22.0 + Vector2(0, -8)
	for m in monstros.duplicate():
		if is_instance_valid(m) and m.global_position.distance_to(ponto) < 30:
			m.ferir(dano, Vector2(jogador.olhando))

func monstro_morreu(m: Node) -> void:
	monstros.erase(m)
	Jogo.ganhar_xp("combate", 5 + mapa.andar / 2)
	var drops := {"gosma": "gosma", "gosma_azul": "gosma", "gosma_roxa": "gosma", "morcego": "asa_morcego", "pedrento": "carvao"}
	if Jogo.rng.randf() < 0.6:
		Jogo.adicionar(drops.get(m.tipo, "gosma"), 1, "", 0, true)
	if monstros.is_empty() and not escada_achada:
		Jogo.mensagem.emit("O andar ficou em silêncio... uma escada apareceu!")
		_por_escada(mapa.celula_de(m.global_position))

func pedra_quebrada(c: Vector2i) -> void:
	if mapa.andar <= 0 or escada_achada:
		return
	pedras_quebradas += 1
	var restantes := int(mapa.get_meta("pedras", 50)) - pedras_quebradas
	var chance := 0.02 + pedras_quebradas * 0.006
	if restantes <= 1 or Jogo.rng.randf() < chance:
		_por_escada(c)

func _por_escada(c: Vector2i) -> void:
	if mapa.andar >= 40:
		return
	if not mapa.objeto(c).is_empty() or mapa.solido(c):
		c = _livre_perto(c)
	escada_achada = true
	mapa.por_objeto(c, {"tipo": "escada_mina"})

# ---------------------------------------------------------------- construção na fazenda

func modo_construcao(tipo: String) -> void:
	construindo = tipo
	ir_para("fazenda", Vector2i(28, 22))
	Jogo.pausado = true
	_fantasma = Node2D.new()
	_fantasma.z_index = 50
	mapa.add_child(_fantasma)
	_fantasma.draw.connect(_desenhar_fantasma)
	Jogo.mensagem.emit("Clique onde quer construir %s. Esc cancela." % Dados.construcoes[tipo].nome.to_lower())

func _origem_construcao() -> Vector2i:
	var t: Vector2i = Dados.construcoes[construindo].tam
	var c := mapa.celula_de(mapa.get_global_mouse_position())
	return c - Vector2i(t.x / 2, t.y - 1)

func _pode_construir(o: Vector2i) -> bool:
	var t: Vector2i = Dados.construcoes[construindo].tam
	if o.x < 3 or o.y < 3 or o.x + t.x > mapa.w - 3 or o.y + t.y + 1 > mapa.h - 3:
		return false
	return mapa.area_livre(o, t + Vector2i(0, 1))

func _desenhar_fantasma() -> void:
	var t: Vector2i = Dados.construcoes[construindo].tam
	var o := _origem_construcao()
	var cor := Color(0.3, 1, 0.3, 0.4) if _pode_construir(o) else Color(1, 0.3, 0.3, 0.4)
	for x in t.x:
		for y in t.y:
			_fantasma.draw_rect(Rect2((o.x + x) * Mapa.T + 1, (o.y + y) * Mapa.T + 1, Mapa.T - 2, Mapa.T - 2), cor)
	_fantasma.draw_rect(Rect2((o.x + t.x / 2) * Mapa.T, (o.y + t.y) * Mapa.T, Mapa.T, Mapa.T), Color(1, 1, 0.5, 0.4))

func _input_construcao(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		_fantasma.queue_redraw()
		# arrasta a câmera quando o mouse chega na borda
		var p: Vector2 = ev.position
		var tela := get_viewport_rect().size
		var mover := Vector2.ZERO
		if p.x < 40: mover.x = -1
		if p.x > tela.x - 40: mover.x = 1
		if p.y < 40: mover.y = -1
		if p.y > tela.y - 40: mover.y = 1
		jogador.position += mover * 16
		return
	if ev.is_action_pressed("menu") or (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT):
		_sair_construcao()
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var o := _origem_construcao()
		if not _pode_construir(o):
			Jogo.mensagem.emit("Não dá para construir aqui.")
			return
		var c: Dictionary = Dados.construcoes[construindo]
		if not Jogo.tem_ingredientes(c.ing) or not Jogo.gastar(int(c.preco)):
			_sair_construcao()
			return
		Jogo.gastar_ingredientes(c.ing)
		Jogo.construcoes.append({"id": Jogo.novo_id(), "tipo": construindo, "x": o.x, "y": o.y, "nivel": 0, "cocho": 0})
		Jogo.mensagem.emit("%s construído!" % c.nome)
		_sair_construcao()

func _sair_construcao() -> void:
	construindo = ""
	Jogo.pausado = false
	var c := jogador.celula()
	if mapa.solido(c):
		c = _livre_perto(c)
	ir_para("fazenda", c)
