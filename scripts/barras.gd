extends Control
## Barras verticais de energia (verde) e vida (vermelha, só na mina ou ferido).

func _draw() -> void:
	var mostrar_vida: bool = Jogo.vida < Jogo.vida_max or (get_parent().get("principal") != null and get_parent().principal.mapa != null and get_parent().principal.mapa.andar > 0)
	var x := size.x - 26
	_barra(Rect2(x, 0, 24, size.y), float(Jogo.energia) / Jogo.energia_max, Color("#5ac84a") if Jogo.energia > Jogo.energia_max * 0.25 else Color("#e8a83a"), "E")
	if mostrar_vida:
		_barra(Rect2(x - 30, size.y * 0.3, 24, size.y * 0.7), float(Jogo.vida) / Jogo.vida_max, Color("#e84a4a"), "V")

func _barra(r: Rect2, fracao: float, cor: Color, letra: String) -> void:
	draw_rect(r, Color("#7a4e2e"))
	draw_rect(r.grow(-3), Color("#3a2416"))
	var altura := (r.size.y - 22) * clampf(fracao, 0.0, 1.0)
	draw_rect(Rect2(r.position.x + 5, r.end.y - 5 - altura, r.size.x - 10, altura), cor)
	draw_string(get_theme_default_font(), Vector2(r.position.x + 7, r.position.y + 14), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f2dfb4"))
