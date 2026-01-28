extends Node

# Script de diagnóstico para o sistema de menu
# É carregado como um autoload para fornecer informações sobre o estado do menu

var is_debug_mode = true
var menu_transitions = []

func _ready():
	print("MenuDiagnostic: Sistema de diagnóstico inicializado")

# Registra transições de menu para depuração
func register_transition(from_screen, to_screen):
	if is_debug_mode:
		var transition = {
			"from": from_screen,
			"to": to_screen,
			"timestamp": Time.get_unix_time_from_system()
		}
		menu_transitions.append(transition)
		print("MenuDiagnostic: Transição de " + from_screen + " para " + to_screen)

# Verifica se há ciclos problemáticos nas transições de menu
func check_for_transition_cycles():
	if menu_transitions.size() < 3:
		return false
		
	var last_three = menu_transitions.slice(menu_transitions.size() - 3, menu_transitions.size())
	if last_three[0].from == last_three[2].to and last_three[0].to == last_three[2].from:
		print("MenuDiagnostic: ALERTA - Ciclo de transição detectado!")
		return true
	
	return false

# Limpa o histórico de transições
func clear_history():
	menu_transitions.clear()
	print("MenuDiagnostic: Histórico de transições limpo")

# Exibe informações de diagnóstico
func print_diagnostics():
	print("MenuDiagnostic: Relatório de Diagnóstico")
	print("Total de transições: " + str(menu_transitions.size()))
	
	if menu_transitions.size() > 0:
		print("Última transição: " + menu_transitions[-1].from + " -> " + menu_transitions[-1].to) 