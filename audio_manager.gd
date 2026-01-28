extends Node

# Buses de áudio
const MASTER_BUS = 0
const MUSIC_BUS = 1
const SFX_BUS = 2

# Caminhos para as músicas
const MENU_MUSIC_PATH = "res://Music/Tema/Menu.mp3"
const GAME_MUSIC_PATH = "res://Music/MusicaFundo1.mp3"

# Caminhos para os efeitos sonoros de combate
const BATTLE_START_SOUND = "res://Music/Efects/BURNHEAD.WAV"
const VICTORY_SOUND = "res://Music/Efects/YELL1.WAV"
const DEFEAT_SOUND = "res://Music/Efects/SCREAMM.WAV"

# Nós de áudio
var menu_player: AudioStreamPlayer
var game_player: AudioStreamPlayer

# Estado
var is_muted = false
var current_music_player = null

# Nós de áudio para efeitos
var battle_effect_players = []
var max_sfx_players = 6  # Número máximo de players de efeitos simultâneos

func _ready():
	# Inicializar os players de áudio
	initialize_audio_players()
	
	# Inicializar players de efeitos sonoros
	initialize_sfx_players()
	
	# Carregar configurações salvas de áudio (se houver)
	load_audio_settings()
	
	print("AudioManager inicializado com sucesso")

# Inicializa os players de áudio
func initialize_audio_players():
	# Criar player para música do menu
	menu_player = AudioStreamPlayer.new()
	add_child(menu_player)
	menu_player.bus = "Music"
	
	# Criar player para música do jogo
	game_player = AudioStreamPlayer.new()
	add_child(game_player)
	game_player.bus = "Music"
	
	# Pré-carregar streams
	if FileAccess.file_exists(MENU_MUSIC_PATH):
		menu_player.stream = load(MENU_MUSIC_PATH)
		print("Música do menu carregada: ", MENU_MUSIC_PATH)
	else:
		print("AVISO: Arquivo de música do menu não encontrado: ", MENU_MUSIC_PATH)
	
	if FileAccess.file_exists(GAME_MUSIC_PATH):
		game_player.stream = load(GAME_MUSIC_PATH)
		print("Música do jogo carregada: ", GAME_MUSIC_PATH)
	else:
		print("AVISO: Arquivo de música do jogo não encontrado: ", GAME_MUSIC_PATH)

# Inicializa os players de efeitos sonoros
func initialize_sfx_players():
	# Criar pool de players para efeitos sonoros
	for i in range(max_sfx_players):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		battle_effect_players.append(player)
		player.finished.connect(_on_sfx_finished.bind(player))
	
	print("Players de efeitos sonoros inicializados: ", max_sfx_players)

# Callback quando um player de efeito termina de tocar
func _on_sfx_finished(player):
	# Liberar o player para uso futuro
	player.stream = null

# Encontra um player de efeitos disponível
func get_available_sfx_player():
	for player in battle_effect_players:
		if not player.playing:
			return player
	
	# Se todos estiverem ocupados, usa o primeiro (menos ideal)
	print("AVISO: Todos os players de efeitos estão em uso, substituindo o mais antigo")
	return battle_effect_players[0]

# Reproduz um efeito sonoro de batalha
func play_battle_effect(effect_path):
	if not FileAccess.file_exists(effect_path):
		print("ERRO: Arquivo de efeito sonoro não encontrado: ", effect_path)
		return
	
	var player = get_available_sfx_player()
	player.stream = load(effect_path)
	player.play()
	print("Tocando efeito sonoro: ", effect_path)

# Reproduz o som de início de batalha
func play_battle_start_sound():
	play_battle_effect(BATTLE_START_SOUND)

# Reproduz o som de vitória
func play_victory_sound():
	play_battle_effect(VICTORY_SOUND)

# Reproduz o som de derrota
func play_defeat_sound():
	play_battle_effect(DEFEAT_SOUND)

# Reproduz sons personalizados para cartas
func play_card_sound(card_data, win_state):
	# Verificar se a carta tem sons personalizados definidos
	var sound_path = ""
	
	if card_data and "card_id" in card_data:
		var card_id = card_data.card_id
		
		# Lógica para selecionar sons personalizados baseado no ID da carta
		# Você pode expandir isso para usar um dicionário de sons por carta
		match card_id:
			"warrior", "knight", "paladin":
				sound_path = "res://Music/Efects/YELL1.WAV" if win_state else "res://Music/Efects/BURNHEAD.WAV"
			"mage", "wizard", "sorcerer":
				sound_path = "res://Music/Efects/BURNHEAD.WAV" if win_state else "res://Music/Efects/SCREAMM.WAV"
			"thief", "rogue", "assassin":
				sound_path = "res://Music/Efects/SCREAMM.WAV" if win_state else "res://Music/Efects/YELL1.WAV"
			_:
				# Som padrão para outras cartas
				sound_path = VICTORY_SOUND if win_state else DEFEAT_SOUND
	else:
		# Sem ID de carta, usar sons padrão
		sound_path = VICTORY_SOUND if win_state else DEFEAT_SOUND
	
	play_battle_effect(sound_path)

# Reproduz música de fundo para o menu
func play_menu_music():
	# Parar qualquer música atual
	stop_all_music()
	
	# Tocar música do menu
	if menu_player and menu_player.stream:
		menu_player.play()
		current_music_player = menu_player
		print("Tocando música do menu")
	else:
		print("ERRO: Não foi possível tocar música do menu")

# Reproduz música de fundo para o jogo
func play_game_music():
	# Parar qualquer música atual
	stop_all_music()
	
	# Tocar música do jogo
	if game_player and game_player.stream:
		game_player.play()
		current_music_player = game_player
		print("Tocando música do jogo")
	else:
		print("ERRO: Não foi possível tocar música do jogo")

# Para todas as músicas
func stop_all_music():
	if menu_player:
		menu_player.stop()
	if game_player:
		game_player.stop()
	current_music_player = null
	print("Todas as músicas paradas")

# Altera o volume do bus Master
func set_master_volume(volume_db):
	AudioServer.set_bus_volume_db(MASTER_BUS, volume_db)
	print("Volume principal ajustado para: ", volume_db, "dB")
	save_audio_settings()

# Altera o volume do bus de Música
func set_music_volume(volume_db):
	AudioServer.set_bus_volume_db(MUSIC_BUS, volume_db)
	print("Volume da música ajustado para: ", volume_db, "dB")
	save_audio_settings()

# Altera o volume do bus de SFX
func set_sfx_volume(volume_db):
	AudioServer.set_bus_volume_db(SFX_BUS, volume_db)
	print("Volume dos efeitos ajustado para: ", volume_db, "dB")
	save_audio_settings()

# Busca o volume atual do bus Master em dB
func get_master_volume():
	return AudioServer.get_bus_volume_db(MASTER_BUS)

# Busca o volume atual do bus de Música em dB
func get_music_volume():
	return AudioServer.get_bus_volume_db(MUSIC_BUS)

# Busca o volume atual do bus de SFX em dB
func get_sfx_volume():
	return AudioServer.get_bus_volume_db(SFX_BUS)

# Ativa/desativa o mudo para todos os buses
func toggle_mute():
	is_muted = !is_muted
	AudioServer.set_bus_mute(MASTER_BUS, is_muted)
	print("Mudo: ", is_muted)
	save_audio_settings()
	return is_muted

# Define o estado de mudo
func set_mute(mute_state):
	is_muted = mute_state
	AudioServer.set_bus_mute(MASTER_BUS, is_muted)
	print("Mudo definido para: ", is_muted)
	save_audio_settings()

# Verifica se o áudio está mudo
func is_audio_muted():
	return is_muted

# Salva as configurações de áudio
func save_audio_settings():
	var save_data = {
		"master_volume": get_master_volume(),
		"music_volume": get_music_volume(),
		"sfx_volume": get_sfx_volume(),
		"is_muted": is_muted
	}
	
	var save_file = FileAccess.open("user://audio_settings.json", FileAccess.WRITE)
	if save_file:
		save_file.store_line(JSON.stringify(save_data))
		save_file.close()
		print("Configurações de áudio salvas")

# Carrega as configurações de áudio
func load_audio_settings():
	if not FileAccess.file_exists("user://audio_settings.json"):
		print("Nenhuma configuração de áudio salva encontrada, usando padrões")
		# Definir valores padrão
		set_master_volume(-10.0)
		set_music_volume(-15.0)
		set_sfx_volume(-10.0)
		set_mute(false)
		return
	
	var save_file = FileAccess.open("user://audio_settings.json", FileAccess.READ)
	if save_file:
		var json_string = save_file.get_line()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			
			if "master_volume" in save_data:
				set_master_volume(save_data.master_volume)
			if "music_volume" in save_data:
				set_music_volume(save_data.music_volume)
			if "sfx_volume" in save_data:
				set_sfx_volume(save_data.sfx_volume)
			if "is_muted" in save_data:
				set_mute(save_data.is_muted)
				
			print("Configurações de áudio carregadas")
		else:
			print("Erro ao analisar o arquivo de configurações de áudio")
	else:
		print("Não foi possível abrir o arquivo de configurações de áudio") 