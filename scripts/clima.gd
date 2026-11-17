extends Node2D
## Chuva e neve desenhadas por cima da tela.

var tipo := ""
var _gotas: Array = []

func _ready() -> void:
	for i in 160:
		_gotas.append(Vector3(randf() * 1400, randf() * 800, randf_range(0.6, 1.0)))

func _process(delta: float) -> void:
	if tipo == "" or tipo == "sol":
		if visible:
			visible = false
		return
	visible = true
	var tam := get_viewport_rect().size
	for i in _gotas.size():
		var g: Vector3 = _gotas[i]
		if tipo == "chuva":
			g.x -= 120 * delta * g.z
			g.y += 700 * delta * g.z
		else:
			g.x += sin(g.y * 0.02 + i) * 20 * delta
			g.y += 60 * delta * g.z
		if g.y > tam.y:
			g.y = -10
			g.x = randf() * (tam.x + 200)
		if g.x < -20:
			g.x = tam.x + 10
		_gotas[i] = g
	queue_redraw()

func _draw() -> void:
	if tipo == "chuva":
		for g in _gotas:
			draw_line(Vector2(g.x, g.y), Vector2(g.x - 4, g.y + 14 * g.z), Color(0.75, 0.85, 1.0, 0.45), 1.5)
	elif tipo == "neve":
		for g in _gotas:
			draw_circle(Vector2(g.x, g.y), 2.0 * g.z, Color(1, 1, 1, 0.8))
