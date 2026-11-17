class_name Npc
extends Node2D
## Aldeão andando pelo mapa conforme a agenda (o principal diz para onde ir).

var id := ""
var principal: Node
var corpo: AnimatedSprite2D
var caminho: Array = []
var direcao := "south"
var velocidade := 55.0
var _alvo := Vector2i(-1, -1)
var _nome: Label

func _ready() -> void:
	var d: Dictionary = Dados.aldeoes[id]
	corpo = AnimatedSprite2D.new()
	corpo.sprite_frames = Jogador._quadros()
	corpo.scale = Vector2(0.29, 0.29)
	corpo.offset = Vector2(0, -104)
	corpo.modulate = Color.WHITE.lerp(d.cor, 0.8) * 1.25
	corpo.light_mask = 2
	add_child(corpo)
	corpo.play("parada-south")
	_nome = Label.new()
	_nome.text = d.nome
	_nome.add_theme_font_size_override("font_size", 8)
	_nome.add_theme_color_override("font_outline_color", Color.BLACK)
	_nome.add_theme_constant_override("outline_size", 3)
	_nome.position = Vector2(-30, -78)
	_nome.size = Vector2(60, 10)
	_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_nome)

func celula() -> Vector2i:
	return Vector2i(floori(position.x / Mapa.T), floori((position.y - 2) / Mapa.T))

func ir_para(alvo: Vector2i) -> void:
	if alvo == _alvo:
		return
	_alvo = alvo
	caminho = principal.caminho_entre(celula(), alvo)
	if not caminho.is_empty():
		caminho.pop_front()

func _process(delta: float) -> void:
	var perto: bool = principal.jogador.global_position.distance_to(global_position) < 70
	_nome.visible = perto
	if Jogo.pausado:
		corpo.play("parada-" + direcao)
		return
	if caminho.is_empty():
		corpo.play("parada-" + direcao)
		if perto:
			_virar(principal.jogador.global_position - global_position)
		return
	var proximo: Vector2i = caminho[0]
	var destino := Vector2(proximo.x * Mapa.T + Mapa.T / 2.0, proximo.y * Mapa.T + Mapa.T - 4)
	var falta := destino - position
	if falta.length() < 2.0:
		position = destino
		caminho.pop_front()
		return
	# para se o jogador estiver bem na frente
	if principal.jogador.global_position.distance_to(global_position + falta.normalized() * 14) < 12:
		corpo.play("parada-" + direcao)
		return
	position += falta.normalized() * min(velocidade * delta, falta.length())
	_virar(falta)
	corpo.play("andar-" + direcao)

func _virar(v: Vector2) -> void:
	if v.length() < 1:
		return
	var d := Vector2i(signi(roundi(v.normalized().x)), signi(roundi(v.normalized().y)))
	if d != Vector2i.ZERO:
		direcao = Jogador.DIRECOES[d]
