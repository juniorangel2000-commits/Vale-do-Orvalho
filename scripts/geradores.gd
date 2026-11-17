class_name Geradores
## Monta cada mapa: terreno, paredes, construções, saídas e (na primeira visita) os objetos.

const M := Mapa.M

static func gerar(m: Mapa, extra: Dictionary) -> void:
	if m.nome == "fazenda":
		fazenda(m)
	elif m.nome == "vila":
		vila(m)
	elif m.nome == "floresta":
		floresta(m)
	elif m.nome == "montanha":
		montanha(m)
	elif m.nome == "casa":
		casa(m)
	elif m.nome == "estufa":
		estufa(m)
	elif m.nome.begins_with("interior_"):
		interior_animais(m, int(m.nome.substr(9)))
	elif m.nome.begins_with("mina"):
		mina(m, int(extra.get("andar", 1)))

# ---------------------------------------------------------------- ajudas

static func retangulo(m: Mapa, r: Rect2i, material: int) -> void:
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			m.por_material(Vector2i(x, y), material)

static func bloquear_ret(m: Mapa, r: Rect2i) -> void:
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			m.bloquear(Vector2i(x, y))

static func elipse(m: Mapa, centro: Vector2, rx: float, ry: float, material: int) -> void:
	for x in range(int(centro.x - rx) - 1, int(centro.x + rx) + 2):
		for y in range(int(centro.y - ry) - 1, int(centro.y + ry) + 2):
			var dx := (x + 0.5 - centro.x) / rx
			var dy := (y + 0.5 - centro.y) / ry
			if dx * dx + dy * dy <= 1.0:
				m.por_material(Vector2i(x, y), material)

## Borda de árvores fixas (não cortáveis), deixando livres as aberturas.
static func borda(m: Mapa, espessura: int, aberturas: Array) -> void:
	for x in m.w:
		for y in m.h:
			if x >= espessura and y >= espessura and x < m.w - espessura and y < m.h - espessura:
				continue
			var c := Vector2i(x, y)
			var livre := false
			for a in aberturas:
				var r: Rect2i = a
				if r.has_point(c):
					livre = true
			if livre:
				continue
			m.bloquear(c)
			if (x + y * 3) % 2 == 0:
				var arte := "asset-pine-%d" % ((x * 5 + y * 7) % 3)
				if (x * 3 + y) % 5 == 0:
					arte = "asset-tree-%d" % ((x + y) % 3)
				m.decoracoes.append({"c": c, "arte": arte, "largura": 96.0 + ((x * 13 + y * 7) % 20)})

static func caminho(m: Mapa, de: Vector2i, ate: Vector2i, largura := 2, material := M.ESTRADA) -> void:
	var c := de
	while c != ate:
		for i in largura:
			for j in largura:
				if m.material(c + Vector2i(i, j)) != M.AGUA:
					m.por_material(c + Vector2i(i, j), material)
		if c.x != ate.x:
			c.x += signi(ate.x - c.x)
		else:
			c.y += signi(ate.y - c.y)
	for i in largura:
		for j in largura:
			m.por_material(ate + Vector2i(i, j), material)

static func saida(m: Mapa, r: Rect2i, destino: String, entrada: Vector2i) -> void:
	m.saidas.append({"rect": r, "destino": destino, "entrada": entrada})

## Prédio da vila/floresta: casa com placa; a porta é interativa (loja) ou só enfeite.
static func predio(m: Mapa, r: Rect2i, rotulo: String, cor: Color, porta_tipo := {}, textura := "res://arte/objetos/asset-house.png") -> Vector2i:
	m.construcoes_fixas.append({"rect": r, "textura": textura, "cor": cor, "rotulo": rotulo, "desce": 6.0})
	bloquear_ret(m, r)
	var porta := Vector2i(r.position.x + r.size.x / 2, r.end.y - 1)
	if not porta_tipo.is_empty():
		m.interativos[Jogo.chave(porta)] = porta_tipo
	# chão de terra batida na frente da porta
	m.por_material(porta + Vector2i(0, 1), M.ESTRADA)
	m.por_material(porta + Vector2i(-1, 1), M.ESTRADA)
	return porta

static func espalhar(m: Mapa, area: Rect2i, qtd: int, tipos: Array, rng: RandomNumberGenerator) -> void:
	for i in qtd:
		var c := Vector2i(rng.randi_range(area.position.x, area.end.x - 1), rng.randi_range(area.position.y, area.end.y - 1))
		if m.solido(c) or not m.objeto(c).is_empty() or m.interativos.has(Jogo.chave(c)) or m.material(c) == M.ESTRADA:
			continue
		var t: String = tipos[rng.randi() % tipos.size()]
		m.est.objetos[Jogo.chave(c)] = {"tipo": t}

static func area_forragem(m: Mapa, area: Rect2i) -> void:
	var lista := []
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			var c := Vector2i(x, y)
			if not m.solido(c) and m.material(c) != M.ESTRADA and not m.interativos.has(Jogo.chave(c)):
				lista.append(c)
	m.marcar_area_forragem(lista)

static func flores(m: Mapa, area: Rect2i, qtd: int, semente: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var artes := ["forest-detail-flowers", "forest-detail-fern", "forest-detail-bush", "forest-detail-mushrooms"]
	for i in qtd:
		var c := Vector2i(rng.randi_range(area.position.x, area.end.x - 1), rng.randi_range(area.position.y, area.end.y - 1))
		if m.solido(c) or m.material(c) == M.ESTRADA or m.material(c) == M.AREIA:
			continue
		m.decoracoes.append({"c": c, "arte": artes[rng.randi() % artes.size()], "largura": 30.0})

# ---------------------------------------------------------------- fazenda

static func fazenda(m: Mapa) -> void:
	m.preparar(60, 45, M.GRAMA)
	m.tipo_agua = "lago"
	borda(m, 2, [Rect2i(58, 20, 2, 3), Rect2i(28, 43, 3, 2), Rect2i(30, 0, 3, 2)])
	saida(m, Rect2i(59, 20, 1, 3), "vila", Vector2i(2, 21))
	saida(m, Rect2i(28, 44, 3, 1), "floresta", Vector2i(29, 2))
	saida(m, Rect2i(30, 0, 3, 1), "montanha", Vector2i(20, 29))
	elipse(m, Vector2(46, 35), 5.5, 4.0, M.AGUA)
	elipse(m, Vector2(46, 35), 7.0, 5.5, M.AREIA)
	elipse(m, Vector2(46, 35), 5.5, 4.0, M.AGUA)
	caminho(m, Vector2i(11, 8), Vector2i(11, 10))
	caminho(m, Vector2i(11, 10), Vector2i(58, 20))
	caminho(m, Vector2i(30, 10), Vector2i(30, 0))
	caminho(m, Vector2i(28, 21), Vector2i(28, 43), 2, M.ESTRADA_UMIDA)
	# casa do jogador
	var r_casa := Rect2i(8, 3, 6, 5)
	m.construcoes_fixas.append({"rect": r_casa, "textura": "res://arte/objetos/asset-house.png", "rotulo": "", "desce": 6.0, "largura": 1.05})
	bloquear_ret(m, r_casa)
	var porta := Vector2i(11, 7)
	m.bloquear(porta, 0)
	saida(m, Rect2i(porta, Vector2i(1, 1)), "casa", Vector2i(6, 8))
	# estufa
	var r_estufa := Rect2i(20, 2, 6, 5)
	var reformada: bool = Jogo.flags.has("estufa")
	m.construcoes_fixas.append({"rect": r_estufa, "textura": "res://arte/objetos/pet-shelter-0-shelter.png",
		"cor": Color(0.85, 1.15, 0.95) if reformada else Color(0.7, 0.65, 0.6), "rotulo": "Estufa" if reformada else "Estufa (em ruínas)", "desce": 6.0})
	bloquear_ret(m, r_estufa)
	var porta_estufa := Vector2i(23, 6)
	if reformada:
		m.bloquear(porta_estufa, 0)
		saida(m, Rect2i(porta_estufa, Vector2i(1, 1)), "estufa", Vector2i(7, 10))
	else:
		m.interativos[Jogo.chave(porta_estufa)] = {"tipo": "aviso", "texto": "A estufa está em ruínas. Dizem que o Salão da Vila sabe como reformá-la."}
	# construções do jogador
	for b in Jogo.construcoes:
		construcao_jogador(m, b)
	# objetos iniciais
	if not m.est.iniciado:
		m.est.objetos[Jogo.chave(Vector2i(14, 8))] = {"tipo": "caixa_envio"}
		m.est.objetos[Jogo.chave(Vector2i(17, 6))] = {"tipo": "poco"}
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		espalhar(m, Rect2i(3, 12, 40, 30), 260, ["mato", "mato", "mato", "pedra", "galho", "pedra", "galho", "toco"], rng)
		espalhar(m, Rect2i(40, 3, 17, 26), 70, ["arvore", "pinheiro", "arvore", "mato"], rng)
		espalhar(m, Rect2i(3, 30, 22, 12), 25, ["arvore", "pinheiro", "rocha"], rng)
		espalhar(m, Rect2i(33, 30, 24, 12), 20, ["arvore", "mato"], rng)
		# limpa em volta da casa
		for x in range(6, 19):
			for y in range(2, 12):
				var k := Jogo.chave(Vector2i(x, y))
				if m.est.objetos.has(k) and m.est.objetos[k].tipo != "caixa_envio" and m.est.objetos[k].tipo != "poco":
					m.est.objetos.erase(k)
	flores(m, Rect2i(3, 2, 55, 8), 25, 7)

static func construcao_jogador(m: Mapa, b: Dictionary) -> void:
	var d: Dictionary = Dados.construcoes[b.tipo]
	var t: Vector2i = d.tam
	var r := Rect2i(int(b.x), int(b.y), t.x, t.y)
	var rotulo: String = d.nome
	if int(b.get("nivel", 0)) > 0:
		rotulo += " grande"
	var textura := "res://arte/objetos/pet-shelter-0-shelter.png"
	m.construcoes_fixas.append({"rect": r, "textura": textura, "cor": d.cor * 1.4, "rotulo": rotulo, "desce": 4.0})
	bloquear_ret(m, r)
	if b.tipo == "silo":
		m.interativos[Jogo.chave(Vector2i(r.position.x + 1, r.end.y - 1))] = {"tipo": "silo"}
		return
	var porta := Vector2i(r.position.x + t.x / 2, r.end.y - 1)
	m.bloquear(porta, 0)
	saida(m, Rect2i(porta, Vector2i(1, 1)), "interior_%d" % int(b.id), Vector2i(6, 7))

# ---------------------------------------------------------------- vila

static func vila(m: Mapa) -> void:
	m.preparar(60, 40, M.GRAMA)
	m.tipo_agua = "rio"
	borda(m, 2, [Rect2i(0, 20, 2, 3), Rect2i(30, 38, 3, 2), Rect2i(29, 0, 3, 2)])
	saida(m, Rect2i(0, 20, 1, 3), "fazenda", Vector2i(57, 21))
	saida(m, Rect2i(30, 39, 3, 1), "floresta", Vector2i(49, 2))
	saida(m, Rect2i(29, 0, 3, 1), "montanha", Vector2i(47, 15))
	caminho(m, Vector2i(0, 20), Vector2i(58, 20))
	caminho(m, Vector2i(30, 0), Vector2i(30, 39))
	# praça
	retangulo(m, Rect2i(22, 12, 18, 7), M.AREIA)
	elipse(m, Vector2(35, 15), 1.6, 1.4, M.AGUA)
	predio(m, Rect2i(22, 4, 8, 5), "Salão da Vila", Color(1.0, 0.95, 0.85), {"tipo": "colecoes"})
	predio(m, Rect2i(14, 12, 6, 5), "Armazém", Color(1.1, 1.0, 0.85), {"tipo": "loja", "loja": "armazem"})
	predio(m, Rect2i(38, 7, 6, 5), "Forja", Color(0.85, 0.8, 0.8), {"tipo": "loja", "loja": "ferreiro"})
	predio(m, Rect2i(8, 23, 6, 5), "Taverna", Color(1.1, 0.9, 0.75), {"tipo": "loja", "loja": "taverna"})
	predio(m, Rect2i(10, 4, 6, 5), "Casa da Celeste", Color(1.0, 0.9, 0.9))
	predio(m, Rect2i(46, 4, 6, 5), "Casa do Bento", Color(0.9, 0.9, 1.0))
	predio(m, Rect2i(42, 23, 6, 5), "Ateliê da Marina", Color(1.0, 0.85, 1.1))
	predio(m, Rect2i(48, 30, 6, 5), "Casa do Augusto", Color(0.95, 0.95, 1.05))
	predio(m, Rect2i(2, 31, 6, 5), "Casa da Lia", Color(1.1, 1.0, 0.9))
	m.est.objetos[Jogo.chave(Vector2i(27, 11))] = {"tipo": "mural"}
	flores(m, Rect2i(2, 2, 56, 36), 60, 11)
	if not m.est.iniciado:
		var rng := RandomNumberGenerator.new()
		rng.seed = 99
		espalhar(m, Rect2i(50, 12, 8, 16), 10, ["arvore"], rng)
		espalhar(m, Rect2i(2, 8, 6, 10), 6, ["arvore"], rng)
	area_forragem(m, Rect2i(34, 30, 12, 7))

# ---------------------------------------------------------------- floresta (rio, rancho, pescaria)

static func floresta(m: Mapa) -> void:
	m.preparar(60, 45, M.GRAMA)
	m.tipo_agua = "rio"
	borda(m, 2, [Rect2i(28, 0, 3, 2), Rect2i(48, 0, 3, 2)])
	saida(m, Rect2i(28, 0, 3, 1), "fazenda", Vector2i(29, 42))
	saida(m, Rect2i(48, 0, 3, 1), "vila", Vector2i(31, 37))
	retangulo(m, Rect2i(2, 34, 56, 9), M.FLORESTA)
	# rio sinuoso
	for x in m.w:
		var meio := 30.0 + sin(x * 0.18) * 2.0
		for y in range(int(meio) - 1, int(meio) + 2):
			m.por_material(Vector2i(x, y), M.AGUA)
		m.por_material(Vector2i(x, int(meio) - 2), M.AREIA)
		m.por_material(Vector2i(x, int(meio) + 2), M.AREIA)
	# ponte
	for x in range(29, 32):
		for y in range(26, 35):
			if m.material(Vector2i(x, y)) == M.AGUA or m.material(Vector2i(x, y)) == M.AREIA:
				m.por_material(Vector2i(x, y), M.PISO)
	caminho(m, Vector2i(29, 0), Vector2i(29, 25))
	caminho(m, Vector2i(49, 0), Vector2i(49, 12))
	caminho(m, Vector2i(29, 12), Vector2i(49, 12))
	caminho(m, Vector2i(14, 20), Vector2i(29, 20))
	retangulo(m, Rect2i(38, 4, 14, 6), M.CAMPO)
	predio(m, Rect2i(31, 4, 6, 5), "Rancho do Tião", Color(1.15, 0.95, 0.85), {"tipo": "loja", "loja": "rancho"})
	predio(m, Rect2i(11, 15, 6, 5), "Pescaria", Color(0.85, 0.95, 1.1), {"tipo": "loja", "loja": "pescaria"})
	for x in range(38, 52):
		m.decoracoes.append({"c": Vector2i(x, 3), "arte": "fence-new-1", "largura": 22.0})
		m.bloquear(Vector2i(x, 3))
	flores(m, Rect2i(2, 2, 56, 22), 40, 23)
	if not m.est.iniciado:
		var rng := RandomNumberGenerator.new()
		rng.seed = 777
		espalhar(m, Rect2i(2, 35, 56, 8), 60, ["arvore", "pinheiro", "arvore", "toco", "mato"], rng)
		espalhar(m, Rect2i(2, 2, 10, 22), 15, ["arvore", "pinheiro"], rng)
		for i in 5:
			var c := Vector2i(rng.randi_range(4, 56), rng.randi_range(5, 24))
			if not m.solido(c):
				m.est.objetos[Jogo.chave(c)] = {"tipo": "arbusto"}
	area_forragem(m, Rect2i(2, 34, 56, 9))

# ---------------------------------------------------------------- montanha (mina, carpintaria, lago)

static func montanha(m: Mapa) -> void:
	m.preparar(50, 32, M.MUSGO)
	m.tipo_agua = "lago"
	borda(m, 2, [Rect2i(19, 30, 3, 2), Rect2i(48, 14, 2, 3)])
	saida(m, Rect2i(19, 31, 3, 1), "fazenda", Vector2i(31, 2))
	saida(m, Rect2i(49, 14, 1, 3), "vila", Vector2i(30, 2))
	retangulo(m, Rect2i(2, 2, 46, 4), M.ROCHA)
	elipse(m, Vector2(34, 22), 8.0, 4.5, M.AGUA)
	caminho(m, Vector2i(20, 31), Vector2i(20, 12))
	caminho(m, Vector2i(9, 12), Vector2i(48, 12))
	caminho(m, Vector2i(24, 6), Vector2i(24, 12))
	predio(m, Rect2i(6, 5, 6, 5), "Carpintaria", Color(1.15, 0.9, 0.8), {"tipo": "loja", "loja": "carpintaria"})
	predio(m, Rect2i(36, 4, 6, 5), "Guilda", Color(0.8, 0.8, 0.9), {"tipo": "loja", "loja": "guilda"})
	# entrada da mina: paredão escuro com boca
	retangulo(m, Rect2i(21, 2, 7, 3), M.VAZIO)
	m.por_material(Vector2i(24, 4), M.ROCHA)
	m.interativos[Jogo.chave(Vector2i(24, 4))] = {"tipo": "mina"}
	m.decoracoes.append({"c": Vector2i(21, 5), "arte": "lake-rock-1", "largura": 50.0})
	m.decoracoes.append({"c": Vector2i(27, 5), "arte": "lake-rock-2", "largura": 50.0})
	m.bloquear(Vector2i(21, 5))
	m.bloquear(Vector2i(27, 5))
	flores(m, Rect2i(2, 6, 46, 24), 30, 31)
	if not m.est.iniciado:
		var rng := RandomNumberGenerator.new()
		rng.seed = 313
		espalhar(m, Rect2i(2, 13, 18, 16), 40, ["pedra", "pedra", "rocha", "arvore", "pinheiro"], rng)
		espalhar(m, Rect2i(42, 17, 6, 12), 10, ["pinheiro", "pedra"], rng)
	area_forragem(m, Rect2i(2, 13, 18, 16))

# ---------------------------------------------------------------- interiores

static func casa(m: Mapa) -> void:
	var nivel := Jogo.nivel_casa
	var largura := 12 if nivel < 2 else 18
	m.preparar(largura, 10, M.PISO)
	m.interior = true
	retangulo(m, Rect2i(0, 0, largura, 2), M.PAREDE)
	retangulo(m, Rect2i(4, 4, 4, 3), M.TAPETE)
	saida(m, Rect2i(5, 9, 2, 1), "fazenda", Vector2i(11, 8))
	m.est.objetos[Jogo.chave(Vector2i(2, 3))] = {"tipo": "cama"}
	m.est.objetos[Jogo.chave(Vector2i(9, 4))] = {"tipo": "mesa"}
	if nivel >= 1:
		m.est.objetos[Jogo.chave(Vector2i(10, 2))] = {"tipo": "fogao"}
	if nivel >= 2:
		retangulo(m, Rect2i(12, 2, 1, 5), M.PAREDE)
		m.est.objetos[Jogo.chave(Vector2i(15, 3))] = {"tipo": "cama"}
		retangulo(m, Rect2i(14, 5, 3, 2), M.TAPETE)

static func estufa(m: Mapa) -> void:
	m.preparar(14, 12, M.TERRA)
	m.interior = true
	retangulo(m, Rect2i(0, 0, 14, 2), M.PAREDE)
	retangulo(m, Rect2i(6, 2, 2, 10), M.PISO)
	saida(m, Rect2i(6, 11, 2, 1), "fazenda", Vector2i(23, 7))

static func interior_animais(m: Mapa, id: int) -> void:
	var b := Jogo.construcao_por_id(id)
	var grande := int(b.get("nivel", 0)) > 0
	m.preparar(16 if grande else 12, 9, M.PISO)
	m.interior = true
	m.construcao_id = id
	retangulo(m, Rect2i(0, 0, m.w, 2), M.PAREDE)
	retangulo(m, Rect2i(1, 3, m.w - 2, 5), M.CAMPO)
	saida(m, Rect2i(5, 8, 2, 1), "fazenda", Vector2i(int(b.get("x", 0)) + int(Dados.construcoes[b.get("tipo", "galinheiro")].tam.x) / 2, int(b.get("y", 0)) + int(Dados.construcoes[b.get("tipo", "galinheiro")].tam.y)))
	m.est.objetos[Jogo.chave(Vector2i(2, 2))] = {"tipo": "cocho"}

# ---------------------------------------------------------------- mina

static func mina(m: Mapa, andar: int) -> void:
	m.preparar(40, 30, M.VAZIO)
	m.andar = andar
	m.escuro = true
	m.tipo_agua = "mina"
	m.est.objetos = {}
	m.est.solo = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = andar * 7919 + Jogo.dia_absoluto() * 31
	# caverna por passeio aleatório
	var c := Vector2i(20, 15)
	var abertos := {}
	for i in 900:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var p := c + Vector2i(dx, dy)
				if p.x > 1 and p.y > 2 and p.x < 38 and p.y < 28:
					m.por_material(p, M.ROCHA)
					abertos[p] = true
		c += [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT][rng.randi() % 4]
		c = Vector2i(clampi(c.x, 3, 36), clampi(c.y, 4, 26))
	# parede de cima visível
	for x in m.w:
		for y in m.h:
			var p := Vector2i(x, y)
			if m.material(p) == M.VAZIO and m.material(p + Vector2i.DOWN) == M.ROCHA:
				m.por_material(p, M.PAREDE)
	# poças nos andares do meio
	if andar >= 10 and andar < 30 and andar % 3 == 0:
		elipse(m, Vector2(rng.randi_range(10, 30), rng.randi_range(10, 20)), 2.5, 1.8, M.AGUA)
	var celulas := []
	for p in abertos:
		if m.material(p) == M.ROCHA:
			celulas.append(p)
	celulas.shuffle()
	var inicio: Vector2i = Vector2i(20, 15)
	if m.material(inicio) != M.ROCHA and not celulas.is_empty():
		inicio = celulas[0]
	m.set_meta("inicio", inicio)
	# escada para subir (volta à montanha)
	m.est.objetos[Jogo.chave(inicio + Vector2i(0, -1))] = {"tipo": "escada_mina", "sobe": true}
	if m.material(inicio + Vector2i(0, -1)) != M.ROCHA:
		m.por_material(inicio + Vector2i(0, -1), M.ROCHA)
	if andar % 5 == 0:
		m.est.objetos[Jogo.chave(inicio + Vector2i(2, -1))] = {"tipo": "elevador"}
		m.por_material(inicio + Vector2i(2, -1), M.ROCHA)
	# pedras e minérios
	var minerio_por_andar := "minerio_cobre"
	if andar >= 30:
		minerio_por_andar = "minerio_ouro"
	elif andar >= 15:
		minerio_por_andar = "minerio_ferro"
	var colocadas := 0
	for p in celulas:
		if (p - inicio).length() < 3.0:
			continue
		if rng.randf() < 0.28:
			var o := {"tipo": "pedra_mina", "hp": 1 + int(andar / 10.0)}
			var sorteio := rng.randf()
			if sorteio < 0.12:
				o = {"tipo": "minerio", "item": minerio_por_andar, "hp": 2 + int(andar / 10.0)}
			elif sorteio < 0.16 and andar >= 5:
				o = {"tipo": "minerio", "item": ["quartzo", "quartzo", "ametista", "esmeralda", "rubi", "diamante"][min(int(andar / 8.0) + rng.randi() % 2, 5)], "hp": 3}
			elif sorteio < 0.18:
				o = {"tipo": "minerio", "item": "argila", "hp": 1}
			m.est.objetos[Jogo.chave(p)] = o
			colocadas += 1
	m.set_meta("pedras", colocadas)
	# monstros
	var qtd := 3 + int(andar / 6.0) + rng.randi() % 3
	var lista := []
	for i in qtd:
		var p: Vector2i = celulas[rng.randi() % celulas.size()]
		if (p - inicio).length() < 6.0 or not m.objeto(p).is_empty():
			continue
		var tipo := "gosma"
		if andar >= 10 and rng.randf() < 0.4:
			tipo = "morcego"
		if andar >= 15 and rng.randf() < 0.3:
			tipo = "gosma_azul"
		if andar >= 25 and rng.randf() < 0.3:
			tipo = "pedrento"
		if andar >= 30 and rng.randf() < 0.3:
			tipo = "gosma_roxa"
		lista.append({"tipo": tipo, "c": p})
	m.set_meta("monstros", lista)
	if andar >= 40 and not Jogo.flags.has("premio_mina"):
		m.est.objetos[Jogo.chave(inicio + Vector2i(0, 2))] = {"tipo": "bau", "itens": _premio_fundo(), "premio": true}

static func _premio_fundo() -> Array:
	var lista := []
	lista.resize(Jogo.SLOTS)
	lista[0] = Jogo.novo_item("diamante", 3)
	lista[1] = Jogo.novo_item("barra_ouro", 10)
	lista[2] = Jogo.novo_item("aspersor_bom", 4)
	lista[3] = Jogo.novo_item("adubo_rapido", 20)
	return lista
