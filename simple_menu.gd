extends Control

enum MenuState {MAIN, AUDIO, CREDITS}
var current_state = MenuState.MAIN

# Referências para os containers de menus
@onready var audio_container = $AudioContainer
@onready var credits_container = $CreditsContainer

# Referências para os controles de áudio
@onready var master_slider = $AudioContainer/AudioPanel/VBoxContainer/MasterVolumeContainer/MasterSlider
@onready var music_slider = $AudioContainer/AudioPanel/VBoxContainer/MusicVolumeContainer/MusicSlider
@onready var sfx_slider = $AudioContainer/AudioPanel/VBoxContainer/SFXVolumeContainer/SFXSlider
@onready var mute_checkbox = $AudioContainer/AudioPanel/VBoxContainer/MuteContainer/MuteCheckBox
@onready var mute_all_button = $AudioContainer/AudioPanel/VBoxContainer/MuteContainer/MuteAllButton
@onready var audio_back_button = $AudioContainer/AudioPanel/VBoxContainer/ResumeContainer/BackButton

# Referências para os controles de créditos
@onready var credits_back_button = $CreditsContainer/CreditsPanel/VBoxContainer/BackButtonContainer/BackButton

func _ready():
	# Conectar os botões do menu principal
	$MenuPanel/VBoxContainer/StartButton.connect("pressed", Callable(self, "_on_start_button_pressed"))
	$MenuPanel/VBoxContainer/ContinueButton.connect("pressed", Callable(self, "_on_continue_button_pressed"))
	$MenuPanel/VBoxContainer/AudioButton.connect("pressed", Callable(self, "_on_audio_button_pressed"))
	$MenuPanel/VBoxContainer/CardsButton.connect("pressed", Callable(self, "_on_cards_button_pressed"))
	$MenuPanel/VBoxContainer/CreditsButton.connect("pressed", Callable(self, "_on_credits_button_pressed"))
	$MenuPanel/VBoxContainer/QuitButton.connect("pressed", Callable(self, "_on_quit_button_pressed"))
	
	# Conectar os controles de áudio
	master_slider.connect("value_changed", Callable(self, "_on_master_volume_changed"))
	music_slider.connect("value_changed", Callable(self, "_on_music_volume_changed"))
	sfx_slider.connect("value_changed", Callable(self, "_on_sfx_volume_changed"))
	mute_checkbox.connect("toggled", Callable(self, "_on_mute_toggled"))
	mute_all_button.connect("pressed", Callable(self, "_on_mute_all_pressed"))
	audio_back_button.connect("pressed", Callable(self, "_on_audio_back_pressed"))
	
	# Conectar botão de voltar dos créditos
	credits_back_button.connect("pressed", Callable(self, "_on_credits_back_pressed"))
	
	# Inicializar estado do menu
	set_menu_state(MenuState.MAIN)
	
	# Inicializar controles de áudio
	initialize_audio_controls()
	
	# Iniciar música do menu
	AudioManager.play_menu_music()

# Inicializa os controles de áudio com os valores atuais
func initialize_audio_controls():
	master_slider.value = AudioManager.get_master_volume()
	music_slider.value = AudioManager.get_music_volume()
	sfx_slider.value = AudioManager.get_sfx_volume()
	mute_checkbox.button_pressed = AudioManager.is_audio_muted()

# Define o estado do menu
func set_menu_state(new_state):
	current_state = new_state
	
	# Esconder todos os containers primeiro
	audio_container.visible = false
	credits_container.visible = false
	
	# Mostrar o container correto
	match current_state:
		MenuState.MAIN:
			# Menu principal já é visível por padrão
			pass
		MenuState.AUDIO:
			audio_container.visible = true
			# Atualizar os controles com os valores atuais
			initialize_audio_controls()
		MenuState.CREDITS:
			credits_container.visible = true

# Botão de iniciar novo jogo
func _on_start_button_pressed():
	print("Iniciando novo jogo")
	# Parar música do menu e iniciar música do jogo
	AudioManager.play_game_music()
	get_tree().change_scene_to_file("res://main.tscn")

# Botão de continuar jogo
func _on_continue_button_pressed():
	print("Tentando continuar jogo salvo")
	
	# Verificar se existe um jogo salvo
	var save_game = FileAccess.open("user://savegame.json", FileAccess.READ)
	if save_game:
		save_game.close()
		# Parar música do menu e iniciar música do jogo
		AudioManager.play_game_music()
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		print("Nenhum jogo salvo encontrado!")
		# Mostrar uma mensagem ou iniciar um novo jogo
		_on_start_button_pressed()

# Botão de configuração de áudio
func _on_audio_button_pressed():
	print("Abrindo configurações de áudio")
	set_menu_state(MenuState.AUDIO)

# Botão de visualizar biblioteca de cartas
func _on_cards_button_pressed():
	print("Abrindo biblioteca de cartas")
	get_tree().change_scene_to_file("res://cards_viewer.tscn")

# Botão de créditos
func _on_credits_button_pressed():
	print("Abrindo créditos")
	set_menu_state(MenuState.CREDITS)

# Botão de sair do jogo
func _on_quit_button_pressed():
	print("Saindo do jogo")
	get_tree().quit()

# Alteração do slider de volume principal
func _on_master_volume_changed(value):
	AudioManager.set_master_volume(value)

# Alteração do slider de volume da música
func _on_music_volume_changed(value):
	AudioManager.set_music_volume(value)

# Alteração do slider de volume dos efeitos
func _on_sfx_volume_changed(value):
	AudioManager.set_sfx_volume(value)

# Toggle de mudo
func _on_mute_toggled(button_pressed):
	AudioManager.set_mute(button_pressed)

# Botão de mutar tudo
func _on_mute_all_pressed():
	var new_state = AudioManager.toggle_mute()
	mute_checkbox.button_pressed = new_state

# Botão de voltar das configurações de áudio
func _on_audio_back_pressed():
	set_menu_state(MenuState.MAIN)

# Botão de voltar dos créditos
func _on_credits_back_pressed():
	set_menu_state(MenuState.MAIN) 
