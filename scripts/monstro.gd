class_name Monstro
extends Node2D
## Monstro da mina: persegue o jogador quando perto e machuca ao encostar.

const STATUS := {
	"gosma": {"vida": 8, "dano": 6, "vel": 35.0, "voa": false},
	"gosma_azul": {"vida": 20, "dano": 10, "vel": 42.0, "voa": false},
	"gosma_roxa": {"vida": 45, "dano": 16, "vel": 48.0, "voa": false},
	"morcego": {"vida": 14, "dano": 8, "vel": 60.0, "voa": true},
	"pedrento": {"vida": 40, "dano": 14, "vel": 28.0, "voa": false},
}

var tipo := "gosma"
var mapa: Mapa
var principal: Node
var andar := 1
var vida := 8
var _quadro := 0.0
var _ferido := 0.0
var _empurrao := Vector2.ZERO
var _passeio := Vector2.ZERO
var _troca := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vida = int(STATUS[tipo].vida * (1.0 + andar / 40.0))

func _process(delta: float) -> void:
	_quadro += delta
	_ferido = max(_ferido - delta, 0.0)
	queue_redraw()
	if Jogo.pausado:
		return
	var st: Dictionary = STATUS[tipo]
	var jog: Jogador = principal.jogador
	var para_jogador := jog.global_position - global_position
	var dir := Vector2.ZERO
	if para_jogador.length() < 170:
		dir = para_jogador.normalized()
	else:
		_troca -= delta
		if _troca <= 0:
			_troca = randf_range(1, 3)
			_passeio = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 0.4
		dir = _passeio
	var passo := dir * float(st.vel) * delta + _empurrao * delta
	_empurrao = _empurrao.move_toward(Vector2.ZERO, 600 * delta)
	if bool(st.voa):
		var novo := position + passo
		if mapa.material(mapa.celula_de(novo)) != Mapa.M.VAZIO:
			position = novo
	else:
		for eixo in [Vector2(passo.x, 0), Vector2(0, passo.y)]:
			var novo: Vector2 = position + eixo
			if not mapa.solido(mapa.celula_de(novo - Vector2(0, 4))):
				position = novo
	if para_jogador.length() < 16 and jog.invencivel <= 0:
		var dano := int(st.dano * (1.0 + andar / 50.0))
		Jogo.ferir(dano)
		jog.invencivel = 1.0
		jog.mover(-para_jogador.normalized() * 18.0)
		Jogo.mensagem.emit("-%d de vida" % dano)

func ferir(dano: int, de: Vector2) -> void:
	vida -= dano
	_ferido = 0.25
	_empurrao = de * 220.0
	if vida <= 0:
		principal.monstro_morreu(self)
		queue_free()

func _draw() -> void:
	draw_circle(Vector2(0, -1), 7, Color(0, 0, 0, 0.25))
	Desenho.monstro(self, tipo, Vector2.ZERO, _quadro, _ferido > 0)
