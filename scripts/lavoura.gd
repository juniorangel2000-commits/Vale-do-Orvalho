extends Node2D
## Desenha o solo arado, a terra molhada e as plantas.

var mapa: Mapa

func _draw() -> void:
	if mapa == null:
		return
	var T := Mapa.T
	var tex_terra: Texture2D = mapa.texturas["soil"]
	for k in mapa.est.solo:
		var c := Jogo.celula(k)
		var s: Dictionary = mapa.est.solo[k]
		var r := Rect2(c.x * T, c.y * T, T, T)
		draw_texture_rect_region(tex_terra, r.grow(-1), Rect2((c.x * T) % 96, (c.y * T) % 96, T, T), Color(0.85, 0.75, 0.7))
		# sulcos
		for i in 3:
			var yy := r.position.y + 8 + i * 8
			draw_line(Vector2(r.position.x + 4, yy), Vector2(r.end.x - 4, yy), Color(0.25, 0.15, 0.1, 0.35), 2)
		if bool(s.get("regado", false)):
			draw_rect(r.grow(-1), Color(0.1, 0.12, 0.25, 0.35))
		if s.has("adubo"):
			for i in 4:
				draw_circle(r.position + Vector2(6 + i * 7, 26), 1.5, Color("#e8e0c0") if s.adubo == "fertilizante" else Color("#7ad84a"))
		if s.has("cultura"):
			Desenho.cultura(self, Vector2(r.position.x + T / 2.0, r.end.y - 3), s.cultura)
