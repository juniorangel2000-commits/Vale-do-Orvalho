class_name ObjetoVisual
extends Node2D
## Desenha um objeto do mapa (árvore, pedra, máquina, baú...). O estado fica no mapa;
## este nó só lê e desenha. Posição = pé do objeto.

const ARTES := {
	"arvore": ["asset-tree-0", "asset-tree-1", "asset-tree-2"],
	"pinheiro": ["asset-pine-0", "asset-pine-1", "asset-pine-2"],
	"toco": ["forest-detail-stump"],
	"pedra": ["asset-small-stones"],
	"galho": ["asset-new-branches"],
	"rocha": ["lake-rock-0", "lake-rock-1", "lake-rock-2"],
	"minerio": ["detailed-ore-atlas-iron"],
	"pedra_mina": ["lake-rock-0", "lake-rock-1", "lake-rock-2"],
	"arbusto": ["asset-berry-bush"],
	"poco": ["property-well-idle"],
}
const LARGURA := {"arvore": 112.0, "pinheiro": 100.0, "toco": 48.0, "pedra": 34.0, "galho": 38.0, "rocha": 58.0,
	"minerio": 38.0, "pedra_mina": 34.0, "arbusto": 52.0, "poco": 84.0, "deco": 40.0, "deco_solida": 52.0}
const CORES_MINERIO := {"minerio_cobre": Color(1.25, 0.85, 0.65), "minerio_ferro": Color(1, 1, 1), "minerio_ouro": Color(1.4, 1.2, 0.5),
	"quartzo": Color(1.3, 1.35, 1.4), "ametista": Color(1.2, 0.8, 1.4), "esmeralda": Color(0.7, 1.3, 0.9), "rubi": Color(1.4, 0.6, 0.6), "diamante": Color(1.2, 1.5, 1.6)}

static var _cache := {}

var mapa: Mapa
var celula := Vector2i.ZERO
var tremor := 0.0

static func textura(nome: String) -> Texture2D:
	if not _cache.has(nome):
		_cache[nome] = load("res://arte/objetos/%s.png" % nome)
	return _cache[nome]

func _process(delta: float) -> void:
	if tremor > 0.0:
		tremor = max(tremor - delta, 0.0)
		queue_redraw()
	elif Engine.get_process_frames() % 30 == 0:
		var o := mapa.objeto(celula)
		if o.has("saida"):
			queue_redraw()

func tremer() -> void:
	tremor = 0.25

func _draw() -> void:
	var o := mapa.objeto(celula)
	if o.is_empty():
		return
	var tipo: String = o.tipo
	var desloc := Vector2(sin(tremor * 60.0) * 2.0 * (1.0 if tremor > 0 else 0.0), 0)
	if ARTES.has(tipo) or tipo == "deco" or tipo == "deco_solida":
		var nomes: Array = ARTES.get(tipo, [])
		var nome_arte: String = String(o.get("arte", "")) if o.has("arte") else String(nomes[abs(celula.x * 7 + celula.y * 13) % nomes.size()])
		var tex := textura(nome_arte)
		var largura: float = LARGURA.get(tipo, 40.0)
		var escala := largura / tex.get_width()
		var tam := Vector2(tex.get_width(), tex.get_height()) * escala
		var cor := Color.WHITE
		if tipo == "arvore" and not mapa.interior:
			if Jogo.estacao == 2:
				cor = Color(1.35, 0.85, 0.5)
			elif Jogo.estacao == 3:
				cor = Color(1.15, 1.15, 1.25)
		elif tipo == "pinheiro" and Jogo.estacao == 3:
			cor = Color(1.1, 1.15, 1.25)
		elif tipo == "minerio":
			cor = CORES_MINERIO.get(String(o.get("item", "minerio_ferro")), Color.WHITE)
		elif tipo == "pedra_mina":
			cor = Color(0.75, 0.7, 0.68)
		var base_y := 4.0 if tipo == "arvore" or tipo == "pinheiro" else 2.0
		draw_texture_rect(tex, Rect2(Vector2(-tam.x / 2.0, -tam.y + base_y) + desloc, tam), false, cor)
		if tipo == "arbusto" and Jogo.estacao == 1 and not bool(o.get("colhido_hoje", false)):
			for p in [Vector2(-8, -20), Vector2(6, -26), Vector2(10, -14), Vector2(-4, -32)]:
				draw_circle(p, 3, Color("#5a2a6e"))
		return
	match tipo:
		"mato":
			var verde := Color("#6a9a3a") if Jogo.estacao != 2 else Color("#a88a3a")
			if Jogo.estacao == 3:
				verde = Color("#9aa89a")
			for i in 5:
				var x := -10.0 + i * 5.0
				draw_colored_polygon(PackedVector2Array([Vector2(x - 3, 0) + desloc, Vector2(x + (i % 2) * 2 - 1, -14 - (i % 3) * 3) + desloc, Vector2(x + 3, 0) + desloc]), verde)
		"caminho":
			for p in [Vector2(-8, -8), Vector2(6, -12), Vector2(-2, -20), Vector2(9, -24), Vector2(-10, -24)]:
				draw_circle(p, 5, Color("#9a9a94"))
				draw_circle(p + Vector2(-1, -1), 3, Color("#b8b8b0"))
		"forragem":
			draw_circle(Vector2(0, -2), 9, Color(0, 0, 0, 0.18))
			Desenho.icone(self, String(o.item), Rect2(Vector2(-11, -24), Vector2(22, 22)))
		"caixa_envio", "bau", "espantalho", "aspersor", "aspersor_bom", "cerca", "tocha", "barril", "conserveiro", "fornalha",\
				"forno_carvao", "prensa_queijo", "batedeira", "tear", "caixa_abelha", "fogao", "cama", "cocho", "mural", "colecoes",\
				"escada_mina", "elevador", "mesa":
			var pronto := false
			var trabalhando := false
			if o.has("saida"):
				pronto = Jogo.minuto_absoluto() >= int(o.get("pronto_em", 0))
				trabalhando = not pronto
			if tipo == "cocho":
				pronto = int(Jogo.construcao_por_id(mapa.construcao_id).get("cocho", 0)) > 0
			if tipo == "mural":
				pronto = not Jogo.pedido.is_empty()
			Desenho.objeto_colocavel(self, tipo, desloc, 28.0, pronto, trabalhando)
			if pronto and o.has("saida"):
				Desenho.icone(self, String(o.saida), Rect2(Vector2(-6, -44), Vector2(12, 12)), String(o.get("origem", "")))
		_:
			draw_rect(Rect2(-8, -16, 16, 16), Color.MAGENTA)
