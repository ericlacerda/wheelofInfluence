extends Node2D

signal region_clicked(region_id)

var region_id = 0
var neighbors = []
var units = []

# Referência ao nó visual da região
@onready var region_sprite = $RegionSprite
@onready var clickable_button = $ClickableButton
@onready var collision_shape = $Area2D/CollisionShape2D
@onready var units_container = $Units
@onready var label = $Label

# Referência à cena da unidade
var unit_scene = preload("res://unit.tscn")

# Configurações para as cartas
const MAX_VISIBLE_CARDS = 12        # Aumentado para mostrar mais cartas
const CARD_SPACING_Y = 15           # Espaçamento vertical entre cartas (altura da área de ataque/defesa)
const CARD_SCALE = 0.7              # Escala das cartas na região (aumentada de 0.3 para 0.4)
const CARD_WIDTH = 70.0             # Largura de uma carta (em pixels)
const CARD_HEIGHT = 105.0           # Altura de uma carta (em pixels)
const MIN_REGION_SIZE = 14.0        # Tamanho mínimo da região (sem cartas) - metade da largura da carta
const CARD_VISIBLE_PORTION = 15.0   # Altura da porção visível de cada carta na pilha (exceto a primeira)

# Variáveis de controle
var has_been_clicked = false
var original_color = Color(0.878431, 0.878431, 0.878431, 1)
var highlight_color = Color(1, 0.5, 0.5, 1)  # Vermelho claro para destacar
var pending_update = false         # Flag para atualizações pendentes em vez de imediatas
var click_timer = null            # Timer para controlar o intervalo entre cliques
var highlight_timer = null        # Timer para controlar a duração do destaque
var unit_instances = []           # Armazenar referências às instâncias de unidades

func _ready():
	# Desabilitar o _process padrão - usaremos timers explícitos em vez disso
	set_process(false)
	
	# Configurar a área clicável
	clickable_button.connect("pressed", Callable(self, "_on_button_pressed"))
	$Area2D.connect("input_event", Callable(self, "_on_Area2D_input_event"))
	$Area2D.input_pickable = true
	
	# Configurar detecção de cliques diretamente no nó
	set_process_input(true)
	
	# Configurações visuais
	original_color = region_sprite.color
	clickable_button.self_modulate = Color(1, 1, 1, 0.01)  # Quase invisível
	units_container.z_index = 10  # Garantir que as unidades fiquem sobre a região
	
	# Criar timers para gerenciar estados
	click_timer = Timer.new()
	click_timer.one_shot = true
	click_timer.wait_time = 0.5  # Tempo de bloqueio entre cliques para evitar spam
	add_child(click_timer)
	
	highlight_timer = Timer.new()
	highlight_timer.one_shot = true
	highlight_timer.wait_time = 0.3  # Tempo de destaque
	highlight_timer.connect("timeout", Callable(self, "_on_highlight_timeout"))
	add_child(highlight_timer)
	
	# Atualizar visualização inicial
	call_deferred("update_visual")

# Quando o timer de destaque termina
func _on_highlight_timeout():
	# Restaurar a cor original sem piscar
	region_sprite.color = original_color
	
	# Emitir sinal de clique
	emit_signal("region_clicked", region_id)

# Quando o botão é pressionado manualmente
func _on_button_pressed():
	_handle_click()

# Capturar cliques globais
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var local_pos = to_local(event.global_position)
		if region_sprite:
			var width = abs(region_sprite.offset_right - region_sprite.offset_left)
			var height = abs(region_sprite.offset_bottom - region_sprite.offset_top)
			var half_width = width / 2
			var half_height = height / 2
			
			if local_pos.x >= -half_width and local_pos.x <= half_width and \
			   local_pos.y >= -half_height and local_pos.y <= half_height:
				_handle_click()

# Quando a área da região é clicada
func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_click()

# Centralizar o tratamento de cliques para evitar duplicações
func _handle_click():
	# Verificar se está no período de cooldown
	if click_timer.is_stopped():
		# Iniciar o timer de cooldown
		click_timer.start()
		
		# Destacar visualmente a região
		region_sprite.color = highlight_color
		
		# Iniciar o timer para retorno à cor original
		highlight_timer.start()

# Adiciona uma unidade à região (com atualização atrasada)
func add_unit(unit_data):
	units.append(unit_data)
	pending_update = true
	call_deferred("update_visual")
	return unit_data

# Remove uma unidade da região (com atualização atrasada)
func remove_unit(unit_to_remove):
	for i in range(units.size()):
		if units[i].id == unit_to_remove.id:
			units.remove_at(i)
			pending_update = true
			call_deferred("update_visual")
			break
	return

# Obtém todas as unidades da região
func get_units():
	return units

# Atualiza a representação visual da região
func update_visual():
	# Evitar atualizações desnecessárias
	if not pending_update and unit_instances.size() == units.size():
		return
	
	# Reiniciar a flag de atualização pendente
	pending_update = false
	
	# Atualizar o texto da contagem de unidades
	label.text = str(units.size())
	
	# Limpar instâncias antigas
	for unit_instance in unit_instances:
		unit_instance.queue_free()
	unit_instances.clear()
	
	# Determinar quais unidades serão visíveis
	var visible_units = units
	var start_index = 0
	
	if units.size() > MAX_VISIBLE_CARDS:
		start_index = units.size() - MAX_VISIBLE_CARDS
		visible_units = units.slice(start_index, units.size())
	
	# Calcular dimensões da região
	var total_cards = visible_units.size()
	var card_width = CARD_WIDTH * CARD_SCALE
	var region_width = card_width / 2  # Metade da largura da carta
	
	# Configurar o posicionamento vertical das cartas (empilhadas)
	var first_card_y = 0
	var total_height = 0
	
	if total_cards > 0:
		# Altura total da pilha considerando a primeira carta completa e as demais com apenas a porção visível
		total_height = (CARD_HEIGHT * CARD_SCALE) + (CARD_VISIBLE_PORTION * (total_cards - 1))
		
		# Posição Y da primeira carta (centralizada em relação à pilha)
		first_card_y = -(total_height / 2) + (CARD_HEIGHT * CARD_SCALE / 2)
	
	# Definir tamanho e posição da região baseado na altura total da pilha
	var region_height = max(MIN_REGION_SIZE, total_height)
	var region_offset_y = 0  # Centralizar a região na pilha
	
	# Atualizar visualização da região sem animações ou transições
	_update_region_visuals(region_width, region_height, region_offset_y)
	
	# Criar instâncias de cartas empilhadas verticalmente
	for i in range(visible_units.size()):
		var unit_instance = unit_scene.instantiate()
		units_container.add_child(unit_instance)
		unit_instances.append(unit_instance)
		
		var actual_index = start_index + i
		
		# Posicionamento vertical para criar efeito de pilha
		# A primeira carta aparece totalmente, e as demais mostram apenas a porção de ataque/defesa
		var y_pos = first_card_y + (i * CARD_VISIBLE_PORTION)
		
		unit_instance.position = Vector2(0, y_pos)
		unit_instance.initialize(visible_units[i])
		unit_instance.set_in_distribution_panel(false)
		unit_instance.z_index = i  # Cartas mais recentes ficam em cima
		unit_instance.scale = Vector2(CARD_SCALE, CARD_SCALE)
		unit_instance.rotation_degrees = 0
		
		# Definir o jogador proprietário
		if actual_index == units.size() - 1 and units.size() > 1:
			var main_node = get_node_or_null("/root/Main")
			if main_node and main_node.has_method("get_current_player"):
				var current_player = main_node.current_player
				unit_instance.set_player(current_player)
			else:
				unit_instance.set_player(1)
		else:
			unit_instance.set_player(1)

# Função desacoplada para atualizar somente os elementos visuais da região
func _update_region_visuals(width, height, offset_y):
	# Calcular a largura baseada na carta com escala 0.4 (70px * 0.4 = 28px)
	# Usamos a largura exata da carta, sem divisão por 2
	var card_width = CARD_WIDTH * CARD_SCALE
	width = max(width, card_width)
	
	# Metade da largura para o offset
	var half_width = width / 2
	
	# Atualizar retângulo visual
	if region_sprite:
		region_sprite.offset_left = -half_width
		region_sprite.offset_top = -(height / 2) + offset_y
		region_sprite.offset_right = half_width
		region_sprite.offset_bottom = (height / 2) + offset_y
		region_sprite.z_index = -1
	
	# Atualizar botão clicável para ter exatamente o mesmo tamanho da região
	if clickable_button:
		clickable_button.offset_left = -half_width
		clickable_button.offset_top = -(height / 2) + offset_y
		clickable_button.offset_right = half_width
		clickable_button.offset_bottom = (height / 2) + offset_y
	
	# Atualizar colisão
	if collision_shape and collision_shape.shape:
		collision_shape.shape.radius = max(half_width, height / 2)
		$Area2D.position.y = offset_y
