class_name Animal
extends Node2D
## Animal dentro do galinheiro ou estábulo. Anda à toa, recebe carinho e dá produtos.

var dados: Dictionary
var mapa: Mapa
var _alvo := Vector2.ZERO
var _espera := 0.0
var _quadro := 0.0
var _dir := 1.0
var _coracao := 0.0

func _ready() -> void:
	_alvo = position

func _process(delta: float) -> void:
	_coracao = max(_coracao - delta, 0.0)
	if Jogo.pausado:
		return
	var falta := _alvo - position
	if falta.length() < 2:
		_espera -= delta
		if _espera <= 0:
			_espera = randf_range(1.5, 4.0)
			var novo := position + Vector2(randf_range(-50, 50), randf_range(-30, 30))
			if not mapa.solido(mapa.celula_de(novo - Vector2(0, 4))):
				_alvo = novo
	else:
		position += falta.normalized() * 22.0 * delta
		_quadro += delta * 8.0
		_dir = 1.0 if falta.x >= 0 else -1.0
	queue_redraw()

func _draw() -> void:
	Desenho.animal(self, String(dados.tipo), Vector2.ZERO, _dir, _quadro)
	if String(dados.get("produto", "")) != "" and Dados.animais[dados.tipo].ferramenta != "":
		draw_circle(Vector2(0, -36), 6, Color(1, 1, 1, 0.9))
		Desenho.icone(self, String(dados.produto), Rect2(Vector2(-5, -41), Vector2(10, 10)))
	if _coracao > 0:
		draw_circle(Vector2(-3, -34 - (1.0 - _coracao) * 10), 3, Color("#e84a6a"))
		draw_circle(Vector2(3, -34 - (1.0 - _coracao) * 10), 3, Color("#e84a6a"))
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -33 - (1.0 - _coracao) * 10), Vector2(6, -33 - (1.0 - _coracao) * 10), Vector2(0, -26 - (1.0 - _coracao) * 10)]), Color("#e84a6a"))

func interagir() -> void:
	var d: Dictionary = Dados.animais[dados.tipo]
	var produto := String(dados.get("produto", ""))
	if produto != "" and d.ferramenta != "":
		if Jogo.id_selecionado() == d.ferramenta:
			if Jogo.adicionar(produto, 1, "", 0, true) == 0:
				dados.produto = ""
				Jogo.ganhar_xp("cultivo", 5)
				Jogo.cansar(1)
			return
		Jogo.mensagem.emit("%s está pronta. Use: %s." % [dados.nome, Dados.nome_item(d.ferramenta)])
	if not bool(dados.get("carinho", false)):
		dados.carinho = true
		dados.amizade = min(int(dados.amizade) + 15, 1000)
		_coracao = 1.0
		Jogo.ganhar_xp("cultivo", 2)
	var coracoes := int(int(dados.amizade) / 200.0)
	Jogo.mensagem.emit("%s (%s) — %s" % [dados.nome, d.nome, "♥".repeat(coracoes) + "♡".repeat(5 - coracoes)])
