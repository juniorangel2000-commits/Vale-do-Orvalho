class_name Desenho
## Desenhos simples feitos por código (ícones, plantas, máquinas, animais, monstros).
## São provisórios: cada um pode ser trocado por uma arte de verdade depois.

static var _tex := {}

## Textura de arte/gerada (ou null se não existir).
static func tex(caminho: String) -> Texture2D:
	if not _tex.has(caminho):
		var p := "res://arte/gerada/%s.png" % caminho
		_tex[caminho] = load(p) if ResourceLoader.exists(p) else null
	return _tex[caminho]

## Desenha um sprite com o pé em "base", ampliado (pixel art). Devolve false se não houver arte.
static func sprite(ci: CanvasItem, caminho: String, base: Vector2, escala := 2.0, mod := Color.WHITE, espelhar := false) -> bool:
	var t := tex(caminho)
	if t == null:
		return false
	var tam := t.get_size() * escala
	if espelhar:
		ci.draw_set_transform(base, 0, Vector2(-1, 1))
		ci.draw_texture_rect(t, Rect2(Vector2(-tam.x / 2.0, -tam.y), tam), false, mod)
		ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		ci.draw_texture_rect(t, Rect2(base - Vector2(tam.x / 2.0, tam.y), tam), false, mod)
	return true

static func textura_item(id: String) -> Texture2D:
	var t := tex("itens/%s_%d" % [id, Jogo.nivel_de(id)])
	if t == null:
		t = tex("itens/" + id)
	if t == null:
		t = tex("objetos/" + id)
	return t

static func _escuro(c: Color, f := 0.7) -> Color:
	return Color(c.r * f, c.g * f, c.b * f, c.a)

static func _claro(c: Color, f := 0.35) -> Color:
	return c.lerp(Color.WHITE, f)

## Ícone de item dentro do retângulo r.
static func icone(ci: CanvasItem, id: String, r: Rect2, origem := "") -> void:
	var d: Dictionary = Dados.item(id)
	var cor: Color = d.cor
	if origem != "" and (id == "geleia" or id == "suco" or id == "licor" or id == "conserva" or id == "mel"):
		cor = cor.lerp(Dados.item(origem).cor, 0.6)
	var c := r.get_center()
	var s: float = min(r.size.x, r.size.y) / 2.0
	var t := textura_item(id)
	if t != null:
		var tt := t.get_size()
		var esc: float = min(r.size.x / tt.x, r.size.y / tt.y)
		if esc >= 2.0:
			esc = floorf(esc)
		var mod := Color.WHITE
		if origem != "" and (id == "geleia" or id == "suco" or id == "licor" or id == "conserva" or id == "mel"):
			mod = Color.WHITE.lerp(Dados.item(origem).cor, 0.45) * 1.15
		ci.draw_texture_rect(t, Rect2(c - tt * esc / 2.0, tt * esc), false, mod)
		return
	match String(d.forma):
		"ferramenta":
			ferramenta(ci, id, r)
		"semente":
			var pts := PackedVector2Array([c + Vector2(-s * 0.6, -s * 0.7), c + Vector2(s * 0.6, -s * 0.7), c + Vector2(s * 0.7, s * 0.8), c + Vector2(-s * 0.7, s * 0.8)])
			ci.draw_colored_polygon(pts, Color("#d8c08a"))
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), Color("#8a6a3a"), 1.5)
			for i in 3:
				ci.draw_circle(c + Vector2(-s * 0.3 + i * s * 0.3, s * 0.15), s * 0.13, cor)
		"folha":
			ci.draw_circle(c + Vector2(0, s * 0.1), s * 0.7, cor)
			ci.draw_circle(c + Vector2(-s * 0.3, -s * 0.2), s * 0.45, _claro(cor))
			ci.draw_line(c + Vector2(0, s * 0.8), c + Vector2(0, -s * 0.3), _escuro(cor), 1.5)
		"bola":
			ci.draw_circle(c + Vector2(0, s * 0.1), s * 0.72, cor)
			ci.draw_circle(c + Vector2(-s * 0.25, -s * 0.15), s * 0.22, _claro(cor, 0.5))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.08, -s * 0.85), Vector2(s * 0.16, s * 0.3)), Color("#4a7a2a"))
		"raiz":
			var pts := PackedVector2Array([c + Vector2(-s * 0.55, -s * 0.3), c + Vector2(s * 0.55, -s * 0.3), c + Vector2(0, s * 0.9)])
			ci.draw_colored_polygon(pts, cor)
			ci.draw_circle(c + Vector2(0, -s * 0.3), s * 0.55, cor)
			for i in 3:
				ci.draw_line(c + Vector2(0, -s * 0.6), c + Vector2(-s * 0.4 + i * s * 0.4, -s * 1.0), Color("#5a9a3a"), 2)
		"baga":
			for p in [Vector2(-0.3, 0.2), Vector2(0.3, 0.2), Vector2(0, -0.2), Vector2(0, 0.55)]:
				ci.draw_circle(c + p * s, s * 0.32, cor)
				ci.draw_circle(c + p * s + Vector2(-s * 0.1, -s * 0.1), s * 0.08, _claro(cor, 0.6))
			ci.draw_line(c + Vector2(0, -s * 0.5), c + Vector2(s * 0.2, -s * 0.9), Color("#4a7a2a"), 2)
		"espiga":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.3, s * 0.8), c + Vector2(-s * 0.35, -s * 0.5), c + Vector2(0, -s * 0.9), c + Vector2(s * 0.35, -s * 0.5), c + Vector2(s * 0.3, s * 0.8)]), cor)
			ci.draw_line(c + Vector2(-s * 0.5, s * 0.9), c + Vector2(-s * 0.2, -s * 0.3), Color("#6a9a3a"), 3)
			ci.draw_line(c + Vector2(s * 0.5, s * 0.9), c + Vector2(s * 0.2, -s * 0.3), Color("#6a9a3a"), 3)
		"melancia":
			ci.draw_circle(c, s * 0.8, cor)
			for i in 3:
				ci.draw_arc(c, s * (0.25 + i * 0.2), -1.2, 1.2, 8, _escuro(cor, 0.6), 1.5)
		"flor":
			ci.draw_line(c + Vector2(0, s * 0.9), c, Color("#4a8a2a"), 2)
			for i in 6:
				var a := TAU * i / 6.0
				ci.draw_circle(c + Vector2(cos(a), sin(a)) * s * 0.4 + Vector2(0, -s * 0.15), s * 0.28, cor)
			ci.draw_circle(c + Vector2(0, -s * 0.15), s * 0.22, Color("#e8a82a") if cor.v > 0.8 else Color("#5a3a1a"))
		"cogumelo":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.18, -s * 0.1), Vector2(s * 0.36, s * 0.85)), Color("#f0e8d8"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.8, 0), c + Vector2(0, -s * 0.8), c + Vector2(s * 0.8, 0)]), cor)
		"pedra":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.8, s * 0.5), c + Vector2(-s * 0.5, -s * 0.4), c + Vector2(s * 0.2, -s * 0.7), c + Vector2(s * 0.8, -s * 0.1), c + Vector2(s * 0.6, s * 0.6)]), cor)
			ci.draw_line(c + Vector2(-s * 0.3, -s * 0.2), c + Vector2(s * 0.2, -s * 0.4), _claro(cor), 2)
		"minerio":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.8, s * 0.5), c + Vector2(-s * 0.5, -s * 0.4), c + Vector2(s * 0.2, -s * 0.7), c + Vector2(s * 0.8, -s * 0.1), c + Vector2(s * 0.6, s * 0.6)]), Color("#6a625a"))
			for p in [Vector2(-0.3, 0.1), Vector2(0.25, -0.2), Vector2(0.2, 0.3)]:
				ci.draw_circle(c + p * s, s * 0.2, cor)
		"barra":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.85, s * 0.45), c + Vector2(-s * 0.5, -s * 0.35), c + Vector2(s * 0.5, -s * 0.35), c + Vector2(s * 0.85, s * 0.45)]), cor)
			ci.draw_line(c + Vector2(-s * 0.4, -s * 0.2), c + Vector2(s * 0.4, -s * 0.2), _claro(cor, 0.6), 2)
		"gema":
			var pts := PackedVector2Array([c + Vector2(0, -s * 0.85), c + Vector2(s * 0.6, -s * 0.2), c + Vector2(0, s * 0.85), c + Vector2(-s * 0.6, -s * 0.2)])
			ci.draw_colored_polygon(pts, cor)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.85), c + Vector2(s * 0.6, -s * 0.2), c]), _claro(cor, 0.45))
		"tronco":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.8, -s * 0.4), Vector2(s * 1.6, s * 0.8)), cor)
			ci.draw_circle(c + Vector2(s * 0.8, 0), s * 0.4, _claro(cor, 0.4))
			ci.draw_arc(c + Vector2(s * 0.8, 0), s * 0.2, 0, TAU, 10, _escuro(cor), 1)
		"fibra":
			for i in 5:
				ci.draw_line(c + Vector2(-s * 0.5 + i * s * 0.25, s * 0.8), c + Vector2(-s * 0.3 + i * s * 0.2, -s * 0.8), cor, 2)
		"peixe":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.8, 0), c + Vector2(-s * 0.2, -s * 0.45), c + Vector2(s * 0.5, -s * 0.2), c + Vector2(s * 0.5, s * 0.2), c + Vector2(-s * 0.2, s * 0.45)]), cor)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.45, 0), c + Vector2(s * 0.9, -s * 0.45), c + Vector2(s * 0.9, s * 0.45)]), _escuro(cor))
			ci.draw_circle(c + Vector2(-s * 0.5, -s * 0.08), s * 0.08, Color.BLACK)
		"ovo":
			ci.draw_set_transform(c, 0, Vector2(0.8, 1.0))
			ci.draw_circle(Vector2.ZERO, s * 0.7, cor)
			ci.draw_circle(Vector2(-s * 0.2, -s * 0.25), s * 0.15, Color.WHITE)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"garrafa":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.45, -s * 0.3), Vector2(s * 0.9, s * 1.1)), cor)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.18, -s * 0.85), Vector2(s * 0.36, s * 0.6)), _escuro(cor, 0.85))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.45, -s * 0.3), Vector2(s * 0.9, s * 1.1)), Color(0, 0, 0, 0.5), false, 1)
		"pote":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.4), Vector2(s * 1.1, s * 1.2)), cor)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.6, -s * 0.65), Vector2(s * 1.2, s * 0.3)), Color("#c8a85a"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.05), Vector2(s * 0.8, s * 0.4)), Color("#f8f0e0"))
		"queijo":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.8, s * 0.5), c + Vector2(s * 0.8, s * 0.5), c + Vector2(s * 0.8, -s * 0.1), c + Vector2(-s * 0.3, -s * 0.6)]), cor)
			ci.draw_circle(c + Vector2(s * 0.2, s * 0.15), s * 0.12, _escuro(cor))
			ci.draw_circle(c + Vector2(-s * 0.3, s * 0.25), s * 0.08, _escuro(cor))
		"la":
			for p in [Vector2(-0.35, 0.1), Vector2(0.35, 0.1), Vector2(0, -0.25), Vector2(0, 0.35)]:
				ci.draw_circle(c + p * s, s * 0.42, cor)
		"tecido":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.7, -s * 0.5), Vector2(s * 1.4, s)), cor)
			ci.draw_line(c + Vector2(-s * 0.7, 0), c + Vector2(s * 0.7, 0), _escuro(cor), 1)
		"prato":
			ci.draw_circle(c + Vector2(0, s * 0.2), s * 0.85, Color("#f0f0e8"))
			ci.draw_circle(c + Vector2(0, s * 0.2), s * 0.55, cor)
			ci.draw_circle(c + Vector2(-s * 0.2, 0), s * 0.15, _claro(cor, 0.5))
		"saco":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.6, s * 0.8), c + Vector2(-s * 0.5, -s * 0.4), c + Vector2(s * 0.5, -s * 0.4), c + Vector2(s * 0.6, s * 0.8)]), Color("#c8a878"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.1), Vector2(s * 0.8, s * 0.6)), cor)
		"lixo":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.3, -s * 0.8), c + Vector2(s * 0.2, -s * 0.8), c + Vector2(s * 0.2, s * 0.3), c + Vector2(s * 0.8, s * 0.4), c + Vector2(s * 0.8, s * 0.8), c + Vector2(-s * 0.3, s * 0.8)]), cor)
		"buque":
			for i in 5:
				var a := -PI / 2 + (i - 2) * 0.45
				ci.draw_line(c + Vector2(0, s * 0.8), c + Vector2(cos(a), sin(a)) * s * 0.55, Color("#4a8a2a"), 1.5)
				ci.draw_circle(c + Vector2(cos(a), sin(a)) * s * 0.6, s * 0.22, [cor, Color("#f8f0a0"), Color("#e86a6a"), Color("#a8c8f8"), cor][i])
		"anel":
			ci.draw_arc(c + Vector2(0, s * 0.2), s * 0.5, 0, TAU, 20, Color("#e8c33a"), 3)
			ci.draw_circle(c + Vector2(0, -s * 0.35), s * 0.25, cor)
		_:
			objeto_colocavel(ci, id, c + Vector2(0, s * 0.8), s * 1.6)

## Ferramentas, com a cor do nível (básica, cobre, ferro, ouro).
static func ferramenta(ci: CanvasItem, id: String, r: Rect2) -> void:
	var c := r.get_center()
	var s: float = min(r.size.x, r.size.y) / 2.0
	var nivel := Jogo.nivel_de(id)
	var metal: Color = [Color("#8a8a90"), Color("#c87443"), Color("#d8d8e0"), Color("#e8c33a")][clampi(nivel, 0, 3)]
	var cabo := Color("#8a5a2a")
	match id:
		"enxada":
			ci.draw_line(c + Vector2(-s * 0.7, s * 0.7), c + Vector2(s * 0.4, -s * 0.4), cabo, 3)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.2, -s * 0.7), c + Vector2(s * 0.85, -s * 0.2), c + Vector2(s * 0.65, 0), c + Vector2(s * 0.1, -s * 0.45)]), metal)
		"regador":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.5, -s * 0.2), Vector2(s * 0.9, s * 0.8)), metal)
			ci.draw_line(c + Vector2(s * 0.4, 0), c + Vector2(s * 0.85, -s * 0.5), metal, 3)
			ci.draw_arc(c + Vector2(-s * 0.05, -s * 0.2), s * 0.35, PI, TAU, 8, _escuro(metal), 2)
		"machado":
			ci.draw_line(c + Vector2(-s * 0.6, s * 0.8), c + Vector2(s * 0.3, -s * 0.6), cabo, 3)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.1, -s * 0.6), c + Vector2(s * 0.8, -s * 0.8), c + Vector2(s * 0.7, 0), c + Vector2(s * 0.25, -s * 0.2)]), metal)
		"picareta":
			ci.draw_line(c + Vector2(-s * 0.5, s * 0.8), c + Vector2(s * 0.2, -s * 0.5), cabo, 3)
			ci.draw_arc(c + Vector2(s * 0.2, -s * 0.1), s * 0.75, -2.6, -0.5, 10, metal, 4)
		"foice":
			ci.draw_line(c + Vector2(-s * 0.4, s * 0.8), c + Vector2(-s * 0.1, -s * 0.2), cabo, 3)
			ci.draw_arc(c + Vector2(s * 0.2, -s * 0.2), s * 0.5, PI, TAU * 0.95, 10, metal, 3)
		"vara", "vara_fibra":
			ci.draw_line(c + Vector2(-s * 0.7, s * 0.8), c + Vector2(s * 0.7, -s * 0.8), Color("#6a8a4a") if id == "vara_fibra" else cabo, 2.5)
			ci.draw_line(c + Vector2(s * 0.7, -s * 0.8), c + Vector2(s * 0.75, s * 0.3), Color(1, 1, 1, 0.6), 1)
			ci.draw_circle(c + Vector2(-s * 0.4, s * 0.45), s * 0.15, Color("#3a3a3a"))
		"espada", "espada_aco":
			var lamina := Color("#e0e0f0") if id == "espada_aco" else Color("#a8a8a8")
			ci.draw_line(c + Vector2(-s * 0.4, s * 0.4), c + Vector2(s * 0.7, -s * 0.7), lamina, 4)
			ci.draw_line(c + Vector2(-s * 0.55, s * 0.15), c + Vector2(-s * 0.15, s * 0.55), Color("#8a6a2a"), 3)
			ci.draw_line(c + Vector2(-s * 0.4, s * 0.4), c + Vector2(-s * 0.75, s * 0.75), cabo, 3)
		"balde":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.6, -s * 0.4), c + Vector2(s * 0.6, -s * 0.4), c + Vector2(s * 0.45, s * 0.7), c + Vector2(-s * 0.45, s * 0.7)]), Color("#a8a8b0"))
			ci.draw_arc(c + Vector2(0, -s * 0.4), s * 0.6, PI, TAU, 10, Color("#6a6a70"), 2)
		"tesoura":
			ci.draw_line(c + Vector2(-s * 0.6, s * 0.6), c + Vector2(s * 0.6, -s * 0.6), Color("#c8c8d0"), 3)
			ci.draw_line(c + Vector2(-s * 0.6, -s * 0.2), c + Vector2(s * 0.6, -s * 0.6), Color("#c8c8d0"), 3)
			ci.draw_circle(c + Vector2(-s * 0.6, s * 0.6), s * 0.2, Color("#c8463a"))
			ci.draw_circle(c + Vector2(-s * 0.6, -s * 0.2), s * 0.2, Color("#c8463a"))
		_:
			ci.draw_circle(c, s * 0.6, metal)

## Planta no solo; base = ponto no chão (centro embaixo).
static func cultura(ci: CanvasItem, base: Vector2, cult: Dictionary) -> void:
	var dados: Dictionary = Dados.culturas[cult.id]
	if cult.get("morta", false) and sprite(ci, "culturas/morta", base + Vector2(0, 2)):
		return
	if not cult.get("morta", false):
		var dias_c := int(cult.dias)
		var fase_c := 0
		var soma_c := 0
		for f in dados.fases:
			soma_c += int(f)
			if dias_c >= soma_c:
				fase_c += 1
		if sprite(ci, "culturas/%s_%d" % [cult.id, min(fase_c, 4)], base + Vector2(0, 2)):
			return
	if cult.get("morta", false):
		ci.draw_line(base, base + Vector2(-4, -12), Color("#6a5a3a"), 2)
		ci.draw_line(base, base + Vector2(5, -10), Color("#6a5a3a"), 2)
		return
	var fases: Array = dados.fases
	var dias := int(cult.dias)
	var fase := 0
	var soma := 0
	for f in fases:
		soma += int(f)
		if dias >= soma:
			fase += 1
	var pronta := fase >= fases.size()
	var verde := Color("#5a9a3a")
	var alto: bool = dados.alto
	if fase == 0:
		ci.draw_circle(base + Vector2(-4, -3), 1.8, Color("#c8a878"))
		ci.draw_circle(base + Vector2(3, -4), 1.8, Color("#c8a878"))
		ci.draw_line(base + Vector2(0, -2), base + Vector2(0, -6), verde, 2)
		return
	var altura := 6.0 + fase * (6.0 if alto else 3.5)
	ci.draw_line(base, base + Vector2(0, -altura), _escuro(verde), 2)
	for i in fase + 1:
		var y := -altura * (0.3 + 0.7 * i / float(fase + 1))
		var lado := -1.0 if i % 2 == 0 else 1.0
		ci.draw_colored_polygon(PackedVector2Array([base + Vector2(0, y), base + Vector2(lado * 8, y - 4), base + Vector2(lado * 4, y + 2)]), verde)
	if pronta and not bool(cult.get("colhida", false)):
		var cor: Color = Dados.item(dados.produto).cor
		var forma: String = Dados.item(dados.produto).forma
		match forma:
			"bola", "melancia":
				var raio := 9.0 if forma == "melancia" or dados.produto == "abobora" else 4.0
				ci.draw_circle(base + Vector2(0, -raio), raio, cor)
				ci.draw_circle(base + Vector2(-raio * 0.3, -raio * 1.3), raio * 0.25, _claro(cor, 0.5))
				if raio < 5:
					ci.draw_circle(base + Vector2(6, -altura * 0.6), 3.5, cor)
			"flor":
				for j in 6:
					var a := TAU * j / 6.0
					ci.draw_circle(base + Vector2(0, -altura) + Vector2(cos(a), sin(a)) * 4, 3, cor)
				ci.draw_circle(base + Vector2(0, -altura), 2.5, Color("#e8a82a"))
			"baga":
				for p in [Vector2(-5, -0.4), Vector2(5, -0.6), Vector2(0, -0.8)]:
					ci.draw_circle(base + Vector2(p.x, altura * p.y), 2.8, cor)
			"espiga":
				ci.draw_rect(Rect2(base + Vector2(3, -altura * 0.8), Vector2(4, 9)), cor)
			"raiz":
				ci.draw_circle(base + Vector2(0, -2), 4, cor)
			"folha":
				ci.draw_circle(base + Vector2(0, -5), 7, cor)
				ci.draw_circle(base + Vector2(-2, -7), 4, _claro(cor))
			_:
				ci.draw_circle(base + Vector2(0, -altura), 4, cor)
	elif not pronta:
		pass

## Objetos colocáveis (máquinas, baú...), base = chão.
static func objeto_colocavel(ci: CanvasItem, tipo: String, base: Vector2, tam := 28.0, pronto := false, trabalhando := false) -> void:
	var s := tam / 28.0
	var nome := tipo
	if trabalhando and (tipo == "fornalha" or tipo == "forno_carvao"):
		nome += "_on"
	if tipo == "cocho" and pronto:
		nome = "cocho_cheio"
	if tex("objetos/" + nome) != null:
		var t := tex("objetos/" + nome)
		var escala := 2.0 * s if tam != 28.0 else 2.0
		if tam < 28.0:
			escala = tam / max(t.get_width(), t.get_height())
		sprite(ci, "objetos/" + nome, base, escala)
		if pronto and tipo != "cocho" and tipo != "mural":
			var topo := base + Vector2(0, -t.get_height() * escala - 8)
			ci.draw_circle(topo, 9, Color(1, 1, 1, 0.92))
			ci.draw_arc(topo, 9, 0, TAU, 16, Color("#6a4a2a"), 1.5)
		return
	match tipo:
		"bau":
			ci.draw_rect(Rect2(base + Vector2(-13, -20) * s, Vector2(26, 18) * s), Color("#9a6b3e"))
			ci.draw_rect(Rect2(base + Vector2(-13, -24) * s, Vector2(26, 7) * s), Color("#7a4e2a"))
			ci.draw_rect(Rect2(base + Vector2(-3, -19) * s, Vector2(6, 5) * s), Color("#e8c33a"))
		"caixa_envio":
			ci.draw_rect(Rect2(base + Vector2(-15, -22) * s, Vector2(30, 20) * s), Color("#8a5a32"))
			ci.draw_rect(Rect2(base + Vector2(-16, -26) * s, Vector2(32, 6) * s), Color("#6a4226"))
			ci.draw_line(base + Vector2(-15, -12) * s, base + Vector2(15, -12) * s, Color("#6a4226"), 1)
		"espantalho":
			ci.draw_line(base, base + Vector2(0, -30) * s, Color("#7a5a3a"), 3)
			ci.draw_line(base + Vector2(-11, -22) * s, base + Vector2(11, -22) * s, Color("#7a5a3a"), 3)
			ci.draw_circle(base + Vector2(0, -32) * s, 6 * s, Color("#e8d8a0"))
			ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-9, -35) * s, base + Vector2(9, -35) * s, base + Vector2(0, -44) * s]), Color("#8a6a3a"))
			ci.draw_rect(Rect2(base + Vector2(-6, -24) * s, Vector2(12, 12) * s), Color("#4a6a9a"))
		"aspersor", "aspersor_bom":
			var cor := Color("#a8a8b0") if tipo == "aspersor" else Color("#e8c33a")
			ci.draw_rect(Rect2(base + Vector2(-3, -12) * s, Vector2(6, 10) * s), cor)
			ci.draw_circle(base + Vector2(0, -13) * s, 5 * s, _escuro(cor))
			ci.draw_circle(base + Vector2(0, -13) * s, 2 * s, Color("#6ac8f0"))
		"cerca":
			ci.draw_rect(Rect2(base + Vector2(-3, -24) * s, Vector2(6, 22) * s), Color("#9a6b3e"))
			ci.draw_rect(Rect2(base + Vector2(-16, -18) * s, Vector2(32, 4) * s), Color("#8a5a2e"))
			ci.draw_rect(Rect2(base + Vector2(-16, -9) * s, Vector2(32, 4) * s), Color("#8a5a2e"))
		"tocha":
			ci.draw_line(base, base + Vector2(0, -22) * s, Color("#5a4030"), 3)
			ci.draw_rect(Rect2(base + Vector2(-5, -32) * s, Vector2(10, 10) * s), Color("#3a3a3a"))
			ci.draw_circle(base + Vector2(0, -27) * s, 3.5 * s, Color("#ffd27a"))
		"barril":
			ci.draw_rect(Rect2(base + Vector2(-10, -26) * s, Vector2(20, 24) * s), Color("#7a4a2a"))
			for yy in [-22, -8]:
				ci.draw_line(base + Vector2(-10, yy) * s, base + Vector2(10, yy) * s, Color("#3a3a3a"), 2)
		"conserveiro":
			ci.draw_rect(Rect2(base + Vector2(-9, -20) * s, Vector2(18, 18) * s), Color("#d8c8a0"))
			ci.draw_rect(Rect2(base + Vector2(-10, -24) * s, Vector2(20, 5) * s), Color("#8a6a3a"))
		"fornalha":
			ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-13, -2) * s, base + Vector2(-10, -26) * s, base + Vector2(10, -26) * s, base + Vector2(13, -2) * s]), Color("#8a5a4a"))
			ci.draw_rect(Rect2(base + Vector2(-6, -14) * s, Vector2(12, 10) * s), Color("#ff8a3a") if trabalhando else Color("#2a1a1a"))
		"forno_carvao":
			ci.draw_rect(Rect2(base + Vector2(-12, -24) * s, Vector2(24, 22) * s), Color("#4a4a4a"))
			ci.draw_rect(Rect2(base + Vector2(-5, -12) * s, Vector2(10, 8) * s), Color("#ff6a2a") if trabalhando else Color("#1a1a1a"))
		"prensa_queijo":
			ci.draw_rect(Rect2(base + Vector2(-11, -12) * s, Vector2(22, 10) * s), Color("#c8b88a"))
			ci.draw_rect(Rect2(base + Vector2(-2, -28) * s, Vector2(4, 16) * s), Color("#7a5a3a"))
			ci.draw_rect(Rect2(base + Vector2(-9, -30) * s, Vector2(18, 4) * s), Color("#7a5a3a"))
		"batedeira":
			ci.draw_rect(Rect2(base + Vector2(-10, -22) * s, Vector2(20, 20) * s), Color("#e8e0c8"))
			ci.draw_circle(base + Vector2(0, -14) * s, 5 * s, Color("#c8b880"))
		"tear":
			ci.draw_rect(Rect2(base + Vector2(-13, -28) * s, Vector2(26, 26) * s), Color("#a87a5a"), false, 3)
			for i in 5:
				ci.draw_line(base + Vector2(-10 + i * 5, -26) * s, base + Vector2(-10 + i * 5, -4) * s, Color("#e8d8f0"), 1)
		"caixa_abelha":
			ci.draw_rect(Rect2(base + Vector2(-11, -22) * s, Vector2(22, 20) * s), Color("#e8b04a"))
			ci.draw_rect(Rect2(base + Vector2(-13, -25) * s, Vector2(26, 4) * s), Color("#8a5a2a"))
			ci.draw_rect(Rect2(base + Vector2(-4, -8) * s, Vector2(8, 3) * s), Color("#2a1a0a"))
		"fogao":
			ci.draw_rect(Rect2(base + Vector2(-14, -26) * s, Vector2(28, 24) * s), Color("#5a5a60"))
			ci.draw_circle(base + Vector2(-6, -22) * s, 4 * s, Color("#2a2a2a"))
			ci.draw_circle(base + Vector2(6, -22) * s, 4 * s, Color("#2a2a2a"))
			ci.draw_rect(Rect2(base + Vector2(-10, -15) * s, Vector2(20, 10) * s), Color("#3a3a40"))
		"cama":
			ci.draw_rect(Rect2(base + Vector2(-16, -52) * s, Vector2(32, 50) * s), Color("#7a4a2a"))
			ci.draw_rect(Rect2(base + Vector2(-13, -48) * s, Vector2(26, 44) * s), Color("#e8e0f0"))
			ci.draw_rect(Rect2(base + Vector2(-13, -30) * s, Vector2(26, 26) * s), Color("#5a7ac8"))
			ci.draw_rect(Rect2(base + Vector2(-9, -46) * s, Vector2(18, 9) * s), Color("#ffffff"))
		"cocho":
			ci.draw_rect(Rect2(base + Vector2(-15, -12) * s, Vector2(30, 10) * s), Color("#7a5a3a"))
			if pronto:
				ci.draw_rect(Rect2(base + Vector2(-13, -14) * s, Vector2(26, 4) * s), Color("#d8c26a"))
		"mural":
			ci.draw_rect(Rect2(base + Vector2(-2, -12) * s, Vector2(4, 10) * s), Color("#5a3a2a"))
			ci.draw_rect(Rect2(base + Vector2(-15, -34) * s, Vector2(30, 22) * s), Color("#9a6b3e"))
			ci.draw_rect(Rect2(base + Vector2(-10, -30) * s, Vector2(8, 10) * s), Color("#f8f0d8"))
			ci.draw_rect(Rect2(base + Vector2(2, -31) * s, Vector2(8, 8) * s), Color("#f8f0d8") if pronto else Color("#c8b898"))
		"colecoes":
			ci.draw_rect(Rect2(base + Vector2(-14, -30) * s, Vector2(28, 28) * s), Color("#c8a85a"))
			ci.draw_rect(Rect2(base + Vector2(-10, -26) * s, Vector2(20, 20) * s), Color("#f8f0d8"))
			ci.draw_circle(base + Vector2(0, -16) * s, 5 * s, Color("#4a9a5a"))
		"escada_mina":
			ci.draw_rect(Rect2(base + Vector2(-12, -26) * s, Vector2(24, 24) * s), Color("#1a1210"))
			for i in 4:
				ci.draw_line(base + Vector2(-8, -22 + i * 6) * s, base + Vector2(8, -22 + i * 6) * s, Color("#9a6b3e"), 2)
		"elevador":
			ci.draw_rect(Rect2(base + Vector2(-13, -30) * s, Vector2(26, 28) * s), Color("#5a5a60"))
			ci.draw_rect(Rect2(base + Vector2(-10, -27) * s, Vector2(20, 22) * s), Color("#2a2a30"))
			ci.draw_circle(base + Vector2(0, -16) * s, 3 * s, Color("#e8c33a"))
		"mesa":
			ci.draw_rect(Rect2(base + Vector2(-15, -20) * s, Vector2(30, 6) * s), Color("#8a5a32"))
			ci.draw_rect(Rect2(base + Vector2(-13, -14) * s, Vector2(3, 12) * s), Color("#6a4226"))
			ci.draw_rect(Rect2(base + Vector2(10, -14) * s, Vector2(3, 12) * s), Color("#6a4226"))
		_:
			ci.draw_rect(Rect2(base + Vector2(-10, -20) * s, Vector2(20, 18) * s), Color("#8a8a8a"))
	if pronto and tipo != "cocho" and tipo != "mural":
		ci.draw_circle(base + Vector2(0, -38) * s, 7 * s, Color(1, 1, 1, 0.9))
		ci.draw_arc(base + Vector2(0, -38) * s, 7 * s, 0, TAU, 14, Color("#6a4a2a"), 1)

## Animal visto de lado; olhando para a direita se dir > 0.
static func animal(ci: CanvasItem, tipo: String, base: Vector2, dir := 1.0, quadro := 0.0) -> void:
	if sprite(ci, "animais/%s_%d" % [tipo, int(quadro / 2.0) % 2], base, 2.0, Color.WHITE, dir < 0):
		return
	var d: Dictionary = Dados.animais.get(tipo, {"cor": Color.WHITE})
	var cor: Color = d.cor
	var pulo := absf(sin(quadro)) * 1.5
	if tipo == "galinha" or tipo == "pato":
		ci.draw_circle(base + Vector2(0, -8 - pulo), 7, cor)
		ci.draw_circle(base + Vector2(6 * dir, -15 - pulo), 4.5, cor)
		ci.draw_colored_polygon(PackedVector2Array([base + Vector2(10 * dir, -16 - pulo), base + Vector2(14 * dir, -14 - pulo), base + Vector2(10 * dir, -13 - pulo)]), Color("#e8a82a"))
		ci.draw_circle(base + Vector2(7 * dir, -16 - pulo), 1, Color.BLACK)
		if tipo == "galinha":
			ci.draw_circle(base + Vector2(5 * dir, -20 - pulo), 2, Color("#d8283c"))
		ci.draw_line(base + Vector2(-2, -2), base + Vector2(-2, 0), Color("#e8a82a"), 1.5)
		ci.draw_line(base + Vector2(2, -2), base + Vector2(2, 0), Color("#e8a82a"), 1.5)
	else:
		var largura := 15.0 if tipo == "vaca" else 12.0
		ci.draw_set_transform(base + Vector2(0, -14 - pulo), 0, Vector2(1.0, 0.65))
		ci.draw_circle(Vector2.ZERO, largura, cor)
		ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		if tipo == "vaca":
			ci.draw_circle(base + Vector2(-4, -16 - pulo), 4, Color("#3a2a2a"))
			ci.draw_circle(base + Vector2(6, -12 - pulo), 3, Color("#3a2a2a"))
		if tipo == "ovelha":
			for i in 5:
				ci.draw_circle(base + Vector2(-10 + i * 5, -20 - pulo), 4, Color.WHITE)
		ci.draw_circle(base + Vector2((largura + 2) * dir, -18 - pulo), 6, _escuro(cor, 0.9) if tipo != "ovelha" else Color("#3a3a3a"))
		ci.draw_circle(base + Vector2((largura + 4) * dir, -19 - pulo), 1.2, Color.BLACK)
		if tipo == "cabra":
			ci.draw_line(base + Vector2((largura) * dir, -23 - pulo), base + Vector2((largura - 4) * dir, -28 - pulo), Color("#8a7a6a"), 2)
		for x in [-largura * 0.6, -largura * 0.2, largura * 0.2, largura * 0.6]:
			ci.draw_line(base + Vector2(x, -6), base + Vector2(x, 0), _escuro(cor, 0.6), 2.5)

## Monstros da mina.
static func monstro(ci: CanvasItem, tipo: String, base: Vector2, quadro: float, ferido: bool) -> void:
	var piscar := Color(1, 0.4, 0.4) if ferido else Color.WHITE
	var desloc := Vector2(0, -6 - sin(quadro * 6.0) * 3.0) if tipo == "morcego" else Vector2.ZERO
	if sprite(ci, "monstros/%s_%d" % [tipo, int(quadro * 4.0) % 2], base + desloc, 2.0, piscar):
		return
	match tipo:
		"gosma", "gosma_azul", "gosma_roxa":
			var cor := Color("#5fc24a")
			if tipo == "gosma_azul":
				cor = Color("#4a8ad8")
			elif tipo == "gosma_roxa":
				cor = Color("#9a4ac8")
			var esmaga := 1.0 + sin(quadro * 2.0) * 0.12
			ci.draw_set_transform(base + Vector2(0, -8), 0, Vector2(esmaga, 1.0 / esmaga))
			ci.draw_circle(Vector2.ZERO, 10, cor * piscar)
			ci.draw_circle(Vector2(-3, -3), 2, Color.WHITE)
			ci.draw_circle(Vector2(3, -3), 2, Color.WHITE)
			ci.draw_circle(Vector2(-3, -3), 1, Color.BLACK)
			ci.draw_circle(Vector2(3, -3), 1, Color.BLACK)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"morcego":
			var asa := sin(quadro * 6.0) * 6.0
			var y := -22.0
			ci.draw_colored_polygon(PackedVector2Array([base + Vector2(0, y), base + Vector2(-14, y - asa), base + Vector2(-8, y + 4)]), Color("#4a3a5a") * piscar)
			ci.draw_colored_polygon(PackedVector2Array([base + Vector2(0, y), base + Vector2(14, y - asa), base + Vector2(8, y + 4)]), Color("#4a3a5a") * piscar)
			ci.draw_circle(base + Vector2(0, y), 5, Color("#3a2a4a") * piscar)
			ci.draw_circle(base + Vector2(-2, y - 1), 1, Color("#ff4a4a"))
			ci.draw_circle(base + Vector2(2, y - 1), 1, Color("#ff4a4a"))
		"pedrento":
			ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-12, 0), base + Vector2(-10, -18), base + Vector2(0, -24), base + Vector2(10, -18), base + Vector2(12, 0)]), Color("#7a7068") * piscar)
			ci.draw_circle(base + Vector2(-4, -14), 2, Color("#ffd24a"))
			ci.draw_circle(base + Vector2(4, -14), 2, Color("#ffd24a"))
