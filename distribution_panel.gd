extends Panel

signal unit_selected(unit)
signal distribute_units
signal cancel_distribution

var unit_buttons = []
var selected_units = []

# Referência à cena da unidade
var unit_scene = preload("res://unit.tscn")

# Configurações para o layout em linha
const CARD_SPACING = 12.0       # Espaçamento maior entre as cartas maiores
const CARD_BASE_SCALE = 1.0     # Cartas em tamanho normal (escala 1.0)
const CARD_HOVER_SCALE = 1.3    # Escala aumentada quando passar o mouse sobre a carta
const CARD_ELEVATION = 20.0     # Elevação maior quando selecionadas

func _ready():
	# Tornar o painel totalmente transparente
	self_modulate = Color(1, 1, 1, 0.95)
	
	# Configurar texto de instrução
	$Instructions.text = "Selecione a ORDEM de distribuição das cartas.\nTodas as cartas serão distribuídas."
	$Instructions.add_theme_color_override("font_color", Color(1, 0.9, 0.6, 1))
	$Instructions.add_theme_font_size_override("font_size", 12)
	
	# Conectar botões à funções
	$DistributeButton.connect("pressed", Callable(self, "_on_distribute_pressed"))
	$CancelButton.connect("pressed", Callable(self, "_on_cancel_pressed"))
	$DistributeButton.text = "Distribuir Todas"

# Limpa todos os botões de unidades
func clear_units():
	for unit_instance in $UnitsContainer.get_children():
		unit_instance.queue_free()
	unit_buttons = []
	selected_units = []

# Adiciona uma carta de unidade
func add_unit_button(unit_data):
	var unit_instance = unit_scene.instantiate()
	$UnitsContainer.add_child(unit_instance)
	
	# Configurar a unidade
	unit_instance.initialize(unit_data)
	
	# Marcar que esta unidade está no painel de distribuição
	unit_instance.set_in_distribution_panel(true)
	
	# Conectar o sinal de clique
	unit_instance.connect("unit_clicked", Callable(self, "_on_unit_clicked"))
	
	# Conectar sinais para efeitos de hover
	unit_instance.connect("mouse_entered", Callable(self, "_on_card_mouse_entered").bind(unit_instance))
	unit_instance.connect("mouse_exited", Callable(self, "_on_card_mouse_exited").bind(unit_instance))
	
	# Adicionar à lista de cartas
	unit_buttons.append(unit_instance)
	
	# Reorganizar cartas no painel
	organize_cards()

# Organiza as cartas visualmente lado a lado
func organize_cards():
	var total_cards = unit_buttons.size()
	if total_cards == 0:
		return
	
	# Calcular o espaço total necessário
	var card_width = 70.0 * CARD_BASE_SCALE  # Largura da carta com escala
	var total_width = (card_width + CARD_SPACING) * total_cards - CARD_SPACING
	
	# Limitar o número máximo de cartas visíveis lado a lado
	var max_visible_cards = min(5, total_cards)  # No máximo 5 cartas lado a lado
	var display_width = (card_width + CARD_SPACING) * max_visible_cards - CARD_SPACING
	
	# Manter tudo na mesma linha, mas limitar a largura total para não ultrapassar a tela
	var effective_width = min(total_width, display_width)
	
	# Posição inicial (canto esquerdo do conjunto de cartas)
	var start_x = -effective_width / 2
	
	# Posicionar as cartas lado a lado
	for i in range(total_cards):
		var x_pos
		if total_cards <= max_visible_cards:
			# Se tiverem poucas cartas, espaçar uniformemente
			x_pos = start_x + i * (card_width + CARD_SPACING)
		else:
			# Se tiverem muitas cartas, distribuir uniformemente no espaço disponível
			x_pos = start_x + (i / float(total_cards - 1)) * (effective_width - card_width)
		
		var y_pos = 0  # Todas na mesma altura
		
		# Aplicar transformações
		unit_buttons[i].position = Vector2(x_pos, y_pos)
		unit_buttons[i].rotation_degrees = 0  # Sem rotação
		unit_buttons[i].scale = Vector2(CARD_BASE_SCALE, CARD_BASE_SCALE)  # Escala base
		
		# Ajustar z_index para que as cartas mais à direita fiquem à frente
		unit_buttons[i].z_index = 10 + i

# Atualiza a visualização dos botões com base na seleção
func update_selection(units):
	# Atualizar a lista de unidades selecionadas
	selected_units = units.duplicate()
	
	print("Atualizando seleção. Unidades selecionadas: ", selected_units.size())
	
	# Reorganizar primeiro para posicionar todas as cartas
	organize_cards()
	
	# Atualizar a aparência de cada carta
	for unit_instance in unit_buttons:
		var is_selected = false
		var selection_order = -1
		
		# Verificar se a unidade está selecionada e qual sua ordem
		for i in range(selected_units.size()):
			if selected_units[i].id == unit_instance.id:
				is_selected = true
				selection_order = i
				print("Carta ", unit_instance.id, " selecionada com ordem ", selection_order + 1)
				break
		
		# Atualizar aparência visual da carta
		unit_instance.set_selected(is_selected, selection_order)
		
		# Ajustar posição vertical quando selecionada
		if is_selected:
			unit_instance.position.y -= CARD_ELEVATION
			unit_instance.z_index = 30 + selection_order  # Cartas selecionadas em ordem ficam em cima
		else:
			unit_instance.z_index = 10  # Cartas não selecionadas ficam abaixo

# Quando o mouse entra em uma carta
func _on_card_mouse_entered(card_instance):
	# Aumentar a carta
	card_instance.scale = Vector2(CARD_HOVER_SCALE, CARD_HOVER_SCALE)
	# Levantar um pouco a carta
	card_instance.position.y -= 10
	# Trazer para frente
	card_instance.z_index += 50

# Quando o mouse sai de uma carta
func _on_card_mouse_exited(card_instance):
	# Verificar se a carta está selecionada
	var is_selected = false
	for unit in selected_units:
		if unit.id == card_instance.id:
			is_selected = true
			break
	
	# Restaurar o tamanho original
	card_instance.scale = Vector2(CARD_BASE_SCALE, CARD_BASE_SCALE)
	
	# Restaurar a posição vertical, considerando se está selecionada
	if is_selected:
		card_instance.position.y = -CARD_ELEVATION
	else:
		card_instance.position.y = 0
	
	# Reorganizar para garantir que os z-indices estejam corretos
	organize_cards()
	
	# Reaplicar elevação para cartas selecionadas
	update_selection(selected_units)

# Quando uma unidade é clicada
func _on_unit_clicked(unit_instance):
	print("Clique em unidade detectado: ", unit_instance.id)
	
	# Busca a unidade original nos dados de jogo da região
	var found = false
	var main_node = get_node("/root/Main")
	if main_node:
		for region in main_node.regions:
			for unit in region.get_units():
				if unit.id == unit_instance.id:
					found = true
					emit_signal("unit_selected", unit)
					break
			if found:
				break
	
	# Caso a unidade não seja encontrada (não deveria acontecer)
	if not found:
		print("ALERTA: Unidade não encontrada nas regiões, enviando dados básicos")
		# Passar os dados básicos
		emit_signal("unit_selected", {
			"id": unit_instance.id,
			"attack": unit_instance.attack,
			"defense": unit_instance.defense,
			"title": unit_instance.title,
			"description": unit_instance.description
		})

# Quando o botão de distribuir é pressionado
func _on_distribute_pressed():
	emit_signal("distribute_units")

# Quando o botão de cancelar é pressionado
func _on_cancel_pressed():
	emit_signal("cancel_distribution") 
