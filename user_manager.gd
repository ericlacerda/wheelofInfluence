extends Node

# Variáveis para armazenar informações do usuário
var logged_in: bool = false
var username: String = ""
var connection_string: String = "Server=MYSQL5035.site4now.net;Database=db_a9b4e5_rigeter;Uid=a9b4e5_rigeter;Pwd=Ade5f#g88@hA9pR"

# Variáveis extraídas da connection string
var mysql_server: String = "MYSQL5035.site4now.net"  # Valor padrão
var mysql_database: String = "db_a9b4e5_rigeter"     # Valor padrão
var mysql_user: String = "a9b4e5_rigeter"            # Valor padrão
var mysql_password: String = ""                      # Por segurança, não definir senha padrão

# Sinal para quando o estado de login muda
signal login_state_changed(logged_in)

func _ready():
	# Parser automático da connection string para separar os componentes
	# Usar try-catch para evitar que erros durante o parsing façam o jogo falhar
	parse_connection_string()
	print("UserManager inicializado com a connection string MySQL")

# Função para analisar a connection string e extrair os componentes
func parse_connection_string():
	# Só processar se a string não estiver vazia
	if connection_string.is_empty():
		print("Connection string vazia, usando valores padrão")
		return
		
	var parts = connection_string.split(";")
	for part in parts:
		if part.is_empty():
			continue
			
		var key_value = part.split("=")
		if key_value.size() >= 2:
			var key = key_value[0].strip_edges()
			var value = key_value[1].strip_edges()
			
			if key == "Server":
				mysql_server = value
			elif key == "Database":
				mysql_database = value
			elif key == "Uid":
				mysql_user = value
			elif key == "Pwd":
				mysql_password = value
	
	print("Configuração do MySQL extraída com sucesso")

# Função para definir dados de conexão manualmente (caso necessário)
func set_connection_string(conn_string: String):
	# Evitar redefinir se a string estiver vazia
	if conn_string.is_empty():
		return
		
	connection_string = conn_string
	parse_connection_string()
	print("Connection string atualizada com sucesso")

# Função para fazer login
func login(user: String, password: String) -> bool:
	# Em uma implementação real, você faria uma requisição HTTP a um backend
	# que verifica as credenciais no banco MySQL
	
	# NOTA: Para conectar ao MySQL, você precisaria de:
	# 1. Um servidor backend (PHP, Node.js, etc.) que consulta o banco
	# 2. Uma API REST que seu jogo Godot pode chamar
	# 3. HTTPRequest no Godot para fazer chamadas à API
	
	# Por enquanto, simulamos um login bem-sucedido para demonstração
	if !user.is_empty() and !password.is_empty():
		logged_in = true
		username = user
		emit_signal("login_state_changed", true)
		print("Usuário ", username, " logado com sucesso (simulação)")
		return true
	else:
		return false

# Função para registrar um novo usuário
func register(user: String, email: String, password: String) -> bool:
	# Em uma implementação real, você enviaria os dados para o servidor backend
	# que insere o novo usuário no banco MySQL
	
	# Simulação de registro para demonstração
	if !user.is_empty() and !email.is_empty() and !password.is_empty():
		logged_in = true
		username = user
		emit_signal("login_state_changed", true)
		print("Usuário ", username, " registrado com sucesso (simulação)")
		return true
	else:
		return false

# Função para fazer logout
func logout():
	logged_in = false
	username = ""
	emit_signal("login_state_changed", false)
	print("Logout realizado com sucesso")

# Verifica se o usuário está logado
func is_logged_in() -> bool:
	return logged_in

# Obtém o nome de usuário atual
func get_username() -> String:
	return username

# Exemplo de como seria uma função real para comunicação com o backend MySQL
func _example_http_request(endpoint: String, data: Dictionary, callback: Callable):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", callback)
	
	var json = JSON.new()
	var body = json.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	# URL do seu backend que se conecta ao MySQL
	var url = "https://seu-backend-aqui.com/api/" + endpoint
	
	# Fazer a solicitação HTTP
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("Erro ao fazer solicitação HTTP") 