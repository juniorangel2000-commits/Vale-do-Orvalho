class_name Mapa
extends Node2D
## Um lugar do jogo (fazenda, vila, casa, andar da mina...). O terreno e as paredes vêm do
## gerador; o que muda (objetos, solo arado, plantas) fica em Jogo.mapas[nome].

const T := 32
enum M { GRAMA, FLORESTA, CAMPO, ESTRADA, ESTRADA_UMIDA, TERRA, AREIA, MUSGO, AGUA, PISO, PAREDE, ROCHA, VAZIO, TAPETE }
const TEXTURAS := ["grass", "forest", "meadow", "path-dry", "path-wet", "soil", "sand", "moss", "water"]

## Objetos que bloqueiam a passagem.
const SOLIDOS := ["arvore", "pinheiro", "toco", "pedra", "rocha", "minerio", "galho", "bau", "espantalho", "aspersor",
	"aspersor_bom", "barril", "conserveiro", "fornalha", "forno_carvao", "prensa_queijo", "batedeira", "tear", "caixa_abelha",
	"tocha", "cerca", "caixa_envio", "arbusto", "deco_solida", "poco", "fogao", "cama", "cocho", "mural", "colecoes", "pedra_mina",
	"caixa_gelo", "estatua", "mesa"]

var nome := ""
var w := 10
var h := 10
var terreno := PackedByteArray()
var bloqueio := PackedByteArray()
var tipo_agua := "lago"
var interior := false
var escuro := false
var andar := 0
var saidas: Array = []
var interativos := {}
var construcoes_fixas: Array = []   # {rect: Rect2i, textura, largura, cor, rotulo}
var decoracoes: Array = []          # {c: Vector2i, arte, largura, cor}: árvores de borda, flores...
var construcao_id := 0              # interiores de galinheiro/estábulo
var est: Dictionary = {}
var musica := ""

var chao: Node2D
var agua_no: Node2D
var lavoura: Node2D
var objetos: Node2D
var visuais := {}
var texturas := {}

func _init(nome_mapa := "") -> void:
	nome = nome_mapa

func preparar(largura: int, altura: int, material := M.GRAMA) -> void:
	w = largura
	h = altura
	terreno = PackedByteArray()
	terreno.resize(w * h)
	terreno.fill(material)
	bloqueio = PackedByteArray()
	bloqueio.resize(w * h)
	bloqueio.fill(0)

func construir(dados_extra := {}) -> void:
	for t in TEXTURAS:
		texturas[t] = load("res://arte/terreno/%s.png" % t)
	est = Jogo.estado_mapa(nome)
	Geradores.gerar(self, dados_extra)
	est.iniciado = true
	chao = Node2D.new()
	chao.set_script(preload("res://scripts/chao.gd"))
	chao.set("mapa", self)
	chao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	chao.z_index = -20
	add_child(chao)
	agua_no = Node2D.new()
	agua_no.set_script(preload("res://scripts/agua.gd"))
	agua_no.set("mapa", self)
	agua_no.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	agua_no.z_index = -19
	add_child(agua_no)
	lavoura = Node2D.new()
	lavoura.set_script(preload("res://scripts/lavoura.gd"))
	lavoura.set("mapa", self)
	lavoura.z_index = -10
	add_child(lavoura)
	objetos = Node2D.new()
	objetos.y_sort_enabled = true
	add_child(objetos)
	for b in construcoes_fixas:
		_criar_construcao_visual(b)
	for d in decoracoes:
		_criar_decoracao(d)
	for k in est.objetos.keys():
		_criar_visual(Jogo.celula(k))

# ---------------------------------------------------------------- consultas

func dentro(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h

func idx(c: Vector2i) -> int:
	return c.y * w + c.x

func material(c: Vector2i) -> int:
	if not dentro(c):
		return M.VAZIO
	return terreno[idx(c)]

func por_material(c: Vector2i, m: int) -> void:
	if dentro(c):
		terreno[idx(c)] = m

func bloquear(c: Vector2i, valor := 1) -> void:
	if dentro(c):
		bloqueio[idx(c)] = valor

func agua(c: Vector2i) -> bool:
	return material(c) == M.AGUA

func solido(c: Vector2i) -> bool:
	if not dentro(c):
		return true
	var m := material(c)
	if m == M.AGUA or m == M.PAREDE or m == M.VAZIO:
		return true
	if bloqueio[idx(c)] != 0:
		return true
	var o := objeto(c)
	if not o.is_empty() and (o.tipo in SOLIDOS):
		return true
	return false

func celula_de(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.y / T))

func centro(c: Vector2i) -> Vector2:
	return Vector2(c.x * T + T / 2.0, c.y * T + T / 2.0)

func objeto(c: Vector2i) -> Dictionary:
	var k := Jogo.chave(c)
	if est.objetos.has(k):
		return est.objetos[k]
	return {}

func solo(c: Vector2i) -> Dictionary:
	var k := Jogo.chave(c)
	if est.solo.has(k):
		return est.solo[k]
	return {}

func aravel(c: Vector2i) -> bool:
	if not dentro(c) or bloqueio[idx(c)] != 0:
		return false
	if nome != "fazenda" and nome != "estufa":
		return false
	var m := material(c)
	return m == M.GRAMA or m == M.TERRA or m == M.CAMPO

func saida_em(c: Vector2i) -> Dictionary:
	for s in saidas:
		var r: Rect2i = s.rect
		if r.has_point(c):
			return s
	return {}

func area_livre(origem: Vector2i, tam: Vector2i) -> bool:
	for x in tam.x:
		for y in tam.y:
			var c := origem + Vector2i(x, y)
			if solido(c) or not est.solo.get(Jogo.chave(c), {}).is_empty() or interativos.has(Jogo.chave(c)):
				return false
			if not objeto(c).is_empty():
				return false
	return true

# ---------------------------------------------------------------- alterações

func por_objeto(c: Vector2i, o: Dictionary) -> void:
	est.objetos[Jogo.chave(c)] = o
	_criar_visual(c)

func remover_objeto(c: Vector2i) -> void:
	var k := Jogo.chave(c)
	est.objetos.erase(k)
	if visuais.has(k):
		visuais[k].queue_free()
		visuais.erase(k)

func atualizar_objeto(c: Vector2i) -> void:
	var k := Jogo.chave(c)
	if visuais.has(k):
		visuais[k].queue_redraw()

func por_solo(c: Vector2i, s: Dictionary) -> void:
	est.solo[Jogo.chave(c)] = s
	redesenhar()

func remover_solo(c: Vector2i) -> void:
	est.solo.erase(Jogo.chave(c))
	redesenhar()

func redesenhar() -> void:
	if lavoura:
		lavoura.queue_redraw()

func redesenhar_chao() -> void:
	if chao:
		chao.queue_redraw()

func _criar_visual(c: Vector2i) -> void:
	var k := Jogo.chave(c)
	if visuais.has(k):
		visuais[k].queue_free()
	var o := objeto(c)
	if o.is_empty():
		return
	var v := ObjetoVisual.new()
	v.mapa = self
	v.celula = c
	v.position = Vector2(c.x * T + T / 2.0, c.y * T + T - 2)
	objetos.add_child(v)
	visuais[k] = v

func _criar_construcao_visual(b: Dictionary) -> void:
	var r: Rect2i = b.rect
	var s := Sprite2D.new()
	var tex: Texture2D = load(b.textura)
	s.texture = tex
	var largura := r.size.x * T * float(b.get("largura", 1.0))
	var escala := largura / tex.get_width()
	s.scale = Vector2(escala, escala)
	s.centered = false
	s.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	s.position = Vector2((r.position.x + r.size.x / 2.0) * T, (r.position.y + r.size.y) * T + float(b.get("desce", 0.0)))
	if b.has("cor"):
		s.modulate = b.cor
	objetos.add_child(s)
	if b.has("rotulo") and String(b.rotulo) != "":
		var placa := Label.new()
		placa.text = b.rotulo
		placa.add_theme_font_size_override("font_size", 9)
		placa.add_theme_color_override("font_color", Color("#fff6dc"))
		placa.add_theme_color_override("font_outline_color", Color("#2a1a10"))
		placa.add_theme_constant_override("outline_size", 4)
		placa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placa.size = Vector2(r.size.x * T, 14)
		placa.position = Vector2(r.position.x * T, (r.position.y + r.size.y) * T + 2)
		placa.z_index = 5
		add_child(placa)

func _criar_decoracao(d: Dictionary) -> void:
	var s := Sprite2D.new()
	var tex := ObjetoVisual.textura(String(d.arte))
	s.texture = tex
	var escala := float(d.largura) / tex.get_width()
	s.scale = Vector2(escala, escala)
	s.offset = Vector2(0, -tex.get_height() / 2.0)
	var c: Vector2i = d.c
	s.position = Vector2(c.x * T + T / 2.0, c.y * T + T - 2)
	if d.has("cor"):
		s.modulate = d.cor
	elif String(d.arte).begins_with("asset-tree") and Jogo.estacao == 2:
		s.modulate = Color(1.35, 0.85, 0.5)
	elif Jogo.estacao == 3 and not interior:
		s.modulate = Color(1.12, 1.15, 1.25)
	objetos.add_child(s)

## Áreas onde nascem forrageiros (guardadas no estado para o Jogo usar à noite).
func marcar_area_forragem(celulas: Array) -> void:
	var lista := []
	for c in celulas:
		lista.append(Jogo.chave(c))
	est.areas_forragem = lista
