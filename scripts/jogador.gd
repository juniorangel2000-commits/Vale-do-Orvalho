class_name Jogador
extends Node2D
## Personagem: anda em 8 direções com colisão por blocos e usa o item da mão.
## A posição é o ponto dos pés.

const DIRECOES := {
	Vector2i(0, 1): "south", Vector2i(0, -1): "north", Vector2i(1, 0): "east", Vector2i(-1, 0): "west",
	Vector2i(1, 1): "south-east", Vector2i(-1, 1): "south-west", Vector2i(1, -1): "north-east", Vector2i(-1, -1): "north-west",
}
const MEIA_LARGURA := 7.0
const ALTURA_PES := 6.0

var principal: Node
var mapa: Mapa
var velocidade := 120.0
var direcao := "south"
var olhando := Vector2i(0, 1)
var corpo: AnimatedSprite2D
var acao_tempo := 0.0
var acao_item := ""
var invencivel := 0.0
var travado := false
static var _quadros_cache: SpriteFrames

func _ready() -> void:
	corpo = AnimatedSprite2D.new()
	corpo.sprite_frames = _quadros()
	corpo.scale = Vector2(0.3, 0.3)
	corpo.offset = Vector2(0, -104)
	corpo.light_mask = 2
	add_child(corpo)
	corpo.play("parada-south")
	z_index = 0

static func _quadros() -> SpriteFrames:
	if _quadros_cache:
		return _quadros_cache
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for d in DIRECOES.values():
		sf.add_animation("parada-" + d)
		sf.add_frame("parada-" + d, load("res://arte/personagem/parada/%s.png" % d))
		sf.add_animation("andar-" + d)
		sf.set_animation_speed("andar-" + d, 10.0)
		for i in 6:
			sf.add_frame("andar-" + d, load("res://arte/personagem/andar/%s/frame_%03d.png" % [d, i]))
	_quadros_cache = sf
	return sf

func celula() -> Vector2i:
	return Vector2i(floori(position.x / Mapa.T), floori((position.y - 2) / Mapa.T))

func celula_alvo() -> Vector2i:
	return celula() + olhando

func _process(delta: float) -> void:
	invencivel = max(invencivel - delta, 0.0)
	modulate.a = 0.5 if invencivel > 0 and int(invencivel * 20) % 2 == 0 else 1.0
	if acao_tempo > 0:
		acao_tempo -= delta
		queue_redraw()
		if acao_tempo <= 0:
			acao_item = ""
		return
	if travado or Jogo.pausado or mapa == null:
		corpo.play("parada-" + direcao)
		return
	var entrada := Input.get_vector("esquerda", "direita", "cima", "baixo")
	if entrada.length() > 0.1:
		var d := Vector2i(signi(roundi(entrada.x)), signi(roundi(entrada.y)))
		if d != Vector2i.ZERO:
			direcao = DIRECOES[d]
			if abs(entrada.x) > abs(entrada.y) + 0.1:
				olhando = Vector2i(d.x, 0)
			else:
				olhando = Vector2i(0, d.y)
		var vel := velocidade
		if Jogo.energia <= 0:
			vel *= 0.6
		var passo := entrada.normalized() * vel * delta
		mover(passo)
		corpo.play("andar-" + direcao)
		principal.ao_mover()
	else:
		corpo.play("parada-" + direcao)

func mover(passo: Vector2) -> void:
	var novo := position + Vector2(passo.x, 0)
	if not _colide(novo):
		position = novo
	novo = position + Vector2(0, passo.y)
	if not _colide(novo):
		position = novo

func _colide(p: Vector2) -> bool:
	var x0 := floori((p.x - MEIA_LARGURA) / Mapa.T)
	var x1 := floori((p.x + MEIA_LARGURA) / Mapa.T)
	var y0 := floori((p.y - ALTURA_PES) / Mapa.T)
	var y1 := floori((p.y - 1) / Mapa.T)
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if mapa.solido(Vector2i(x, y)):
				return true
	return false

## Vira o personagem para uma célula (usado quando clica com o mouse).
func virar_para(c: Vector2i) -> void:
	var d := c - celula()
	if d == Vector2i.ZERO:
		return
	if abs(d.x) >= abs(d.y):
		olhando = Vector2i(signi(d.x), 0)
	else:
		olhando = Vector2i(0, signi(d.y))
	direcao = DIRECOES[olhando]

func animar_acao(item: String, tempo := 0.3) -> void:
	acao_item = item
	acao_tempo = tempo
	corpo.play("parada-" + direcao)
	queue_redraw()

func _draw() -> void:
	if acao_item == "":
		return
	# ferramenta balançando na frente do personagem
	var t := clampf(1.0 - acao_tempo / 0.3, 0.0, 1.0)
	var lado := Vector2(olhando) * 14.0
	var angulo := lerpf(-1.2, 0.6, t) * (1.0 if olhando.x >= 0 else -1.0)
	draw_set_transform(lado + Vector2(0, -26), angulo, Vector2.ONE)
	Desenho.icone(self, acao_item, Rect2(-10, -18, 20, 20))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
