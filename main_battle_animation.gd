extends Node

# Esse script contém as funções necessárias para implementar 
# a animação de batalha estilo Yu-Gi-Oh no jogo.
# Copie as funções relevantes para o main.gd

# Adicione estas variáveis ao main.gd:
# var battles_pending = []  # Lista para armazenar combates pendentes
# var waiting_for_battle_animation = false  # Flag para evitar ações durante animações
# var battle_scene_res = preload("res://battle_scene.tscn")
# var battle_scene_instance = null

# Verifica e atualiza a pontuação após batalhas (Substitui a versão atual em main.gd)
func check_and_update_score():
	battles_pending.clear()  # Limpar lista de combates pendentes
	
	for region_index in range(regions.size()):
		var region = regions[region_index]
		var units = region.get_units()
		if units.size() == 2:
			var attacker = units[1]  # Unidade adicionada mais recentemente
			var defender = units[0]  # Unidade que já estava lá
			
			# Adicionar este combate à lista de pendentes
			battles_pending.append({
				"region_id": region_index,
				"attacker": attacker,
				"defender": defender
			})
	
	# Se houver combates pendentes, iniciar o primeiro
	if not battles_pending.is_empty():
		waiting_for_battle_animation = true
		start_next_battle()
	else:
		# Nenhum combate para processar
		print("Nenhum combate para processar")
		end_turn()

# Inicia o próximo combate da fila
func start_next_battle():
	if battles_pending.is_empty():
		# Todos os combates foram processados
		waiting_for_battle_animation = false
		end_turn()
		return
	
	# Pegar o próximo combate
	var battle_data = battles_pending.pop_front()
	
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
	
	if attacker_wins:
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
	start_next_battle()

# Finaliza o turno atual
func end_turn():
	# Troca o jogador e atualiza a UI
	current_player = 2 if current_player == 1 else 1
	update_ui()
	
	# Auto-salvar o jogo
	save_game()

# Modifique a função _on_distribute_units() para usar a nova lógica:
func _on_distribute_units_modificada():
	# Código existente...
	
	# Fechar o painel de distribuição
	close_distribution_panel()
	
	# Verifica batalhas e atualiza pontuação
	check_and_update_score()
	
	# NÃO INCLUA ESTAS LINHAS:
	# current_player = 2 if current_player == 1 else 1
	# update_ui()
	# save_game()
	# Isso já é feito pela função end_turn() 