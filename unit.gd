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

var selection_indicator = null

func _ready():
	# Tentar obter o nó SelectionIndicator com segurança
	if has_node("SelectionIndicator"):
		selection_indicator = $SelectionIndicator
		selection_indicator.visible = false
	
	# Definir a escala inicial da carta
	
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
		var base_path = "res://Image/Cards/" + unit_data.image
		if ResourceLoader.exists(base_path):
			image_path = base_path
		else:
			# Fallback para estrutura antiga ou aninhada
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
	# Estatísticas
	if attack_label:
		attack_label.text = str(attack)
		# Electric Crimson #FF0055
		attack_label.add_theme_color_override("font_color", Color("#FF0055"))
		
	if defense_label:
		defense_label.text = str(defense)
		# Cyan Frost #00F0FF
		defense_label.add_theme_color_override("font_color", Color("#00F0FF"))

	# Garantir que os rótulos estáticos "ATK" e "DEF" estejam visíveis
	var stat_labels = $Card/StatLabels
	if stat_labels:
		# Remover a modulação escura/transparente do editor
		stat_labels.modulate = Color(1, 1, 1, 1) 
		
		# Opcional: Colorir os rótulos para combinar com os números
		var atk_static = stat_labels.get_node_or_null("AtkLabel")
		if atk_static:
			atk_static.add_theme_color_override("font_color", Color("#FF0055")) # Red
			
		var def_static = stat_labels.get_node_or_null("DefLabel")
		if def_static:
			def_static.add_theme_color_override("font_color", Color("#00F0FF")) # Cyan

	if title_label:
		title_label.text = title
	if description_label:
		description_label.text = description
		
	# Carregar a textura da unidade
	if unit_texture and ResourceLoader.exists(image_path):
		var texture = load(image_path)
		unit_texture.texture = texture
	
	# Definir cor da borda baseada no jogador com cores Neon
	var card_border = $Card/Border
	if card_border:
		if player == 1:
			card_border.modulate = Color("#00F0FF") # Cyan Frost para Jogador 1 (Defesa/Azul)
		else:
			card_border.modulate = Color("#FF0055") # Electric Crimson para Jogador 2 (Ataque/Vermelho)

# Define o estado de seleção da carta
func set_selected(selected, order = -1):
	if selected:
		# Solar Gold #FFD700 para destaque de seleção
		$Card.modulate = Color(1.2, 1.2, 1.2) # Brilho extra
		$Card/Border.modulate = Color("#FFD700") 
		
		# Se houver uma ordem, mostrar no centro com tamanho maior
		if order >= 0 and order_label:
			order_label.text = str(order + 1)
			order_label.visible = true
			
			# Cores Neon para a ordem
			var order_colors = [
				Color("#FF0055"),  # Crimson
				Color("#00F0FF"),  # Cyan
				Color("#FFD700"),  # Gold
				Color("#9D00FF"),  # Neon Purple
				Color("#00FF00")   # Neon Green
			]
			
			# Selecionar a cor com base na ordem
			var color_index = order % order_colors.size()
			order_label.add_theme_color_override("font_color", order_colors[color_index])
			order_label.add_theme_constant_override("outline_size", 4) # Outline mais grosso
			
			# Aumentar o tamanho da fonte
			order_label.add_theme_font_size_override("font_size", 48)
	else:
		$Card.modulate = Color(1, 1, 1) # Cor normal
		if order_label:
			order_label.visible = false 
		update_card() # Restaura as cores originais da borda 

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
