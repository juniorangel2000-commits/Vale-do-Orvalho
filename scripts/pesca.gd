extends Control
## Pesca: espera a fisgada, aperta na hora certa e depois mantém a barra verde sobre o peixe
## (segure clique ou Espaço para subir) até encher o medidor.

var lugar := "rio"
var fase := "esperando"
var _tempo := 0.0
var _espera := 2.0
var _peixe := ""
var _dif := 15.0
var _peixe_y := 0.5
var _peixe_alvo := 0.5
var _barra_y := 0.6
var _barra_vel := 0.0
var _barra_tam := 0.2
var _progresso := 0.3
var _perfeito := true
var _isca := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_isca = Jogo.contar("isca") > 0
	if _isca:
		Jogo.remover("isca", 1)
	_espera = randf_range(1.0, 2.5) if _isca else randf_range(1.5, 5.0)
	_escolher_peixe()
	var nivel := Jogo.nivel_habilidade("pesca")
	_barra_tam = 0.17 + nivel * 0.015 + (0.06 if Jogo.contar("vara_fibra") > 0 else 0.0)

func _escolher_peixe() -> void:
	var sorteio := randf()
	if sorteio < 0.1:
		_peixe = "bota_velha"
		_dif = 5
		return
	if sorteio < 0.17 and lugar != "mina":
		_peixe = "alga"
		_dif = 5
		return
	var opcoes := []
	var pesos := []
	var h := Jogo.hora()
	for id in Dados.peixes:
		var p: Dictionary = Dados.peixes[id]
		if not (lugar in p.lugares) or not (Jogo.estacao in p.estacoes):
			continue
		if h < int(p.hora[0]) or h >= int(p.hora[1]):
			continue
		if p.has("chuva") and bool(p.chuva) and Jogo.clima == "sol" and randf() < 0.7:
			continue
		if p.has("nivel") and Jogo.nivel_habilidade("pesca") < int(p.nivel):
			continue
		opcoes.append(id)
		pesos.append(float(p.chance))
	if opcoes.is_empty():
		_peixe = "lambari"
		_dif = 15
		return
	var total := 0.0
	for w in pesos:
		total += w
	var r := randf() * total
	for i in opcoes.size():
		r -= pesos[i]
		if r <= 0:
			_peixe = opcoes[i]
			break
	if _peixe == "":
		_peixe = opcoes[0]
	_dif = float(Dados.peixes[_peixe].dif)

func _segurando() -> bool:
	return Input.is_action_pressed("usar") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _input(ev: InputEvent) -> void:
	if ev.is_action_pressed("menu"):
		Jogo.mensagem.emit("Você recolheu a linha.")
		queue_free()
		get_viewport().set_input_as_handled()
		return
	var apertou: bool = ev.is_action_pressed("usar") or (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT)
	if not apertou:
		return
	get_viewport().set_input_as_handled()
	if fase == "esperando":
		Jogo.mensagem.emit("Puxou cedo demais!")
		queue_free()
	elif fase == "fisgou":
		if _dif <= 5:
			_terminar(true)
		else:
			fase = "lutando"
			_tempo = 0.0

func _process(delta: float) -> void:
	_tempo += delta
	queue_redraw()
	match fase:
		"esperando":
			if _tempo >= _espera:
				Som.tocar("fisgou", 1.0, false)
				fase = "fisgou"
				_tempo = 0.0
		"fisgou":
			if _tempo > 0.9:
				Som.tocar("splash")
				Jogo.mensagem.emit("O peixe escapou...")
				queue_free()
		"lutando":
			_lutar(delta)

func _lutar(delta: float) -> void:
	var agito := _dif / 100.0
	if randf() < delta * (0.6 + agito * 2.5):
		_peixe_alvo = clampf(_peixe_y + randf_range(-0.5, 0.5) * (0.4 + agito), 0.03, 0.97)
	_peixe_y = move_toward(_peixe_y, _peixe_alvo, delta * (0.15 + agito * 0.9))
	_barra_vel += (-2.2 if _segurando() else 1.8) * delta
	_barra_vel = clampf(_barra_vel, -1.2, 1.2)
	_barra_y += _barra_vel * delta
	if _barra_y < _barra_tam / 2.0:
		_barra_y = _barra_tam / 2.0
		_barra_vel = 0.0
	if _barra_y > 1.0 - _barra_tam / 2.0:
		_barra_y = 1.0 - _barra_tam / 2.0
		_barra_vel *= -0.3
	if abs(_peixe_y - _barra_y) < _barra_tam / 2.0:
		_progresso += delta * 0.32
	else:
		_progresso -= delta * (0.18 + agito * 0.12)
		_perfeito = false
	if _progresso >= 1.0:
		_terminar(true)
	elif _progresso <= 0.0:
		Som.tocar("splash")
		Jogo.mensagem.emit("O peixe escapou...")
		queue_free()

func _terminar(pegou: bool) -> void:
	if pegou:
		var q := 0
		if _perfeito and _dif > 5:
			q = 1 if randf() < 0.6 else 2
		Som.tocar("peixe", 1.0, false)
		if Jogo.adicionar(_peixe, 1, "", q, true) == 0:
			if Dados.item(_peixe).tipo == "peixe":
				Jogo.somar_stat("peixes")
				var tipos: Array = Jogo.stats.get("tipos_peixe", [])
				if not (_peixe in tipos):
					tipos.append(_peixe)
					Jogo.stats["tipos_peixe"] = tipos
					Jogo.mensagem.emit("Peixe novo: %s!" % Dados.nome_item(_peixe))
				Jogo.ganhar_xp("pesca", 3 + int(_dif / 3.0) + (10 if _perfeito else 0))
			else:
				Jogo.ganhar_xp("pesca", 1)
	queue_free()

func _draw() -> void:
	var tela := get_viewport_rect().size
	var c := tela / 2.0
	match fase:
		"esperando":
			var pontos := ".".repeat(int(_tempo * 2) % 4)
			_texto(c + Vector2(0, -120), "Esperando o peixe morder" + pontos, 18)
			_texto(c + Vector2(0, -95), "(clique ou Espaço quando aparecer o !)", 13)
		"fisgou":
			draw_circle(c + Vector2(0, -120), 26, Color("#f8e858"))
			_texto(c + Vector2(0, -108), "!", 36, Color("#a82a10"))
		"lutando":
			var r := Rect2(c.x + 140, c.y - 170, 50, 340)
			draw_rect(r.grow(8), Color("#7a4e2e"))
			draw_rect(r, Color("#3a6a8a"))
			var bt := _barra_tam * r.size.y
			draw_rect(Rect2(r.position.x + 3, r.position.y + _barra_y * r.size.y - bt / 2.0, r.size.x - 6, bt), Color(0.45, 0.9, 0.35, 0.75))
			Desenho.icone(self, _peixe if _peixe != "bota_velha" else "lambari", Rect2(r.position.x + 5, r.position.y + _peixe_y * r.size.y - 20, 40, 40))
			var pr := Rect2(r.end.x + 14, r.position.y, 14, r.size.y)
			draw_rect(pr.grow(3), Color("#7a4e2e"))
			draw_rect(pr, Color("#2a1a10"))
			var alt := pr.size.y * clampf(_progresso, 0, 1)
			draw_rect(Rect2(pr.position.x, pr.end.y - alt, pr.size.x, alt), Color("#e8a83a").lerp(Color("#5ac84a"), _progresso))
			_texto(Vector2(r.get_center().x, r.position.y - 18), "Segure para subir", 13)

func _texto(p: Vector2, t: String, tam: int, cor := Color.WHITE) -> void:
	var f := get_theme_default_font()
	var largura := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	draw_string_outline(f, p - Vector2(largura / 2.0, 0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 5, Color("#2a1a10"))
	draw_string(f, p - Vector2(largura / 2.0, 0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)
