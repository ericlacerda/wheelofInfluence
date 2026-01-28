extends CanvasLayer

signal battle_finished(result)

# Dados da batalha
var attacker_data = null
var defender_data = null
var attacker_wins = false
var region_id = -1

# Referências Visuais
@onready var left_panel = $LeftPanel
@onready var right_panel = $RightPanel
@onready var anim_player = $AnimationPlayer
@onready var result_label = $ResultLabel

func _ready():
	visible = false

func setup_battle(attacker, defender, region, _from_pos = Vector2.ZERO):
	attacker_data = attacker
	defender_data = defender
	region_id = region
	attacker_wins = attacker.attack > defender.defense
	
	# Configurar Atacante (Esquerda)
	setup_combatant_panel($LeftPanel, attacker, true)
	
	# Configurar Defensor (Direita)
	setup_combatant_panel($RightPanel, defender, false)
	
	# Restaurar estado inicial
	result_label.visible = false
	$Background.modulate.a = 0.0
	$VSLabel.modulate.a = 0.0
	$FlashOverlay.color.a = 0.0
	
	# Iniciar
	visible = true
	start_battle_sequence_code()

# Configura visual do painel de combatente
func setup_combatant_panel(panel, unit, is_attacker):
	var portrait = panel.get_node("PortraitFrame/Portrait")
	var name_label = panel.get_node("InfoPanel/NameLabel")
	var stats_label = panel.get_node("InfoPanel/StatsLabel")
	
	name_label.text = unit.title
	
	# Carregar Imagem
	var img_path = "res://Image/Cards/" + unit.image
	if not ResourceLoader.exists(img_path):
		img_path = "res://Image/Cards/Cards/" + unit.image # Fallback para pasta aninhada
	
	if ResourceLoader.exists(img_path):
		portrait.texture = load(img_path)
	else:
		portrait.texture = load("res://icon.svg")
		
	# Estatísticas
	if is_attacker:
		stats_label.text = "ATK: " + str(int(unit.attack))
		stats_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4)) # Vermelho suave
	else:
		stats_label.text = "DEF: " + str(int(unit.defense))
		stats_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1)) # Azul suave

# Sequência de Batalha via Código (Mais robusta que AnimationPlayer para UI dinâmica)
func start_battle_sequence_code():
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_width = 220
	
	# Posições Iniciais (Fora da tela)
	left_panel.position.x = -panel_width
	right_panel.position.x = viewport_size.x + panel_width
	
	# Posições Finais (Separadas: 25% e 75%)
	var left_final_x = (viewport_size.x * 0.25) - (panel_width / 2.0)
	var right_final_x = (viewport_size.x * 0.75) - (panel_width / 2.0)
	
	# Centralizar Verticalmente
	var panel_height = 320
	var center_y = (viewport_size.y - panel_height) / 2.0
	left_panel.position.y = center_y
	right_panel.position.y = center_y
	
	# Ajustar tamanho dos painéis (importante caso o Tscn tenha tamanho diferente)
	left_panel.size = Vector2(panel_width, panel_height)
	right_panel.size = Vector2(panel_width, panel_height)
	
	if AudioManager:
		AudioManager.play_battle_start_sound()
		
	# --- FASE 1: ENTRADA (0.0s - 0.5s) ---
	var tween_intro = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween_intro.tween_property($Background, "modulate:a", 1.0, 0.5)
	tween_intro.tween_property(left_panel, "position:x", left_final_x, 0.5)
	tween_intro.tween_property(right_panel, "position:x", right_final_x, 0.5)
	
	# VS Label aparece com delay e efeito de impacto
	$VSLabel.scale = Vector2(2.5, 2.5) # Começa grande
	
	var tween_vs = create_tween().set_parallel(true)
	tween_vs.tween_interval(0.3)
	tween_vs.tween_property($VSLabel, "modulate:a", 1.0, 0.2).set_delay(0.3)
	tween_vs.tween_property($VSLabel, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(0.3)
	
	await tween_intro.finished
	
	# --- FASE 2: TENSÃO (0.5s - 2.0s) ---
	# Aguarda leitura dos stats
	await get_tree().create_timer(1.5).timeout
	
	# --- FASE 3: IMPACTO (2.0s) ---
	# Flash antes do impacto
	var tween_flash = create_tween()
	tween_flash.tween_property($FlashOverlay, "color:a", 0.8, 0.1)
	tween_flash.tween_callback(Callable(self, "trigger_impact_visuals"))
	tween_flash.tween_property($FlashOverlay, "color:a", 0.0, 0.3)
	
	await tween_flash.finished
	
	# --- FASE 4: FIM (3.0s - 4.0s) ---
	await get_tree().create_timer(1.0).timeout
	animation_finished()

# (Depreciado) Mantido apenas para evitar erros se sobrar referência no Tscn
func start_battle_sequence():
	start_battle_sequence_code()

# Chamado pela AnimationPlayer no momento do impacto (aprox 2.0s)
func trigger_impact_visuals():
	print("IMPACTO!")
	
	# Screen Shake
	shake_screen()
	
	# Esconder VS Label para evitar sobreposição
	var tween_hide_vs = create_tween()
	tween_hide_vs.tween_property($VSLabel, "modulate:a", 0.0, 0.2)
	
	# Mostrar Resultado
	result_label.visible = true
	if attacker_wins:
		result_label.text = "CRITICAL HIT!"
		result_label.modulate = Color(1, 0, 0)
		
		# Som
		if AudioManager:
			AudioManager.play_card_sound(attacker_data, true)
			
		# Efeito visual no perdedor (Direita)
		var tween = create_tween()
		tween.tween_property($RightPanel, "modulate", Color(10, 0, 0), 0.1) # Flash vermelho
		tween.tween_property($RightPanel, "modulate", Color(1, 1, 1), 0.1)
		tween.tween_property($RightPanel, "rotation_degrees", 5.0, 0.05)
		tween.tween_property($RightPanel, "rotation_degrees", -5.0, 0.05)
		tween.tween_property($RightPanel, "rotation_degrees", 0.0, 0.05)
		tween.tween_property($RightPanel, "modulate:a", 0.0, 0.5) # Desaparece
		
	else:
		result_label.text = "BLOCKED!"
		result_label.modulate = Color(0.5, 0.5, 1.0)
		
		# Som
		if AudioManager:
			AudioManager.play_card_sound(defender_data, true)
			
		# Efeito visual no atacante (Esquerda - Recoil)
		var tween = create_tween()
		tween.tween_property($LeftPanel, "position:x", $LeftPanel.position.x - 50, 0.2).set_trans(Tween.TRANS_ELASTIC)
		
# Tremor de tela simples
func shake_screen():
	var original_pos = Vector2.ZERO
	# Como é CanvasLayer, movemos o offset transform
	var tween = create_tween()
	for i in range(10):
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		tween.tween_property(self, "offset", offset, 0.05)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.05)

# Chamado pela AnimationPlayer no final
func animation_finished():
	print("Batalha finalizada")
	emit_signal("battle_finished", attacker_wins)
	queue_free() # Destroi a cena para economizar recursos e garantir reset limpo na próxima

# (Compatibilidade) Funções antigas vazias caso chamadas externamente
func update_card_visual(_p, _u): pass
func fade_in_battle(): pass
func fade_out_battle_and_reset(): pass
