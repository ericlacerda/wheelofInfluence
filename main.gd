extends Node2D

# Constantes
const NUM_REGIONS = 10
const INITIAL_UNITS_PER_REGION = 3
const CIRCLE_RADIUS = 110 # Reduzido para que as regiões não pareçam tão largas

# Variáveis do jogo
var regions = []
var player_one_score = 0
var player_two_score = 0
var current_player = 1
var selected_region = null
var selected_units = []
var is_distribution_panel_visible = false
var load_saved_game = false  # Flag para indicar se devemos carregar um jogo salvo

# Variáveis para posicionamento das regiões
var radius_x = CIRCLE_RADIUS * 2.3
var radius_y = CIRCLE_RADIUS * 1.0

# Variáveis para a animação de batalha
var battles_pending = []  # Lista para armazenar combates pendentes
var waiting_for_battle_animation = false  # Flag para evitar ações durante animações

# Nós da UI
@onready var player_one_score_label = $CanvasLayer/UI/ScoresPanel/PlayerOneScore
@onready var player_two_score_label = $CanvasLayer/UI/ScoresPanel/PlayerTwoScore
@onready var current_player_label = $CanvasLayer/UI/ScoresPanel/CurrentPlayerLabel
@onready var distribution_panel = $CanvasLayer/UI/DistributionPanel
@onready var regions_container = $RegionsContainer

# Referências de cenas
var region_scene = preload("res://region.tscn")
var unit_scene = preload("res://unit.tscn")
var battle_scene_res = preload("res://battle_scene.tscn")
var battle_scene_instance = null

#region Inicialização e ciclo de vida
func _ready():
	# Iniciar música do jogo (se já não estiver tocando)
	if AudioManager:
		AudioManager.play_game_music()
	
	# Verificar se é um jogo salvo
	var args = OS.get_cmdline_args()
	if args.size() > 0 and args[0] == "--load-saved-game":
		load_saved_game = true
	
	# Inicializa o jogo
	if load_saved_game:
		load_game()
	else:
		initialize_game()
	
	update_ui()
	distribution_panel.visible = false
	
	# Conectar sinais dos botões da UI
	connect_ui_buttons()
	
	print("Jogo inicializado!")

func connect_ui_buttons():
	# Conectar o botão da biblioteca de cartas
	if has_node("CanvasLayer/UI/CardsLibraryButton"):
		$CanvasLayer/UI/CardsLibraryButton.connect("pressed", Callable(self, "_on_cards_library_button_pressed"))
	else:
		print("Aviso: CardsLibraryButton não encontrado na cena")
	
	# Conectar o botão de menu
	if has_node("CanvasLayer/UI/MenuButton"):
		$CanvasLayer/UI/MenuButton.connect("pressed", Callable(self, "_on_menu_button_pressed"))
	else:
		print("Aviso: MenuButton não encontrado na cena")
	
	# Conectar o botão de salvar (opcional)
	if has_node("CanvasLayer/UI/SaveButton"):
		$CanvasLayer/UI/SaveButton.connect("pressed", Callable(self, "_on_save_button_pressed"))

func initialize_game():
	# Limpar regiões existentes se houver
	clear_regions()
	
	# Criar as regiões em uma elipse
	for i in range(NUM_REGIONS):
		create_region(i)

func clear_regions():
	for child in regions_container.get_children():
		child.queue_free()
	regions.clear()

func create_region(region_id):
	var angle = (region_id / float(NUM_REGIONS)) * 2 * PI
	var x = radius_x * cos(angle)
	var y = radius_y * sin(angle)

	var region = region_scene.instantiate()
	regions_container.add_child(region)
	region.position = Vector2(x, y)
	region.region_id = region_id
	
	# Conectar o sinal de clique
	var connection = region.connect("region_clicked", Callable(self, "_on_region_clicked"))
	print("Região ", region_id, " conectada ao sinal: ", (connection == 0))

	# Adicionar unidades iniciais
	for _j in range(INITIAL_UNITS_PER_REGION):
		var unit = generate_unit()
		region.add_unit(unit)

	# Definir vizinhos (anterior e próximo no círculo)
	region.neighbors = [
		(region_id - 1 + NUM_REGIONS) % NUM_REGIONS,
		(region_id + 1) % NUM_REGIONS
	]

	regions.append(region)

func update_ui():
	player_one_score_label.text = str(player_one_score)
	player_two_score_label.text = str(player_two_score)
	current_player_label.text = "Turno do Jogador " + str(current_player)

func _input(event):
	# Verificar se a tecla Esc foi pressionada
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		# Verificar se não estamos no meio de uma distribuição
		if not is_distribution_panel_visible:
			# Salvar o jogo automaticamente
			save_game()
			
			# Trocar para música do menu
			if AudioManager:
				AudioManager.play_menu_music()
			
			# Voltar ao menu principal
			get_tree().change_scene_to_file("res://menu.tscn")
#endregion

#region Geração de unidades
# Gera uma unidade com valores aleatórios baseados em cartas do JSON
func generate_unit():
	# Obter uma carta aleatória do CardManager
	var card = CardManager.get_random_card()

	# Se o CardManager não tiver cartas (ou não estiver inicializado), use o método antigo
	if card == null:
		return generate_unit_fallback()

	# Criar uma unidade baseada na carta selecionada
	var unit = CardManager.create_unit_from_card(card)
	return unit

# Método antigo de geração de unidades (como fallback)
func generate_unit_fallback():
	var unit = {}
	unit.id = str(randi() % 1000000)
	unit.attack = (randi() % 10) + 1  # Valor de ataque aleatório de 1-10
	unit.defense = (randi() % 10) + 1  # Valor de defesa aleatório de 1-10

	# Adicionar título e descrição
	var nome_unidades = [
		"Cavaleiro", "Arqueiro", "Mago", "Guerreiro", "Assassino",
		"Paladino", "Druida", "Bárbaro", "Ninja", "Xamã"
	]

	var descricoes = [
		"Ataca com força brutal.",
		"Dispara flechas à distância.",
		"Conjura magias poderosas.",
		"Forte em batalhas corpo a corpo.",
		"Especialista em ataques furtivos.",
		"Protege seus aliados com honra.",
		"Usa a força da natureza.",
		"Entra em fúria durante o combate.",
		"Move-se rapidamente no campo de batalha.",
		"Convoca espíritos para ajudá-lo."
	]

	# Escolher aleatoriamente um nome e descrição
	unit.title = nome_unidades[randi() % nome_unidades.size()]
	unit.description = descricoes[randi() % descricoes.size()]

	return unit
#endregion

#region Sistema de batalha
# Inicia o processo de verificação de batalhas
func check_and_update_score():
	battles_pending.clear()  # Limpar lista de combates pendentes

	# Encontrar todos os combates pendentes primeiro
	for region_index in range(regions.size()):
		var region = regions[region_index]
		var units = region.get_units()
		if units.size() == 2:
			var attacker = units[1]  # Unidade adicionada mais recentemente
			var defender = units[0]  # Unidade que já estava lá

			# Adicionar este combate à lista de pendentes
			battles_pending.append({
				"region_id": region_index,
				"attacker": attacker.duplicate(true),  # Fazer uma cópia completa para evitar problemas
				"defender": defender.duplicate(true)
			})

			print("Combate pendente adicionado: Região", region_index,
				  ", Atacante:", attacker.title, "(", attacker.attack, ")", 
				  ", Defensor:", defender.title, "(", defender.defense, ")")

	# Se houver combates pendentes, iniciar o primeiro
	if not battles_pending.is_empty():
		print("Iniciando sequência de combates. Total:", battles_pending.size())
		waiting_for_battle_animation = true
		call_deferred("start_next_battle")  # Usar call_deferred para evitar problemas de timing
	else:
		# Nenhum combate para processar
		print("Nenhum combate para processar")
		end_turn()

# Inicia o próximo combate da fila
func start_next_battle():
	if battles_pending.is_empty():
		# Todos os combates foram processados
		print("Todos os combates foram processados")
		waiting_for_battle_animation = false
		end_turn()
		return

	# Pegar o próximo combate
	var battle_data = battles_pending.pop_front()
	print("Iniciando combate na região", battle_data.region_id)

	# Criar a cena de batalha se ainda não existe
	if not battle_scene_instance:
		battle_scene_instance = battle_scene_res.instantiate()
		add_child(battle_scene_instance)
		battle_scene_instance.connect("battle_finished", Callable(self, "_on_battle_finished"))

	# Configurar e mostrar a batalha
	battle_scene_instance.setup_battle(
		battle_data.attacker,
		battle_data.defender,
		battle_data.region_id
	)

# Callback quando uma animação de batalha termina
func _on_battle_finished(attacker_wins):
	var last_battle = battle_scene_instance.region_id
	var region = regions[last_battle]
	var units = region.get_units()

	print("Combate finalizado na região", last_battle,
		  ", Resultado:", "Vitória do atacante" if attacker_wins else "Defesa bem-sucedida")

	if units.size() >= 2 and attacker_wins:
		# Atacante vence, remove o defensor
		region.remove_unit(units[0])  # Remover o defensor

		# Adiciona ponto ao jogador atual
		if current_player == 1:
			player_one_score += 1
		else:
			player_two_score += 1

		# Atualizar a UI
		update_ui()

	# Continuar com o próximo combate, se houver
	call_deferred("start_next_battle")  # Usar call_deferred para evitar problemas de timing

# Finaliza o turno atual
func end_turn():
	# Troca o jogador e atualiza a UI
	current_player = 2 if current_player == 1 else 1
	update_ui()

	# Auto-salvar o jogo
	save_game()
#endregion

#region Sistema de distribuição
# Evento quando uma região é clicada
func _on_region_clicked(region_id):
	print("Função _on_region_clicked chamada para região: ", region_id)

	# Prevenir processamento excessivo se já estiver mostrando painel
	if is_distribution_panel_visible:
		print("Painel de distribuição já está visível, ignorando clique.")
		return

	print("Selecionando região: ", region_id)
	selected_region = region_id
	selected_units = []

	# Atrasar ligeiramente a exibição do painel para evitar conflitos de renderização
	call_deferred("_deferred_show_distribution_panel")

# Versão diferida da função para mostrar o painel, evitando problemas de timing
func _deferred_show_distribution_panel():
	print("Preparando painel de distribuição")

	# Preparar painel antes de mostrar
	distribution_panel.clear_units()

	# Preencher o painel com as unidades da região selecionada
	var units = regions[selected_region].get_units()
	for unit in units:
		distribution_panel.add_unit_button(unit)

	# Gerenciar conexões de sinais
	manage_distribution_panel_signals(true)

	# Atualizar a flag e tornar visível em um único passo
	is_distribution_panel_visible = true
	distribution_panel.visible = true
	print("Painel de distribuição configurado e visível")

# Gerencia as conexões de sinais do painel de distribuição
func manage_distribution_panel_signals(connect_signals):
	var signals = [
		{"name": "unit_selected", "callable": Callable(self, "_on_unit_selected")},
		{"name": "distribute_units", "callable": Callable(self, "_on_distribute_units")},
		{"name": "cancel_distribution", "callable": Callable(self, "_on_cancel_distribution")}
	]
	
	for signal_info in signals:
		if distribution_panel.is_connected(signal_info.name, signal_info.callable):
			distribution_panel.disconnect(signal_info.name, signal_info.callable)
		
		if connect_signals:
			distribution_panel.connect(signal_info.name, signal_info.callable)

# Evento quando uma unidade é selecionada no painel
func _on_unit_selected(unit):
	print("Unidade selecionada no painel: ", unit.id)

	# Verifica se a unidade já está selecionada
	var already_selected = false
	var selected_index = -1

	for i in range(selected_units.size()):
		if selected_units[i].id == unit.id:
			already_selected = true
			selected_index = i
			break

	# Ação baseada no estado atual
	if already_selected:
		# Remove da seleção
		selected_units.remove_at(selected_index)
		print("Unidade removida da seleção. Total: ", selected_units.size())
	else:
		# Adiciona à lista
		selected_units.append(unit)
		print("Unidade adicionada à seleção. Total: ", selected_units.size())

	# Atualiza a visualização de seleção no painel
	distribution_panel.update_selection(selected_units)

# Evento quando o botão de distribuir unidades é pressionado
func _on_distribute_units():
	print("Botão Distribuir pressionado")

	var units_from_region = regions[selected_region].get_units()

	# Selecionar automaticamente unidades não selecionadas
	auto_select_remaining_units(units_from_region)

	print("Distribuindo ", selected_units.size(), " unidades da região ", selected_region)

	# Guardar cópias das unidades selecionadas para evitar problemas com referências
	var units_to_distribute = selected_units.duplicate()

	# Remove as unidades selecionadas da região de origem
	for unit in units_to_distribute:
		print("Removendo unidade ID: ", unit.id, " da região ", selected_region)
		regions[selected_region].remove_unit(unit)

	# Distribui as unidades no sentido anti-horário (na ordem selecionada)
	for i in range(units_to_distribute.size()):
		var target_region_id = (selected_region - (i + 1) + NUM_REGIONS) % NUM_REGIONS
		print("Movendo unidade ID: ", units_to_distribute[i].id, " para região: ", target_region_id)
		regions[target_region_id].add_unit(units_to_distribute[i])

	# Fechar o painel de distribuição
	close_distribution_panel()

	# Verifica batalhas e atualiza pontuação
	check_and_update_score()

# Seleciona automaticamente as unidades que faltam
func auto_select_remaining_units(units_from_region):
	# Verificar se todas as unidades foram selecionadas
	if selected_units.size() != units_from_region.size():
		# Se o jogador não selecionou todas as cartas, selecionar automaticamente as restantes
		print("Nem todas as unidades foram selecionadas. Selecionando automaticamente as restantes.")

		# Identificar quais unidades ainda não foram selecionadas
		for unit in units_from_region:
			var is_already_selected = false
			for selected in selected_units:
				if selected.id == unit.id:
					is_already_selected = true
					break

			# Adicionar à seleção se ainda não estiver selecionada
			if not is_already_selected:
				selected_units.append(unit)
				print("Unidade ID: ", unit.id, " adicionada automaticamente à seleção")

		# Atualizar a visualização para mostrar todas as cartas selecionadas
		distribution_panel.update_selection(selected_units)

# Fecha o painel de distribuição
func _on_cancel_distribution():
	print("Cancelando distribuição")
	close_distribution_panel()

func close_distribution_panel():
	print("Fechando painel de distribuição")

	# Limpar o painel antes de fechar
	distribution_panel.clear_units()

	# Desativar a visibilidade
	is_distribution_panel_visible = false
	distribution_panel.visible = false

	# Desconectar sinais com segurança
	manage_distribution_panel_signals(false)

	# Resetar variáveis de seleção
	selected_region = null
	selected_units.clear()  # Usar clear em vez de atribuir um novo array

	print("Painel de distribuição fechado e variáveis resetadas")
#endregion

#region Gerenciamento de dados e navegação
# Abre a biblioteca de cartas
func _on_cards_library_button_pressed():
	get_tree().change_scene_to_file("res://cards_viewer.tscn")

# Salva o estado atual do jogo
func save_game():
	print("Salvando jogo...")

	var save_data = {
		"player_one_score": player_one_score,
		"player_two_score": player_two_score,
		"current_player": current_player,
		"regions": []
	}

	# Salvar dados de cada região
	for region in regions:
		var region_data = {
			"region_id": region.region_id,
			"units": []
		}

		# Salvar dados de cada unidade na região
		for unit in region.get_units():
			var unit_data = {
				"id": unit.id,
				"attack": unit.attack,
				"defense": unit.defense,
				"title": unit.title,
				"description": unit.description
			}

			# Adicionar card_id e image_path se existirem
			if "card_id" in unit:
				unit_data["card_id"] = unit.card_id
			if "image" in unit:
				unit_data["image"] = unit.image

			region_data.units.append(unit_data)

		save_data.regions.append(region_data)

	# Salvar para arquivo
	var save_file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if save_file:
		save_file.store_line(JSON.stringify(save_data))
		save_file.close()
		print("Jogo salvo com sucesso!")
	else:
		print("Erro ao salvar o jogo!")

# Carrega um jogo salvo
func load_game():
	print("Carregando jogo salvo...")

	var load_file = FileAccess.open("user://savegame.json", FileAccess.READ)
	if not load_file:
		print("Nenhum jogo salvo encontrado! Iniciando novo jogo.")
		initialize_game()
		return

	# Limpar o jogo atual
	clear_regions()

	# Carregar os dados do jogo
	var json_string = load_file.get_line()
	load_file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Erro ao analisar dados salvos! Iniciando novo jogo.")
		initialize_game()
		return

	var save_data = json.data

	# Restaurar pontuações e jogador atual
	player_one_score = save_data.player_one_score
	player_two_score = save_data.player_two_score
	current_player = save_data.current_player

	# Restaurar regiões
	for region_data in save_data.regions:
		var region = region_scene.instantiate()
		regions_container.add_child(region)

		# Configurar região
		region.region_id = region_data.region_id

		# Posicionar a região no círculo
		var angle = (region.region_id / float(NUM_REGIONS)) * 2 * PI
		var x = radius_x * cos(angle)
		var y = radius_y * sin(angle)
		region.position = Vector2(x, y)

		# Adicionar unidades à região
		for unit_data in region_data.units:
			var unit = unit_scene.instantiate()
			region.add_child(unit)
			unit.initialize(unit_data)

		# Definir vizinhos (anterior e próximo no círculo)
		region.neighbors = [
			(region.region_id - 1 + NUM_REGIONS) % NUM_REGIONS,
			(region.region_id + 1) % NUM_REGIONS
		]

		# Conectar sinal de clique
		region.connect("region_clicked", Callable(self, "_on_region_clicked"))

		regions.append(region)

	print("Jogo carregado com sucesso!")

# Botão para salvar manualmente o jogo (opcional)
func _on_save_button_pressed():
	save_game()
	# Mostrar feedback de jogo salvo (opcional)
	print("Jogo salvo manualmente!")

# Volta ao menu principal
func _on_menu_button_pressed():
	# Salvar o jogo antes de sair
	save_game()

	# Trocar para a música do menu
	if AudioManager:
		AudioManager.play_menu_music()

	# Voltar ao menu principal
	get_tree().change_scene_to_file("res://menu.tscn")
#endregion
