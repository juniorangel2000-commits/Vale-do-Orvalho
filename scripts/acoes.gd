class_name Acoes
## O que acontece quando o jogador usa o item da mão (usar) ou mexe em algo (interagir).
## P é o nó principal (abre menus, mostra mensagens, troca de mapa).

const COLOCAVEIS_RECOLHIVEIS := ["bau", "espantalho", "aspersor", "aspersor_bom", "cerca", "tocha", "barril", "conserveiro",
	"fornalha", "forno_carvao", "prensa_queijo", "batedeira", "tear", "caixa_abelha", "caminho"]

static func _rng() -> RandomNumberGenerator:
	return Jogo.rng

# ---------------------------------------------------------------- usar item da mão

static func usar(P: Node, m: Mapa, c: Vector2i) -> void:
	var s = Jogo.selecionado()
	if s == null:
		return
	var id: String = s.id
	var d: Dictionary = Dados.item(id)
	var jog: Jogador = P.jogador
	if d.tipo == "ferramenta":
		jog.animar_acao(id)
		match id:
			"enxada": _enxada(P, m, c)
			"regador": _regador(P, m, c)
			"machado": _machado(P, m, c)
			"picareta": _picareta(P, m, c)
			"foice": _foice(P, m, c)
			"vara", "vara_fibra": _vara(P, m, c)
			"espada", "espada_aco": P.atacar(id)
			"balde", "tesoura": interagir(P, m, c)
		return
	if d.tipo == "semente":
		_plantar(P, m, c, id)
	elif d.tipo == "muda":
		_plantar_arvore(P, m, c, id)
	elif id == "fertilizante" or id == "adubo_rapido":
		var so := m.solo(c)
		if not so.is_empty() and not so.has("adubo") and (not so.has("cultura") or int(so.cultura.dias) == 0):
			so.adubo = id
			Jogo.remover_do_slot(Jogo.slot)
			m.redesenhar()
	elif id == "escada":
		if m.andar > 0:
			Jogo.remover_do_slot(Jogo.slot)
			P.entrar_mina(m.andar + 1)
	elif bool(d.get("colocavel", false)):
		_colocar(P, m, c, id)
	elif id == "feno":
		interagir(P, m, c)

static func _gastar_energia(h: String, base := 2.0) -> bool:
	if Jogo.energia <= -14:
		Jogo.mensagem.emit("Você está exausto demais.")
		return false
	Jogo.cansar(Jogo.custo_energia(h, base))
	return true

static func _enxada(P: Node, m: Mapa, c: Vector2i) -> void:
	if not _gastar_energia("cultivo"):
		return
	var celulas := [c]
	var nivel := Jogo.nivel_de("enxada")
	for i in range(1, nivel * 2 + 1):
		celulas.append(c + P.jogador.olhando * i)
	for cc in celulas:
		var o := m.objeto(cc)
		if not o.is_empty():
			if o.tipo == "forragem" or o.tipo == "mato":
				continue
			continue
		if m.aravel(cc) and m.solo(cc).is_empty() and not m.interativos.has(Jogo.chave(cc)):
			m.por_solo(cc, {"regado": Jogo.clima == "chuva" and not m.interior})
	Som.tocar("enxada")

static func capacidade_regador() -> int:
	return 40 + Jogo.nivel_de("regador") * 20

static func _regador(P: Node, m: Mapa, c: Vector2i) -> void:
	if m.agua(c) or m.objeto(c).get("tipo", "") == "poco":
		Jogo.flags["agua"] = capacidade_regador()
		Jogo.mensagem.emit("Regador cheio.")
		Som.tocar("splash")
		return
	var agua := int(Jogo.flags.get("agua", 40))
	if agua <= 0:
		Jogo.mensagem.emit("O regador está vazio. Encha num poço, rio ou lago.")
		return
	if not _gastar_energia("cultivo", 1.5):
		return
	var celulas := [c]
	var nivel := Jogo.nivel_de("regador")
	if nivel >= 3:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx != 0 or dy != 0:
					celulas.append(c + Vector2i(dx, dy))
	else:
		for i in range(1, nivel * 2 + 1):
			celulas.append(c + P.jogador.olhando * i)
	Som.tocar("regar")
	var molhou := false
	for cc in celulas:
		var so := m.solo(cc)
		if not so.is_empty() and not bool(so.get("regado", false)):
			so.regado = true
			molhou = true
	if molhou:
		Jogo.flags["agua"] = agua - 1
		m.redesenhar()

static func _machado(P: Node, m: Mapa, c: Vector2i) -> void:
	var o := m.objeto(c)
	if o.is_empty():
		return
	if o.tipo in COLOCAVEIS_RECOLHIVEIS:
		_recolher(P, m, c)
		return
	if not _gastar_energia("coleta"):
		return
	Som.tocar("machado")
	var forca := 1 + Jogo.nivel_de("machado")
	var visual = m.visuais.get(Jogo.chave(c))
	if visual:
		visual.tremer()
	match String(o.tipo):
		"galho":
			m.remover_objeto(c)
			Jogo.adicionar("madeira", _rng().randi_range(1, 2), "", 0, true)
			Jogo.ganhar_xp("coleta", 1)
		"arvore", "pinheiro":
			o.hp = int(o.get("hp", 10)) - forca
			if int(o.hp) <= 0:
				var tipo: String = o.tipo
				m.remover_objeto(c)
				m.por_objeto(c, {"tipo": "toco", "de": tipo})
				Som.tocar("arvore_cai")
				Jogo.adicionar("madeira", _rng().randi_range(8, 12), "", 0, true)
				if _rng().randf() < 0.5:
					Jogo.adicionar("seiva", _rng().randi_range(1, 3), "", 0, true)
				if _rng().randf() < 0.1:
					Jogo.adicionar("madeira_dura", 1, "", 0, true)
				if _rng().randf() < 0.3:
					Jogo.adicionar("semente_arvore", 1, "", 0, true)
				Jogo.ganhar_xp("coleta", 12)
		"toco":
			if Jogo.nivel_de("machado") < 1 and o.has("de") == false:
				Jogo.mensagem.emit("Este toco é duro demais. Melhore o machado na forja.")
				return
			o.hp = int(o.get("hp", 6)) - forca
			if int(o.hp) <= 0:
				m.remover_objeto(c)
				if o.has("de"):
					Jogo.adicionar("madeira", _rng().randi_range(3, 5), "", 0, true)
				else:
					Jogo.adicionar("madeira_dura", 2, "", 0, true)
				Jogo.ganhar_xp("coleta", 5)
		"mato":
			m.remover_objeto(c)
			if _rng().randf() < 0.5:
				Jogo.adicionar("fibra", 1, "", 0, true)
		"muda":
			m.remover_objeto(c)
			Jogo.adicionar("semente_arvore", 1, "", 0, true)
		"frutifera":
			o.hp = int(o.get("hp", 12)) - forca
			if int(o.hp) <= 0:
				m.remover_objeto(c)
				m.por_objeto(c, {"tipo": "toco", "de": "arvore"})
				Som.tocar("arvore_cai")
				Jogo.adicionar("madeira", _rng().randi_range(8, 12), "", 0, true)
				Jogo.ganhar_xp("coleta", 12)

static func _picareta(P: Node, m: Mapa, c: Vector2i) -> void:
	var o := m.objeto(c)
	if o.is_empty():
		var so := m.solo(c)
		if not so.is_empty() and not so.has("cultura"):
			m.remover_solo(c)
		return
	if o.tipo in COLOCAVEIS_RECOLHIVEIS:
		_recolher(P, m, c)
		return
	if not (o.tipo in ["pedra", "rocha", "pedra_mina", "minerio"]):
		return
	if not _gastar_energia("mineracao"):
		return
	Som.tocar("picareta")
	var forca := 1 + Jogo.nivel_de("picareta")
	var visual = m.visuais.get(Jogo.chave(c))
	if visual:
		visual.tremer()
	match String(o.tipo):
		"pedra":
			m.remover_objeto(c)
			Som.tocar("quebrar")
			Jogo.adicionar("pedra", _rng().randi_range(1, 2), "", 0, true)
			if _rng().randf() < 0.05:
				Jogo.adicionar("minerio_cobre", 1, "", 0, true)
			Jogo.ganhar_xp("mineracao", 1)
		"rocha":
			if Jogo.nivel_de("picareta") < 1:
				Jogo.mensagem.emit("Essa rocha é grande demais. Melhore a picareta na forja.")
				return
			o.hp = int(o.get("hp", 8)) - forca
			if int(o.hp) <= 0:
				m.remover_objeto(c)
				Jogo.adicionar("pedra", _rng().randi_range(10, 15), "", 0, true)
				Jogo.ganhar_xp("mineracao", 15)
		"pedra_mina", "minerio":
			o.hp = int(o.get("hp", 1)) - forca
			if int(o.hp) > 0:
				return
			m.remover_objeto(c)
			Som.tocar("quebrar")
			if o.tipo == "minerio":
				var item: String = o.item
				var qtd := 1 if Dados.item(item).tipo == "gema" else _rng().randi_range(1, 3)
				Jogo.adicionar(item, qtd, "", 0, true)
				Jogo.ganhar_xp("mineracao", 5 if item.begins_with("minerio") else 12)
			else:
				Jogo.adicionar("pedra", 1, "", 0, true)
				if _rng().randf() < 0.08:
					Jogo.adicionar("carvao", 1, "", 0, true)
				Jogo.ganhar_xp("mineracao", 1)
			P.pedra_quebrada(c)

static func _foice(P: Node, m: Mapa, c: Vector2i) -> void:
	Jogo.cansar(0.3)
	Som.tocar("foice")
	var celulas := [c]
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if d != -P.jogador.olhando:
			celulas.append(c + d)
	var tem_silo := false
	for b in Jogo.construcoes:
		if b.tipo == "silo":
			tem_silo = true
	for cc in celulas:
		var o := m.objeto(cc)
		if o.get("tipo", "") == "mato":
			m.remover_objeto(cc)
			if tem_silo and Jogo.feno_silo < 240 * _contar_silos() and _rng().randf() < 0.5:
				Jogo.feno_silo += 1
			elif _rng().randf() < 0.5:
				Jogo.adicionar("fibra", 1, "", 0, true)
		var so := m.solo(cc)
		if so.has("cultura") and bool(so.cultura.get("morta", false)):
			so.erase("cultura")
			m.redesenhar()
	P.atacar("foice")

static func _contar_silos() -> int:
	var n := 0
	for b in Jogo.construcoes:
		if b.tipo == "silo":
			n += 1
	return n

static func _vara(P: Node, m: Mapa, c: Vector2i) -> void:
	for i in range(0, 4):
		var cc: Vector2i = c + P.jogador.olhando * i
		if m.agua(cc):
			if Jogo.energia <= -14:
				Jogo.mensagem.emit("Você está exausto demais.")
				return
			Jogo.cansar(Jogo.custo_energia("pesca", 4.0))
			Som.tocar("lancar")
			var mao: Vector2 = P.jogador.global_position + Vector2(P.jogador.olhando) * 12.0 + Vector2(0, -34)
			P.ui.pescar(m.tipo_agua, m.centro(cc), mao)
			return
	Jogo.mensagem.emit("Fique de frente para a água para pescar.")

static func _plantar(P: Node, m: Mapa, c: Vector2i, semente: String) -> void:
	var so := m.solo(c)
	if so.is_empty() or so.has("cultura"):
		return
	var cult := Dados.cultura_da_semente(semente)
	if cult == "":
		return
	if cult == "mista":
		var opcoes := []
		for k in Dados.culturas:
			if k != "mista" and (Jogo.estacao in Dados.culturas[k].estacoes):
				opcoes.append(k)
		if opcoes.is_empty():
			opcoes = ["alface"]
		cult = opcoes[_rng().randi() % opcoes.size()]
		if Jogo.estacao == 3:
			cult = "inverno"
	if cult == "inverno":
		Jogo.mensagem.emit("Nada cresce na terra congelada do inverno (só na estufa).")
		return
	if m.nome != "estufa" and not (Jogo.estacao in Dados.culturas[cult].estacoes):
		Jogo.mensagem.emit("Essa semente não cresce no %s." % Dados.ESTACOES[Jogo.estacao].to_lower())
		return
	so.cultura = {"id": cult, "dias": 0}
	Som.tocar("plantar")
	Jogo.remover_do_slot(Jogo.slot)
	m.redesenhar()

static func _plantar_arvore(P: Node, m: Mapa, c: Vector2i, id: String) -> void:
	if m.nome != "fazenda":
		Jogo.mensagem.emit("Árvores só podem ser plantadas na fazenda.")
		return
	if c == P.jogador.celula() or m.solido(c) or not m.objeto(c).is_empty() or not m.solo(c).is_empty() or not m.aravel(c):
		Jogo.mensagem.emit("Não dá para plantar aqui.")
		return
	if id != "semente_arvore":
		# frutíferas precisam de espaço em volta
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var v := c + Vector2i(dx, dy)
				if (dx != 0 or dy != 0) and (m.solido(v) or not m.solo(v).is_empty()):
					Jogo.mensagem.emit("A muda precisa de espaço livre em volta (3x3).")
					return
		m.por_objeto(c, {"tipo": "frutifera", "especie": id, "dias": 0, "frutos": 0})
	else:
		m.por_objeto(c, {"tipo": "muda", "dias": 0})
	Som.tocar("plantar")
	Jogo.remover_do_slot(Jogo.slot)

static func _colocar(P: Node, m: Mapa, c: Vector2i, id: String) -> void:
	if c == P.jogador.celula():
		return
	if m.solido(c) or not m.objeto(c).is_empty() or m.agua(c) or m.interativos.has(Jogo.chave(c)) or not m.saida_em(c).is_empty():
		Jogo.mensagem.emit("Não dá para colocar aqui.")
		return
	if m.andar > 0:
		Jogo.mensagem.emit("Não dá para construir na mina.")
		return
	if not m.solo(c).is_empty() and id != "aspersor" and id != "aspersor_bom" and id != "espantalho":
		return
	if not m.solo(c).is_empty():
		if m.solo(c).has("cultura"):
			return
		m.remover_solo(c)
	var o := {"tipo": id}
	if id == "bau":
		var itens := []
		itens.resize(Jogo.SLOTS)
		o.itens = itens
	if id == "caixa_abelha":
		o.dias = 0
	m.por_objeto(c, o)
	Som.tocar("porta", 0.6)
	Jogo.remover_do_slot(Jogo.slot)

static func _recolher(P: Node, m: Mapa, c: Vector2i) -> void:
	var o := m.objeto(c)
	if o.tipo == "bau":
		for s in o.itens:
			if s != null:
				Jogo.mensagem.emit("Esvazie o baú antes de recolher.")
				return
	if o.has("saida") and Jogo.minuto_absoluto() >= int(o.pronto_em):
		_coletar_maquina(m, c, o)
	if not Jogo.cabe(o.tipo):
		Jogo.mensagem.emit("Mochila cheia!")
		return
	m.remover_objeto(c)
	Jogo.adicionar(o.tipo, 1)

# ---------------------------------------------------------------- interagir

static func interagir(P: Node, m: Mapa, c: Vector2i) -> bool:
	var o := m.objeto(c)
	var so := m.solo(c)
	if so.has("cultura") and _pronta(so.cultura):
		colher(P, m, c)
		return true
	if not o.is_empty():
		if _interagir_objeto(P, m, c, o):
			return true
	var it: Dictionary = m.interativos.get(Jogo.chave(c), {})
	if not it.is_empty():
		match String(it.tipo):
			"loja": P.ui.abrir_loja(String(it.loja))
			"colecoes": P.ui.abrir_colecoes()
			"mina": P.entrar_mina_menu()
			"silo": Jogo.mensagem.emit("Feno no silo: %d" % Jogo.feno_silo)
			"aviso": P.ui.mostrar_texto(String(it.texto))
		return true
	return false

static func _pronta(cult: Dictionary) -> bool:
	return not bool(cult.get("morta", false)) and int(cult.dias) >= Dados.dias_totais(cult.id)

static func colher(P: Node, m: Mapa, c: Vector2i) -> void:
	var so := m.solo(c)
	var cult: Dictionary = so.cultura
	var dados: Dictionary = Dados.culturas[cult.id]
	var produto: String = dados.produto
	var qtd := 1
	if dados.has("extra_chance") and _rng().randf() < float(dados.extra_chance):
		qtd += 1
	var nivel := Jogo.nivel_habilidade("cultivo")
	var chance_q := 0.02 + nivel * 0.03 + (0.15 if so.get("adubo", "") == "fertilizante" else 0.0)
	var q := 0
	if _rng().randf() < chance_q:
		q = 2 if _rng().randf() < 0.3 else 1
	if not Jogo.cabe(produto, qtd):
		Jogo.mensagem.emit("Mochila cheia!")
		return
	Jogo.adicionar(produto, qtd, "", q, true)
	Som.tocar("colher")
	Jogo.ganhar_xp("cultivo", int(Dados.item(produto).preco / 6.0) + 2)
	Jogo.somar_stat("colhidos")
	Jogo.conquistar("primeira_colheita")
	if int(dados.rebrota) > 0:
		cult.dias = Dados.dias_totais(cult.id) - int(dados.rebrota)
	else:
		so.erase("cultura")
	m.redesenhar()

static func _interagir_objeto(P: Node, m: Mapa, c: Vector2i, o: Dictionary) -> bool:
	var tipo: String = o.tipo
	match tipo:
		"forragem":
			var item: String = o.item
			if not Jogo.cabe(item):
				Jogo.mensagem.emit("Mochila cheia!")
				return true
			var q := 0
			if _rng().randf() < Jogo.nivel_habilidade("coleta") * 0.05:
				q = 1
			Jogo.adicionar(item, 1, "", q, true)
			Som.tocar("pegar")
			if Dados.item(item).tipo == "forragem":
				Jogo.ganhar_xp("coleta", 7)
				if Jogo.nivel_habilidade("coleta") >= 4 and _rng().randf() < 0.2:
					Jogo.adicionar(item, 1)
			m.remover_objeto(c)
			return true
		"caixa_envio":
			var s = Jogo.selecionado()
			if s == null or Dados.item(s.id).tipo == "ferramenta" or Dados.preco_venda(s.id, String(s.get("origem", "")), int(s.get("q", 0))) <= 0:
				P.ui.abrir_venda()
				return true
			Jogo.caixa_envio.append(s.duplicate())
			Som.tocar("moeda", 0.6)
			Jogo.inventario[Jogo.slot] = null
			Jogo.inventario_mudou.emit()
			Jogo.mensagem.emit("Colocado na caixa: %d %s (vende à noite)" % [int(s.qtd), Dados.nome_item(s.id, String(s.get("origem", "")))])
			return true
		"bau":
			P.ui.abrir_bau(o.itens, "Baú")
			if bool(o.get("premio", false)):
				Jogo.flags["premio_mina"] = true
			return true
		"cama":
			P.ui.confirmar("Dormir e terminar o dia?", Callable(P, "dormir"))
			return true
		"fogao":
			P.ui.abrir_cozinha()
			return true
		"mural":
			P.ui.abrir_mural()
			return true
		"poco":
			if Jogo.id_selecionado() == "regador":
				Jogo.flags["agua"] = capacidade_regador()
				Jogo.mensagem.emit("Regador cheio.")
			else:
				Jogo.mensagem.emit("Um poço antigo. A água é fresquinha.")
			return true
		"cocho":
			var b := Jogo.construcao_por_id(m.construcao_id)
			var vagas := int(Dados.construcoes[b.tipo].vagas) * (2 if int(b.get("nivel", 0)) > 0 else 1)
			var atual := int(b.get("cocho", 0))
			if Jogo.id_selecionado() == "feno":
				var por: int = min(Jogo.contar("feno"), vagas - atual)
				if por > 0:
					Jogo.remover("feno", por)
					b.cocho = atual + por
			elif Jogo.feno_silo > 0 and atual < vagas:
				var por2: int = min(Jogo.feno_silo, vagas - atual)
				Jogo.feno_silo -= por2
				b.cocho = atual + por2
				Jogo.mensagem.emit("Cocho abastecido com feno do silo.")
			else:
				Jogo.mensagem.emit("Feno no cocho: %d/%d" % [atual, vagas])
			m.atualizar_objeto(c)
			return true
		"escada_mina":
			Som.tocar("escada")
			if bool(o.get("sobe", false)):
				P.ir_para("montanha", Vector2i(24, 5))
			else:
				P.entrar_mina(m.andar + 1)
			return true
		"elevador":
			P.entrar_mina_menu()
			return true
		"frutifera":
			var f: Dictionary = Dados.frutiferas[o.especie]
			if int(o.get("frutos", 0)) > 0:
				var anos := int((int(o.dias) - 28) / 112.0)
				if Jogo.adicionar(String(f.fruta), int(o.frutos), "", clampi(anos, 0, 2), true) == 0:
					o.frutos = 0
					Som.tocar("colher")
					Jogo.ganhar_xp("coleta", 6)
					m.atualizar_objeto(c)
			elif int(o.dias) < 28:
				Jogo.mensagem.emit("%s: fica adulto em %d dia(s)." % [f.nome, 28 - int(o.dias)])
			else:
				Jogo.mensagem.emit("%s dá frutos no %s." % [f.nome, Dados.ESTACOES[int(f.estacao)].to_lower()])
			return true
		"muda":
			Jogo.mensagem.emit("Uma árvore nova. Vira árvore grande em %d dia(s)." % max(10 - int(o.get("dias", 0)), 1))
			return true
		"arbusto":
			if Jogo.estacao == 1 and not bool(o.get("colhido_hoje", false)):
				o.colhido_hoje = true
				Jogo.adicionar("amora", _rng().randi_range(2, 4), "", 0, true)
				Jogo.ganhar_xp("coleta", 3)
				m.atualizar_objeto(c)
			return true
	if Dados.maquinas.has(tipo):
		_maquina(P, m, c, o)
		return true
	return false

static func _coletar_maquina(m: Mapa, c: Vector2i, o: Dictionary) -> bool:
	var saida: String = o.saida
	var origem: String = String(o.get("origem", ""))
	var qtd := int(o.get("qtd_saida", 1))
	if Jogo.adicionar(saida, qtd, origem, 0, true) > 0:
		return false
	Som.tocar("pegar")
	o.erase("saida")
	o.erase("origem")
	o.erase("qtd_saida")
	o.erase("pronto_em")
	m.atualizar_objeto(c)
	Jogo.ganhar_xp("cultivo", 3)
	return true

static func _maquina(P: Node, m: Mapa, c: Vector2i, o: Dictionary) -> void:
	if o.has("saida"):
		if Jogo.minuto_absoluto() >= int(o.get("pronto_em", 0)):
			_coletar_maquina(m, c, o)
		else:
			var falta := int(o.pronto_em) - Jogo.minuto_absoluto()
			Jogo.mensagem.emit("%s: pronto em %dh%02d." % [Dados.nome_item(o.tipo), int(falta / 60.0), falta % 60])
		return
	var s = Jogo.selecionado()
	if s == null:
		Jogo.mensagem.emit(Dados.nome_item(o.tipo) + ": coloque um item para processar.")
		return
	var id: String = s.id
	var categoria: String = String(Dados.item(id).get("categoria", ""))
	for regra in Dados.maquinas[o.tipo]:
		var entrada: String = regra.entrada
		if entrada == id or (entrada == categoria and categoria != ""):
			var qtd := int(regra.qtd)
			if Jogo.contar(id) < qtd:
				Jogo.mensagem.emit("Precisa de %d %s." % [qtd, Dados.nome_item(id)])
				return
			if regra.has("extra") and Jogo.contar(String(regra.extra)) < 1:
				Jogo.mensagem.emit("Precisa de 1 %s também." % Dados.nome_item(String(regra.extra)))
				return
			Jogo.remover(id, qtd)
			if regra.has("extra"):
				Jogo.remover(String(regra.extra), 1)
			o.saida = regra.saida
			o.qtd_saida = int(regra.get("qtd_saida", 1))
			if bool(regra.get("origem", false)):
				o.origem = id
			o.pronto_em = Jogo.minuto_absoluto() + int(regra.min)
			Som.tocar("clique")
			m.atualizar_objeto(c)
			Jogo.somar_stat("processados")
			return
	Jogo.mensagem.emit("%s não aceita %s." % [Dados.nome_item(o.tipo), Dados.nome_item(id).to_lower()])
