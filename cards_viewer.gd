extends Control

# Referência à cena da unidade
var unit_scene = preload("res://unit.tscn")
var cards_data = []
var card_scale = 0.6 # Escala reduzida para resolução menor

func _ready():
	# Conectar o botão de voltar
	$BackButton.connect("pressed", Callable(self, "_on_back_button_pressed"))
	
	# Carregar os dados das cartas
	_load_cards()
	
	# Exibir as cartas
	_display_cards()

# Carrega e exibe todas as cartas
func _load_cards():
	# Obter todas as cartas do CardManager
	cards_data = CardManager.get_all_cards()
	if cards_data.is_empty():
		$Title.text = "Biblioteca de Cartas (Vazia)"

func _display_cards():
	var grid = $CardsContainer/GridContainer
	
	# Limpar qualquer conteúdo existente
	for child in grid.get_children():
		child.queue_free()
	
	# Adicionar as cartas à grade
	for card_data in cards_data:
		var card_instance = unit_scene.instantiate()
		grid.add_child(card_instance)
		
		# Configurar a carta com os dados
		card_instance.initialize(card_data)
		
		# Escalar a carta para o tamanho adequado
		card_instance.scale = Vector2(card_scale, card_scale)
		
		# Centralizar a carta dentro da célula
		card_instance.position = Vector2(0, 0)

# Quando o botão de voltar é pressionado
func _on_back_button_pressed():
	# Voltar ao menu principal
	if AudioManager:
		AudioManager.play_menu_music()
	get_tree().change_scene_to_file("res://menu.tscn") 
