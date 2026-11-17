extends Node
## Efeitos sonoros, música (com transição suave) e chuva ambiente. Volumes ficam salvos
## em user://config.cfg.

const CONFIG := "user://config.cfg"
const CANAIS := 10

var vol_musica := 0.6
var vol_efeitos := 0.8
var _cache := {}
var _tocadores: Array = []
var _proximo := 0
var _musica: AudioStreamPlayer
var _ambiente: AudioStreamPlayer
var _musica_atual := ""
var _abafada := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in CANAIS:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_tocadores.append(p)
	_musica = AudioStreamPlayer.new()
	add_child(_musica)
	_ambiente = AudioStreamPlayer.new()
	add_child(_ambiente)
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG) == OK:
		vol_musica = float(cfg.get_value("som", "musica", vol_musica))
		vol_efeitos = float(cfg.get_value("som", "efeitos", vol_efeitos))

func _carregar(caminho: String) -> AudioStream:
	if not _cache.has(caminho):
		_cache[caminho] = load(caminho) if ResourceLoader.exists(caminho) else null
	return _cache[caminho]

## Toca um efeito de som/efeitos/<nome>.wav, com uma leve variação de tom.
func tocar(nome: String, volume := 1.0, variar := true) -> void:
	if vol_efeitos <= 0.01:
		return
	var s := _carregar("res://som/efeitos/%s.wav" % nome)
	if s == null:
		return
	var p: AudioStreamPlayer = _tocadores[_proximo]
	_proximo = (_proximo + 1) % CANAIS
	p.stream = s
	p.volume_db = linear_to_db(vol_efeitos * volume)
	p.pitch_scale = randf_range(0.93, 1.07) if variar else 1.0
	p.play()

## Troca a música (som/musica/<nome>.ogg) com fade. "" para parar.
func musica(nome: String) -> void:
	if nome == _musica_atual:
		return
	_musica_atual = nome
	var t := create_tween()
	if _musica.playing:
		t.tween_property(_musica, "volume_db", -40.0, 0.8)
	t.tween_callback(func():
		if nome == "":
			_musica.stop()
			return
		var s := _carregar("res://som/musica/%s.ogg" % nome)
		if s == null:
			_musica.stop()
			return
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		_musica.stream = s
		_musica.volume_db = -40.0
		_musica.play())
	t.tween_property(_musica, "volume_db", _volume_musica_db(), 1.2)

func _volume_musica_db() -> float:
	var v := vol_musica * (0.45 if _abafada else 1.0)
	return linear_to_db(max(v, 0.0001))

## Música mais baixa (noite, chuva).
func abafar(sim: bool) -> void:
	if sim == _abafada:
		return
	_abafada = sim
	if _musica.playing:
		create_tween().tween_property(_musica, "volume_db", _volume_musica_db(), 1.5)

func chuva(ligada: bool) -> void:
	if ligada and not _ambiente.playing:
		var s := _carregar("res://som/efeitos/chuva.wav")
		if s is AudioStreamWAV:
			var w := s as AudioStreamWAV
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_end = int(w.get_length() * w.mix_rate)
		_ambiente.stream = s
		_ambiente.volume_db = linear_to_db(max(vol_efeitos * 0.5, 0.0001))
		_ambiente.play()
	elif not ligada and _ambiente.playing:
		_ambiente.stop()

func definir_volumes(m: float, e: float) -> void:
	vol_musica = m
	vol_efeitos = e
	_musica.volume_db = _volume_musica_db()
	if _ambiente.playing:
		_ambiente.volume_db = linear_to_db(max(vol_efeitos * 0.5, 0.0001))
	var cfg := ConfigFile.new()
	cfg.set_value("som", "musica", vol_musica)
	cfg.set_value("som", "efeitos", vol_efeitos)
	cfg.save(CONFIG)
