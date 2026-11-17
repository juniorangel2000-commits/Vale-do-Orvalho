extends Node
## Dados fixos do jogo: itens, culturas, receitas, aldeões, lojas, peixes, construções,
## festivais e coleções. Nada aqui muda durante a partida (o estado fica em jogo.gd).

const TILE := 32
const ESTACOES := ["Primavera", "Verão", "Outono", "Inverno"]
const DIAS_SEMANA := ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
const DIAS_POR_ESTACAO := 28
const HABILIDADES := ["cultivo", "coleta", "mineracao", "pesca", "combate"]
const NOMES_HABILIDADES := {"cultivo": "Cultivo", "coleta": "Coleta", "mineracao": "Mineração", "pesca": "Pesca", "combate": "Combate"}
## XP total necessário para cada nível (1 a 10).
const XP_NIVEL := [100, 380, 770, 1300, 2150, 3300, 4800, 6900, 10000, 15000]
const NOMES_NIVEL_FERRAMENTA := ["", "de cobre", "de ferro", "de ouro"]

var itens := {}
var culturas := {}
var receitas := {}
var receitas_cozinha := {}
var maquinas := {}
var aldeoes := {}
var lojas := {}
var peixes := {}
var construcoes := {}
var animais := {}
var festivais := {}
var colecoes := {}
var conquistas := {}

func _ready() -> void:
	_itens()
	_culturas()
	_receitas()
	_maquinas()
	_animais()
	_construcoes()
	_peixes()
	_aldeoes()
	_lojas()
	_festivais()
	_colecoes()
	_conquistas()

# ---------------------------------------------------------------- itens

func _i(id: String, nome: String, preco: int, tipo: String, cor: String, forma: String, extra := {}) -> void:
	var d := {"id": id, "nome": nome, "preco": preco, "tipo": tipo, "cor": Color(cor), "forma": forma, "energia": 0}
	d.merge(extra, true)
	itens[id] = d

func _itens() -> void:
	# Ferramentas (não empilham; nível fica em Jogo.nivel_ferramenta)
	for f in [["enxada", "Enxada"], ["regador", "Regador"], ["machado", "Machado"], ["picareta", "Picareta"],
			["foice", "Foice"], ["vara", "Vara de pesca"], ["espada", "Espada"], ["balde", "Balde de leite"], ["tesoura", "Tesoura"]]:
		_i(f[0], f[1], 0, "ferramenta", "#8a6a48", "ferramenta", {"pilha": 1})
	# Sementes (o preço é o de venda; compra = Dados.culturas[...].preco_semente)
	_i("sem_alface", "Sementes de alface", 10, "semente", "#9bc26b", "semente")
	_i("sem_batata", "Sementes de batata", 25, "semente", "#b89463", "semente")
	_i("sem_morango", "Sementes de morango", 50, "semente", "#e2526a", "semente")
	_i("sem_couve", "Sementes de couve", 30, "semente", "#4f9e4a", "semente")
	_i("sem_margarida", "Sementes de margarida", 15, "semente", "#f2f2f2", "semente")
	_i("sem_tomate", "Sementes de tomate", 25, "semente", "#d9412b", "semente")
	_i("sem_milho", "Sementes de milho", 75, "semente", "#e8c33a", "semente")
	_i("sem_melancia", "Sementes de melancia", 40, "semente", "#3c8a3e", "semente")
	_i("sem_pimenta", "Sementes de pimenta", 20, "semente", "#c8261b", "semente")
	_i("sem_girassol", "Sementes de girassol", 100, "semente", "#f0b81d", "semente")
	_i("sem_abobora", "Sementes de abóbora", 50, "semente", "#e07b23", "semente")
	_i("sem_berinjela", "Sementes de berinjela", 10, "semente", "#6b3a8a", "semente")
	_i("sem_inhame", "Sementes de inhame", 30, "semente", "#9a6b4b", "semente")
	_i("sem_uva", "Sementes de uva", 30, "semente", "#7a3f9e", "semente")
	_i("sem_mista", "Sementes silvestres", 10, "semente", "#a0a070", "semente")
	# Colheitas
	_i("alface", "Alface", 35, "cultura", "#9bc26b", "folha", {"energia": 20, "categoria": "vegetal"})
	_i("batata", "Batata", 80, "cultura", "#c19a6b", "raiz", {"energia": 25, "categoria": "vegetal"})
	_i("morango", "Morango", 120, "cultura", "#e2526a", "baga", {"energia": 50, "categoria": "fruta"})
	_i("couve", "Couve", 110, "cultura", "#4f9e4a", "folha", {"energia": 30, "categoria": "vegetal"})
	_i("margarida", "Margarida", 30, "cultura", "#f7f7f0", "flor", {"energia": 10, "categoria": "flor"})
	_i("tomate", "Tomate", 60, "cultura", "#d9412b", "bola", {"energia": 20, "categoria": "vegetal"})
	_i("milho", "Milho", 50, "cultura", "#e8c33a", "espiga", {"energia": 25, "categoria": "vegetal"})
	_i("melancia", "Melancia", 250, "cultura", "#3c8a3e", "melancia", {"energia": 60, "categoria": "fruta"})
	_i("pimenta", "Pimenta", 40, "cultura", "#c8261b", "baga", {"energia": 5, "categoria": "fruta"})
	_i("girassol", "Girassol", 80, "cultura", "#f0b81d", "flor", {"energia": 15, "categoria": "flor"})
	_i("abobora", "Abóbora", 320, "cultura", "#e07b23", "bola", {"energia": 0, "categoria": "vegetal"})
	_i("berinjela", "Berinjela", 60, "cultura", "#6b3a8a", "raiz", {"energia": 20, "categoria": "vegetal"})
	_i("inhame", "Inhame", 160, "cultura", "#9a6b4b", "raiz", {"energia": 35, "categoria": "vegetal"})
	_i("uva", "Uva", 80, "cultura", "#7a3f9e", "baga", {"energia": 30, "categoria": "fruta"})
	# Recursos
	_i("madeira", "Madeira", 2, "recurso", "#9a6b3e", "tronco")
	_i("pedra", "Pedra", 2, "recurso", "#9a9a94", "pedra")
	_i("fibra", "Fibra", 1, "recurso", "#7fa04a", "fibra")
	_i("seiva", "Seiva", 2, "recurso", "#c98a2a", "garrafa")
	_i("argila", "Argila", 20, "recurso", "#b0714a", "pedra")
	_i("carvao", "Carvão", 15, "recurso", "#2b2b2b", "pedra")
	_i("feno", "Feno", 0, "recurso", "#d8c26a", "fibra")
	_i("madeira_dura", "Madeira de lei", 15, "recurso", "#6a4426", "tronco")
	_i("minerio_cobre", "Minério de cobre", 5, "minerio", "#c87443", "minerio")
	_i("minerio_ferro", "Minério de ferro", 10, "minerio", "#a8a8b0", "minerio")
	_i("minerio_ouro", "Minério de ouro", 25, "minerio", "#e8c33a", "minerio")
	_i("barra_cobre", "Barra de cobre", 60, "barra", "#c87443", "barra")
	_i("barra_ferro", "Barra de ferro", 120, "barra", "#a8a8b0", "barra")
	_i("barra_ouro", "Barra de ouro", 250, "barra", "#e8c33a", "barra")
	_i("quartzo", "Quartzo", 25, "gema", "#e8eef2", "gema")
	_i("ametista", "Ametista", 100, "gema", "#9b59c8", "gema")
	_i("esmeralda", "Esmeralda", 250, "gema", "#2eb872", "gema")
	_i("rubi", "Rubi", 250, "gema", "#d8283c", "gema")
	_i("diamante", "Diamante", 750, "gema", "#bfefff", "gema")
	_i("gosma", "Gosma", 5, "recurso", "#5fc24a", "bola")
	_i("asa_morcego", "Asa de morcego", 15, "recurso", "#4a3a5a", "folha")
	# Coleta (forrageiros)
	_i("alho_selvagem", "Alho-do-campo", 40, "forragem", "#e8e4cf", "raiz", {"energia": 10})
	_i("dente_leao", "Dente-de-leão", 40, "forragem", "#f0d02a", "flor", {"energia": 10})
	_i("amora", "Amora", 20, "forragem", "#5a2a6e", "baga", {"energia": 25, "categoria": "fruta"})
	_i("flor_silvestre", "Flor silvestre", 50, "forragem", "#e87ab0", "flor", {"energia": 5})
	_i("cogumelo", "Cogumelo", 40, "forragem", "#c8a07a", "cogumelo", {"energia": 25})
	_i("avela", "Avelã", 90, "forragem", "#8a5a2a", "bola", {"energia": 15})
	_i("raiz_inverno", "Raiz de inverno", 70, "forragem", "#d8c8a8", "raiz", {"energia": 20})
	_i("cristal_gelo", "Cristal de geada", 60, "forragem", "#cfe8ff", "gema")
	# Peixes
	_i("lambari", "Lambari", 30, "peixe", "#c8d0d8", "peixe", {"energia": 10})
	_i("tilapia", "Tilápia", 60, "peixe", "#8a9aa8", "peixe", {"energia": 15})
	_i("traira", "Traíra", 80, "peixe", "#5a6a3a", "peixe", {"energia": 15})
	_i("carpa", "Carpa", 40, "peixe", "#b89a4a", "peixe", {"energia": 15})
	_i("bagre", "Bagre", 120, "peixe", "#6a5a4a", "peixe", {"energia": 20})
	_i("dourado", "Dourado", 180, "peixe", "#e8a82a", "peixe", {"energia": 25})
	_i("enguia", "Enguia", 150, "peixe", "#3a4a3a", "peixe", {"energia": 20})
	_i("pintado", "Pintado", 200, "peixe", "#9aa0a0", "peixe", {"energia": 25})
	_i("peixe_gelo", "Peixe-de-gelo", 140, "peixe", "#a8d8f0", "peixe", {"energia": 20})
	_i("peixe_orvalho", "Peixe-do-orvalho", 1500, "peixe", "#7ad8e8", "peixe", {"energia": 60})
	_i("bota_velha", "Bota velha", 1, "lixo", "#5a4030", "lixo")
	_i("alga", "Alga", 5, "recurso", "#3a7a4a", "folha", {"energia": 5})
	# Animais
	_i("ovo", "Ovo", 50, "animal", "#f2ead8", "ovo", {"energia": 20})
	_i("ovo_grande", "Ovo grande", 95, "animal", "#f8f2e2", "ovo", {"energia": 30})
	_i("leite", "Leite", 125, "animal", "#fafafa", "garrafa", {"energia": 30})
	_i("leite_grande", "Leite grande", 190, "animal", "#ffffff", "garrafa", {"energia": 40})
	_i("leite_cabra", "Leite de cabra", 225, "animal", "#f2f0e6", "garrafa", {"energia": 40})
	_i("la", "Lã", 340, "animal", "#f0ece0", "la")
	# Artesanais (preço calculado a partir da origem quando houver)
	_i("geleia", "Geleia", 50, "artesanal", "#c8263a", "pote", {"energia": 40})
	_i("conserva", "Conserva", 50, "artesanal", "#7a9a3a", "pote", {"energia": 40})
	_i("suco", "Suco", 50, "artesanal", "#7ab83a", "garrafa", {"energia": 50})
	_i("licor", "Licor", 50, "artesanal", "#8a1a4a", "garrafa", {"energia": 10})
	_i("queijo", "Queijo", 230, "artesanal", "#f0c84a", "queijo", {"energia": 50})
	_i("queijo_cabra", "Queijo de cabra", 400, "artesanal", "#f2e2a8", "queijo", {"energia": 50})
	_i("maionese", "Maionese", 190, "artesanal", "#f8f0c0", "pote", {"energia": 30})
	_i("tecido", "Tecido", 470, "artesanal", "#c8b8e8", "tecido")
	# Comidas
	_i("omelete", "Omelete", 125, "comida", "#f2d24a", "prato", {"energia": 100})
	_i("salada", "Salada", 110, "comida", "#7ab84a", "prato", {"energia": 110})
	_i("sopa_abobora", "Sopa de abóbora", 300, "comida", "#e07b23", "prato", {"energia": 200})
	_i("peixe_assado", "Peixe assado", 100, "comida", "#c88a4a", "prato", {"energia": 120})
	_i("torta_morango", "Torta de morango", 280, "comida", "#e2526a", "prato", {"energia": 180})
	_i("batata_frita", "Batata rústica", 150, "comida", "#d8b04a", "prato", {"energia": 130})
	_i("milho_assado", "Milho na brasa", 90, "comida", "#e8c33a", "prato", {"energia": 90})
	_i("cafe", "Café", 150, "comida", "#4a2a1a", "garrafa", {"energia": 10, "rapido": true})
	_i("pao_queijo", "Pão de queijo", 120, "comida", "#f0d08a", "prato", {"energia": 80})
	# Colocáveis e consumíveis de fabricação
	_i("bau", "Baú", 50, "objeto", "#9a6b3e", "bau", {"colocavel": true})
	_i("espantalho", "Espantalho", 50, "objeto", "#c8a85a", "espantalho", {"colocavel": true})
	_i("aspersor", "Aspersor", 100, "objeto", "#a8a8b0", "aspersor", {"colocavel": true})
	_i("aspersor_bom", "Aspersor de qualidade", 450, "objeto", "#e8c33a", "aspersor", {"colocavel": true})
	_i("fertilizante", "Fertilizante", 2, "consumivel", "#6a4a2a", "saco")
	_i("adubo_rapido", "Adubo acelerador", 20, "consumivel", "#4a8a3a", "saco")
	_i("cerca", "Cerca de madeira", 1, "objeto", "#9a6b3e", "cerca", {"colocavel": true})
	_i("caminho", "Caminho de pedra", 1, "objeto", "#8a8a84", "pedra", {"colocavel": true, "piso": true})
	_i("tocha", "Lampião", 5, "objeto", "#f0a83a", "maquina", {"colocavel": true})
	_i("barril", "Barril", 50, "objeto", "#7a4a2a", "maquina", {"colocavel": true, "maquina": true})
	_i("conserveiro", "Pote de conserva", 50, "objeto", "#c89a5a", "maquina", {"colocavel": true, "maquina": true})
	_i("fornalha", "Fornalha", 50, "objeto", "#8a3a2a", "maquina", {"colocavel": true, "maquina": true})
	_i("forno_carvao", "Forno de carvão", 50, "objeto", "#3a3a3a", "maquina", {"colocavel": true, "maquina": true})
	_i("prensa_queijo", "Prensa de queijo", 50, "objeto", "#d8c89a", "maquina", {"colocavel": true, "maquina": true})
	_i("batedeira", "Batedeira de maionese", 50, "objeto", "#e8e0c8", "maquina", {"colocavel": true, "maquina": true})
	_i("tear", "Tear", 50, "objeto", "#a87a5a", "maquina", {"colocavel": true, "maquina": true})
	_i("caixa_abelha", "Caixa de abelhas", 50, "objeto", "#e8b04a", "maquina", {"colocavel": true, "maquina": true})
	_i("mel", "Mel", 100, "artesanal", "#f0b030", "pote", {"energia": 40})
	_i("isca", "Isca", 1, "consumivel", "#8a5a4a", "minerio")
	_i("escada", "Escada de corda", 10, "consumivel", "#9a6b3e", "cerca")
	_i("pocao", "Tônico de cura", 50, "comida", "#d84a5a", "garrafa", {"energia": 30, "vida": 60})
	# Especiais
	_i("buque", "Buquê", 100, "especial", "#f08ab0", "buque")
	_i("anel_orvalho", "Anel do Orvalho", 2500, "especial", "#7ad8e8", "anel")
	_i("chave_estufa", "Chave da estufa", 0, "especial", "#e8c33a", "anel")
	_i("vara_fibra", "Vara de fibra", 0, "ferramenta", "#6a8a4a", "ferramenta", {"pilha": 1})
	_i("espada_aco", "Espada de aço", 0, "ferramenta", "#c8c8d8", "ferramenta", {"pilha": 1})

func item(id: String) -> Dictionary:
	if itens.has(id):
		return itens[id]
	return {"id": id, "nome": id, "preco": 0, "tipo": "?", "cor": Color.MAGENTA, "forma": "bola", "energia": 0}

func nome_item(id: String, origem := "") -> String:
	var n: String = item(id).nome
	if origem != "":
		match id:
			"geleia", "suco", "licor", "conserva":
				return "%s de %s" % [n, String(item(origem).nome).to_lower()]
			"mel":
				return "Mel de %s" % String(item(origem).nome).to_lower()
	return n

func preco_venda(id: String, origem := "", qualidade := 0) -> int:
	var base: int = item(id).preco
	if origem != "":
		var p: int = item(origem).preco
		match id:
			"geleia", "conserva": base = p * 2 + 50
			"suco": base = int(p * 2.25)
			"licor": base = p * 3
			"mel": base = 100 + p * 2
	return int(base * [1.0, 1.25, 1.5, 2.0][clampi(qualidade, 0, 3)])

func comestivel(id: String) -> bool:
	return int(item(id).energia) > 0 and item(id).tipo != "semente"

# ---------------------------------------------------------------- culturas

func _c(id: String, semente: String, preco_semente: int, estacoes: Array, fases: Array, rebrota: int, extra := {}) -> void:
	var d := {"id": id, "semente": semente, "produto": id, "preco_semente": preco_semente, "estacoes": estacoes,
		"fases": fases, "rebrota": rebrota, "qtd": 1, "alto": false, "cor": item(id).cor}
	d.merge(extra, true)
	culturas[id] = d

func _culturas() -> void:
	_c("alface", "sem_alface", 20, [0], [1, 1, 1, 1], 0)
	_c("batata", "sem_batata", 50, [0], [1, 1, 2, 2], 0, {"extra_chance": 0.2})
	_c("morango", "sem_morango", 100, [0], [1, 2, 2, 3], 4)
	_c("couve", "sem_couve", 60, [0], [1, 2, 2, 1], 0)
	_c("margarida", "sem_margarida", 30, [0], [1, 2, 2, 2], 0)
	_c("tomate", "sem_tomate", 50, [1], [2, 2, 3, 4], 4, {"alto": true})
	_c("milho", "sem_milho", 150, [1, 2], [2, 3, 3, 6], 4, {"alto": true})
	_c("melancia", "sem_melancia", 80, [1], [2, 3, 3, 4], 0)
	_c("pimenta", "sem_pimenta", 40, [1], [1, 1, 1, 2], 3)
	_c("girassol", "sem_girassol", 200, [1, 2], [1, 2, 3, 2], 0, {"alto": true})
	_c("abobora", "sem_abobora", 100, [2], [1, 2, 3, 7], 0)
	_c("berinjela", "sem_berinjela", 20, [2], [1, 1, 1, 2], 5)
	_c("inhame", "sem_inhame", 60, [2], [1, 3, 3, 3], 0)
	_c("uva", "sem_uva", 60, [2], [1, 2, 3, 4], 3, {"alto": true})
	_c("mista", "sem_mista", 20, [0, 1, 2, 3], [1, 2, 2, 2], 0, {"aleatoria": true})

func cultura_da_semente(semente: String) -> String:
	for c in culturas:
		if culturas[c].semente == semente:
			return c
	return ""

func dias_totais(cultura: String) -> int:
	var t := 0
	for f in culturas[cultura].fases:
		t += int(f)
	return t

# ---------------------------------------------------------------- receitas

func _r(id: String, ing: Dictionary, qtd := 1, requisito := {}) -> void:
	receitas[id] = {"id": id, "ing": ing, "qtd": qtd, "req": requisito}

func _rc(id: String, ing: Dictionary, requisito := {}) -> void:
	receitas_cozinha[id] = {"id": id, "ing": ing, "qtd": 1, "req": requisito}

func _receitas() -> void:
	_r("bau", {"madeira": 50})
	_r("cerca", {"madeira": 2}, 2)
	_r("caminho", {"pedra": 1}, 1)
	_r("tocha", {"madeira": 1, "seiva": 2})
	_r("espantalho", {"madeira": 50, "carvao": 1, "fibra": 20}, 1, {"cultivo": 1})
	_r("fertilizante", {"seiva": 2}, 1, {"cultivo": 1})
	_r("sem_mista", {"fibra": 10}, 5, {"coleta": 1})
	_r("forno_carvao", {"madeira": 20, "barra_cobre": 2}, 1, {"coleta": 2})
	_r("aspersor", {"barra_cobre": 1, "barra_ferro": 1}, 1, {"cultivo": 2})
	_r("barril", {"madeira": 30, "barra_cobre": 1, "madeira_dura": 1}, 1, {"cultivo": 6})
	_r("conserveiro", {"madeira": 50, "pedra": 40, "carvao": 8}, 1, {"cultivo": 4})
	_r("fornalha", {"minerio_cobre": 20, "pedra": 25})
	_r("prensa_queijo", {"madeira": 45, "pedra": 45, "madeira_dura": 10, "barra_cobre": 1}, 1, {"cultivo": 6})
	_r("batedeira", {"madeira": 15, "pedra": 15, "quartzo": 1, "barra_cobre": 1}, 1, {"cultivo": 2})
	_r("tear", {"madeira": 60, "fibra": 30, "seiva": 1}, 1, {"cultivo": 7})
	_r("caixa_abelha", {"madeira": 40, "carvao": 8, "barra_ferro": 1}, 1, {"cultivo": 3})
	_r("aspersor_bom", {"barra_ferro": 1, "barra_ouro": 1, "quartzo": 1}, 1, {"cultivo": 6})
	_r("adubo_rapido", {"fibra": 5, "gosma": 5}, 2, {"cultivo": 3})
	_r("isca", {"asa_morcego": 1}, 5, {"pesca": 2})
	_r("escada", {"madeira": 30, "fibra": 10}, 1, {"mineracao": 2})
	_r("pocao", {"cogumelo": 1, "amora": 2}, 1, {"combate": 1})
	_rc("omelete", {"ovo": 1, "leite": 1})
	_rc("salada", {"alface": 1, "dente_leao": 1})
	_rc("sopa_abobora", {"abobora": 1, "leite": 1})
	_rc("peixe_assado", {"tilapia": 1})
	_rc("torta_morango", {"morango": 2, "ovo": 1})
	_rc("batata_frita", {"batata": 2})
	_rc("milho_assado", {"milho": 1})
	_rc("pao_queijo", {"queijo": 1, "ovo": 1})
	_rc("cafe", {"avela": 2})

# ---------------------------------------------------------------- máquinas
## Cada máquina: lista de regras. "entrada" pode ser um id, "fruta" ou "vegetal".
## "saida" é o id; "origem" true guarda de onde veio (Suco de tomate). Tempo em minutos de jogo.

func _maquinas() -> void:
	maquinas = {
		"barril": [{"entrada": "fruta", "qtd": 1, "saida": "licor", "origem": true, "min": 4320},
			{"entrada": "vegetal", "qtd": 1, "saida": "suco", "origem": true, "min": 2880}],
		"conserveiro": [{"entrada": "fruta", "qtd": 1, "saida": "geleia", "origem": true, "min": 3000},
			{"entrada": "vegetal", "qtd": 1, "saida": "conserva", "origem": true, "min": 3000}],
		"fornalha": [{"entrada": "minerio_cobre", "qtd": 5, "saida": "barra_cobre", "min": 30, "extra": "carvao"},
			{"entrada": "minerio_ferro", "qtd": 5, "saida": "barra_ferro", "min": 120, "extra": "carvao"},
			{"entrada": "minerio_ouro", "qtd": 5, "saida": "barra_ouro", "min": 300, "extra": "carvao"},
			{"entrada": "quartzo", "qtd": 1, "saida": "quartzo", "min": 60}],
		"forno_carvao": [{"entrada": "madeira", "qtd": 10, "saida": "carvao", "min": 30}],
		"prensa_queijo": [{"entrada": "leite", "qtd": 1, "saida": "queijo", "min": 200},
			{"entrada": "leite_grande", "qtd": 1, "saida": "queijo", "min": 200, "qtd_saida": 2},
			{"entrada": "leite_cabra", "qtd": 1, "saida": "queijo_cabra", "min": 200}],
		"batedeira": [{"entrada": "ovo", "qtd": 1, "saida": "maionese", "min": 180},
			{"entrada": "ovo_grande", "qtd": 1, "saida": "maionese", "min": 180, "qtd_saida": 2}],
		"tear": [{"entrada": "la", "qtd": 1, "saida": "tecido", "min": 240}],
		"tocha": [],
		"caixa_abelha": [],
	}

# ---------------------------------------------------------------- animais e construções

func _animais() -> void:
	animais = {
		"galinha": {"nome": "Galinha", "preco": 800, "casa": "galinheiro", "produto": "ovo", "produto_bom": "ovo_grande", "dias": 1, "ferramenta": "", "cor": Color("#f2ead8")},
		"pato": {"nome": "Pato", "preco": 1200, "casa": "galinheiro", "produto": "ovo", "produto_bom": "ovo_grande", "dias": 2, "ferramenta": "", "cor": Color("#e8e0b0"), "req_nivel": 1},
		"vaca": {"nome": "Vaca", "preco": 1500, "casa": "estabulo", "produto": "leite", "produto_bom": "leite_grande", "dias": 1, "ferramenta": "balde", "cor": Color("#f0e8e0")},
		"cabra": {"nome": "Cabra", "preco": 2000, "casa": "estabulo", "produto": "leite_cabra", "produto_bom": "leite_cabra", "dias": 2, "ferramenta": "balde", "cor": Color("#d8c8b0"), "req_nivel": 1},
		"ovelha": {"nome": "Ovelha", "preco": 4000, "casa": "estabulo", "produto": "la", "produto_bom": "la", "dias": 3, "ferramenta": "tesoura", "cor": Color("#f8f8f0"), "req_nivel": 1},
	}

func _construcoes() -> void:
	construcoes = {
		"galinheiro": {"nome": "Galinheiro", "preco": 4000, "ing": {"madeira": 300, "pedra": 100}, "tam": Vector2i(6, 3), "vagas": 4, "cor": Color("#b88a5a")},
		"estabulo": {"nome": "Estábulo", "preco": 6000, "ing": {"madeira": 350, "pedra": 150}, "tam": Vector2i(7, 4), "vagas": 4, "cor": Color("#a85a3a")},
		"silo": {"nome": "Silo", "preco": 100, "ing": {"pedra": 100, "argila": 10, "barra_cobre": 5}, "tam": Vector2i(3, 3), "vagas": 0, "cor": Color("#c8c0b0")},
		"melhoria_galinheiro": {"nome": "Galinheiro grande", "preco": 10000, "ing": {"madeira": 400, "pedra": 150}, "melhoria": "galinheiro"},
		"melhoria_estabulo": {"nome": "Estábulo grande", "preco": 12000, "ing": {"madeira": 450, "pedra": 200}, "melhoria": "estabulo"},
		"casa_1": {"nome": "Cozinha na casa", "preco": 10000, "ing": {"madeira": 450}, "casa": 1},
		"casa_2": {"nome": "Quarto extra na casa", "preco": 50000, "ing": {"madeira_dura": 150}, "casa": 2},
	}

# ---------------------------------------------------------------- peixes
## lugares: "rio", "lago", "mina". estacoes: lista; hora: [início, fim) em horas; chuva: null/true/false

func _peixes() -> void:
	peixes = {
		"lambari": {"lugares": ["rio", "lago"], "estacoes": [0, 1, 2, 3], "hora": [6, 26], "dif": 15, "chance": 1.0},
		"carpa": {"lugares": ["lago"], "estacoes": [0, 1, 2], "hora": [6, 26], "dif": 15, "chance": 0.9},
		"tilapia": {"lugares": ["rio", "lago"], "estacoes": [1, 2], "hora": [6, 14], "dif": 30, "chance": 0.7},
		"traira": {"lugares": ["lago"], "estacoes": [0, 2, 3], "hora": [6, 20], "dif": 40, "chance": 0.6},
		"bagre": {"lugares": ["rio"], "estacoes": [0, 2], "hora": [6, 26], "dif": 60, "chance": 0.4, "chuva": true},
		"dourado": {"lugares": ["rio"], "estacoes": [1], "hora": [6, 19], "dif": 65, "chance": 0.35},
		"enguia": {"lugares": ["rio"], "estacoes": [0, 2], "hora": [16, 26], "dif": 70, "chance": 0.35, "chuva": true},
		"pintado": {"lugares": ["rio"], "estacoes": [1, 2], "hora": [18, 26], "dif": 75, "chance": 0.3},
		"peixe_gelo": {"lugares": ["lago", "mina"], "estacoes": [3], "hora": [6, 26], "dif": 50, "chance": 0.5},
		"peixe_orvalho": {"lugares": ["lago"], "estacoes": [0], "hora": [6, 10], "dif": 95, "chance": 0.05, "nivel": 6, "chuva": true},
	}

# ---------------------------------------------------------------- aldeões
## agenda: lista de [hora, mapa, x, y]. O aldeão anda até o ponto a partir da hora.

func _a(id: String, nome: String, cor: String, aniv: Array, casavel: bool, gostos: Dictionary, agenda: Array, falas: Dictionary, extra := {}) -> void:
	var d := {"id": id, "nome": nome, "cor": Color(cor), "aniversario": aniv, "casavel": casavel,
		"ama": gostos.get("ama", []), "gosta": gostos.get("gosta", []), "odeia": gostos.get("odeia", []),
		"agenda": agenda, "falas": falas}
	d.merge(extra, true)
	aldeoes[id] = d

func _aldeoes() -> void:
	_a("celeste", "Celeste", "#e8b8a8", [0, 9], false,
		{"ama": ["margarida", "torta_morango", "flor_silvestre"], "gosta": ["ovo", "leite", "morango"], "odeia": ["bota_velha", "gosma"]},
		[[6, "vila", 18, 13], [9, "vila", 18, 13], [18, "vila", 30, 20], [21, "vila", 18, 11]],
		{"geral": ["Bom dia! As sementes chegaram fresquinhas hoje.", "Meu armazém está aqui há trinta anos. Já vi muita gente chegar e partir.",
			"Plante o que a estação pede, querido. A terra sabe o que faz.", "Você está com cara de quem trabalhou desde cedo!"],
		 "primavera": ["A primavera é minha estação preferida. Tudo recomeça."], "verao": ["Que calor! Lembre de regar tudo duas vezes... brincadeira, uma basta."],
		 "outono": ["As abóboras deste ano vão ser enormes, eu sinto."], "inverno": ["No inverno a vila fica quietinha. Eu gosto."],
		 "coracao4": ["Sabe, você me lembra meu filho. Ele também tinha mãos de lavrador."], "coracao8": ["Você virou parte da família do vale, sabia?"]})
	_a("bento", "Bento", "#8a6a5a", [3, 4], false,
		{"ama": ["barra_ouro", "rubi", "diamante"], "gosta": ["barra_ferro", "carvao", "cafe"], "odeia": ["margarida", "salada"]},
		[[6, "vila", 40, 11], [9, "vila", 40, 13], [17, "vila", 30, 21], [22, "vila", 40, 11]],
		{"geral": ["Hm. Precisa de alguma coisa da forja?", "Traga barras e eu deixo suas ferramentas novinhas.", "O ferro da mina daqui é bom. Teimoso, mas bom.",
			"Não gosto de conversa fiada. Mas você até que é tolerável."],
		 "inverno": ["Inverno é bom pra forja. O fogo esquenta a oficina."], "coracao4": ["Meu pai me ensinou a martelar quando eu tinha sete anos."],
		 "coracao8": ["Fiz uma coisinha pra você... não, esqueci em casa. Outro dia."]})
	_a("rosa", "Rosa", "#c84a5a", [2, 20], false,
		{"ama": ["licor", "madeira_dura", "abobora"], "gosta": ["madeira", "cafe", "queijo"], "odeia": ["gosma", "alga"]},
		[[6, "montanha", 10, 8], [9, "montanha", 10, 10], [18, "vila", 30, 19], [21, "montanha", 10, 8]],
		{"geral": ["Quer construir alguma coisa? É só pedir.", "Madeira boa faz casa boa. Simples assim.", "Meu galpão está sempre cheio de serragem.",
			"Já reformei metade das casas do vale."],
		 "coracao4": ["Eu e Bento fomos colegas de escola. Ele sempre foi ranzinza."], "coracao8": ["Se um dia quiser ampliar sua casa, faço desconto. Só pra você."]})
	_a("tiao", "Tião", "#6a8a4a", [1, 17], false,
		{"ama": ["queijo", "queijo_cabra", "milho_assado"], "gosta": ["feno", "milho", "ovo"], "odeia": ["peixe_gelo"]},
		[[6, "floresta", 32, 10], [9, "floresta", 32, 12], [17, "floresta", 26, 18], [21, "floresta", 32, 10]],
		{"geral": ["Bicho bem cuidado é bicho feliz. E bicho feliz produz mais.", "Fale com seus animais todo dia. Eles gostam.",
			"O feno do silo dura o inverno todo, se você cortar bastante capim.", "Ê lasqueira, que dia bonito!"],
		 "coracao4": ["Minha primeira vaca se chamava Estrela. Saudade."], "coracao8": ["Você é o melhor criador que o vale já teve. Não conta pra ninguém."]})
	_a("nonato", "Nonato", "#5a7a9a", [3, 18], false,
		{"ama": ["dourado", "peixe_orvalho", "pintado"], "gosta": ["lambari", "tilapia", "cafe"], "odeia": ["bota_velha"]},
		[[6, "floresta", 14, 30], [8, "floresta", 18, 33], [18, "floresta", 14, 30]],
		{"geral": ["O rio conversa com quem tem paciência.", "Isca boa, linha firme e calma. É tudo que precisa.",
			"Dizem que no lago da montanha mora um peixe que brilha. Só aparece em manhã de chuva, na primavera.", "Meu neto Davi pesca melhor que eu já. Não conta pra ele."],
		 "coracao4": ["Pesco neste rio há cinquenta anos."], "coracao8": ["Tome conta do Davi por mim, quando eu não estiver mais aqui."]})
	_a("augusto", "Augusto", "#4a4a6a", [0, 26], false,
		{"ama": ["licor", "torta_morango", "esmeralda"], "gosta": ["cafe", "queijo"], "odeia": ["gosma", "fibra"]},
		[[6, "vila", 24, 8], [9, "vila", 24, 18], [13, "vila", 30, 22], [18, "vila", 24, 8]],
		{"geral": ["Bem-vindo ao Vale do Orvalho! Ou melhor, bem-vindo de volta.", "O mural da praça tem pedidos dos moradores. Dá uma olhada!",
			"A vila precisa de gente como você.", "Se completar as coleções do salão, a estufa velha pode voltar a funcionar."],
		 "coracao4": ["Ser prefeito de um vale pequeno é bom. Todo mundo se conhece."], "coracao8": ["Você mudou este lugar. Obrigado."]})
	_a("lia", "Lia", "#d88a3a", [1, 5], true,
		{"ama": ["sopa_abobora", "morango", "torta_morango"], "gosta": ["leite", "girassol", "uva"], "odeia": ["peixe_gelo", "bota_velha", "gosma"]},
		[[6, "vila", 12, 22], [12, "vila", 10, 24], [24, "vila", 12, 22]],
		{"geral": ["A taverna abre ao meio-dia! Aparece pra comer alguma coisa.", "Estou testando uma receita nova de sopa. Quer provar depois?",
			"Cozinhar pra vila inteira cansa, mas é o que eu amo.", "Você parece faminto. Sempre parece, na verdade."],
		 "verao": ["No verão vendo suco gelado. Sai que é uma beleza!"], "coracao4": ["Herdei a taverna da minha avó. Às vezes queria viajar um pouco."],
		 "coracao6": ["Fica mais um pouco? A taverna fica mais gostosa com você aqui."], "coracao8": ["Eu... penso em você quando estou cozinhando. Pronto, falei."],
		 "casado": ["Fiz café pra você. Bom dia, amor.", "Hoje vou cozinhar algo especial. Volte cedo!", "Nossa casa ficou tão aconchegante."]})
	_a("davi", "Davi", "#3a8aaa", [0, 22], true,
		{"ama": ["peixe_assado", "pintado", "dourado"], "gosta": ["lambari", "cafe", "avela"], "odeia": ["margarida", "salada"]},
		[[6, "floresta", 20, 30], [9, "floresta", 22, 34], [15, "vila", 34, 26], [20, "floresta", 20, 30]],
		{"geral": ["Ei! Pegou alguma coisa boa hoje?", "Vovô fala demais, mas sabe tudo sobre peixe.", "Um dia vou pescar o Peixe-do-orvalho. Anota aí.",
			"Gosto de ficar aqui ouvindo o rio."],
		 "coracao4": ["Meus pais moram na capital. Prefiro aqui, com o vovô."], "coracao6": ["Quer pescar junto amanhã? Ou... qualquer dia."],
		 "coracao8": ["Acho que gosto de você mais do que de pescar. E isso é muito."],
		 "casado": ["Peguei uns peixes pro jantar.", "Bom dia! Já reguei umas plantas pra você.", "Te amo, sabia?"]})
	_a("marina", "Marina", "#9a5ac8", [2, 7], true,
		{"ama": ["ametista", "girassol", "flor_silvestre"], "gosta": ["quartzo", "margarida", "cafe"], "odeia": ["gosma", "bota_velha", "carvao"]},
		[[6, "vila", 44, 24], [10, "vila", 50, 30], [16, "floresta", 10, 14], [20, "vila", 44, 24]],
		{"geral": ["Estou pintando o rio hoje. A luz está perfeita.", "As cores do outono são as mais difíceis de pintar.",
			"Você já reparou como o orvalho brilha de manhã?", "Arte não paga as contas, mas paga a alma."],
		 "coracao4": ["Vim da cidade pra pintar o vale e nunca mais fui embora."], "coracao6": ["Posso te pintar um dia? Fica parado, só um pouquinho."],
		 "coracao8": ["Você é minha cor preferida. Isso soou estranho? Talvez."],
		 "casado": ["Pintei nossa fazenda hoje.", "Bom dia! O céu está lindo.", "Fico feliz de acordar aqui."]})
	_a("caio", "Caio", "#5a5a5a", [3, 12], true,
		{"ama": ["esmeralda", "omelete", "rubi"], "gosta": ["barra_ferro", "cafe", "pocao"], "odeia": ["margarida", "flor_silvestre"]},
		[[6, "montanha", 30, 12], [10, "montanha", 28, 16], [19, "vila", 32, 22], [23, "montanha", 30, 12]],
		{"geral": ["A mina é perigosa. Leve comida.", "Vi uma gosma enorme no andar vinte. Cuidado.", "Treino com a espada toda manhã.",
			"Se precisar de equipamento, a guilda fica aqui na montanha."],
		 "coracao4": ["Eu era soldado. Agora só protejo a entrada da mina. É mais tranquilo."], "coracao6": ["Você é corajoso. Gosto disso."],
		 "coracao8": ["Quando você entra na mina eu fico preocupado. Isso deve significar alguma coisa."],
		 "casado": ["Afiei suas ferramentas.", "Bom dia. Dormiu bem?", "Ninguém mexe com a nossa fazenda."]})

func estacao_chave(e: int) -> String:
	return ["primavera", "verao", "outono", "inverno"][e]

# ---------------------------------------------------------------- lojas
## Cada loja: dono, horário, porta (mapa, x, y), itens vendidos ([id, preço, estações ou []]).

func _lojas() -> void:
	lojas = {
		"armazem": {"nome": "Armazém da Celeste", "dono": "celeste", "abre": 9, "fecha": 18, "folga": 2,
			"itens": [["sem_alface", 20, [0]], ["sem_batata", 50, [0]], ["sem_couve", 60, [0]], ["sem_margarida", 30, [0]], ["sem_morango", 100, [0]],
				["sem_tomate", 50, [1]], ["sem_milho", 150, [1, 2]], ["sem_melancia", 80, [1]], ["sem_pimenta", 40, [1]], ["sem_girassol", 200, [1, 2]],
				["sem_abobora", 100, [2]], ["sem_berinjela", 20, [2]], ["sem_inhame", 60, [2]], ["sem_uva", 60, [2]],
				["fertilizante", 100, []], ["buque", 200, []], ["cafe", 300, []]]},
		"ferreiro": {"nome": "Forja do Bento", "dono": "bento", "abre": 9, "fecha": 16, "folga": -1,
			"itens": [["minerio_cobre", 75, []], ["minerio_ferro", 150, []], ["carvao", 150, []], ["minerio_ouro", 400, []]], "melhorias": true},
		"carpintaria": {"nome": "Carpintaria da Rosa", "dono": "rosa", "abre": 9, "fecha": 17, "folga": 1,
			"itens": [["madeira", 10, []], ["pedra", 20, []], ["madeira_dura", 100, []]], "construcoes": true},
		"rancho": {"nome": "Rancho do Tião", "dono": "tiao", "abre": 9, "fecha": 16, "folga": 0,
			"itens": [["feno", 50, []], ["balde", 1000, []], ["tesoura", 1000, []]], "animais": true},
		"pescaria": {"nome": "Pescaria do Nonato", "dono": "nonato", "abre": 9, "fecha": 17, "folga": -1,
			"itens": [["isca", 5, []], ["vara_fibra", 1800, []]]},
		"taverna": {"nome": "Taverna da Lia", "dono": "lia", "abre": 12, "fecha": 24, "folga": -1,
			"itens": [["salada", 220, []], ["omelete", 250, []], ["cafe", 300, []], ["pao_queijo", 240, []], ["sopa_abobora", 600, [2]]], "receitas": true},
		"guilda": {"nome": "Guilda dos Aventureiros", "dono": "caio", "abre": 14, "fecha": 22, "folga": -1,
			"itens": [["espada_aco", 2000, []], ["pocao", 150, []], ["escada", 300, []]]},
	}

# ---------------------------------------------------------------- festivais

func _festivais() -> void:
	festivais = {
		"0-13": {"nome": "Festa das Flores", "desc": "A vila se enche de flores. Converse com todos e dance com quem gosta de você.", "tipo": "danca"},
		"1-11": {"nome": "Luau do Rio", "desc": "Toda a vila contribui com um ingrediente para a grande sopa.", "tipo": "sopa"},
		"2-16": {"nome": "Feira da Colheita", "desc": "Mostre seu melhor produto e ganhe prêmios.", "tipo": "feira"},
		"3-25": {"nome": "Noite das Lanternas", "desc": "Troca de presentes à luz das lanternas.", "tipo": "presentes"},
	}

# ---------------------------------------------------------------- coleções do salão (mural)

func _colecoes() -> void:
	colecoes = {
		"lavoura": {"nome": "Coleção da Lavoura", "itens": {"alface": 1, "batata": 1, "tomate": 1, "milho": 1, "abobora": 1, "uva": 1}, "premio": ["aspersor", 5]},
		"campo": {"nome": "Coleção do Campo", "itens": {"alho_selvagem": 1, "dente_leao": 1, "amora": 1, "cogumelo": 1, "avela": 1, "raiz_inverno": 1}, "premio": ["cafe", 5]},
		"rio": {"nome": "Coleção do Rio", "itens": {"lambari": 1, "tilapia": 1, "traira": 1, "bagre": 1, "dourado": 1, "carpa": 1}, "premio": ["vara_fibra", 1]},
		"mina": {"nome": "Coleção da Mina", "itens": {"barra_cobre": 2, "barra_ferro": 2, "barra_ouro": 1, "quartzo": 3, "ametista": 1, "esmeralda": 1}, "premio": ["fornalha", 2]},
		"rancho": {"nome": "Coleção do Rancho", "itens": {"ovo": 3, "leite": 2, "la": 1, "queijo": 1, "maionese": 1, "mel": 1}, "premio": ["prensa_queijo", 1]},
		"artesao": {"nome": "Coleção do Artesão", "itens": {"geleia": 1, "conserva": 1, "suco": 1, "licor": 1, "tecido": 1, "madeira_dura": 10}, "premio": ["barril", 2]},
	}

func _conquistas() -> void:
	conquistas = {
		"primeira_colheita": {"nome": "Primeira colheita", "desc": "Colha sua primeira planta."},
		"mil_moedas": {"nome": "Pé-de-meia", "desc": "Junte 1.000 moedas de uma vez."},
		"dez_mil": {"nome": "Fazendeiro próspero", "desc": "Ganhe 10.000 moedas no total."},
		"cem_mil": {"nome": "Barão do vale", "desc": "Ganhe 100.000 moedas no total."},
		"amigo": {"nome": "Bom vizinho", "desc": "Chegue a 5 corações com alguém."},
		"melhor_amigo": {"nome": "Melhor amigo", "desc": "Chegue a 10 corações com alguém."},
		"pescador": {"nome": "Pescador", "desc": "Pesque 10 peixes."},
		"mestre_pescador": {"nome": "Mestre do rio", "desc": "Pesque todos os tipos de peixe."},
		"mina_20": {"nome": "Fundo da terra", "desc": "Chegue ao andar 20 da mina."},
		"mina_40": {"nome": "Coração da montanha", "desc": "Chegue ao andar 40 da mina."},
		"casamento": {"nome": "Felizes para sempre", "desc": "Case-se com alguém do vale."},
		"colecoes": {"nome": "Salão restaurado", "desc": "Complete todas as coleções do salão."},
		"cozinheiro": {"nome": "Cozinheiro", "desc": "Cozinhe 10 pratos."},
		"criador": {"nome": "Criador", "desc": "Tenha 5 animais."},
		"artesao": {"nome": "Artesão", "desc": "Fabrique 50 itens."},
	}
