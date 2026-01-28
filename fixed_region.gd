extends Node2D

signal region_clicked(region_id)

var region_id = 0
var neighbors = []
var units = []

# Referência ao nó visual da região
@onready var region_sprite = $RegionSprite
@onready var clickable_button = $ClickableButton

# Referência à cena da unidade
var unit_scene = preload("res://unit.tscn")

# Máximo de cartas visíveis na pilha
const MAX_VISIBLE_CARDS = 5

func _ready():
	# Conectar o botão de clique
	clickable_button.connect("pressed", Callable(self, "_on_button_pressed"))
	
	# Certificar-se que a Area2D também está conectada
	$Area2D.connect("input_event", Callable(self, "_on_Area2D_input_event"))
	$Area2D.input_pickable = true
	
	# Garantir que o botão está visível mas transparente
	clickable_button.self_modulate = Color(1, 1, 1, 0.01)  # Quase invisível

# Quando o botão é pressionado
func _on_button_pressed():
	print("Botão da região clicado: ", region_id)
	emit_signal("region_clicked", region_id)

# Quando a área da região é clicada
func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Area2D da região detectou clique: ", region_id)
		emit_signal("region_clicked", region_id)

# Adiciona uma unidade à região
func add_unit(unit_data):
	units.append(unit_data)
	update_visual()
	return unit_data

# Remove uma unidade da região
func remove_unit(unit_to_remove):
	for i in range(units.size()):
		if units[i].id == unit_to_remove.id:
			units.remove_at(i)
			break
	update_visual()

# Obtém todas as unidades da região
func get_units():
	return units

# Atualiza a representação visual da região
func update_visual():
	# Atualizar o texto para mostrar quantas unidades estão na região
	$Label.text = str(units.size())
	
	# Limpar unidades visuais existentes
	for child in $Units.get_children():
		child.queue_free()
	
	# Determinar quais cartas mostrar (limitando a um número máximo)
	var visible_units = units
	var start_index = 0
	
	# Se tivermos mais cartas que o limite, mostrar apenas as mais recentes
	if units.size() > MAX_VISIBLE_CARDS:
		start_index = units.size() - MAX_VISIBLE_CARDS
		visible_units = units.slice(start_index, units.size())
	
	# Adicionar representação visual para cada unidade como uma carta
	for i in range(visible_units.size()):
		var unit_instance = unit_scene.instantiate()
		$Units.add_child(unit_instance)
		
		var actual_index = start_index + i
		
		# Para cartas maiores, precisamos de posicionamento diferente
		# Vamos empilhar melhor (mais para cima) e usar uma escala menor
		
		# Posição base acima da região
		var offset_x = 0
		var offset_y = -95  
		
		# Para criar o efeito de lista, cada carta vai ficar um pouco abaixo da anterior
		offset_y += i * 20  # Deslocamento vertical para criar o efeito de lista
		
		unit_instance.position = Vector2(offset_x, offset_y)
		unit_instance.initialize(visible_units[i])
		
		# Marcar explicitamente que esta unidade NÃO está no painel de distribuição
		unit_instance.set_in_distribution_panel(false)
		
		# Definir a profundidade (z_index) para que as cartas mais recentes fiquem por cima
		unit_instance.z_index = i
		
		# Escalar as cartas para ocuparem menos espaço (sendo que são maiores agora)
		var scale_factor = 0.65
		unit_instance.scale = Vector2(scale_factor, scale_factor)
		
		# Definir o jogador proprietário (para a cor)
		if actual_index == units.size() - 1 and units.size() > 1:
			# A unidade mais recente (a que acabou de ser adicionada)
			# pertence ao jogador atual
			var current_player = get_node("/root/Main").current_player
			unit_instance.set_player(current_player)
		else:
			# Unidades mais antigas pertencem ao jogador 1
			unit_instance.set_player(1) 
