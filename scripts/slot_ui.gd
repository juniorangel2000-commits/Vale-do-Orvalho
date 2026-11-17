class_name SlotUI
extends Control
## Um quadradinho de item (mochila, baú, barra). Desenha ícone, quantidade e qualidade.

signal clicado(slot: SlotUI, botao: int)

var lista: Array = []
var indice := 0
var destaque := false
var item_fixo := {}   # para mostrar um item que não está numa lista (lojas, receitas)
var escurecido := false

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(44, 44)
	tooltip_text = " "
	mouse_filter = Control.MOUSE_FILTER_STOP

func conteudo():
	if not item_fixo.is_empty():
		return item_fixo
	if indice < lista.size():
		return lista[indice]
	return null

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("#f2dfb4"))
	draw_rect(r.grow(-2), Color("#e3c993"))
	draw_rect(r, Color("#7a4e2e"), false, 2.0)
	if destaque:
		draw_rect(r.grow(-1), Color("#e8402a"), false, 3.0)
	var s = conteudo()
	if s == null:
		return
	Desenho.icone(self, String(s.id), r.grow(-4), String(s.get("origem", "")))
	if escurecido:
		draw_rect(r.grow(-2), Color(0.2, 0.15, 0.1, 0.55))
	var q := int(s.get("q", 0))
	if q > 0:
		var cor: Color = [Color.WHITE, Color("#c0c0c8"), Color("#f0c83a"), Color("#a86ad8")][q]
		draw_circle(Vector2(8, size.y - 8), 5, Color("#3a2a1a"))
		draw_circle(Vector2(8, size.y - 8), 4, cor)
	var qtd := int(s.get("qtd", 1))
	if qtd > 1:
		var fonte := get_theme_default_font()
		var texto := str(qtd)
		var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string_outline(fonte, Vector2(size.x - largura - 4, size.y - 4), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color("#3a2010"))
		draw_string(fonte, Vector2(size.x - largura - 4, size.y - 4), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	if String(s.id) == "regador":
		var cheio := float(Jogo.flags.get("agua", 40)) / Acoes.capacidade_regador()
		draw_rect(Rect2(4, size.y - 6, (size.x - 8) * cheio, 3), Color("#4aa8e8"))

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		clicado.emit(self, ev.button_index)
		accept_event()

func _get_tooltip(_pos: Vector2) -> String:
	var s = conteudo()
	if s == null:
		return ""
	return Ui.descricao_item(s)
