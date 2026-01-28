extends Node2D

# Propriedades da unidade
var id: String
var card_id: String = ""  # ID da carta para referência ao tipo da unidade
var attack: int
var defense: int
var title: String = "Unidade"
var description: String = "Uma unidade de combate."
var image_path: String
var player: int = 1  # 1 para jogador 1, 2 para jogador 2
var in_distribution_panel: bool = false  # Flag para saber se está no painel de distribuição

# Sinais
signal unit_clicked(unit)
signal mouse_entered
signal mouse_exited

# Referências a nós
@onready var attack_label = $Card/AttackBox/AttackLabel
@onready var defense_label = $Card/DefenseBox/DefenseLabel
@onready var title_label = $Card/TitleLabel
@onready var description_label = $Card/DescriptionLabel
@onready var unit_texture = $Card/UnitTexture
@onready var order_label = $Card/OrderLabel
@onready var card = $Card
@onready var selection_indicator = $SelectionIndicator

func _ready():
	# Garantir que o selection_indicator comece invisível
	if selection_indicator:
		selection_indicator.visible = false
	
	# Definir a escala inicial da carta
	if not in_distribution_panel:
		scale = Vector2(0.4, 0.4)  # Escala 0.4 resulta em 28px de largura (70px * 0.4)
	
	# Monitorar eventos de input
	set_process_input(true)
	
	# Atualizar a visualização da carta
	update_card()
	
	# Configurar a aparência do rótulo de ordem
	if order_label:
		# Configurar o número de ordem para aparecer no centro da carta
		# e com fonte grande e branca para melhor visibilidade
		configure_order_label()
		
	# Conectar sinais de mouse para detecção de hover
	if card:
		card.mouse_entered.connect(_on_card_mouse_entered)
		card.mouse_exited.connect(_on_card_mouse_exited)
	
	# Conectar o sinal de clique apenas se a unidade estiver no painel de distribuição
	$Card.connect("gui_input", Callable(self, "_on_card_gui_input"))

# Configura a aparência do rótulo de ordem
func configure_order_label():
	# Definir a posição para o centro
	var label_size = Vector2(60, 60)
	order_label.position = Vector2(30, 60)  # Posição aproximada do centro da carta
	order_label.size = label_size
	
	# Configurar a fonte e cores
	var font_size = 42
	var white_color = Color(1, 1, 1, 1)
	var outline_color = Color(0, 0, 0, 1)
	
	# Aplicar as configurações
	order_label.add_theme_font_size_override("font_size", font_size)
	order_label.add_theme_color_override("font_color", white_color)
	order_label.add_theme_color_override("font_outline_color", outline_color)
	order_label.add_theme_constant_override("outline_size", 2)
	
	# Configurar o alinhamento do texto
	order_label.horizontal_alignment = 1  # HORIZONTAL_CENTER = 1
	order_label.vertical_alignment = 1    # VERTICAL_CENTER = 1

# Detectar cliques na própria unidade
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Verificar se o clique foi nesta unidade e se estamos no painel de distribuição
		if in_distribution_panel:
			# Obter a posição local do clique
			var local_pos = to_local(event.global_position)
			var size = Vector2(70, 105) * scale  # Ajustar pelo escala atual da carta
			var rect = Rect2(-size/2, size)
			
			# Verificar se o clique está dentro da área da carta
			if rect.has_point(local_pos):
				print("Carta clicada: " + title + " (ID: " + id + ")")
				get_viewport().set_input_as_handled()  # Evitar que o clique passe para baixo
				emit_signal("unit_clicked", self)

# Quando o mouse entra na carta
func _on_card_mouse_entered():
	if in_distribution_panel:
		emit_signal("mouse_entered")

# Quando o mouse sai da carta
func _on_card_mouse_exited():
	if in_distribution_panel:
		emit_signal("mouse_exited")

# Obtém o retângulo da carta para detecção de clique
func get_rect() -> Rect2:
	var size = Vector2(70, 105) * scale  # Ajustar pelo escala atual da carta
	return Rect2(-size/2, size)

func initialize(unit_data):
	id = unit_data.id
	attack = unit_data.attack
	defense = unit_data.defense
	
	# Pegar o título e descrição se existirem
	if "title" in unit_data:
		title = unit_data.title
	if "description" in unit_data:
		description = unit_data.description
	
	# Pegar o card_id e imagem se existirem
	if "card_id" in unit_data:
		card_id = unit_data.card_id
	if "image" in unit_data:
		# Usar o caminho da imagem específica desta carta
		image_path = "res://Image/Cards/Cards/" + unit_data.image
	else:
		# Se não tiver imagem específica, usar uma aleatória (comportamento antigo)
		var img_index = randi() % 24
		image_path = "res://Image/Cards/Cards/frame_" + str(img_index) + ".png"
	
	# Atualizar a visualização
	update_card()

# Define se a unidade está no painel de distribuição
func set_in_distribution_panel(in_panel: bool):
	in_distribution_panel = in_panel
	# Quando no painel de distribuição, queremos que o filtro de mouse seja STOP
	$Card.mouse_filter = Control.MOUSE_FILTER_STOP if in_panel else Control.MOUSE_FILTER_IGNORE
	
	# Ajustar escala automaticamente com base no painel
	if in_panel:
		# Não alteramos a escala diretamente aqui, isso será feito pelo distribution_panel
		pass
	else:
		# Se não estiver no painel de distribuição, usar a escala padrão para regiões
		scale = Vector2(0.4, 0.4)

# Define o jogador proprietário da unidade
func set_player(player_number):
	player = player_number
	update_card()

# Atualiza a visualização da carta
func update_card():
	if attack_label and defense_label and title_label and description_label and unit_texture:
		attack_label.text = str(attack)
		defense_label.text = str(defense)
		title_label.text = title
		description_label.text = description
		
		# Carregar a textura da unidade
		if ResourceLoader.exists(image_path):
			var texture = load(image_path)
			unit_texture.texture = texture
		
		# Definir cor da borda baseada no jogador
		var card_border = $Card/Border
		if card_border:
			if player == 1:
				card_border.modulate = Color(0.2, 0.5, 0.9) # Azul para jogador 1
			else:
				card_border.modulate = Color(0.9, 0.2, 0.2) # Vermelho para jogador 2

# Define o estado de seleção da carta
func set_selected(selected, order = -1):
	if selected:
		# Cor azulada para cartas selecionadas (em vez do cinza)
		$Card.modulate = Color(0.7, 0.8, 1.0, 1.0)  # Tom azulado suave
		
		# Se houver uma ordem, mostrar no centro com tamanho maior
		if order >= 0 and order_label:
			order_label.text = str(order + 1)
			order_label.visible = true
			
			# Ajustar a cor do texto de acordo com o número de ordem
			# Isso ajuda a diferenciar visualmente a sequência
			var order_colors = [
				Color(1, 0, 0),  # Primeira ordem - vermelho
				Color(0, 0.8, 0),  # Segunda ordem - verde
				Color(0, 0, 1),  # Terceira ordem - azul
				Color(1, 0.5, 0),  # Quarta ordem - laranja
				Color(0.8, 0, 0.8)  # Quinta ordem - roxo
			]
			
			# Selecionar a cor com base na ordem (com ciclo para mais de 5 ordens)
			var color_index = order % order_colors.size()
			order_label.add_theme_color_override("font_color", order_colors[color_index])
			
			# Aumentar o tamanho da fonte para números maiores
			order_label.add_theme_font_size_override("font_size", 48)
	else:
		$Card.modulate = Color(1, 1, 1) # Cor normal
		if order_label:
			order_label.visible = false 

# Conectar o sinal de clique apenas se a unidade estiver no painel de distribuição
func _on_card_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Verificar se o clique foi nesta unidade e se estamos no painel de distribuição
		if in_distribution_panel:
			# Obter a posição local do clique
			var local_pos = to_local(event.global_position)
			var size = Vector2(70, 105) * scale  # Ajustar pelo escala atual da carta
			var rect = Rect2(-size/2, size)
			
			# Verificar se o clique está dentro da área da carta
			if rect.has_point(local_pos):
				print("Carta clicada: " + title + " (ID: " + id + ")")
				get_viewport().set_input_as_handled()  # Evitar que o clique passe para baixo
				emit_signal("unit_clicked", self)
