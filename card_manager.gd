extends Node

# Lista de cartas carregadas do JSON
var cards_data = []
var cards_by_id = {}

func _ready():
	load_cards_data()

# Carrega os dados das cartas do arquivo JSON
func load_cards_data():
	var file = FileAccess.open("res://cards_data.json", FileAccess.READ)
	if not file:
		printerr("Erro ao abrir o arquivo de dados das cartas!")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		printerr("Erro ao analisar o JSON: ", json.get_error_message(), " na linha ", json.get_error_line())
		return
	
	var data = json.get_data()
	if not data.has("cards"):
		printerr("Arquivo JSON de cartas não tem o campo 'cards'!")
		return
	
	cards_data = data.cards
	
	# Cria um dicionário para acesso rápido pelo ID
	for card in cards_data:
		cards_by_id[card.id] = card
	
	print("Dados de ", cards_data.size(), " cartas carregados com sucesso!")

# Retorna uma carta aleatória
func get_random_card():
	if cards_data.is_empty():
		return null
	
	var index = randi() % cards_data.size()
	return cards_data[index]

# Retorna uma carta específica pelo ID
func get_card_by_id(id):
	if cards_by_id.has(id):
		return cards_by_id[id]
	return null

# Retorna todas as cartas
func get_all_cards():
	return cards_data

# Cria uma unidade baseada em uma carta específica
func create_unit_from_card(card):
	var unit = {}
	unit.id = str(randi() % 1000000)  # ID único para a instância da unidade
	unit.card_id = card.id            # ID da carta para referência
	unit.title = card.title
	unit.attack = card.attack
	unit.defense = card.defense
	unit.description = card.description
	unit.image = card.image
	return unit 
