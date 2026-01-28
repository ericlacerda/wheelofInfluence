extends Control

signal confirmed
signal cancelled

# Mensagem a ser exibida
var message = "Tem certeza?"

# Função para configurar a mensagem
func set_message(new_message):
	message = new_message
	if has_node("Panel/Message"):
		$Panel/Message.text = message

func _ready():
	# Definir a mensagem no label
	if has_node("Panel/Message"):
		$Panel/Message.text = message
	
	# Conectar os botões
	if has_node("Panel/ButtonContainer/ConfirmButton"):
		$Panel/ButtonContainer/ConfirmButton.connect("pressed", Callable(self, "_on_confirm_pressed"))
	
	if has_node("Panel/ButtonContainer/CancelButton"):
		$Panel/ButtonContainer/CancelButton.connect("pressed", Callable(self, "_on_cancel_pressed"))

# Quando o botão de confirmar é pressionado
func _on_confirm_pressed():
	emit_signal("confirmed")
	queue_free()

# Quando o botão de cancelar é pressionado
func _on_cancel_pressed():
	emit_signal("cancelled")
	queue_free()

# Mostrar a caixa de diálogo
static func show_dialog(parent, dialog_message):
	var dialog_scene = load("res://confirmation_dialog.tscn")
	var dialog = dialog_scene.instantiate()
	parent.add_child(dialog)
	dialog.set_message(dialog_message)
	return dialog 