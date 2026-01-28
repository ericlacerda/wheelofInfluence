extends CanvasLayer

signal battle_finished(result)

# Referências e configurações
var attacker_unit = null
var defender_unit = null
var attacker_wins = false
var region_id = -1
var unit_scene = preload("res://unit.tscn")

# Configurações de som
var battle_start_sound_played = false
var result_sound_played = false

# Configurações do efeito de destaque (highlight)
var highlight_effect_active = false
var highlight_timer = 0.0
var highlight_duration = 2.0  # Duração total do efeito em segundos
var highlight_target = null   # Referência à carta defensora que será destacada
var highlight_color = Color("#00FFFF")  # Azul ciano para destacar

# Configurações do efeito de queima (burn)
var burn_effect_active = false
var burn_timer = 0.0
var burn_duration = 2.0  # Duração total do efeito em segundos
var burn_target = null   # Referência à carta defensora que será queimada
var burn_color = Color("#FF4500")  # Vermelho-laranja para o efeito de queima
var burn_particles = null  # Armazenará as partículas de fogo se existirem

# A escala base é definida dinamicamente na função setup_battle
var card_battle_scale = Vector2(2.2, 2.2)  # Valor padrão

func _ready():
	# Inicializar cena de batalha
	visible = false
	layer = 10  # Valor alto para garantir que fique sobre todos os outros elementos

func _process(delta):
	# Processar o efeito de destaque se estiver ativo
	if highlight_effect_active and highlight_target:
		process_highlight_effect(delta)
	
	# Processar o efeito de queima se estiver ativo
	if burn_effect_active and burn_target:
		process_burn_effect(delta)

# Processar o efeito de destaque (highlight) 
func process_highlight_effect(delta):
	highlight_timer += delta
	
	# Verificar se já terminou o tempo do efeito
	if highlight_timer > highlight_duration:
		highlight_effect_active = false
		
		# Restaurar a aparência normal da carta
		var unit_instance = get_unit_instance(highlight_target)
		if unit_instance:
			unit_instance.modulate = Color(1, 1, 1, 1)
		
		return
	
	# Calcular progresso do efeito (0.0 a 1.0)
	var progress = min(highlight_timer / highlight_duration, 1.0)
	
	# Obter a instância da carta
	var unit_instance = get_unit_instance(highlight_target)
	if unit_instance:
		# Efeitos cintilantes azul-ciano para vitória
		
		# Base de "pulsação": velocidade rápida para efeito cintilante
		var pulse_fast = sin(Time.get_ticks_msec() * 0.02) * 0.4 + 0.6  # Pulsação rápida
		var pulse_slow = sin(Time.get_ticks_msec() * 0.005) * 0.3 + 0.7  # Pulsação lenta
		
		# Combinar pulsações para efeito mais complexo
		var pulse_combined = pulse_fast * pulse_slow
		
		# Efeito de brilho azul-ciano que varia na intensidade
		var blue_intensity = 1.0 + 0.8 * pulse_combined  # Brilho azul mais intenso
		var green_intensity = 1.0 + 0.6 * pulse_combined  # Turquesa/ciano
		var red_intensity = 0.7  # Mantém um pouco de vermelho para não ficar completamente azul
		
		# Aplicar modulação de cor
		unit_instance.modulate = Color(
			red_intensity,
			green_intensity, 
			blue_intensity,
			1.0
		)
		
		# Adicionar escala pulsante sutil
		var scale_pulse = 1.0 + 0.05 * pulse_combined
		unit_instance.scale = card_battle_scale * scale_pulse
		
		if int(highlight_timer * 5) % 5 == 0:  # Log a cada 0.2 segundos
			print("Efeito de destaque: ", progress * 100, "%")

# Processar o efeito de queima (burn) com modulação de cor e transparência
func process_burn_effect(delta):
	burn_timer += delta
	
	# Verificar se já terminou o tempo do efeito
	if burn_timer > burn_duration:
		burn_effect_active = false
		
		# Restaurar a aparência normal da carta
		var unit_instance = get_unit_instance(burn_target)
		if unit_instance:
			unit_instance.modulate = Color(1, 1, 1, 1)
			unit_instance.scale = card_battle_scale  # Restaurar escala original
		
		print("Efeito de queima finalizado")
		return
	
	# Calcular progresso do efeito (0.0 a 1.0)
	var progress = min(burn_timer / burn_duration, 1.0)
	
	# Obter a instância da carta
	var unit_instance = get_unit_instance(burn_target)
	if unit_instance:
		# Intensidade da pulsação para efeito de fogo
		var pulse_intensity = sin(Time.get_ticks_msec() * 0.015) * 0.3 + 0.7  # Varia entre 0.4 e 1.0
		
		# Efeito de queimadura com vermelho-laranja pulsante
		var red_intensity = 1.0 + 0.5 * pulse_intensity;
		var green_intensity = 0.7 - 0.4 * progress * pulse_intensity;
		var blue_intensity = 0.5 - 0.5 * progress * pulse_intensity;
		
		# Transparência gradual (a carta vai sumindo conforme queima)
		var alpha = 1.0;
		if progress > 0.5:
			alpha = lerp(1.0, 0.0, (progress - 0.5) * 2.0);
		
		# Aplicar o efeito visual
		unit_instance.modulate = Color(red_intensity, green_intensity, blue_intensity, alpha);
		
		if int(burn_timer * 10) % 10 == 0:  # Log a cada 0.1 segundos
			print("Efeito de queima: ", progress * 100, "% - Alpha: ", alpha);

# Função auxiliar para obter a instância da carta dentro de um nó
func get_unit_instance(node):
	if not node:
		return null
		
	for child in node.get_children():
		if child is Node2D:
			return child
	
	return null

# Configurar a cena de batalha com as unidades envolvidas
func setup_battle(attacker, defender, region):
	# Armazenar dados necessários
	attacker_unit = attacker
	defender_unit = defender
	region_id = region
	attacker_wins = attacker.attack > defender.defense
	
	# Reiniciar estado
	battle_start_sound_played = false
	result_sound_played = false
	highlight_effect_active = false
	highlight_timer = 0.0
	burn_effect_active = false
	burn_timer = 0.0
	
	# Configurar posições iniciais das cartas
	$AttackerCard.position = Vector2(160, 240)
	$DefenderCard.position = Vector2(480, 240)
	
	# Criar cópias visuais das cartas
	setup_card(attacker, $AttackerCard, true)
	setup_card(defender, $DefenderCard, false)
	call_deferred("apply_battle_scale")
	
	# Configurar textos
	$AttackerStats.text = "ATK: " + str(attacker.attack)
	$DefenderStats.text = "DEF: " + str(defender.defense)
	
	# Configurar o resultado da batalha
	if attacker_wins:
		$BattleResult.text = "Vitória do Atacante!"
		$BattleResult.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	else:
		$BattleResult.text = "Ataque Repelido!"
		$BattleResult.add_theme_color_override("font_color", Color(1, 0.5, 0, 1))
	
	# Garantir estado inicial dos elementos visuais
	$VersusLabel.modulate = Color(1, 0.874, 0, 0)
	$BattleResult.modulate = Color(1, 1, 1, 0)
	$AttackEffect.modulate = Color(1, 1, 1, 0)
	
	# Centralizar todos os elementos na tela
	center_battle_elements()
	
	# Tocar som de início de batalha
	if AudioManager:
		AudioManager.play_battle_start_sound()
		battle_start_sound_played = true
	
	# Mostrar cena e iniciar animação
	visible = true
	$AnimationPlayer.stop()
	
	# Conectar o sinal para detectar passos da animação (se ainda não conectado)
	if not $AnimationPlayer.is_connected("animation_step", Callable(self, "_on_animation_step")):
		$AnimationPlayer.connect("animation_step", Callable(self, "_on_animation_step"))
	
	$AnimationPlayer.play("battle_animation")
	print("Iniciando animação de batalha entre cartas")

# Função para monitorar os passos da animação e iniciar o efeito após o hit
func _on_animation_step(anim_name, step_time):
	# O efeito de hit ocorre aproximadamente no tempo 1.6 na animação
	if anim_name == "battle_animation" and step_time >= 1.6 and step_time < 1.7:
		print("Momento ideal para iniciar efeito após hit: ", step_time)
		
		# Decidir qual efeito aplicar com base no resultado da batalha
		if not attacker_wins:
			# Defesa ganhou - aplicar efeito de destaque na carta defensora
			start_highlight_effect()
		else:
			# Defesa perdeu - aplicar efeito de queima na carta defensora
			start_burn_effect()
			
		play_result_sounds()

# Tocar sons de resultado da batalha
func play_result_sounds():
	if result_sound_played or not AudioManager:
		return
		
	if attacker_wins:
		# O atacante vence
		AudioManager.play_card_sound(attacker_unit, true)
		AudioManager.play_card_sound(defender_unit, false)
	else:
		# O defensor vence
		AudioManager.play_card_sound(defender_unit, true)
		AudioManager.play_card_sound(attacker_unit, false)
	
	result_sound_played = true

# Chamado quando a animação terminar
func animation_finished():
	print("Animação de batalha concluída, resultado:", "Vitória" if attacker_wins else "Derrota")
	
	# Se por algum motivo os efeitos ainda não foram iniciados, inicie-os agora
	if not highlight_effect_active and not attacker_wins:
		start_highlight_effect()
		play_result_sounds()
	elif not burn_effect_active and attacker_wins:
		start_burn_effect()
		play_result_sounds()
	
	# Aguardar a conclusão do efeito
	var effect_duration = max(highlight_duration, burn_duration)
	await get_tree().create_timer(effect_duration).timeout
	
	# Limpar efeitos
	cleanup_effects()
	
	# Emitir sinal de que a batalha terminou
	emit_signal("battle_finished", attacker_wins)
	
	# Esconder a cena e redefinir estado
	reset_battle_scene()

# Limpar os efeitos 
func cleanup_effects():
	# Restaurar aparência da carta com highlight se necessário
	if highlight_target:
		var unit_instance = get_unit_instance(highlight_target)
		if unit_instance:
			unit_instance.modulate = Color(1, 1, 1, 1)
			unit_instance.scale = card_battle_scale  # Restaurar escala original
	
	# Restaurar aparência da carta com burn se necessário
	if burn_target:
		var unit_instance = get_unit_instance(burn_target)
		if unit_instance:
			unit_instance.modulate = Color(1, 1, 1, 1)
			unit_instance.scale = card_battle_scale  # Restaurar escala original

# Resetar a cena de batalha para o estado inicial
func reset_battle_scene():
	visible = false
	$AttackerCard.position = Vector2(160, 240)
	$DefenderCard.position = Vector2(480, 240)
	$VersusLabel.modulate = Color(1, 0.874, 0, 0)
	$BattleResult.modulate = Color(1, 1, 1, 0)
	$AttackEffect.modulate = Color(1, 1, 1, 0)
	
	highlight_effect_active = false
	burn_effect_active = false
	
	# Desconectar o sinal para evitar múltiplas conexões
	if $AnimationPlayer.is_connected("animation_step", Callable(self, "_on_animation_step")):
		$AnimationPlayer.disconnect("animation_step", Callable(self, "_on_animation_step"))

# Aplicar escala de batalha às cartas
func apply_battle_scale():
	card_battle_scale = Vector2(2.2, 2.2)
	
	# Aplicar à carta do atacante
	for child in $AttackerCard.get_children():
		if child is Node2D:
			child.scale = card_battle_scale
	
	# Aplicar à carta do defensor
	for child in $DefenderCard.get_children():
		if child is Node2D:
			child.scale = card_battle_scale

# Começar o efeito de destaque (highlight) na carta defensora quando ela ganha
func start_highlight_effect():
	# Efeito de highlight SOMENTE é aplicado na carta defensora quando ela ganha
	highlight_target = $DefenderCard
	
	# Encontrar a instância da carta
	var unit_instance = get_unit_instance(highlight_target)
	if not unit_instance:
		print("ERRO: Não encontrou instância da carta para aplicar efeito de destaque")
		return
	
	# Iniciar o efeito de destaque (vai ser processado em process_highlight_effect)
	highlight_effect_active = true
	highlight_timer = 0.0
	
	print("Iniciando efeito de destaque na carta defensora")

# Começar o efeito de queima (burn) na carta defensora quando ela perde
func start_burn_effect():
	# Efeito de burn SOMENTE é aplicado na carta defensora quando ela perde
	burn_target = $DefenderCard
	
	# Encontrar a instância da carta
	var unit_instance = get_unit_instance(burn_target)
	if not unit_instance:
		print("ERRO: Não encontrou instância da carta para aplicar efeito de queima")
		return
	
	# Iniciar o efeito de queima (vai ser processado em process_burn_effect)
	burn_effect_active = true
	burn_timer = 0.0
	
	print("Iniciando efeito de queima na carta defensora")

# Configurar uma carta visual para a batalha
func setup_card(unit_data, parent_node, is_attacker):
	# Limpar quaisquer cartas existentes
	for child in parent_node.get_children():
		child.queue_free()
	
	# Instanciar e configurar nova carta
	var unit_instance = unit_scene.instantiate()
	parent_node.add_child(unit_instance)
	unit_instance.position = Vector2(0, 0)
	unit_instance.initialize(unit_data)
	unit_instance.set_player(1 if is_attacker else 2)
	unit_instance.set_in_distribution_panel(false)
	unit_instance.rotation_degrees = 0

# Centraliza os elementos da batalha na tela
func center_battle_elements():
	var screen_size = get_viewport().get_visible_rect().size
	var screen_center = screen_size / 2
	
	# Posicionar elementos centralizados
	$VersusLabel.position = Vector2(screen_center.x, screen_center.y)
	$VersusLabel.pivot_offset = $VersusLabel.size / 2
	
	# Centralizar as cartas verticalmente
	$AttackerCard.position.y = screen_center.y
	$DefenderCard.position.y = screen_center.y
	
	# Centralizar os efeitos
	$AttackEffect.position = screen_center
	$AttackEffect.pivot_offset = Vector2(25, 25)
	
	print("Centro da tela:", screen_center)
	print("Posição inicial dos elementos:",
		"\nAttackerCard:", $AttackerCard.position,
		"\nDefenderCard:", $DefenderCard.position,
		"\nAttackEffect:", $AttackEffect.position)

# Função para tocar som de ataque (chamada pela animação)
func play_attack_sound():
	if AudioManager and not result_sound_played:
		AudioManager.play_battle_effect(AudioManager.BATTLE_START_SOUND)

# Função auxiliar para encontrar sprites nas cartas
func find_sprite_in_children(node):
	# Procura diretamente
	if node is Sprite2D:
		return node
		
	# Procura recursivamente nos filhos
	for child in node.get_children():
		if child is Sprite2D:
			return child
		
		# Recursão: procurar em filhos de filhos
		var found = find_sprite_in_children(child)
		if found:
			return found
			
	return null  # Não encontrado 
