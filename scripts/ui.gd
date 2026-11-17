class_name Ui
extends CanvasLayer
## Todos os menus e janelas. Cada janela é montada por código quando abre e apagada ao fechar.

const COR_TEXTO := Color("#3a2010")
const COR_TITULO := Color("#6a2a10")

var principal: Node
var _fundo: ColorRect
var _janela: Control
var _ao_fechar := Callable()
var _pausou := false
var _selecionado := -1
var _aba := "mochila"
var _titulo_tela: Control
var _pesca: Control
var _conteudo: VBoxContainer

# ---------------------------------------------------------------- estilos

static func estilo_painel(cor := Color("#f2dfb4")) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = cor
	e.border_color = Color("#7a4e2e")
	e.set_border_width_all(4)
	e.set_corner_radius_all(6)
	e.content_margin_left = 12
	e.content_margin_right = 12
	e.content_margin_top = 10
	e.content_margin_bottom = 10
	return e

static func descricao_item(s) -> String:
	var id: String = s.id
	var d: Dictionary = Dados.item(id)
	var origem := String(s.get("origem", ""))
	var t := Dados.nome_item(id, origem)
	var q := int(s.get("q", 0))
	if q > 0:
		t += " (" + ["", "prata", "ouro", "irídio"][q] + ")"
	if d.tipo == "ferramenta" and Jogo.nivel_de(id) > 0:
		t = "%s %s" % [d.nome, Dados.NOMES_NIVEL_FERRAMENTA[Jogo.nivel_de(id)]]
	var tipos := {"semente": "Semente", "cultura": "Colheita", "recurso": "Recurso", "forragem": "Coleta", "peixe": "Peixe", "animal": "Produto animal",
		"artesanal": "Artesanal", "comida": "Comida", "objeto": "Objeto", "minerio": "Minério", "barra": "Barra", "gema": "Mineral",
		"ferramenta": "Ferramenta", "consumivel": "Consumível", "especial": "Especial", "lixo": "Lixo", "muda": "Árvore (plante na fazenda)"}
	t += "\n" + String(tipos.get(d.tipo, ""))
	if d.tipo == "semente":
		var c := Dados.cultura_da_semente(id)
		if c != "":
			var est := []
			for e in Dados.culturas[c].estacoes:
				est.append(Dados.ESTACOES[e])
			t += "\nCresce em %d dias (%s)" % [Dados.dias_totais(c), ", ".join(est)]
			if int(Dados.culturas[c].rebrota) > 0:
				t += "\nVolta a dar a cada %d dias" % int(Dados.culturas[c].rebrota)
	var preco := Dados.preco_venda(id, origem, q)
	if preco > 0 and d.tipo != "ferramenta":
		t += "\nVende por %d" % preco
	if int(d.energia) > 0 and d.tipo != "semente":
		t += "\nEnergia +%d (Q para comer)" % int(d.energia)
	return t

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fundo = ColorRect.new()
	_fundo.color = Color(0, 0, 0, 0.45)
	_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundo.visible = false
	add_child(_fundo)

func menu_aberto() -> bool:
	return _janela != null or _pesca != null

func _input(ev: InputEvent) -> void:
	if _janela == null or _titulo_tela != null:
		return
	if ev.is_action_pressed("menu") or (ev.is_action_pressed("inventario") and _aba != "texto"):
		fechar()
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- base das janelas

func _abrir(titulo: String, largura := 640.0, altura := 0.0) -> VBoxContainer:
	if _janela:
		_janela.queue_free()
		_janela = null
	if _janela == null:
		Som.tocar("abrir", 0.7)
	_fundo.visible = true
	if not Jogo.pausado:
		Jogo.pausado = true
		_pausou = true
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_janela = centro
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", estilo_painel())
	painel.custom_minimum_size = Vector2(largura, altura)
	centro.add_child(painel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	painel.add_child(vb)
	_conteudo = vb
	if titulo != "":
		var t := _label(titulo, 22, COR_TITULO)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(t)
	return vb

func fechar() -> void:
	if _janela:
		Som.tocar("fechar", 0.6)
		_janela.queue_free()
		_janela = null
	_fundo.visible = false
	_selecionado = -1
	if _pausou:
		Jogo.pausado = false
		_pausou = false
	var cb := _ao_fechar
	_ao_fechar = Callable()
	if cb.is_valid():
		cb.call()
	if principal and principal.hud:
		principal.hud.atualizar()

func _label(texto: String, tamanho := 15, cor := COR_TEXTO) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _botao(texto: String, acao: Callable, ativo := true) -> Button:
	var b := Button.new()
	b.text = texto
	b.disabled = not ativo
	b.add_theme_font_size_override("font_size", 14)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): Som.tocar("clique", 0.7))
	b.pressed.connect(acao)
	return b

func _rolagem(altura := 360.0) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, altura)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	sc.add_child(vb)
	_conteudo.add_child(sc)
	return vb

func _linha_item(pai: Control, id: String, texto: String, botoes: Array, origem := "") -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var s := SlotUI.new()
	s.custom_minimum_size = Vector2(36, 36)
	s.item_fixo = {"id": id, "qtd": 1, "origem": origem}
	hb.add_child(s)
	var l := _label(texto, 14)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(l)
	for b in botoes:
		hb.add_child(b)
	pai.add_child(hb)

func _ingredientes_texto(ing: Dictionary) -> String:
	var partes := []
	for id in ing:
		partes.append("%d %s (%d)" % [int(ing[id]), Dados.nome_item(id), Jogo.contar(id)])
	return ", ".join(partes)

# ---------------------------------------------------------------- título

func mostrar_titulo() -> void:
	Jogo.em_partida = false
	_titulo_tela = ColorRect.new()
	(_titulo_tela as ColorRect).color = Color("#2a4a3a")
	_titulo_tela.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_titulo_tela)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_titulo_tela.add_child(centro)
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", estilo_painel())
	painel.custom_minimum_size = Vector2(440, 0)
	centro.add_child(painel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	painel.add_child(vb)
	var t := _label("Vale do Orvalho", 40, COR_TITULO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var sub := _label("Uma vida nova no campo", 16)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	vb.add_child(_label("Seu nome:", 14))
	var nome := LineEdit.new()
	nome.text = "Ana"
	vb.add_child(nome)
	vb.add_child(_label("Nome da fazenda:", 14))
	var fazenda := LineEdit.new()
	fazenda.text = "Orvalho"
	vb.add_child(fazenda)
	vb.add_child(_botao("Novo jogo", func():
		if Jogo.existe_save():
			_confirmar_novo(nome.text, fazenda.text)
		else:
			_comecar(nome.text, fazenda.text)))
	vb.add_child(_botao("Continuar", func():
		_titulo_tela.queue_free()
		_titulo_tela = null
		principal.continuar(), Jogo.existe_save()))
	vb.add_child(_botao("Sair", func(): get_tree().quit()))
	var ajuda := _label("WASD: andar · Clique esquerdo/Espaço: usar ferramenta · Clique direito/F: interagir\nE: mochila · 1-0: escolher item · Q: comer · M: mapa · J: mural · K: amizades · Esc: menu", 12)
	ajuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(ajuda)

func _confirmar_novo(nome: String, fazenda: String) -> void:
	var tela := _titulo_tela
	tela.visible = false
	_titulo_tela = null
	confirmar("Já existe uma partida salva. Começar outra apaga a anterior. Continuar?", func():
		tela.queue_free()
		_comecar(nome, fazenda), func():
		tela.visible = true
		_titulo_tela = tela)

func _comecar(nome: String, fazenda: String) -> void:
	if _titulo_tela:
		_titulo_tela.queue_free()
		_titulo_tela = null
	principal.iniciar_novo(nome, fazenda)

# ---------------------------------------------------------------- caixas simples

func confirmar(texto: String, sim: Callable, nao := Callable()) -> void:
	var vb := _abrir("", 420)
	vb.add_child(_label(texto, 16))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 20)
	hb.add_child(_botao("Sim", func():
		_ao_fechar = Callable()
		fechar()
		sim.call()))
	hb.add_child(_botao("Não", func():
		_ao_fechar = Callable()
		fechar()
		if nao.is_valid():
			nao.call()))
	vb.add_child(hb)

func mostrar_texto(texto: String, depois := Callable()) -> void:
	var vb := _abrir("", 480)
	vb.add_child(_label(texto, 15))
	vb.add_child(_botao("OK", fechar))
	_ao_fechar = depois

func mostrar_dialogo(npc: String, texto: String, depois := Callable()) -> void:
	var d: Dictionary = Dados.aldeoes[npc]
	var vb := _abrir("", 640)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	var retrato := Control.new()
	retrato.custom_minimum_size = Vector2(80, 90)
	var cor: Color = d.cor
	retrato.draw.connect(func():
		retrato.draw_rect(Rect2(0, 0, 80, 90), Color("#c8a878"))
		retrato.draw_circle(Vector2(40, 38), 24, Color("#f0c8a0"))
		retrato.draw_rect(Rect2(14, 60, 52, 30), cor)
		retrato.draw_arc(Vector2(40, 34), 25, PI, TAU, 16, cor.darkened(0.3), 10)
		retrato.draw_circle(Vector2(32, 38), 2.5, Color.BLACK)
		retrato.draw_circle(Vector2(48, 38), 2.5, Color.BLACK)
		retrato.draw_arc(Vector2(40, 46), 6, 0.3, PI - 0.3, 8, Color("#8a3a2a"), 2))
	hb.add_child(retrato)
	var direita := VBoxContainer.new()
	direita.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	direita.custom_minimum_size = Vector2(520, 0)
	var co := Jogo.coracoes(npc)
	var status := ""
	if Jogo.conjuge == npc:
		status = " (cônjuge)"
	elif Jogo.namorando.has(npc):
		status = " (namorando)"
	direita.add_child(_label("%s%s   %s" % [d.nome, status, "♥".repeat(co) + "♡".repeat(max(Jogo.max_coracoes(npc) - co, 0))], 16, COR_TITULO))
	direita.add_child(_label(texto, 16))
	hb.add_child(direita)
	vb.add_child(hb)
	vb.add_child(_botao("Continuar" if depois.is_valid() else "Até mais", fechar))
	_ao_fechar = depois

# ---------------------------------------------------------------- mochila e abas

func abrir_inventario(aba := "mochila") -> void:
	_aba = aba
	var vb := _abrir("", 720)
	var abas := HBoxContainer.new()
	abas.alignment = BoxContainer.ALIGNMENT_CENTER
	for par in [["mochila", "Mochila"], ["fabricar", "Fabricar"], ["habilidades", "Habilidades"], ["social", "Amizades"], ["conquistas", "Conquistas"], ["opcoes", "Opções"]]:
		var b := _botao(par[1], func(): abrir_inventario(par[0]))
		if par[0] == aba:
			b.modulate = Color(1.2, 1.0, 0.7)
		abas.add_child(b)
	vb.add_child(abas)
	match aba:
		"mochila": _aba_mochila(vb)
		"fabricar": _aba_fabricar()
		"habilidades": _aba_habilidades(vb)
		"social": _aba_social()
		"conquistas": _aba_conquistas()
		"opcoes": _aba_opcoes(vb)

func _grade(pai: Control, lista: Array, ao_clicar: Callable, colunas := 12) -> GridContainer:
	var g := GridContainer.new()
	g.columns = colunas
	g.add_theme_constant_override("h_separation", 3)
	g.add_theme_constant_override("v_separation", 3)
	for i in lista.size():
		var s := SlotUI.new()
		s.lista = lista
		s.indice = i
		s.destaque = i == _selecionado
		s.clicado.connect(ao_clicar)
		g.add_child(s)
	pai.add_child(g)
	return g

func _aba_mochila(vb: VBoxContainer) -> void:
	vb.add_child(_label("Clique num item e depois em outro lugar para mover. A primeira fileira é a barra de itens.", 13))
	_grade(vb, Jogo.inventario, func(s: SlotUI, _b: int):
		if _selecionado < 0:
			if Jogo.inventario[s.indice] != null:
				_selecionado = s.indice
		else:
			Jogo.trocar_slots(_selecionado, s.indice)
			_selecionado = -1
		abrir_inventario("mochila"))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.add_child(_botao("Jogar fora o selecionado", func():
		if _selecionado >= 0 and Jogo.inventario[_selecionado] != null and Dados.item(Jogo.inventario[_selecionado].id).tipo != "ferramenta":
			Jogo.inventario[_selecionado] = null
			_selecionado = -1
			Jogo.inventario_mudou.emit()
			abrir_inventario("mochila"), _selecionado >= 0))
	var info := _label("%s · %s · Energia %d/%d" % [Jogo.nome_fazendeiro, Hud_milhar(Jogo.dinheiro) + " moedas", int(Jogo.energia), Jogo.energia_max], 14)
	info.autowrap_mode = TextServer.AUTOWRAP_OFF
	hb.add_child(info)
	vb.add_child(hb)

static func Hud_milhar(n: int) -> String:
	var t := str(abs(n))
	var r := ""
	while t.length() > 3:
		r = "." + t.substr(t.length() - 3) + r
		t = t.substr(0, t.length() - 3)
	return t + r

func _aba_fabricar() -> void:
	var lista := _rolagem(380)
	for r in Jogo.receitas_conhecidas:
		var rec: Dictionary = Dados.receitas[r]
		var pode := Jogo.tem_ingredientes(rec.ing) and Jogo.cabe(r, int(rec.qtd))
		var texto := "%s%s\n%s" % [Dados.nome_item(r), (" x%d" % int(rec.qtd)) if int(rec.qtd) > 1 else "", _ingredientes_texto(rec.ing)]
		_linha_item(lista, r, texto, [_botao("Fabricar", func():
			if Jogo.tem_ingredientes(rec.ing):
				Jogo.gastar_ingredientes(rec.ing)
				Jogo.adicionar(r, int(rec.qtd), "", 0, true)
				Jogo.somar_stat("fabricados")
				abrir_inventario("fabricar"), pode)])
	var faltam := []
	for r in Dados.receitas:
		if not (r in Jogo.receitas_conhecidas):
			var req: Dictionary = Dados.receitas[r].req
			for h in req:
				faltam.append("%s (%s %d)" % [Dados.nome_item(r), Dados.NOMES_HABILIDADES[h], int(req[h])])
	if not faltam.is_empty():
		lista.add_child(_label("A aprender: " + ", ".join(faltam), 12))

func _aba_habilidades(vb: VBoxContainer) -> void:
	for h in Dados.HABILIDADES:
		var n := Jogo.nivel_habilidade(h)
		var prox := "máximo" if n >= 10 else "%d/%d XP" % [int(Jogo.xp.get(h, 0)), int(Dados.XP_NIVEL[n])]
		vb.add_child(_label("%s — nível %d  %s  (%s)" % [Dados.NOMES_HABILIDADES[h], n, "■".repeat(n) + "□".repeat(10 - n), prox], 16))
	vb.add_child(_label("Cada nível diminui o cansaço das ferramentas da área e libera receitas novas.", 13))
	var fer := []
	for f in ["enxada", "regador", "machado", "picareta"]:
		fer.append("%s: %s" % [Dados.nome_item(f), ["básica", "cobre", "ferro", "ouro"][Jogo.nivel_de(f)]])
	vb.add_child(_label("Ferramentas — " + ", ".join(fer), 13))
	vb.add_child(_label("Mina: andar mais fundo %d · Peixes pescados: %d · Itens colhidos: %d" % [Jogo.mina_andar_max, int(Jogo.stats.get("peixes", 0)), int(Jogo.stats.get("colhidos", 0))], 13))

func _aba_social() -> void:
	var lista := _rolagem(400)
	for id in Dados.aldeoes:
		var d: Dictionary = Dados.aldeoes[id]
		var co := Jogo.coracoes(id)
		var aniv: Array = d.aniversario
		var status := ""
		if Jogo.conjuge == id:
			status = " · cônjuge"
		elif Jogo.namorando.has(id):
			status = " · namorando"
		elif d.casavel:
			status = " · solteiro(a)"
		var texto := "%s%s\n%s  Aniversário: %d de %s · Presentes na semana: %d/2%s" % [d.nome, status, "♥".repeat(co) + "♡".repeat(max(Jogo.max_coracoes(id) - co, 0)),
			int(aniv[1]), Dados.ESTACOES[int(aniv[0])], int(Jogo.presentes_semana.get(id, 0)), " · conversou hoje" if Jogo.conversou_hoje.has(id) else ""]
		var l := _label(texto, 14)
		lista.add_child(l)

func _aba_conquistas() -> void:
	var lista := _rolagem(400)
	for id in Dados.conquistas:
		var c: Dictionary = Dados.conquistas[id]
		var feita: bool = id in Jogo.conquistas
		lista.add_child(_label("%s %s — %s" % ["★" if feita else "☆", c.nome, c.desc], 14, COR_TEXTO if feita else Color("#8a7a6a")))

func _aba_opcoes(vb: VBoxContainer) -> void:
	vb.add_child(_label("O jogo salva sozinho toda vez que você dorme.", 15))
	vb.add_child(_label("Controles:\nWASD ou setas: andar\nClique esquerdo ou Espaço: usar o item da mão\nClique direito ou F: falar, colher, abrir, interagir\n1 a 0, - e =: escolher item (ou roda do mouse)\nE: mochila · Q: comer o item da mão · M: mapa · J: mural de pedidos · K: amizades · Esc: menu", 14))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	vb.add_child(_label("Volume da música", 14))
	var sm := HSlider.new()
	sm.min_value = 0.0
	sm.max_value = 1.0
	sm.step = 0.05
	sm.value = Som.vol_musica
	sm.custom_minimum_size = Vector2(300, 20)
	sm.value_changed.connect(func(v: float): Som.definir_volumes(v, Som.vol_efeitos))
	vb.add_child(sm)
	vb.add_child(_label("Volume dos efeitos", 14))
	var se := HSlider.new()
	se.min_value = 0.0
	se.max_value = 1.0
	se.step = 0.05
	se.value = Som.vol_efeitos
	se.custom_minimum_size = Vector2(300, 20)
	se.value_changed.connect(func(v: float):
		Som.definir_volumes(Som.vol_musica, v)
		Som.tocar("pegar"))
	vb.add_child(se)
	hb.add_child(_botao("Voltar ao título", func():
		confirmar("Voltar ao título? O que aconteceu desde a manhã será perdido.", func():
			fechar()
			get_tree().reload_current_scene())))
	hb.add_child(_botao("Sair do jogo", func():
		confirmar("Sair do jogo? O que aconteceu desde a manhã será perdido.", func(): get_tree().quit())))
	hb.add_child(_botao("Fechar", fechar))
	vb.add_child(hb)

# ---------------------------------------------------------------- baú e venda

func abrir_bau(itens: Array, titulo: String) -> void:
	var vb := _abrir(titulo, 720)
	vb.add_child(_label("Clique num item para passar de um lado para o outro.", 13))
	_grade(vb, itens, func(s: SlotUI, _b: int):
		var it = itens[s.indice]
		if it != null:
			var resto := Jogo.adicionar(String(it.id), int(it.qtd), String(it.get("origem", "")), int(it.get("q", 0)))
			if resto > 0:
				it.qtd = resto
			else:
				itens[s.indice] = null
		abrir_bau(itens, titulo))
	vb.add_child(_label("Mochila", 15, COR_TITULO))
	_grade(vb, Jogo.inventario, func(s: SlotUI, _b: int):
		var it = Jogo.inventario[s.indice]
		if it != null and Dados.item(it.id).tipo != "ferramenta":
			var resto := Jogo.adicionar_em(itens, String(it.id), int(it.qtd), String(it.get("origem", "")), int(it.get("q", 0)))
			if resto > 0:
				it.qtd = resto
			else:
				Jogo.inventario[s.indice] = null
			Jogo.inventario_mudou.emit()
		abrir_bau(itens, titulo))
	vb.add_child(_botao("Fechar", fechar))

func abrir_venda() -> void:
	var vb := _abrir("Caixa de venda", 720)
	var total := 0
	for s in Jogo.caixa_envio:
		total += Dados.preco_venda(s.id, String(s.get("origem", "")), int(s.get("q", 0))) * int(s.qtd)
	vb.add_child(_label("Tudo o que estiver na caixa é vendido durante a noite. Hoje: %d moedas. Clique num item da mochila para colocar." % total, 14))
	_grade(vb, Jogo.inventario, func(s: SlotUI, _b: int):
		var it = Jogo.inventario[s.indice]
		if it != null and Dados.item(it.id).tipo != "ferramenta" and Dados.preco_venda(it.id, String(it.get("origem", "")), int(it.get("q", 0))) > 0:
			Jogo.caixa_envio.append(it.duplicate())
			Jogo.inventario[s.indice] = null
			Jogo.inventario_mudou.emit()
		abrir_venda())
	var hb := HBoxContainer.new()
	hb.add_child(_botao("Tirar o último da caixa", func():
		if not Jogo.caixa_envio.is_empty():
			var ult: Dictionary = Jogo.caixa_envio.pop_back()
			var resto := Jogo.adicionar(String(ult.id), int(ult.qtd), String(ult.get("origem", "")), int(ult.get("q", 0)))
			if resto > 0:
				ult.qtd = resto
				Jogo.caixa_envio.append(ult)
		abrir_venda(), not Jogo.caixa_envio.is_empty()))
	hb.add_child(_botao("Fechar", fechar))
	vb.add_child(hb)

# ---------------------------------------------------------------- lojas

func _loja_aberta(id: String) -> String:
	var l: Dictionary = Dados.lojas[id]
	var h := Jogo.hora()
	if not Jogo.festival_hoje().is_empty() and h < 14:
		return "Fechado: hoje é dia de festa na vila!"
	if Jogo.dia_semana() == int(l.folga):
		return "Fechado hoje (%s é dia de folga)." % Dados.DIAS_SEMANA[int(l.folga)]
	if h < int(l.abre) or h >= int(l.fecha):
		return "Fechado. Abre das %dh às %dh." % [int(l.abre), int(l.fecha)]
	return ""

func abrir_loja(id: String, aba := "comprar") -> void:
	var l: Dictionary = Dados.lojas[id]
	var fechado := _loja_aberta(id)
	if fechado != "":
		mostrar_texto("%s\n\n%s" % [l.nome, fechado])
		return
	var vb := _abrir(l.nome, 700)
	var abas := HBoxContainer.new()
	abas.alignment = BoxContainer.ALIGNMENT_CENTER
	var opcoes := [["comprar", "Comprar"], ["vender", "Vender"]]
	if l.has("melhorias"):
		opcoes.append(["melhorias", "Melhorar ferramentas"])
	if l.has("construcoes"):
		opcoes.append(["construcoes", "Construções"])
	if l.has("animais"):
		opcoes.append(["animais", "Animais"])
	if l.has("receitas"):
		opcoes.append(["receitas", "Receitas"])
	for par in opcoes:
		var b := _botao(par[1], func(): abrir_loja(id, par[0]))
		if par[0] == aba:
			b.modulate = Color(1.2, 1.0, 0.7)
		abas.add_child(b)
	vb.add_child(abas)
	vb.add_child(_label("Moedas: %s" % Hud_milhar(Jogo.dinheiro), 15, COR_TITULO))
	var lista := _rolagem(360)
	match aba:
		"comprar":
			for it in l.itens:
				var item_id: String = it[0]
				var preco: int = it[1]
				var estacoes: Array = it[2]
				if not estacoes.is_empty() and not (Jogo.estacao in estacoes):
					continue
				if Dados.item(item_id).tipo == "ferramenta" and Jogo.contar(item_id) > 0:
					continue
				_linha_item(lista, item_id, "%s — %d moedas" % [Dados.nome_item(item_id), preco], [
					_botao("1", func(): _comprar(item_id, preco, 1, id, aba), Jogo.dinheiro >= preco),
					_botao("5", func(): _comprar(item_id, preco, 5, id, aba), Jogo.dinheiro >= preco * 5 and Dados.item(item_id).tipo != "ferramenta")])
		"vender":
			lista.add_child(_label("A loja paga o preço cheio. (A caixa de venda da fazenda também.)", 13))
			for i in Jogo.inventario.size():
				var s = Jogo.inventario[i]
				if s == null or Dados.item(s.id).tipo == "ferramenta":
					continue
				var p := Dados.preco_venda(s.id, String(s.get("origem", "")), int(s.get("q", 0)))
				if p <= 0:
					continue
				var idx := i
				_linha_item(lista, s.id, "%s x%d — %d cada" % [Dados.nome_item(s.id, String(s.get("origem", ""))), int(s.qtd), p], [
					_botao("Vender 1", func(): _vender(idx, 1, id, aba)), _botao("Tudo", func(): _vender(idx, 999, id, aba))], String(s.get("origem", "")))
		"melhorias":
			_melhorias(lista, id)
		"construcoes":
			_construcoes(lista, id)
		"animais":
			_animais(lista, id)
		"receitas":
			_receitas_loja(lista, id)
	vb.add_child(_botao("Fechar", fechar))

func _comprar(item: String, preco: int, qtd: int, loja: String, aba: String) -> void:
	if not Jogo.cabe(item, qtd):
		Jogo.mensagem.emit("Mochila cheia!")
		return
	if Jogo.gastar(preco * qtd):
		Som.tocar("moeda")
		Jogo.adicionar(item, qtd)
		if item == "vara_fibra" or item == "espada_aco":
			var antigo := "vara" if item == "vara_fibra" else "espada"
			if Jogo.contar(antigo) > 0:
				Jogo.remover(antigo, 1)
	abrir_loja(loja, aba)

func _vender(i: int, qtd: int, loja: String, aba: String) -> void:
	var s = Jogo.inventario[i]
	if s == null:
		return
	var n: int = min(qtd, int(s.qtd))
	Jogo.ganhar(Dados.preco_venda(s.id, String(s.get("origem", "")), int(s.get("q", 0))) * n)
	Som.tocar("moeda")
	Jogo.remover_do_slot(i, n)
	abrir_loja(loja, aba)

const CUSTO_MELHORIA := [[2000, "barra_cobre"], [5000, "barra_ferro"], [10000, "barra_ouro"]]

func _melhorias(lista: VBoxContainer, loja: String) -> void:
	if not Jogo.melhoria.is_empty():
		var f: String = Jogo.melhoria.ferramenta
		if bool(Jogo.melhoria.get("pronta", false)):
			lista.add_child(_label("Sua %s está pronta!" % Dados.nome_item(f).to_lower(), 15))
			lista.add_child(_botao("Buscar", func():
				Jogo.nivel_ferramenta[f] = int(Jogo.melhoria.nivel)
				Jogo.adicionar(f, 1)
				Jogo.melhoria = {}
				abrir_loja(loja, "melhorias")))
		else:
			lista.add_child(_label("Estou trabalhando na sua %s. Volte em alguns dias." % Dados.nome_item(f).to_lower(), 15))
		return
	lista.add_child(_label("A ferramenta fica comigo por 2 dias. Ferramentas melhores gastam menos energia e alcançam mais blocos.", 13))
	for f in ["enxada", "regador", "machado", "picareta"]:
		var nivel := Jogo.nivel_de(f)
		if nivel >= 3:
			lista.add_child(_label("%s: já está no máximo (ouro)." % Dados.nome_item(f), 14))
			continue
		var custo: Array = CUSTO_MELHORIA[nivel]
		var barra: String = custo[1]
		var pode := Jogo.dinheiro >= int(custo[0]) and Jogo.contar(barra) >= 5 and Jogo.contar(f) > 0
		_linha_item(lista, f, "%s → %s\n%d moedas + 5 %s (%d)" % [Dados.nome_item(f), ["cobre", "ferro", "ouro"][nivel], int(custo[0]), Dados.nome_item(barra), Jogo.contar(barra)],
			[_botao("Melhorar", func():
				if Jogo.gastar(int(custo[0])):
					Jogo.remover(barra, 5)
					Jogo.remover(f, 1)
					Jogo.melhoria = {"ferramenta": f, "nivel": nivel + 1, "dia": Jogo.dia_absoluto() + 2}
					abrir_loja(loja, "melhorias"), pode)])

func _construcoes(lista: VBoxContainer, loja: String) -> void:
	for id in Dados.construcoes:
		var c: Dictionary = Dados.construcoes[id]
		var desc := "%s — %d moedas\n%s" % [c.nome, int(c.preco), _ingredientes_texto(c.ing)]
		var pode := Jogo.dinheiro >= int(c.preco) and Jogo.tem_ingredientes(c.ing)
		var disponivel := true
		if c.has("casa"):
			disponivel = Jogo.nivel_casa == int(c.casa) - 1
		elif c.has("melhoria"):
			disponivel = _primeira_sem_melhoria(String(c.melhoria)) != {}
		if not disponivel:
			continue
		lista.add_child(_label(desc, 14))
		lista.add_child(_botao("Construir", func():
			if c.has("casa"):
				Jogo.gastar(int(c.preco))
				Jogo.gastar_ingredientes(c.ing)
				Jogo.nivel_casa = int(c.casa)
				mostrar_texto("Pronto! Sua casa foi ampliada.")
			elif c.has("melhoria"):
				var b := _primeira_sem_melhoria(String(c.melhoria))
				Jogo.gastar(int(c.preco))
				Jogo.gastar_ingredientes(c.ing)
				b.nivel = 1
				mostrar_texto("Pronto! %s foi ampliado." % Dados.construcoes[c.melhoria].nome)
			else:
				fechar()
				principal.call("modo_construcao", id), pode))

func _primeira_sem_melhoria(tipo: String) -> Dictionary:
	for b in Jogo.construcoes:
		if b.tipo == tipo and int(b.get("nivel", 0)) == 0:
			return b
	return {}

func _animais(lista: VBoxContainer, loja: String) -> void:
	lista.add_child(_label("Animais moram no galinheiro (aves) ou no estábulo. Cada construção tem 4 vagas (8 quando ampliada). Alimente com feno no cocho.", 13))
	for id in Dados.animais:
		var a: Dictionary = Dados.animais[id]
		var casa := _casa_com_vaga(String(a.casa), int(a.get("req_nivel", 0)))
		var motivo := ""
		if casa.is_empty():
			motivo = " (precisa de %s%s com vaga)" % [Dados.construcoes[a.casa].nome.to_lower(), " grande" if int(a.get("req_nivel", 0)) > 0 else ""]
		_linha_item(lista, "ovo" if a.casa == "galinheiro" else "leite", "%s — %d moedas%s" % [a.nome, int(a.preco), motivo], [_botao("Comprar", func():
			if Jogo.gastar(int(a.preco)):
				var nomes := ["Pipoca", "Mimosa", "Estrela", "Biscoito", "Nuvem", "Paçoca", "Bolinha", "Canela", "Tapioca", "Jabuti", "Cocada", "Pitanga"]
				var nome: String = nomes[Jogo.rng.randi() % nomes.size()]
				Jogo.animais.append({"id": Jogo.novo_id(), "tipo": id, "nome": nome, "casa": int(casa.id), "amizade": 100, "dias": 0, "produto": "", "carinho": false})
				Jogo.somar_stat("animais_comprados")
				mostrar_texto("%s, %s, já está no seu %s. Cuide bem!" % [nome, String(a.nome).to_lower(), Dados.construcoes[a.casa].nome.to_lower()]), not casa.is_empty() and Jogo.dinheiro >= int(a.preco))])

func _casa_com_vaga(tipo: String, req_nivel: int) -> Dictionary:
	for b in Jogo.construcoes:
		if b.tipo != tipo or int(b.get("nivel", 0)) < req_nivel:
			continue
		var vagas := int(Dados.construcoes[tipo].vagas) * (2 if int(b.get("nivel", 0)) > 0 else 1)
		var ocupadas := 0
		for a in Jogo.animais:
			if int(a.casa) == int(b.id):
				ocupadas += 1
		if ocupadas < vagas:
			return b
	return {}

func _receitas_loja(lista: VBoxContainer, loja: String) -> void:
	lista.add_child(_label("Receitas para cozinhar no fogão de casa (precisa da cozinha, feita pela Rosa).", 13))
	for r in Dados.receitas_cozinha:
		if r in Jogo.receitas_cozinha_conhecidas:
			continue
		var preco: int = Dados.item(r).preco * 4
		_linha_item(lista, r, "Receita: %s — %d moedas\n%s" % [Dados.nome_item(r), preco, _ingredientes_texto(Dados.receitas_cozinha[r].ing)],
			[_botao("Aprender", func():
				if Jogo.gastar(preco):
					Jogo.receitas_cozinha_conhecidas.append(r)
					abrir_loja(loja, "receitas"), Jogo.dinheiro >= preco)])

# ---------------------------------------------------------------- cozinha

func abrir_cozinha() -> void:
	var vb := _abrir("Fogão", 620)
	var lista := _rolagem(360)
	for r in Jogo.receitas_cozinha_conhecidas:
		var rec: Dictionary = Dados.receitas_cozinha[r]
		_linha_item(lista, r, "%s (+%d energia)\n%s" % [Dados.nome_item(r), int(Dados.item(r).energia), _ingredientes_texto(rec.ing)], [_botao("Cozinhar", func():
			if Jogo.tem_ingredientes(rec.ing) and Jogo.cabe(r):
				Jogo.gastar_ingredientes(rec.ing)
				Jogo.adicionar(r, 1, "", 0, true)
				Jogo.somar_stat("pratos")
				abrir_cozinha(), Jogo.tem_ingredientes(rec.ing))])
	vb.add_child(_label("Aprenda mais receitas na Taverna da Lia.", 13))
	vb.add_child(_botao("Fechar", fechar))

# ---------------------------------------------------------------- mural e salão

func abrir_mural() -> void:
	var vb := _abrir("Mural de pedidos", 520)
	if Jogo.pedido.is_empty():
		vb.add_child(_label("Nenhum pedido hoje. Volte amanhã!", 15))
	else:
		var p: Dictionary = Jogo.pedido
		var prazo := int(p.prazo) - Jogo.dia_absoluto()
		vb.add_child(_label("%s precisa de %d %s.\nRecompensa: %d moedas e amizade.\nPrazo: %s.\n\nEntregue falando com %s com o item na mão." % [
			Dados.aldeoes[p.npc].nome, int(p.qtd), Dados.nome_item(p.item), int(p.recompensa), "hoje" if prazo <= 0 else "%d dia(s)" % prazo, Dados.aldeoes[p.npc].nome], 15))
		vb.add_child(_label("Você tem: %d" % Jogo.contar(p.item), 14))
	vb.add_child(_botao("Fechar", fechar))

func abrir_colecoes() -> void:
	var vb := _abrir("Salão da Vila — Coleções", 720)
	vb.add_child(_label("Doe itens para completar as coleções. Cada coleção completa dá um prêmio. Todas completas reformam a estufa da sua fazenda.", 13))
	var lista := _rolagem(380)
	for cid in Dados.colecoes:
		var col: Dictionary = Dados.colecoes[cid]
		var completa: bool = cid in Jogo.colecoes_completas
		lista.add_child(_label("%s %s — prêmio: %d %s" % ["★" if completa else "☆", col.nome, int(col.premio[1]), Dados.nome_item(col.premio[0])], 16, COR_TITULO))
		if completa:
			continue
		var entregues: Dictionary = Jogo.colecoes_entregues.get(cid, {})
		var hb := HBoxContainer.new()
		for item in col.itens:
			var precisa := int(col.itens[item])
			var tem := int(entregues.get(item, 0))
			var caixa := VBoxContainer.new()
			var s := SlotUI.new()
			s.item_fixo = {"id": item, "qtd": precisa}
			s.escurecido = tem < precisa
			caixa.add_child(s)
			if tem < precisa:
				caixa.add_child(_botao("Doar", func(): _doar(cid, item), Jogo.contar(item) > 0))
			else:
				caixa.add_child(_label("✔", 14))
			hb.add_child(caixa)
		lista.add_child(hb)
	vb.add_child(_botao("Fechar", fechar))

func _doar(cid: String, item: String) -> void:
	var col: Dictionary = Dados.colecoes[cid]
	if not Jogo.colecoes_entregues.has(cid):
		Jogo.colecoes_entregues[cid] = {}
	var ent: Dictionary = Jogo.colecoes_entregues[cid]
	var falta := int(col.itens[item]) - int(ent.get(item, 0))
	var por: int = min(falta, Jogo.contar(item))
	if por <= 0:
		return
	Jogo.remover(item, por)
	ent[item] = int(ent.get(item, 0)) + por
	var completa := true
	for i in col.itens:
		if int(ent.get(i, 0)) < int(col.itens[i]):
			completa = false
	if completa:
		Jogo.colecoes_completas.append(cid)
		Jogo.adicionar(String(col.premio[0]), int(col.premio[1]), "", 0, true)
		Jogo.mensagem.emit("%s completa!" % col.nome)
		if Jogo.colecoes_completas.size() >= Dados.colecoes.size():
			Jogo.flags["estufa"] = true
			Jogo.conquistar("colecoes")
			mostrar_texto("Todas as coleções completas!\n\nO prefeito Augusto mandou reformar a estufa da sua fazenda. Lá dentro, qualquer semente cresce em qualquer estação.\n\nObrigado por trazer o vale de volta à vida.")
			return
	abrir_colecoes()

# ---------------------------------------------------------------- mapa

const CORES_MAPA := {0: "#5a9a3a", 1: "#3a7a2a", 2: "#8aaa4a", 3: "#c8955a", 4: "#a8754a", 5: "#8a5a3a", 6: "#e0c890",
	7: "#4a7a3a", 8: "#3a7ac8", 9: "#9a6a42", 10: "#5a3a2a", 11: "#7a6a5a", 12: "#101010", 13: "#8a2a2a"}
const NOMES_LUGARES := {"fazenda": "Fazenda", "vila": "Vila", "floresta": "Bosque do Rio", "montanha": "Montanha", "casa": "Casa", "estufa": "Estufa"}

func abrir_mapa() -> void:
	var m: Mapa = principal.mapa
	if m == null:
		return
	var vb := _abrir("Mapa — " + String(NOMES_LUGARES.get(m.nome, "Mina" if m.andar > 0 else "Interior")), 780)
	var area := Control.new()
	var escala: float = min(740.0 / m.w, 420.0 / m.h)
	area.custom_minimum_size = Vector2(m.w * escala, m.h * escala)
	area.draw.connect(func():
		for y in m.h:
			for x in m.w:
				var c := Vector2i(x, y)
				var cor := Color(CORES_MAPA.get(m.material(c), "#000000"))
				if m.bloqueio[m.idx(c)] != 0:
					cor = cor.darkened(0.45)
				var o := m.objeto(c)
				if not o.is_empty() and (o.tipo == "arvore" or o.tipo == "pinheiro" or o.tipo == "frutifera"):
					cor = Color("#2a5a20")
				area.draw_rect(Rect2(x * escala, y * escala, escala + 0.5, escala + 0.5), cor)
		for k in m.est.solo:
			var c2 := Jogo.celula(k)
			area.draw_rect(Rect2(c2.x * escala, c2.y * escala, escala, escala), Color("#6a3a1a"))
		var fonte := area.get_theme_default_font()
		for b in m.construcoes_fixas:
			var r: Rect2i = b.rect
			var rr := Rect2(r.position.x * escala, r.position.y * escala, r.size.x * escala, r.size.y * escala)
			area.draw_rect(rr, Color("#a8643a"))
			area.draw_rect(rr, Color("#3a2010"), false, 1.5)
			if String(b.get("rotulo", "")) != "":
				area.draw_string_outline(fonte, rr.position + Vector2(0, rr.size.y + 12), String(b.rotulo), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color.BLACK)
				area.draw_string(fonte, rr.position + Vector2(0, rr.size.y + 12), String(b.rotulo), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		for s in m.saidas:
			var r2: Rect2i = s.rect
			var p := Vector2((r2.position.x + r2.size.x / 2.0) * escala, (r2.position.y + r2.size.y / 2.0) * escala)
			area.draw_circle(p, 5, Color("#f8e858"))
			var nome := String(NOMES_LUGARES.get(String(s.destino), ""))
			if nome != "" and r2.size.x * r2.size.y > 1:
				area.draw_string_outline(fonte, p + Vector2(-20, -8), "→ " + nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color.BLACK)
				area.draw_string(fonte, p + Vector2(-20, -8), "→ " + nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f8e858"))
		for id in principal.npcs:
			var n = principal.npcs[id]
			var pn: Vector2 = n.position / Mapa.T * escala
			area.draw_circle(pn, 4, Dados.aldeoes[id].cor)
			area.draw_string_outline(fonte, pn + Vector2(5, 4), Dados.aldeoes[id].nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color.BLACK)
			area.draw_string(fonte, pn + Vector2(5, 4), Dados.aldeoes[id].nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		var pj: Vector2 = principal.jogador.position / Mapa.T * escala
		area.draw_circle(pj, 6, Color.WHITE)
		area.draw_circle(pj, 4.5, Color("#e8402a")))
	var centro := CenterContainer.new()
	centro.add_child(area)
	vb.add_child(centro)
	vb.add_child(_label("Fazenda ↔ Vila (leste) · Fazenda ↔ Bosque do Rio (sul) · Fazenda ↔ Montanha (norte) · Vila ↔ Montanha (norte) · Vila ↔ Bosque (sul)", 12))
	vb.add_child(_botao("Fechar", fechar))

# ---------------------------------------------------------------- mina

func abrir_elevador() -> void:
	var vb := _abrir("Elevador da mina", 460)
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	var andares := [1]
	for a in range(5, Jogo.mina_andar_max + 1, 5):
		andares.append(a)
	for a in andares:
		g.add_child(_botao("Andar %d" % a, func():
			fechar()
			principal.entrar_mina(a)))
	vb.add_child(g)
	vb.add_child(_botao("Voltar à superfície" if principal.mapa.andar > 0 else "Fechar", func():
		fechar()
		if principal.mapa.andar > 0:
			principal.ir_para("montanha", Vector2i(24, 5))))

# ---------------------------------------------------------------- festivais

func abrir_festival() -> void:
	var f := Jogo.festival_hoje()
	var vb := _abrir(f.nome, 600)
	var chave := "festival_%d" % Jogo.dia_absoluto()
	vb.add_child(_label(String(f.desc), 15))
	if Jogo.flags.has(chave):
		vb.add_child(_label("Você já participou hoje. Aproveite a festa!", 15))
		vb.add_child(_botao("Fechar", fechar))
		return
	match String(f.tipo):
		"danca":
			vb.add_child(_label("Com quem você quer dançar? (Precisa de 4 corações.)", 14))
			for id in Dados.aldeoes:
				if Dados.aldeoes[id].casavel:
					vb.add_child(_botao(Dados.aldeoes[id].nome, func():
						Jogo.flags[chave] = true
						Jogo.mudar_amizade(id, 150)
						mostrar_dialogo(id, "Seria uma honra! (Vocês dançam até o sol se pôr.)"), Jogo.coracoes(id) >= 4))
		"sopa":
			var s = Jogo.selecionado()
			vb.add_child(_label("Segure um ingrediente na mão para colocar na sopa.", 14))
			if s != null and Dados.item(s.id).tipo != "ferramenta":
				vb.add_child(_botao("Colocar %s na sopa" % Dados.nome_item(s.id), func():
					Jogo.flags[chave] = true
					var valor := Dados.preco_venda(s.id, String(s.get("origem", "")), int(s.get("q", 0)))
					var ruim: bool = Dados.item(s.id).tipo == "lixo" or s.id == "gosma"
					Jogo.remover_do_slot(Jogo.slot)
					for id in Dados.aldeoes:
						Jogo.mudar_amizade(id, -50 if ruim else (60 if valor >= 150 else 20))
					mostrar_texto("Todos provam a sopa..." + ("\n\nEca! Ninguém gostou." if ruim else ("\n\nUma delícia! A vila inteira adorou." if valor >= 150 else "\n\nFicou boa!")))))
		"feira":
			var s2 = Jogo.selecionado()
			vb.add_child(_label("Segure seu melhor produto na mão para expor na feira.", 14))
			if s2 != null and Dados.item(s2.id).tipo != "ferramenta":
				vb.add_child(_botao("Expor %s" % Dados.nome_item(s2.id), func():
					Jogo.flags[chave] = true
					var pontos := Dados.preco_venda(s2.id, String(s2.get("origem", "")), int(s2.get("q", 0))) + Jogo.colecoes_completas.size() * 50
					var premio := 0
					var lugar := "participação"
					if pontos >= 400:
						premio = 2000
						lugar = "1º lugar"
					elif pontos >= 200:
						premio = 1000
						lugar = "2º lugar"
					elif pontos >= 80:
						premio = 500
						lugar = "3º lugar"
					Jogo.ganhar(premio)
					mostrar_texto("Os jurados avaliaram seu produto: %s!\nPrêmio: %d moedas." % [lugar, premio])))
		"presentes":
			var ids := Dados.aldeoes.keys()
			var amigo: String = ids[Jogo.dia_absoluto() % ids.size()]
			vb.add_child(_label("Seu amigo secreto é %s. Segure um presente na mão." % Dados.aldeoes[amigo].nome, 14))
			var s3 = Jogo.selecionado()
			if s3 != null and Dados.item(s3.id).tipo != "ferramenta":
				vb.add_child(_botao("Dar %s" % Dados.nome_item(s3.id), func():
					Jogo.flags[chave] = true
					var d: Dictionary = Dados.aldeoes[amigo]
					Jogo.mudar_amizade(amigo, 200 if s3.id in d.ama else 100)
					Jogo.remover_do_slot(Jogo.slot)
					var ganho: String = ["diamante", "anel_orvalho", "aspersor_bom", "torta_morango", "cafe"][Jogo.rng.randi() % 5]
					if ganho == "anel_orvalho" and Jogo.conjuge != "":
						ganho = "cafe"
					Jogo.adicionar(ganho, 1)
					mostrar_texto("%s adorou! E você também ganhou um presente: %s." % [d.nome, Dados.nome_item(ganho)])))
	vb.add_child(_botao("Fechar", fechar))

# ---------------------------------------------------------------- fim do dia e cartas

func mostrar_relatorio(rel: Dictionary, depois: Callable) -> void:
	var vb := _abrir("Fim do dia", 560)
	if rel.vendas.is_empty():
		vb.add_child(_label("Nada foi vendido hoje.", 15))
	else:
		var lista := _rolagem(200)
		for v in rel.vendas:
			lista.add_child(_label("%s x%d — %d moedas" % [v[0], int(v[1]), int(v[2])], 14))
		vb.add_child(_label("Total: %d moedas" % int(rel.total), 17, COR_TITULO))
		Som.tocar("moeda", 1.0, false)
	for e in rel.eventos:
		vb.add_child(_label("• " + String(e), 14))
	vb.add_child(_label("Bom dia! %s. Jogo salvo." % Jogo.texto_data(), 15))
	vb.add_child(_botao("Continuar", fechar))
	_pausou = true
	_ao_fechar = depois

func mostrar_cartas() -> void:
	if Jogo.cartas.is_empty():
		return
	var carta: Dictionary = Jogo.cartas.pop_front()
	var vb := _abrir("✉ " + String(carta.titulo), 520)
	vb.add_child(_label(String(carta.texto), 15))
	for par in carta.get("itens", []):
		Jogo.adicionar(String(par[0]), int(par[1]), "", 0, true)
	vb.add_child(_botao("OK", fechar))
	_ao_fechar = func():
		if not Jogo.cartas.is_empty():
			mostrar_cartas()

# ---------------------------------------------------------------- pesca

func pescar(lugar: String, alvo := Vector2.ZERO, mao := Vector2.ZERO) -> void:
	if _pesca:
		return
	Jogo.pausado = true
	_pesca = Control.new()
	_pesca.set_script(preload("res://scripts/pesca.gd"))
	_pesca.set("lugar", lugar)
	_pesca.set("alvo_mundo", alvo)
	_pesca.set("mao_mundo", mao)
	_pesca.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_pesca)
	_pesca.tree_exited.connect(func():
		_pesca = null
		Jogo.pausado = false)
