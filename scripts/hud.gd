extends CanvasLayer
## Interface sempre visível: relógio e data, dinheiro, energia/vida, barra de itens e mensagens.

var principal: Node
var _relogio: Label
var _dinheiro: Label
var _barra: HBoxContainer
var _slots: Array = []
var _mensagens: VBoxContainer
var _energia: Control
var _local: Label
var _objetivo: PanelContainer
var _objetivo_texto: Label

func _ready() -> void:
	# Relógio
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", Ui.estilo_painel())
	painel.anchor_left = 1.0
	painel.anchor_right = 1.0
	painel.offset_left = -230
	painel.offset_right = -10
	painel.offset_top = 10
	add_child(painel)
	var vb := VBoxContainer.new()
	painel.add_child(vb)
	_relogio = Label.new()
	_relogio.add_theme_color_override("font_color", Color("#3a2010"))
	_relogio.add_theme_font_size_override("font_size", 15)
	vb.add_child(_relogio)
	_dinheiro = Label.new()
	_dinheiro.add_theme_color_override("font_color", Color("#6a3a10"))
	_dinheiro.add_theme_font_size_override("font_size", 17)
	_dinheiro.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(_dinheiro)
	_local = Label.new()
	_local.add_theme_color_override("font_color", Color("#5a4030"))
	_local.add_theme_font_size_override("font_size", 12)
	vb.add_child(_local)
	# Barra de itens
	var fundo := PanelContainer.new()
	fundo.add_theme_stylebox_override("panel", Ui.estilo_painel())
	fundo.anchor_left = 0.5
	fundo.anchor_right = 0.5
	fundo.anchor_top = 1.0
	fundo.anchor_bottom = 1.0
	fundo.offset_left = -290
	fundo.offset_right = 290
	fundo.offset_top = -70
	fundo.offset_bottom = -10
	add_child(fundo)
	_barra = HBoxContainer.new()
	_barra.add_theme_constant_override("separation", 3)
	_barra.alignment = BoxContainer.ALIGNMENT_CENTER
	fundo.add_child(_barra)
	for i in 12:
		var s := SlotUI.new()
		s.indice = i
		s.clicado.connect(_slot_clicado)
		_barra.add_child(s)
		_slots.append(s)
	# Energia e vida
	_energia = Control.new()
	_energia.set_script(preload("res://scripts/barras.gd"))
	_energia.anchor_left = 1.0
	_energia.anchor_right = 1.0
	_energia.anchor_top = 1.0
	_energia.anchor_bottom = 1.0
	_energia.offset_left = -70
	_energia.offset_right = -10
	_energia.offset_top = -200
	_energia.offset_bottom = -10
	_energia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_energia)
	# Mensagens
	_mensagens = VBoxContainer.new()
	_mensagens.anchor_top = 1.0
	_mensagens.anchor_bottom = 1.0
	_mensagens.offset_left = 12
	_mensagens.offset_right = 380
	_mensagens.offset_top = -260
	_mensagens.offset_bottom = -80
	_mensagens.alignment = BoxContainer.ALIGNMENT_END
	_mensagens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mensagens)
	_objetivo = PanelContainer.new()
	_objetivo.add_theme_stylebox_override("panel", Ui.estilo_painel(Color("#f2dfb4", 0.92)))
	_objetivo.position = Vector2(10, 10)
	_objetivo.custom_minimum_size = Vector2(330, 0)
	_objetivo.visible = false
	var vbo := VBoxContainer.new()
	_objetivo.add_child(vbo)
	var t := Label.new()
	t.text = "Objetivo"
	t.add_theme_color_override("font_color", Color("#6a2a10"))
	t.add_theme_font_size_override("font_size", 14)
	vbo.add_child(t)
	_objetivo_texto = Label.new()
	_objetivo_texto.add_theme_color_override("font_color", Color("#3a2010"))
	_objetivo_texto.add_theme_font_size_override("font_size", 13)
	_objetivo_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objetivo_texto.custom_minimum_size = Vector2(306, 0)
	vbo.add_child(_objetivo_texto)
	add_child(_objetivo)
	Jogo.inventario_mudou.connect(atualizar)
	Jogo.dinheiro_mudou.connect(atualizar)
	Jogo.energia_mudou.connect(atualizar)
	Jogo.mensagem.connect(_mensagem)

func atualizar() -> void:
	if _relogio == null:
		return
	var climas := {"sol": "☀", "chuva": "☂", "neve": "❄"}
	_relogio.text = "%s  %s\n%s  Ano %d" % [Jogo.texto_hora(), climas.get(Jogo.clima, ""), Jogo.texto_data(), Jogo.ano]
	_dinheiro.text = "%s moedas" % _milhar(Jogo.dinheiro)
	var lugar := ""
	if principal and principal.mapa:
		var m: Mapa = principal.mapa
		lugar = {"fazenda": "Fazenda " + Jogo.nome_fazenda, "vila": "Vila do Orvalho", "floresta": "Bosque do Rio", "montanha": "Montanha",
			"casa": "Sua casa", "estufa": "Estufa"}.get(m.nome, "")
		if m.andar > 0:
			lugar = "Mina — andar %d" % m.andar
		elif m.construcao_id > 0:
			lugar = Dados.construcoes[Jogo.construcao_por_id(m.construcao_id).get("tipo", "galinheiro")].nome
	_local.text = lugar
	for i in 12:
		var s: SlotUI = _slots[i]
		s.lista = Jogo.inventario
		s.destaque = i == Jogo.slot
		s.queue_redraw()
	_energia.queue_redraw()

static func _milhar(n: int) -> String:
	var t := str(abs(n))
	var r := ""
	while t.length() > 3:
		r = "." + t.substr(t.length() - 3) + r
		t = t.substr(0, t.length() - 3)
	return ("-" if n < 0 else "") + t + r

func mostrar_objetivo(texto: String) -> void:
	if _objetivo == null:
		return
	_objetivo.visible = texto != ""
	if _objetivo_texto.text != texto:
		_objetivo_texto.text = texto
		_objetivo.reset_size()

func _slot_clicado(s: SlotUI, botao: int) -> void:
	if botao == MOUSE_BUTTON_LEFT:
		Jogo.slot = s.indice
		atualizar()

func _mensagem(texto: String) -> void:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color("#fff6dc"))
	l.add_theme_color_override("font_outline_color", Color("#2a1a10"))
	l.add_theme_constant_override("outline_size", 5)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mensagens.add_child(l)
	while _mensagens.get_child_count() > 6:
		_mensagens.get_child(0).queue_free()
		_mensagens.remove_child(_mensagens.get_child(0))
	var t := l.create_tween()
	t.tween_interval(4.0)
	t.tween_property(l, "modulate:a", 0.0, 1.0)
	t.tween_callback(l.queue_free)
