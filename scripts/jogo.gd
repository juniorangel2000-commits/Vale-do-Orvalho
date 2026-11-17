extends Node
## Estado da partida: tempo, dinheiro, inventário, mapas, amizades, animais, progresso.
## Tudo que precisa ser salvo mora aqui. O resto do jogo lê e altera por estas funções.

signal inventario_mudou
signal dinheiro_mudou
signal hora_mudou
signal mensagem(texto: String)
signal energia_mudou
signal desmaiou(motivo: String)

const VERSAO_SAVE := 1
const ARQUIVO_SAVE := "user://vale_do_orvalho.json"
const SLOTS := 36
const SEGUNDOS_POR_10_MIN := 7.0
const HORA_INICIO := 360
const HORA_LIMITE := 1560   # 2h da manhã

var rng := RandomNumberGenerator.new()
var em_partida := false
var pausado := false
var _acumulado := 0.0

# --- dados salvos
var nome_fazendeiro := "Ana"
var nome_fazenda := "Orvalho"
var dinheiro := 500
var total_ganho := 0
var ano := 1
var estacao := 0
var dia := 1
var minutos := HORA_INICIO
var clima := "sol"
var clima_amanha := "sol"
var energia := 270.0
var energia_max := 270
var vida := 100
var vida_max := 100
var inventario: Array = []
var slot := 0
var nivel_ferramenta := {}
var melhoria := {}
var xp := {}
var mapas := {}
var amizade := {}
var conversou_hoje := {}
var presente_hoje := {}
var presentes_semana := {}
var namorando := {}
var noivado := {}
var conjuge := ""
var animais: Array = []
var construcoes: Array = []
var nivel_casa := 0
var caixa_envio: Array = []
var receitas_conhecidas: Array = []
var receitas_cozinha_conhecidas: Array = []
var mina_andar_max := 0
var pedido := {}
var colecoes_entregues := {}
var colecoes_completas: Array = []
var conquistas: Array = []
var stats := {}
var cartas: Array = []
var flags := {}
var feno_silo := 0
var proximo_id := 1
var ultimo_relatorio := {}

# ---------------------------------------------------------------- início

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_criar_controles()

func _criar_controles() -> void:
	var mapa := {
		"cima": [KEY_W, KEY_UP], "baixo": [KEY_S, KEY_DOWN], "esquerda": [KEY_A, KEY_LEFT], "direita": [KEY_D, KEY_RIGHT],
		"usar": [KEY_SPACE, KEY_C], "interagir": [KEY_F, KEY_X], "inventario": [KEY_E, KEY_I, KEY_TAB], "menu": [KEY_ESCAPE],
		"comer": [KEY_Q], "diario": [KEY_J], "social": [KEY_K], "mapa": [KEY_M],
	}
	for acao in mapa:
		if not InputMap.has_action(acao):
			InputMap.add_action(acao)
		for tecla in mapa[acao]:
			var ev := InputEventKey.new()
			ev.physical_keycode = tecla
			InputMap.action_add_event(acao, ev)
	var teclas_slot := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS, KEY_EQUAL]
	for i in 12:
		var nome := "slot%d" % i
		if not InputMap.has_action(nome):
			InputMap.add_action(nome)
			var ev := InputEventKey.new()
			ev.physical_keycode = teclas_slot[i]
			InputMap.action_add_event(nome, ev)

func novo_jogo(fazendeiro: String, fazenda: String) -> void:
	rng.randomize()
	nome_fazendeiro = fazendeiro if fazendeiro.strip_edges() != "" else "Ana"
	nome_fazenda = fazenda if fazenda.strip_edges() != "" else "Orvalho"
	dinheiro = 500
	total_ganho = 0
	ano = 1
	estacao = 0
	dia = 1
	minutos = HORA_INICIO
	clima = "sol"
	clima_amanha = "sol"
	energia_max = 270
	energia = energia_max
	vida_max = 100
	vida = vida_max
	inventario = []
	inventario.resize(SLOTS)
	slot = 0
	for f in ["enxada", "regador", "machado", "picareta", "foice", "vara", "espada"]:
		adicionar(f, 1)
	adicionar("sem_alface", 15)
	nivel_ferramenta = {"enxada": 0, "regador": 0, "machado": 0, "picareta": 0, "foice": 0}
	melhoria = {}
	xp = {}
	for h in Dados.HABILIDADES:
		xp[h] = 0
	mapas = {}
	amizade = {}
	for a in Dados.aldeoes:
		amizade[a] = 0
	conversou_hoje = {}
	presente_hoje = {}
	presentes_semana = {}
	namorando = {}
	noivado = {}
	conjuge = ""
	animais = []
	construcoes = []
	nivel_casa = 0
	caixa_envio = []
	receitas_conhecidas = ["bau", "cerca", "caminho", "tocha", "fornalha"]
	receitas_cozinha_conhecidas = ["omelete", "batata_frita", "milho_assado"]
	mina_andar_max = 0
	pedido = {}
	colecoes_entregues = {}
	colecoes_completas = []
	conquistas = []
	stats = {"colhidos": 0, "peixes": 0, "tipos_peixe": [], "pratos": 0, "fabricados": 0, "presentes": 0}
	cartas = [{"titulo": "Bem-vindo ao vale", "texto": "Querido(a) %s,\n\nA fazenda do seu avô é sua agora. A terra está cheia de mato, mas é boa. Deixei umas sementes de alface na sua bolsa.\n\nPasse no Armazém da Celeste, na vila (saída à direita da fazenda), para comprar mais.\n\nCom carinho,\nPrefeito Augusto" % nome_fazendeiro, "itens": []}]
	flags = {}
	feno_silo = 0
	proximo_id = 1
	ultimo_relatorio = {}
	em_partida = true
	pausado = false
	inventario_mudou.emit()
	dinheiro_mudou.emit()

# ---------------------------------------------------------------- tempo

func _process(delta: float) -> void:
	if not em_partida or pausado:
		return
	_acumulado += delta
	if _acumulado >= SEGUNDOS_POR_10_MIN:
		_acumulado -= SEGUNDOS_POR_10_MIN
		avancar_minutos(10)

func avancar_minutos(m: int) -> void:
	minutos += m
	hora_mudou.emit()
	if minutos >= HORA_LIMITE:
		desmaiou.emit("tarde")

func hora() -> int:
	return int(minutos / 60.0)

func texto_hora() -> String:
	var h := hora() % 24
	var m := minutos % 60
	return "%02d:%02d" % [h, m]

func dia_absoluto() -> int:
	return (ano - 1) * 112 + estacao * 28 + (dia - 1)

func minuto_absoluto() -> int:
	return dia_absoluto() * 1440 + minutos

func dia_semana() -> int:
	return (dia - 1) % 7

func texto_data() -> String:
	return "%s, %d de %s" % [Dados.DIAS_SEMANA[dia_semana()], dia, Dados.ESTACOES[estacao]]

func festival_hoje() -> Dictionary:
	var chave := "%d-%d" % [estacao, dia]
	if Dados.festivais.has(chave):
		return Dados.festivais[chave]
	return {}

func noite() -> bool:
	return minutos >= 1200

# ---------------------------------------------------------------- dinheiro e energia

func ganhar(valor: int) -> void:
	dinheiro += valor
	if valor > 0:
		total_ganho += valor
	dinheiro_mudou.emit()
	_verificar_conquistas()

func gastar(valor: int) -> bool:
	if dinheiro < valor:
		mensagem.emit("Dinheiro insuficiente.")
		return false
	dinheiro -= valor
	dinheiro_mudou.emit()
	return true

func cansar(valor: float) -> void:
	energia = max(energia - valor, -15.0)
	energia_mudou.emit()
	if energia <= -15.0:
		desmaiou.emit("exausto")

func recuperar(valor: float) -> void:
	energia = min(energia + valor, float(energia_max))
	energia_mudou.emit()

func ferir(valor: int) -> void:
	vida = max(vida - valor, 0)
	energia_mudou.emit()
	if vida <= 0:
		desmaiou.emit("ferido")

func curar(valor: int) -> void:
	vida = min(vida + valor, vida_max)
	energia_mudou.emit()

# ---------------------------------------------------------------- inventário

func novo_item(id: String, qtd := 1, origem := "", q := 0) -> Dictionary:
	return {"id": id, "qtd": qtd, "origem": origem, "q": q}

func _pilha_max(id: String) -> int:
	return int(Dados.item(id).get("pilha", 999))

func _mesma(a: Dictionary, id: String, origem: String, q: int) -> bool:
	return a.id == id and String(a.get("origem", "")) == origem and int(a.get("q", 0)) == q

## Coloca no inventário; devolve quantos NÃO couberam.
func adicionar(id: String, qtd := 1, origem := "", q := 0, avisar := false) -> int:
	var resto := adicionar_em(inventario, id, qtd, origem, q)
	inventario_mudou.emit()
	if avisar and qtd - resto > 0:
		mensagem.emit("+%d %s" % [qtd - resto, Dados.nome_item(id, origem)])
	if resto > 0:
		mensagem.emit("Mochila cheia!")
	return resto

func adicionar_em(lista: Array, id: String, qtd: int, origem := "", q := 0) -> int:
	var maxp := _pilha_max(id)
	for i in lista.size():
		if qtd <= 0:
			break
		var s = lista[i]
		if s != null and _mesma(s, id, origem, q) and s.qtd < maxp:
			var cabe: int = min(maxp - int(s.qtd), qtd)
			s.qtd += cabe
			qtd -= cabe
	for i in lista.size():
		if qtd <= 0:
			break
		if lista[i] == null:
			var cabe: int = min(maxp, qtd)
			lista[i] = novo_item(id, cabe, origem, q)
			qtd -= cabe
	return qtd

func cabe(id: String, qtd := 1) -> bool:
	var copia: Array = inventario.duplicate(true)
	return adicionar_em(copia, id, qtd) == 0

func contar(id: String) -> int:
	var t := 0
	for s in inventario:
		if s != null and s.id == id:
			t += int(s.qtd)
	return t

func remover(id: String, qtd := 1) -> bool:
	if contar(id) < qtd:
		return false
	for i in inventario.size():
		var s = inventario[i]
		if s != null and s.id == id and qtd > 0:
			var tira: int = min(int(s.qtd), qtd)
			s.qtd -= tira
			qtd -= tira
			if s.qtd <= 0:
				inventario[i] = null
	inventario_mudou.emit()
	return true

func remover_do_slot(i: int, qtd := 1) -> void:
	var s = inventario[i]
	if s == null:
		return
	s.qtd -= qtd
	if s.qtd <= 0:
		inventario[i] = null
	inventario_mudou.emit()

func tem_ingredientes(ing: Dictionary) -> bool:
	for id in ing:
		if contar(id) < int(ing[id]):
			return false
	return true

func gastar_ingredientes(ing: Dictionary) -> void:
	for id in ing:
		remover(id, int(ing[id]))

func selecionado():
	return inventario[slot]

func id_selecionado() -> String:
	var s = inventario[slot]
	return "" if s == null else String(s.id)

func trocar_slots(a: int, b: int) -> void:
	var t = inventario[a]
	inventario[a] = inventario[b]
	inventario[b] = t
	inventario_mudou.emit()

func nivel_de(ferramenta: String) -> int:
	return int(nivel_ferramenta.get(ferramenta, 0))

# ---------------------------------------------------------------- habilidades

func nivel_habilidade(h: String) -> int:
	var n := 0
	for limite in Dados.XP_NIVEL:
		if int(xp.get(h, 0)) >= limite:
			n += 1
	return n

func ganhar_xp(h: String, valor: int) -> void:
	var antes := nivel_habilidade(h)
	xp[h] = int(xp.get(h, 0)) + valor
	var depois := nivel_habilidade(h)
	if depois > antes:
		mensagem.emit("%s subiu para o nível %d!" % [Dados.NOMES_HABILIDADES[h], depois])
		Som.tocar("nivel", 1.0, false)
		_liberar_receitas()
		if h == "combate":
			vida_max = 100 + depois * 5
		if h == "cultivo" or h == "mineracao" or h == "coleta":
			energia_max = 270 + (nivel_habilidade("cultivo") + nivel_habilidade("mineracao") + nivel_habilidade("coleta")) * 3

func _liberar_receitas() -> void:
	for r in Dados.receitas:
		if r in receitas_conhecidas:
			continue
		var req: Dictionary = Dados.receitas[r].req
		var ok := true
		for h in req:
			if nivel_habilidade(h) < int(req[h]):
				ok = false
		if ok and not req.is_empty():
			receitas_conhecidas.append(r)
			mensagem.emit("Nova receita: %s" % Dados.nome_item(r))

func custo_energia(h: String, base := 2.0) -> float:
	return max(base - nivel_habilidade(h) * 0.1, 0.5)

# ---------------------------------------------------------------- mapas (estado salvo de cada mapa)

func estado_mapa(nome: String) -> Dictionary:
	if not mapas.has(nome):
		mapas[nome] = {"objetos": {}, "solo": {}, "iniciado": false}
	return mapas[nome]

static func chave(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]

static func celula(k: String) -> Vector2i:
	var p := k.split(",")
	return Vector2i(int(p[0]), int(p[1]))

func novo_id() -> int:
	proximo_id += 1
	return proximo_id

# ---------------------------------------------------------------- amizade

func coracoes(npc: String) -> int:
	return int(amizade.get(npc, 0) / 250.0)

func max_coracoes(npc: String) -> int:
	if not Dados.aldeoes[npc].casavel:
		return 10
	if conjuge == npc:
		return 14
	return 10 if namorando.has(npc) else 8

func mudar_amizade(npc: String, valor: int) -> void:
	var limite := max_coracoes(npc) * 250 + 249
	amizade[npc] = clampi(int(amizade.get(npc, 0)) + valor, 0, limite)
	_verificar_conquistas()

func aniversario_hoje(npc: String) -> bool:
	var a: Array = Dados.aldeoes[npc].aniversario
	return int(a[0]) == estacao and int(a[1]) == dia

# ---------------------------------------------------------------- conquistas

func conquistar(id: String) -> void:
	if id in conquistas or not Dados.conquistas.has(id):
		return
	conquistas.append(id)
	Som.tocar("nivel", 0.8, false)
	mensagem.emit("Conquista: %s!" % Dados.conquistas[id].nome)

func _verificar_conquistas() -> void:
	if dinheiro >= 1000:
		conquistar("mil_moedas")
	if total_ganho >= 10000:
		conquistar("dez_mil")
	if total_ganho >= 100000:
		conquistar("cem_mil")
	for npc in amizade:
		if coracoes(npc) >= 5:
			conquistar("amigo")
		if coracoes(npc) >= 10:
			conquistar("melhor_amigo")
	if int(stats.get("peixes", 0)) >= 10:
		conquistar("pescador")
	if Array(stats.get("tipos_peixe", [])).size() >= Dados.peixes.size():
		conquistar("mestre_pescador")
	if mina_andar_max >= 20:
		conquistar("mina_20")
	if mina_andar_max >= 40:
		conquistar("mina_40")
	if conjuge != "":
		conquistar("casamento")
	if colecoes_completas.size() >= Dados.colecoes.size():
		conquistar("colecoes")
	if int(stats.get("pratos", 0)) >= 10:
		conquistar("cozinheiro")
	if animais.size() >= 5:
		conquistar("criador")
	if int(stats.get("fabricados", 0)) >= 50:
		conquistar("artesao")

func somar_stat(nome: String, valor := 1) -> void:
	stats[nome] = int(stats.get(nome, 0)) + valor
	_verificar_conquistas()

# ---------------------------------------------------------------- noite: passagem de dia

## Fecha o dia: vende a caixa, cresce plantas, cuida dos animais, sorteia clima, etc.
## Devolve o relatório mostrado na tela de fim de dia.
func passar_dia(desmaio: String) -> Dictionary:
	var rel := {"vendas": [], "total": 0, "eventos": []}
	# Vendas
	for s in caixa_envio:
		var valor := Dados.preco_venda(s.id, String(s.get("origem", "")), int(s.get("q", 0))) * int(s.qtd)
		rel.vendas.append([Dados.nome_item(s.id, String(s.get("origem", ""))), int(s.qtd), valor])
		rel.total += valor
	caixa_envio = []
	if rel.total > 0:
		ganhar(rel.total)
	# Desmaio
	if desmaio == "tarde" or desmaio == "exausto":
		var multa: int = min(int(dinheiro * 0.1), 1000)
		if multa > 0:
			dinheiro -= multa
			rel.eventos.append("Você desmaiou e alguém te levou para casa. Perdeu %d moedas." % multa)
	# Energia
	if desmaio != "":
		energia = energia_max * 0.5
	elif minutos > 1440:
		energia = energia_max * 0.75
	else:
		energia = energia_max
	vida = vida_max
	# Calendário
	var estacao_antes := estacao
	dia += 1
	if dia > Dados.DIAS_POR_ESTACAO:
		dia = 1
		estacao += 1
		if estacao > 3:
			estacao = 0
			ano += 1
	minutos = HORA_INICIO
	clima = clima_amanha
	clima_amanha = _sortear_clima()
	if estacao != estacao_antes:
		rel.eventos.append("Começou o %s!" % Dados.ESTACOES[estacao].to_lower())
	# Mapas: plantas, solo, máquinas que dependem de dia, objetos que nascem
	_crescer_plantas(estacao != estacao_antes)
	_espalhar_objetos()
	# Animais
	_cuidar_animais(rel)
	# Amizade
	for npc in amizade:
		if not conversou_hoje.has(npc) and int(amizade[npc]) > 0 and npc != conjuge:
			if rng.randf() < 0.5:
				amizade[npc] = max(int(amizade[npc]) - 2, 0)
	conversou_hoje = {}
	presente_hoje = {}
	if dia_semana() == 0:
		presentes_semana = {}
	# Melhoria de ferramenta
	if not melhoria.is_empty() and dia_absoluto() >= int(melhoria.dia):
		cartas.append({"titulo": "Ferramenta pronta", "texto": "Sua %s está pronta. Passe na forja para buscar.\n\n— Bento" % Dados.nome_item(melhoria.ferramenta).to_lower(), "itens": []})
		melhoria.pronta = true
	# Pedido do mural
	if not pedido.is_empty() and dia_absoluto() > int(pedido.prazo):
		rel.eventos.append("O pedido de %s expirou." % Dados.aldeoes[pedido.npc].nome)
		pedido = {}
	if pedido.is_empty() and rng.randf() < 0.5:
		_novo_pedido()
	# Casamento
	if not noivado.is_empty() and dia_absoluto() >= int(noivado.dia):
		conjuge = String(noivado.npc)
		noivado = {}
		rel.eventos.append("Hoje é o dia do seu casamento com %s!" % Dados.aldeoes[conjuge].nome)
		_verificar_conquistas()
	if conjuge != "":
		_ajuda_conjuge(rel)
	# Cartas da estação
	if dia == 1:
		cartas.append({"titulo": "Nova estação", "texto": "Chegaram sementes de %s no armazém! Lembre: o que não é da estação murcha na virada.\n\n— Celeste" % Dados.ESTACOES[estacao].to_lower(), "itens": []})
	if dia_absoluto() == 1:
		cartas.append({"titulo": "Um presente", "texto": "Ouvi dizer que você chegou. Toma umas sementes de batata pra começar.\n\n— Tião", "itens": [["sem_batata", 5]]})
	for npc in Dados.aldeoes:
		if aniversario_hoje(npc):
			rel.eventos.append("Hoje é aniversário de %s." % Dados.aldeoes[npc].nome)
	if not festival_hoje().is_empty():
		rel.eventos.append("Hoje tem %s na vila, das 9h às 14h!" % festival_hoje().nome)
	ultimo_relatorio = rel
	salvar()
	return rel

func _sortear_clima() -> String:
	var proximo_dia := dia + 1
	var e := estacao
	if proximo_dia > 28:
		proximo_dia = 1
		e = (e + 1) % 4
	if Dados.festivais.has("%d-%d" % [e, proximo_dia]) or proximo_dia == 1:
		return "sol"
	var chance: float = [0.2, 0.12, 0.2, 0.25][e]
	if rng.randf() < chance:
		return "neve" if e == 3 else "chuva"
	return "sol"

func _crescer_plantas(virou_estacao: bool) -> void:
	for nome in mapas:
		var est: Dictionary = mapas[nome]
		var coberto: bool = nome == "estufa"
		var molha_chuva: bool = (clima == "chuva") and not coberto
		# aspersores regam ao amanhecer
		var regados_aspersor := {}
		for k in est.objetos:
			var o: Dictionary = est.objetos[k]
			if o.tipo == "aspersor" or o.tipo == "aspersor_bom":
				var c := celula(k)
				var raio := 1
				for dx in range(-raio, raio + 1):
					for dy in range(-raio, raio + 1):
						if o.tipo == "aspersor" and abs(dx) + abs(dy) != 1:
							continue
						if dx == 0 and dy == 0:
							continue
						regados_aspersor[chave(c + Vector2i(dx, dy))] = true
		var remover_solo := []
		for k in est.solo:
			var s: Dictionary = est.solo[k]
			if s.has("cultura"):
				var cult: Dictionary = s.cultura
				var dados_c: Dictionary = Dados.culturas[cult.id]
				if virou_estacao and not coberto and not (estacao in dados_c.estacoes):
					cult.morta = true
				if not cult.get("morta", false) and bool(s.get("regado", false)):
					cult.dias = int(cult.dias) + 1
					if s.get("adubo", "") == "adubo_rapido" and rng.randf() < 0.25:
						cult.dias = int(cult.dias) + 1
			elif not bool(s.get("regado", false)) and not s.has("adubo") and rng.randf() < 0.1 and not coberto:
				remover_solo.append(k)
			s.regado = molha_chuva or regados_aspersor.has(k)
			if estacao == 3 and not coberto and not s.has("cultura"):
				s.regado = false
		for k in remover_solo:
			est.solo.erase(k)
		# caixas de abelha, árvores e outras produções diárias
		for k in est.objetos.keys():
			var o: Dictionary = est.objetos[k]
			if o.tipo == "muda":
				o.dias = int(o.get("dias", 0)) + 1
				if int(o.dias) >= 10:
					est.objetos[k] = {"tipo": "arvore"}
				continue
			if o.tipo == "frutifera":
				o.dias = int(o.get("dias", 0)) + 1
				var f: Dictionary = Dados.frutiferas.get(String(o.especie), {})
				if int(o.dias) >= 28 and not f.is_empty():
					if estacao == int(f.estacao):
						o.frutos = min(int(o.get("frutos", 0)) + 1, 3)
					else:
						o.frutos = 0
				continue
			if o.tipo == "caixa_abelha" and estacao != 3:
				o.dias = int(o.get("dias", 0)) + 1
				if int(o.dias) >= 4 and not o.has("saida"):
					o.saida = "mel"
					o.qtd_saida = 1
					o.pronto_em = 0
					o.dias = 0

func _espalhar_objetos() -> void:
	# Mato e galhos nascem na fazenda; forrageiros nascem na floresta, vila e montanha.
	var faz: Dictionary = estado_mapa("fazenda")
	if faz.iniciado:
		for i in 6:
			var c := Vector2i(rng.randi_range(4, 56), rng.randi_range(12, 42))
			var k := chave(c)
			if not faz.objetos.has(k) and not faz.solo.has(k) and not _ocupado_por_construcao(c):
				faz.objetos[k] = {"tipo": ["mato", "mato", "galho", "pedra"][rng.randi() % 4]}
	var forragens := {
		0: ["alho_selvagem", "dente_leao", "alho_selvagem"],
		1: ["amora", "flor_silvestre", "amora"],
		2: ["cogumelo", "avela", "amora"],
		3: ["raiz_inverno", "cristal_gelo", "raiz_inverno"],
	}
	for nome in mapas:
		for k in mapas[nome].objetos:
			if mapas[nome].objetos[k].tipo == "arbusto":
				mapas[nome].objetos[k].colhido_hoje = false
	for nome in ["floresta", "vila", "montanha"]:
		var est: Dictionary = estado_mapa(nome)
		if not est.iniciado:
			continue
		var existentes := 0
		for k in est.objetos:
			if est.objetos[k].tipo == "forragem":
				existentes += 1
		if existentes > 12:
			continue
		var areas: Array = est.get("areas_forragem", [])
		for i in 4:
			if areas.is_empty():
				break
			var k: String = areas[rng.randi() % areas.size()]
			if not est.objetos.has(k):
				var lista: Array = forragens[estacao]
				est.objetos[k] = {"tipo": "forragem", "item": lista[rng.randi() % lista.size()]}

func _ocupado_por_construcao(c: Vector2i) -> bool:
	for b in construcoes:
		var t: Vector2i = Dados.construcoes[b.tipo].tam
		if c.x >= int(b.x) and c.x < int(b.x) + t.x and c.y >= int(b.y) - 1 and c.y < int(b.y) + t.y + 1:
			return true
	return false

func _cuidar_animais(rel: Dictionary) -> void:
	for a in animais:
		var casa := construcao_por_id(int(a.casa))
		var comeu := false
		if not casa.is_empty() and int(casa.get("cocho", 0)) > 0:
			casa.cocho = int(casa.cocho) - 1
			comeu = true
		elif feno_silo > 0:
			feno_silo -= 1
			comeu = true
		elif estacao != 3 and rng.randf() < 0.5:
			comeu = true # pastou do lado de fora
		if comeu:
			a.dias = int(a.get("dias", 0)) + 1
			var d: Dictionary = Dados.animais[a.tipo]
			if int(a.dias) >= int(d.dias):
				a.dias = 0
				var bom := rng.randf() < float(a.amizade) / 1500.0
				a.produto = String(d.produto_bom if bom else d.produto)
				if d.ferramenta == "" and not casa.is_empty():
					# Ovos aparecem no chão do galinheiro
					var interior: Dictionary = estado_mapa("interior_%d" % int(casa.id))
					for tentativa in 20:
						var c := Vector2i(rng.randi_range(2, 9), rng.randi_range(3, 7))
						if not interior.objetos.has(chave(c)):
							interior.objetos[chave(c)] = {"tipo": "forragem", "item": a.produto}
							break
					a.produto = ""
		else:
			a.amizade = max(int(a.amizade) - 20, 0)
			rel.eventos.append("%s ficou com fome." % a.nome)
		if not bool(a.get("carinho", false)):
			a.amizade = max(int(a.amizade) - 10, 0)
		a.carinho = false

func construcao_por_id(id: int) -> Dictionary:
	for b in construcoes:
		if int(b.id) == id:
			return b
	return {}

func _novo_pedido() -> void:
	var npcs := Dados.aldeoes.keys()
	var npc: String = npcs[rng.randi() % npcs.size()]
	var opcoes := []
	for c in Dados.culturas:
		if estacao in Dados.culturas[c].estacoes and c != "mista":
			opcoes.append(c)
	opcoes.append_array(["lambari", "tilapia", "pedra", "madeira", "minerio_cobre", "ovo", "carpa"])
	var item: String = opcoes[rng.randi() % opcoes.size()]
	var qtd := 1 if Dados.item(item).preco > 40 else rng.randi_range(5, 20)
	pedido = {"npc": npc, "item": item, "qtd": qtd, "prazo": dia_absoluto() + 2,
		"recompensa": max(Dados.item(item).preco * qtd * 3, 150)}

func _ajuda_conjuge(rel: Dictionary) -> void:
	var nome: String = Dados.aldeoes[conjuge].nome
	var sorteio := rng.randf()
	if sorteio < 0.3:
		var faz: Dictionary = estado_mapa("fazenda")
		for k in faz.solo:
			faz.solo[k].regado = true
		rel.eventos.append("%s regou todas as plantas!" % nome)
	elif sorteio < 0.55:
		cartas.append({"titulo": "Café da manhã", "texto": "Fiz isso pra você. Bom trabalho hoje!\n\n— %s" % nome, "itens": [[["omelete", "cafe", "torta_morango", "salada"][rng.randi() % 4], 1]]})
	elif sorteio < 0.7:
		for a in animais:
			a.carinho = true
			a.amizade = min(int(a.amizade) + 10, 1000)
		if not animais.is_empty():
			rel.eventos.append("%s cuidou dos animais." % nome)

# ---------------------------------------------------------------- salvar e carregar

func existe_save() -> bool:
	return FileAccess.file_exists(ARQUIVO_SAVE)

func salvar() -> void:
	var d := {
		"versao": VERSAO_SAVE, "nome_fazendeiro": nome_fazendeiro, "nome_fazenda": nome_fazenda,
		"dinheiro": dinheiro, "total_ganho": total_ganho, "ano": ano, "estacao": estacao, "dia": dia,
		"clima": clima, "clima_amanha": clima_amanha, "energia_max": energia_max, "vida_max": vida_max,
		"inventario": inventario, "nivel_ferramenta": nivel_ferramenta, "melhoria": melhoria, "xp": xp,
		"mapas": mapas, "amizade": amizade, "presentes_semana": presentes_semana, "namorando": namorando,
		"noivado": noivado, "conjuge": conjuge, "animais": animais, "construcoes": construcoes,
		"nivel_casa": nivel_casa, "receitas_conhecidas": receitas_conhecidas,
		"receitas_cozinha_conhecidas": receitas_cozinha_conhecidas, "mina_andar_max": mina_andar_max,
		"pedido": pedido, "colecoes_entregues": colecoes_entregues, "colecoes_completas": colecoes_completas,
		"conquistas": conquistas, "stats": stats, "cartas": cartas, "flags": flags, "feno_silo": feno_silo,
		"proximo_id": proximo_id,
	}
	var f := FileAccess.open(ARQUIVO_SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

func carregar() -> bool:
	if not existe_save():
		return false
	var f := FileAccess.open(ARQUIVO_SAVE, FileAccess.READ)
	if not f:
		return false
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return false
	novo_jogo(String(d.get("nome_fazendeiro", "Ana")), String(d.get("nome_fazenda", "Orvalho")))
	d = migrar(d)
	for campo in ["dinheiro", "total_ganho", "ano", "estacao", "dia", "energia_max", "vida_max", "nivel_casa", "mina_andar_max", "feno_silo", "proximo_id"]:
		set(campo, int(d.get(campo, get(campo))))
	for campo in ["clima", "clima_amanha", "conjuge"]:
		set(campo, String(d.get(campo, get(campo))))
	for campo in ["nivel_ferramenta", "melhoria", "xp", "mapas", "amizade", "presentes_semana", "namorando", "noivado",
			"pedido", "colecoes_entregues", "stats", "flags"]:
		var v = d.get(campo, get(campo))
		if typeof(v) == TYPE_DICTIONARY:
			set(campo, v)
	for campo in ["animais", "construcoes", "receitas_conhecidas", "receitas_cozinha_conhecidas", "colecoes_completas", "conquistas", "cartas"]:
		var v = d.get(campo, get(campo))
		if typeof(v) == TYPE_ARRAY:
			set(campo, v)
	var inv = d.get("inventario", [])
	inventario = []
	inventario.resize(SLOTS)
	for i in min(inv.size(), SLOTS):
		if typeof(inv[i]) == TYPE_DICTIONARY:
			inventario[i] = inv[i]
			inventario[i].qtd = int(inv[i].qtd)
			inventario[i].q = int(inv[i].get("q", 0))
	_normalizar_numeros()
	minutos = HORA_INICIO
	energia = energia_max
	vida = vida_max
	inventario_mudou.emit()
	dinheiro_mudou.emit()
	return true

## Saves de versões antigas são convertidos aqui antes de carregar.
func migrar(d: Dictionary) -> Dictionary:
	var v := int(d.get("versao", 1))
	if v < 1:
		v = 1
	d.versao = VERSAO_SAVE
	return d

## O JSON devolve números como float; aqui voltam a ser inteiros onde importa.
func _normalizar_numeros() -> void:
	for a in animais:
		for k in ["casa", "amizade", "dias", "id"]:
			if a.has(k):
				a[k] = int(a[k])
	for b in construcoes:
		for k in ["id", "x", "y", "nivel", "cocho"]:
			if b.has(k):
				b[k] = int(b[k])
	for k in amizade:
		amizade[k] = int(amizade[k])
	for k in xp:
		xp[k] = int(xp[k])
	for k in nivel_ferramenta:
		nivel_ferramenta[k] = int(nivel_ferramenta[k])
	for nome in mapas:
		var est: Dictionary = mapas[nome]
		for k in est.get("solo", {}):
			var s: Dictionary = est.solo[k]
			if s.has("cultura"):
				s.cultura.dias = int(s.cultura.dias)
		for k in est.get("objetos", {}):
			var o: Dictionary = est.objetos[k]
			for campo in ["hp", "pronto_em", "qtd_saida", "dias", "id"]:
				if o.has(campo):
					o[campo] = int(o[campo])
			if o.has("itens"):
				for s in o.itens:
					if s != null:
						s.qtd = int(s.qtd)
						s.q = int(s.get("q", 0))
