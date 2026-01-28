extends Node

# Classe para representar um movimento possível
class Move:
	var region_id: int
	var unit_order: Array # Array de unidades na ordem de distribuição
	var score: int = -1000

# Simula e encontra o melhor movimento para o jogador atual (IA)
func find_best_move(regions: Array, _scores: Dictionary, ai_player_id: int) -> Dictionary:
	var best_move = null
	var highest_score = -9999
	var num_regions = regions.size()
	
	print("[IA] Iniciando cálculo de melhor jogada...")
	
	# Para cada região
	for region_index in range(regions.size()):
		var region = regions[region_index]
		var units = region.get_units()
		
		# Regras de validação de movimento:
		# 1. Região deve ter unidades
		if units.size() == 0:
			continue
			
		# Gerar todas as permutações possíveis das unidades (para decidir a ordem de distribuição)
		var permutations = get_permutations(units)
		
		# Para cada permutação (ordem de distribuição)
		for perm in permutations:
			var current_score = evaluate_move(regions, num_regions, region_index, perm, ai_player_id)
			
			if current_score > highest_score:
				highest_score = current_score
				best_move = {
					"region_id": region_index,
					"unit_order": perm,
					"score": current_score
				}
	
	if best_move:
		print("[IA] Melhor jogada encontrada: Região ", best_move.region_id, " Score: ", best_move.score)
	else:
		print("[IA] Nenhuma jogada possível encontrada!")
		
	return best_move

# Avalia o "score" de um movimento simulado
func evaluate_move(regions: Array, num_regions: int, start_region_index: int, unit_order: Array, ai_player_id: int) -> int:
	var score = 0
	
	# Simular Distribuição
	for i in range(unit_order.size()):
		var unit = unit_order[i]
		# O destino é calculado em sentido anti-horário
		var target_region_id = (start_region_index - (i + 1) + num_regions) % num_regions
		var target_region = regions[target_region_id]
		var target_units = target_region.get_units()
		
		# Verificar o que acontece na região de destino
		
		# Caso 1: Região Vazia
		if target_units.size() == 0:
			# Dominar região vazia é bom, mas não crítico
			score += 10
			
		# Caso 2: Região já ocupada (Combate Iminente)
		elif target_units.size() == 1:
			var defender = target_units[0]
			var attacker = unit
			
			# Simular Combate
			if attacker.attack > defender.defense:
				# Vitória do Atacante (IA)
				score += 50 # Pontuação alta por vitória
				
				# Bônus se a região pertencia ao inimigo (embora as unidades não tenham dono fixo na região,
				# podemos inferir pelo "dono" original da carta ou apenas pelo fato de ganhar a batalha)
				score += 20
				
				# Bônus extra se o defensor era uma unidade forte
				score += defender.attack * 2
				
			else:
				# Derrota do Atacante
				score -= 30 # Penalidade por perder unidade
				
				# Se a unidade perdida era forte, penalidade maior
				score -= attacker.attack * 2
		
		# Caso 3: Região com mais de 1 unidade (atualmente o jogo não deve permitir isso antes da batalha, 
		# mas se permitir, é suporte)
		else:
			score += 5
	
	# Fator de aleatoriedade pequena para não ser 100% previsível em empates
	score += randi() % 5
	
	return score

# Função auxiliar para gerar permutações
func get_permutations(array: Array) -> Array:
	var result = []
	if array.size() == 0:
		return result
		
	# Caso base: apenas 1 elemento
	if array.size() == 1:
		result.append(array.duplicate())
		return result
		
	# Recursão
	for i in range(array.size()):
		var first = array[i]
		var remainder = array.slice(0, i) + array.slice(i + 1)
		var sub_permutations = get_permutations(remainder)
		
		for p in sub_permutations:
			p.push_front(first)
			result.append(p)
			
	return result
