extends Node2D
## Água animada: a textura corre devagar. Redesenha poucas vezes por segundo.

var mapa: Mapa
var _tempo := 0.0
var _celulas: Array = []

func _ready() -> void:
	for y in mapa.h:
		for x in mapa.w:
			if mapa.material(Vector2i(x, y)) == Mapa.M.AGUA:
				_celulas.append(Vector2i(x, y))

func _process(delta: float) -> void:
	_tempo += delta
	if not _celulas.is_empty() and Engine.get_process_frames() % 6 == 0:
		queue_redraw()

func _draw() -> void:
	if _celulas.is_empty():
		return
	var T := Mapa.T
	var tex: Texture2D = mapa.texturas["water"]
	var desloc := int(_tempo * 6.0) % 96
	var cor := Color.WHITE
	if Jogo.estacao == 3:
		cor = Color(1.1, 1.2, 1.35)
	for c in _celulas:
		var r := Rect2(c.x * T, c.y * T, T, T)
		var ox := (c.x * T + desloc) % 96
		var oy := (c.y * T) % 96
		var largura: int = min(T, 96 - ox)
		draw_texture_rect_region(tex, Rect2(r.position, Vector2(largura, T)), Rect2(ox, oy, largura, T), cor)
		if largura < T:
			draw_texture_rect_region(tex, Rect2(r.position + Vector2(largura, 0), Vector2(T - largura, T)), Rect2(0, oy, T - largura, T), cor)
		# margem: escurece a borda que encosta em terra
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not mapa.agua(c + d) and mapa.dentro(c + d):
				var borda := Rect2(r.position, Vector2(T, 4))
				if d == Vector2i.DOWN:
					borda = Rect2(r.position + Vector2(0, T - 4), Vector2(T, 4))
				elif d == Vector2i.LEFT:
					borda = Rect2(r.position, Vector2(4, T))
				elif d == Vector2i.RIGHT:
					borda = Rect2(r.position + Vector2(T - 4, 0), Vector2(4, T))
				draw_rect(borda, Color("#c8b88a", 0.85))
