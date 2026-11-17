extends Node2D
## Desenha o chão do mapa bloco a bloco (só quando muda).

var mapa: Mapa

func _draw() -> void:
	if mapa == null:
		return
	var T := Mapa.T
	var inverno := Jogo.estacao == 3 and not mapa.interior and not mapa.nome.begins_with("mina")
	var outono := Jogo.estacao == 2 and not mapa.interior
	for y in mapa.h:
		for x in mapa.w:
			var c := Vector2i(x, y)
			var m := mapa.material(c)
			var r := Rect2(x * T, y * T, T, T)
			if m == Mapa.M.AGUA:
				# a água tem nó próprio (animada); aqui só a margem de areia por baixo
				draw_rect(r, Color("#3a5a6a"))
				continue
			if m < Mapa.TEXTURAS.size():
				var tex: Texture2D = mapa.texturas[Mapa.TEXTURAS[m]]
				var origem := Rect2((x * T) % 96, (y * T) % 96, T, T)
				var cor := Color.WHITE
				if inverno and (m == Mapa.M.GRAMA or m == Mapa.M.CAMPO or m == Mapa.M.FLORESTA or m == Mapa.M.MUSGO):
					cor = Color(1.25, 1.3, 1.45)
				elif outono and (m == Mapa.M.GRAMA or m == Mapa.M.CAMPO):
					cor = Color(1.15, 0.95, 0.7)
				draw_texture_rect_region(tex, r, origem, cor)
				if inverno and m != Mapa.M.TERRA and m != Mapa.M.ESTRADA and m != Mapa.M.ESTRADA_UMIDA:
					draw_rect(r, Color(0.95, 0.97, 1.0, 0.55))
			elif m == Mapa.M.PISO:
				draw_rect(r, Color("#9a6a42"))
				draw_line(Vector2(r.position.x, r.position.y + 15), Vector2(r.end.x, r.position.y + 15), Color("#7a4e2e"), 1)
				draw_line(Vector2(r.position.x, r.end.y - 1), Vector2(r.end.x, r.end.y - 1), Color("#7a4e2e"), 1)
				var junta := 8.0 if (y % 2 == 0) else 24.0
				draw_line(Vector2(r.position.x + junta, r.position.y), Vector2(r.position.x + junta, r.position.y + 15), Color("#7a4e2e"), 1)
			elif m == Mapa.M.TAPETE:
				draw_rect(r, Color("#8a2a2a"))
				draw_rect(r.grow(-3), Color("#a8483a"), false, 2)
			elif m == Mapa.M.PAREDE:
				draw_rect(r, Color("#6a4a3a"))
				draw_rect(Rect2(r.position.x, r.end.y - 6, T, 6), Color("#4a2e22"))
				for i in 4:
					draw_line(Vector2(r.position.x + i * 8 + 4, r.position.y), Vector2(r.position.x + i * 8 + 4, r.end.y - 6), Color("#7a5848"), 1)
			elif m == Mapa.M.ROCHA:
				var tex2: Texture2D = mapa.texturas["path-dry"]
				draw_texture_rect_region(tex2, r, Rect2((x * T) % 96, (y * T) % 96, T, T), Color(0.55, 0.5, 0.5) if mapa.andar < 20 else Color(0.5, 0.55, 0.7))
			else:
				draw_rect(r, Color("#0e0a0a"))
	# saídas: setas discretas no chão
	for s in mapa.saidas:
		var rr: Rect2i = s.rect
		if s.get("oculta", false):
			continue
		var centro := Vector2((rr.position.x + rr.size.x / 2.0) * T, (rr.position.y + rr.size.y / 2.0) * T)
		draw_circle(centro, 5, Color(1, 1, 0.8, 0.35))
