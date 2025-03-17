extends Node2D

var started = false

@onready var player = $Player/Player

var height_lvl = 1000

var sonic_alarm = preload("res://Scenes/sonic_alarm.tscn")

var upgrade_part = preload("res://Scenes/upgrade_part.tscn")

var meteorite_belt = preload("res://Scenes/meteorite_belt.tscn")
var comet_spawner = preload("res://Scenes/asteroids_spawner.tscn")
var satellites_preload = preload("res://Scenes/satallites.tscn")
var lasers = preload("res://Scenes/LasersSpawner.tscn")

var planets_and_comets_preload = preload("res://Scenes/planets_and_comets.tscn")
var planets_and_asteroids_preload = preload("res://Scenes/planets_and_asteroids.tscn")

var filepath = "user://wallet1.json"
var keypair: Keypair

@onready var client = $SolanaClient;
@onready var idl = $AnchorProgram;
@onready var share: Share = $Share as Share
@onready var machine = $MplCandyMachine
@export var guard_settings:CandyGuardAccessList
@onready var http_request = $HTTPRequest


var internet_status = false

func has_internet_connection() -> bool:
	http_request.cancel_request()
	var error = http_request.request("https://www.fast.com")
	if error != OK:
		return false
	
	await http_request.request_completed
	
	return 1


func has_access_to_rpc() -> bool:
	http_request.cancel_request()
	
	var request_body = {
		"jsonrpc": "2.0",
		"id": 1,
		"method": "getBalance",
		"params": ["orbwa31L7BZ2bTTg9QgUPTxAB7KnFfeU8oT9b56XG7f"]
	}
	
	var json_string = JSON.stringify(request_body)
	
	var error = http_request.request(
		$SolanaClient.url_override,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		json_string
	)
	
	if error != OK:
		return false
		
	await http_request.request_completed
	
	return 1

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	internet_status = response_code == 200
	

func _ready() -> void:
	if FileAccess.file_exists(filepath):
		keypair = Keypair.new_from_file(filepath)
	else:
		keypair = Keypair.new_random()
		keypair.save_to_file(filepath)
		
	#var json_as_text = FileAccess.get_file_as_string(filepath)
	#var json_as_dict = JSON.parse_string(json_as_text)
	#print(SolanaUtils.bs58_encode(PackedByteArray(json_as_dict)))
	
	var pk_string: String = keypair.get_public_string()
	var trimmed_pk = pk_string.substr(0, 8)
	$MainMenu/Wallet.text = "                     Your wallet: " + trimmed_pk + "... 🔗"
	
	await has_internet_connection()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No internet connection!\nCheck your provider and restart game!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		return
	
	await has_access_to_rpc()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No RPC connection!\nSonic Devnet is not responsing...\nCheck news, try again later!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		return
	
	client.get_balance(pk_string)
	var response21 = await client.http_response_received
	
	
	if response21.has("result"):
		if response21.result.value < 100000000:
			var game_authority_pda = Pubkey.new_pda_bytes(
				[
					"game_authority".to_utf8_buffer(),
				],
				Pubkey.new_from_string($AnchorProgram.get_pid())
			);
			
			var payer = Keypair.new_from_bytes(PackedByteArray([168,60,171,117,252,244,33,221,80,38,159,101,192,126,195,14,146,175,62,31,59,214,230,54,122,172,251,9,28,104,133,179,12,0,201,143,160,54,136,1,228,48,10,248,79,188,133,16,212,252,244,115,28,25,22,15,38,30,7,44,55,114,0,252]))
			print(payer.get_public_string())
			print(game_authority_pda.to_string())
		
			
			var tx := Transaction.new()
			add_child(tx)
			
			var ix = idl.build_instruction("askForAirdrop", [Pubkey.new_from_string(keypair.get_public_string()), game_authority_pda, SystemProgram.get_pid()], { })
			tx.add_instruction(ix)
			tx.set_payer(payer)
			tx.set_signers([payer, keypair])
			tx.update_latest_blockhash()
			tx.sign_and_send()
			print('sent')
			var response = await tx.transaction_response_received
			print("Im here", response)
			if response.has("result"):
				var alarm = sonic_alarm.instantiate()
				alarm.text = "Succesfully airdropped SOL"
				add_child(alarm)
			else:
				pass
	
	var extra_seed_bytes = Pubkey.new_pda_bytes(
		[
			$SolanaClient.get_meta("extra_seeds").to_utf8_buffer(),
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	);
	
	var leaderboard_pda = Pubkey.new_pda_bytes(
		[
			"leaderboard".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	);
	
	var res = $AnchorProgram.fetch_account("Leaderboard", leaderboard_pda.to_string())
	var account_data = await $AnchorProgram.account_fetched
	
	print(account_data)
	
	var flag_registered = false
	
	if account_data.has("players"):
		var alarm = sonic_alarm.instantiate()
		alarm.text = "Player data fetched succesfully!"
		add_child(alarm)
		
		for player_table in account_data.players:
			if pk_string == player_table.pubkey.to_string():
				flag_registered = true
				
				if player_table.hasActiveTry:
					$MainMenu/StartGame/Start.disabled = false
					$MainMenu/StartGame/BuyTry.disabled = true
					
					$MainMenu/StartGame/BuyTry.text = "You have paid try"
				else:
					$MainMenu/StartGame/Start.disabled = true
					$MainMenu/StartGame/BuyTry.disabled = false
					
					$MainMenu/StartGame/BuyTry.text = "Buy new try"
					
				break
	else:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "Some error uccurred, restart game please!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
	
	if flag_registered:
		$MainMenu/StartGame.visible = true
	else:
		$MainMenu/NotRegistered.visible = true


func sort_players_descending(arr: Array) -> void:
	var n = arr.size()
	for i in range(n):
		var max_idx = i
		for j in range(i + 1, n):
			if arr[j]["lastScore"] > arr[max_idx]["lastScore"]:
				max_idx = j
		if max_idx != i:
			var temp = arr[i]
			arr[i] = arr[max_idx]
			arr[max_idx] = temp


func tween_clear_color(from_color: Color, to_color: Color, duration: float) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	var current_color = from_color
	
	tween.tween_method(
		func(t: float):
			current_color = from_color.lerp(to_color, t)
			RenderingServer.set_default_clear_color(current_color),
		0.0,
		1.0,
		duration
	)


func _on_button_pressed() -> void:
	tween_clear_color(Color.WHITE, Color.BLACK, 2)
	
	$MainMenu/StartGame.visible = false
	$MainMenu/NotRegistered.visible = false
	$MainMenu.visible = false
	
	$Player/Player._ready()
	$BoosterSpawner._ready()
	$Player.visible = true
	$Player/Player/Stars.visible = true
	$Player/Player/UI.visible = true
	
	$Game.play()
	$Menu.stop()
	
	started = true


func _on_spawner_timeout() -> void:
	pass


var last_gen: int = -1


func _process(delta: float) -> void:
	if not started:
		if Input.is_action_just_pressed("left_mouse"):
			$Pressing.play()
		
	_on_obstacle_spawner_timeout()

func _on_obstacle_spawner_timeout() -> void:
	if abs(player.global_position.y) > height_lvl:
		var obstacle_types = [0, 1, 2, 3, 4, 5]
		
		if last_gen in obstacle_types:
			obstacle_types.erase(last_gen)
		
		var gen = obstacle_types[randi() % obstacle_types.size()]
		last_gen = gen
		
		if gen == 0:
			height_lvl = abs(player.global_position.y) + 250
		elif gen == 1:
			var meteorite = meteorite_belt.instantiate()
			meteorite.global_position.y = -height_lvl - 750 
			meteorite.global_position.x = player.global_position.x
			$Meteorites.add_child(meteorite)
			
			height_lvl = abs(player.global_position.y) + 500 + 3500 + 750
			
			$Player/Player/UI/Label.text = "$sonic-orbit: fly only up, collect rings and stars!\n$sonic-orbit: area: meteorite belt"
			
		elif gen == 2:
			var planets_and_comets = planets_and_comets_preload.instantiate()
			planets_and_comets.global_position.y = -height_lvl - 750 
			planets_and_comets.global_position.x = player.global_position.x
			planets_and_comets.player = player
			$Comets.add_child(planets_and_comets)
			
			$Player/Player/UI/Label.text = "$sonic-orbit: fly only up, collect rings and stars!\n$sonic-orbit: area: planets and comets"
			
			height_lvl = abs(player.global_position.y) + 500 + 7500 + 750
		elif gen == 3:
			var satellites = satellites_preload.instantiate()
			satellites.global_position.y = -height_lvl - 1250
			satellites.global_position.x = player.global_position.x
			satellites.player = player
			$Satallites.add_child(satellites)
			
			$Player/Player/UI/Label.text = "$sonic-orbit: fly only up, collect rings and stars!\n$sonic-orbit: area: planets with satellites"
			
			height_lvl = abs(player.global_position.y) + 1250 + 7000 + 500
		elif gen == 4:
			var planets_and_asteroids = planets_and_asteroids_preload.instantiate()
			planets_and_asteroids.global_position.y = -height_lvl - 750 
			planets_and_asteroids.global_position.x = player.global_position.x
			planets_and_asteroids.player = player
			$Comets.add_child(planets_and_asteroids)
			
			$Player/Player/UI/Label.text = "$sonic-orbit: fly only up, collect rings and stars!\n$sonic-orbit: area: planets and asteroids"
			
			height_lvl = abs(player.global_position.y) + 500 + 7500 + 750
			
		elif gen == 5:
			var lasers = lasers.instantiate()
			lasers.global_position.y = -height_lvl - 750 
			lasers.global_position.x = player.global_position.x
			lasers.player = player
			$Comets.add_child(lasers)
			
			$Player/Player/UI/Label.text = "$sonic-orbit: fly only up, collect rings and stars!\n$sonic-orbit: area: light pillars"
			
			height_lvl = abs(player.global_position.y) + 500 + 7500 + 750

func _on_wallet_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var pk_string: String = keypair.get_public_string()
			DisplayServer.clipboard_set(keypair.get_public_string())
			
			await has_internet_connection()
			if not internet_status:
				var alarm = sonic_alarm.instantiate()
				alarm.text = "No internet connection!\nCheck your provider and restart game!"
				alarm.get_node("Control/Timer").wait_time = 50
				add_child(alarm)
				
				return
			
			await has_access_to_rpc()
			if not internet_status:
				var alarm = sonic_alarm.instantiate()
				alarm.text = "No RPC connection!\nSonic Devnet is not responsing...\nCheck news, try again later!"
				alarm.get_node("Control/Timer").wait_time = 50
				add_child(alarm)
				
				return
			
			client.get_balance(pk_string)
			var response = await client.http_response_received
			
			if response.has("result"):
				var alarm = sonic_alarm.instantiate()
				alarm.text = "Address copied! SOL balance fetched succesfully!\nYour SOL balance: " + str(response.result.value / 1_000_000_000)
				add_child(alarm)



func _on_reg_pressed() -> void:
	$MainMenu/NotRegistered/Reg.disabled = true
	
	var player_pk = keypair.to_pubkey()
	var extra_seed_bytes = Pubkey.new_pda_bytes(
		[
			$SolanaClient.get_meta("extra_seeds").to_utf8_buffer(),
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	);
	
	var gameOwner = Pubkey.new_from_string($SolanaClient.get_meta("game_owner"))
	var leaderboard_pda = Pubkey.new_pda_bytes(
		[
			"leaderboard".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	)
	
	var systemProgram = SystemProgram.get_pid()
	var rent = Pubkey.new_from_string("SysvarRent111111111111111111111111111111111")
	
	var ix = idl.build_instruction("newPlayer", [player_pk, gameOwner, leaderboard_pda, extra_seed_bytes, systemProgram], {})
	
	var tx = Transaction.new()
	add_child(tx)
	
	tx.add_instruction(ix)
	tx.set_payer(keypair)
	tx.update_latest_blockhash()
	
	await has_internet_connection()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No internet connection!\nCheck your provider and restart game!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		return
	
	await has_access_to_rpc()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No RPC connection!\nSonic Devnet is not responsing...\nCheck news, try again later!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		return
		
	client.get_balance(player_pk.to_string())
	var response = await client.http_response_received
	
	if response.has("result"):
		if (response.result.value / 10_000_000) < 0.01:
			var alarm = sonic_alarm.instantiate()
			alarm.text = "You need to have\natleast 0.0101 SOL in your address!"
			add_child(alarm)
			
			$MainMenu/NotRegistered/Reg.disabled = false
			return
	
	tx.sign_and_send()

	response = await tx.transaction_response_received
	
	if response.has("result"):
		var alarm = sonic_alarm.instantiate()
		alarm.text = "User registered successfully!"
		add_child(alarm)
		
		await get_tree().create_timer(1.0).timeout
		
		$MainMenu/NotRegistered.visible = false
		_ready()
	
	else:
		$MainMenu/NotRegistered.visible = false
		$MainMenu/Error.visible = true
		$MainMenu/Error/Info.text = "Some error occurred:\n\nRestart game and try again!"
		
		if response.has("error"):
			$MainMenu/Error/Info.text = "Some error occurred:\n\n" + response.error.message + "\n\nRestart game and try again!"
			


func _on_buy_try_pressed() -> void:
	$MainMenu/StartGame/BuyTry.disabled = true
	$MainMenu/StartGame/BuyTry.text = "Processing..."
	
	var player_pk = keypair.to_pubkey()
	var extra_seed_bytes = Pubkey.new_pda_bytes(
		[
			$SolanaClient.get_meta("extra_seeds").to_utf8_buffer(),
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	);
	
	var gameOwner = Pubkey.new_from_string($SolanaClient.get_meta("game_owner"))
	var leaderboard_pda = Pubkey.new_pda_bytes(
		[
			"leaderboard".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	)
	
	var systemProgram = SystemProgram.get_pid()
	var rent = Pubkey.new_from_string("SysvarRent111111111111111111111111111111111")
	
	var ix = idl.build_instruction("purchaseGameAttempt", [player_pk, gameOwner, leaderboard_pda, extra_seed_bytes, systemProgram], {})
	
	var tx = Transaction.new()
	add_child(tx)
	tx.set_payer(keypair)
	tx.add_instruction(ix)
	
	tx.update_latest_blockhash()
	
	await has_internet_connection()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No internet connection!\nCheck your provider and restart game!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		return
	
	await has_access_to_rpc()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No RPC connection!\nSonic Devnet is not responsing...\nCheck news, try again later!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		return
		
	client.get_balance(player_pk.to_string())
	var response = await client.http_response_received
	
	if response.has("result"):
		if (response.result.value / 5_000_000) < 0.0051:
			var alarm = sonic_alarm.instantiate()
			alarm.text = "You need to have\natleast 0.0051 SOL in your address!"
			add_child(alarm)
			
			$MainMenu/StartGame/BuyTry.disabled = false
			$MainMenu/StartGame/BuyTry.text = "Buy new try"
			return
	
	tx.sign_and_send()

	response = await tx.transaction_response_received
	
	if response.has("result"):
		var alarm = sonic_alarm.instantiate()
		alarm.text = "New try bought successfully! -0.005 SOL"
		add_child(alarm)
		
		$MainMenu/StartGame/Start.disabled = false
		$MainMenu/StartGame/BuyTry.disabled = true
		$MainMenu/StartGame/BuyTry.text = "You have paid try"
	
	else:
		$MainMenu/StartGame.visible = false
		$MainMenu/NotRegistered.visible = false
		$MainMenu/Error.visible = true
		$MainMenu/Error/Info.text = "Some error occurred:\n\nRestart game and try again!"
		
		if response.has("error"):
			$MainMenu/Error/Info.text = "Some error occurred:\n\n" + response.error.message + "\n\nRestart game and try again!"


func _on_info_pressed() -> void:
	$MainMenu/Info.visible = true
	$MainMenu/StartGame.visible = false


func _on_close_info_pressed() -> void:
	$MainMenu/Info.visible = false
	$MainMenu/StartGame.visible = true


func _on_close_table_pressed() -> void:
	$MainMenu/Table.visible = false
	$MainMenu/StartGame.visible = true


func _on_table_pressed() -> void:
	$MainMenu/Loading.visible = true
	
	for i in range(11):
		$MainMenu/Table/Screen.get_node("id" + str(i + 1)).text = str(i + 1)
		$MainMenu/Table/Screen.get_node("score" + str(i + 1)).text = "####"
		$MainMenu/Table/Screen.get_node("address" + str(i + 1)).text = "None..."
		
		$MainMenu/Table/S/Screen.get_node("id" + str(i + 1)).text = str(i + 1)
		$MainMenu/Table/S/Screen.get_node("score" + str(i + 1)).text = "####"
		$MainMenu/Table/S/Screen.get_node("address" + str(i + 1)).text = "None..."
	
	$MainMenu/Table/Screen.get_node("id11").text = "id?"
	$MainMenu/Table/S/Screen.get_node("id11").text = "id?"
	
	await has_internet_connection()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No internet connection!\nCheck your provider and restart game!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		$MainMenu/Loading.visible = false
		return
	
	await has_access_to_rpc()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No RPC connection!\nSonic Devnet is not responsing...\nCheck news, try again later!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		$MainMenu/Loading.visible = false
		return
		
	var extra_seed_bytes = Pubkey.new_pda_bytes(
		[
			$SolanaClient.get_meta("extra_seeds").to_utf8_buffer(),
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	);
	
	var gameOwner = Pubkey.new_from_string($SolanaClient.get_meta("game_owner"))
	var leaderboard_pda = Pubkey.new_pda_bytes(
		[
			"leaderboard".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	)
	
	idl.fetch_account("Leaderboard", leaderboard_pda.to_string())
	var account_data = await $AnchorProgram.account_fetched
	
	if account_data.has("players"):
		var alarm = sonic_alarm.instantiate()
		alarm.text = "Leaderboard fetched succesfully!"
		add_child(alarm)
		
		sort_players_descending(account_data.players)
		
		var in_top_10 = false
		
		var i = 1
		for player_table in account_data.players:
			if i <= 10:
				if keypair.get_public_string() == player_table.pubkey.to_string():
					$MainMenu/Table/Screen.get_node("tag" + str(i)).visible = true
					$MainMenu/Table/S/Screen.get_node("tag" + str(i)).visible = true
					in_top_10 = true
				
				var trimmed_pk = player_table.pubkey.to_string().substr(0, 6)
				
				$MainMenu/Table/Screen.get_node("address" + str(i)).text = trimmed_pk + "..."
				$MainMenu/Table/Screen.get_node("score" + str(i)).text = str(player_table.lastScore)
				
				$MainMenu/Table/S/Screen.get_node("address" + str(i)).text = trimmed_pk + "..."
				$MainMenu/Table/S/Screen.get_node("score" + str(i)).text = str(player_table.lastScore)
			
			if i > 10:
				if not in_top_10:
					if keypair.get_public_string() == player_table.pubkey.to_string():
						var trimmed_pk = player_table.pubkey.to_string().substr(0, 6)
						
						$MainMenu/Table/Screen.get_node("id11").text = str(i)
						$MainMenu/Table/Screen.get_node("address11").text = trimmed_pk + "..."
						$MainMenu/Table/Screen.get_node("score11").text = str(player_table.lastScore)
						$MainMenu/Table/Screen.get_node("tag11").visible = true
						
						$MainMenu/Table/S/Screen.get_node("id11").text = str(i)
						$MainMenu/Table/S/Screen.get_node("address11").text = trimmed_pk + "..."
						$MainMenu/Table/S/Screen.get_node("score11").text = str(player_table.lastScore)
						$MainMenu/Table/S/Screen.get_node("tag11").visible = true
						
						break
						
			i += 1
	
	$MainMenu/Table.visible = true
	$MainMenu/StartGame.visible = false
	
	$MainMenu/Loading.visible = false

func _on_share_result_pressed() -> void:
	share.share_viewport($MainMenu/Table/S.get_viewport(), "My results in Orbit!", "Can you beat my score?", "My result in Orbit!\nCan you beat my score?\n\nIt's my ref link: not-implemented-yet\n\n#Sonic #SonicOrbit")


func _on_close_inventory_pressed() -> void:
	$MainMenu/Inventory.visible = false
	$MainMenu/StartGame.visible = true


func _on_inventory_pressed() -> void:
	$MainMenu/StartGame.visible = false
	$MainMenu/Loading.visible = true
	
	await has_internet_connection()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No internet connection!\nCheck your provider and restart game!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		return
	
	await has_access_to_rpc()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No RPC connection!\nSonic Devnet is not responsing...\nCheck news, try again later!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		return
	
	client.get_token_accounts_by_owner(keypair.to_pubkey().to_string(), "", "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
	var response_dict: Dictionary = await client.http_response_received
	
	var count = 0
	var balance = 0
	
	var extra_seed_bytes = Pubkey.new_pda_bytes(
			[
				$SolanaClient.get_meta("extra_seeds").to_utf8_buffer(),
			],
			Pubkey.new_from_string($AnchorProgram.get_pid())
		);
	var collection_mint = Pubkey.new_pda_bytes(
		[
			"collection_mint".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	)
	
	if response_dict.has('result'):
		var alarm = sonic_alarm.instantiate()
		alarm.text = "Inventory successfully loaded! Building..."
		add_child(alarm)
	
		var wallet_tokens: Array[Dictionary]
		for token in response_dict["result"]["value"]:
			var token_byte_data = SolanaUtils.bs64_decode(token["account"]["data"][0])
			var token_data:Dictionary = parse_token_data(token_byte_data)
			
			if token_data["amount"] == 0:
				continue
			
			wallet_tokens.append(token_data)
		
		var textures = [
			preload("res://Assets/rockets/0.png"),
			preload("res://Assets/rockets/1.png"),
			preload("res://Assets/rockets/2.png"),
			preload("res://Assets/rockets/3.png"),
			preload("res://Assets/rockets/4.png"),
			preload("res://Assets/rockets/5.png"),
			preload("res://Assets/rockets/6.png"),
			preload("res://Assets/rockets/7.png"),
			preload("res://Assets/rockets/8.png")
		]
		
		var flag_selected = false
		var selected_type = $PlayerData.type_rocket
		
		if selected_type == "Vessel 0":
			var card = get_node("MainMenu/Inventory/Card1")
			card.get_node("Selected").visible = true
			card.get_node("ColorRect2").visible = true
			card.get_node("ColorRect").visible = true
			
			flag_selected = true
		
		var i = 2
		for asset in wallet_tokens:
			$MplTokenMetadata.get_mint_metadata(asset.mint)
			var metadata = await $MplTokenMetadata.metadata_fetched
			if metadata.get_collection() and metadata.get_collection().get_key().to_string() == collection_mint.to_string():
				var card = get_node("MainMenu/Inventory/Card" + str(i))
				
				var type = metadata.get_token_name()
				card.get_node("Type").text = type
				
				var name = metadata.get_symbol()
				card.get_node("Name").text = name
				
				match name:
					"RKT-SR":
						card.get_node("Panel/TextureRect").texture = textures[8]
						card.get_node("Info").text = "* x2 coins/x1.25 score\n* More boosters and speed\n* More gates\n* Initial 1000 score"
					"RKT-B":
						card.get_node("Panel/TextureRect").texture = textures[7]
						card.get_node("Info").text = "* More speed on boosters"
					"RKT-S":
						card.get_node("Panel/TextureRect").texture = textures[6]
						card.get_node("Info").text = "* 1000 initial score"
					"RKT-T":
						card.get_node("Panel/TextureRect").texture = textures[5]
						card.get_node("Info").text = "* More gates on the map"
					"RKT-E":
						card.get_node("Panel/TextureRect").texture = textures[4]
						card.get_node("Info").text = "* x1.25 to score"
					"RKT-3":
						card.get_node("Panel/TextureRect").texture = textures[3]
						card.get_node("Info").text = "* x2 to collected coins"
					"RKT-2":
						card.get_node("Panel/TextureRect").texture = textures[2]
						card.get_node("Info").text = "* More boosters on the map"
					"RKT-1":
						card.get_node("Panel/TextureRect").texture = textures[1]
						card.get_node("Info").text = "* Two lives: one more chance"
					_:
						card.get_node("Panel/TextureRect").texture = textures[0]
						card.get_node("Info").text = "* Nothing special here..."
				
				card.modulate.a = 1
				
				i += 1
				count += 1
				
				if not flag_selected:
					if name == selected_type:
						card.get_node("Selected").visible = true
						card.get_node("ColorRect2").visible = true
						card.get_node("ColorRect").visible = true
						flag_selected = true
				
				if i > 6:
					break
		
		var token_mint = Pubkey.new_pda_bytes(
			[
				"token_mint".to_utf8_buffer(),
				extra_seed_bytes.to_bytes()
			],
			Pubkey.new_from_string($AnchorProgram.get_pid())
		)
	
		for asset in wallet_tokens:
			if asset.mint == token_mint.to_string():
				balance = asset.amount / (10**6)
				$MainMenu/Inventory/Balance.text = "Your Orbitals: " + str(asset.amount / (10**6)) + " ⛁"
	
	if count >= 6:
		$MainMenu/Inventory/OpenChest.disabled = true
		$MainMenu/Inventory/OpenChest.text = "Inventory is full"
	else:
		$MainMenu/Inventory/OpenChest.disabled = false
		$MainMenu/Inventory/OpenChest.text = "Open chest"
	
	if balance < 100000:
		$MainMenu/Inventory/OpenChest.disabled = true
		$MainMenu/Inventory/OpenChest.text = "Not enough Orbitals!"
	else:
		$MainMenu/Inventory/OpenChest.disabled = false
		$MainMenu/Inventory/OpenChest.text = "Open chest"
	
	$MainMenu/Loading.visible = false
	$MainMenu/Inventory.visible = true


func parse_token_data(data: PackedByteArray) -> Dictionary:
	if data.size() < 64:
		print("Invalid token data")
		return {}
	
	var mint_address = SolanaUtils.bs58_encode(data.slice(0, 32))
	var owner_address = SolanaUtils.bs58_encode(data.slice(32, 64))

	var amount_bytes = data.slice(64, 72)
	var amount = amount_bytes.decode_u64(0)
	
	return {"mint":mint_address,"owner":owner_address,"amount":amount}
	
func hex_to_bytes(hex_str: String) -> PackedByteArray:
		var bytes = PackedByteArray()
		# Припускаємо, що рядок має парну довжину
		for i in range(0, hex_str.length(), 2):
			var byte_str = hex_str.substr(i, 2)
			# Конвертуємо hex рядок в число (0-255)
			var byte_val = int("0x" + byte_str)
			bytes.append(byte_val)
		return bytes

func _on_open_chest_pressed() -> void:
	$MainMenu/Loading.visible = true
	
	await has_internet_connection()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No internet connection!\nCheck your provider and restart game!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		return
	
	await has_access_to_rpc()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No RPC connection!\nSonic Devnet is not responsing...\nCheck news, try again later!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		return
	
	var extra_seed_bytes = Pubkey.new_pda_bytes(
		[
			$SolanaClient.get_meta("extra_seeds").to_utf8_buffer(),
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	);
	
	var token_mint = Pubkey.new_pda_bytes(
		[
			"token_mint".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		$AnchorProgram.get_pid()
	)
	
	var leaderboard_pda = Pubkey.new_pda_bytes(
		[
			"leaderboard".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		$AnchorProgram.get_pid()
	)
	
	var project_data_pda = Pubkey.new_pda_bytes(
		[
			"project_data".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		$AnchorProgram.get_pid()
	)
	
	var game_authority_pda = Pubkey.new_pda_bytes(
		[
			"game_authority".to_utf8_buffer()
		],
		$AnchorProgram.get_pid()
	)
	
	var res = $AnchorProgram.fetch_account("ProjectData", project_data_pda.to_string())
	var account_data = await $AnchorProgram.account_fetched
	
	var id_bytes;
	# Функція для конвертації hex рядка в PackedByteArray

	if account_data.has("skinMintIndex"):
		var skin_mint_index = account_data.skinMintIndex
		# Форматуємо число у рядок із 8 шестнадцяткових символів (зліва доповнюємо нулями)
		var hex_str = String("%08x" % skin_mint_index)
		
		id_bytes = PackedByteArray()
		# Перетворюємо кожні 2 символи в байт (очевидно, що hex_str.length == 8)
		for i in range(0, hex_str.length(), 2):
			id_bytes.append(hex_str.substr(i, 2).hex_to_int())

		# Змінюємо порядок байтів: інвертуємо масив
		var reversed_bytes = PackedByteArray()
		for i in range(id_bytes.size() - 1, -1, -1):
			reversed_bytes.append(id_bytes[i])
		id_bytes = reversed_bytes
	else:
		return

	
	print(id_bytes)
	print(account_data.skinMintIndex)
	
	var skin_mint = Pubkey.new_pda_bytes(
		[
			"skin".to_utf8_buffer(),
			extra_seed_bytes.to_bytes(),
			id_bytes
		],
		$AnchorProgram.get_pid()
	)
	
	var gameOwner = Pubkey.new_from_string($SolanaClient.get_meta("game_owner"))
	
	var tx := Transaction.new()
	add_child(tx)
	
	client.get_token_accounts_by_owner(keypair.get_public_string(), token_mint.to_string(), "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
	var response_dict: Dictionary = await client.http_response_received
	var player_token_account;
	
	if not response_dict.has("error"):
		if response_dict["result"]["value"].size() == 0:
			player_token_account = Pubkey.new_associated_token_address(Pubkey.new_from_string(keypair.get_public_string()), token_mint.to_string())
		else:
			player_token_account = Pubkey.new_from_string(response_dict["result"]["value"][0]["pubkey"])
	
	client.get_token_accounts_by_owner(gameOwner.to_string(), token_mint.to_string(), "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
	var response_dict1: Dictionary = await client.http_response_received
	var owner_token_account;
	
	if not response_dict1.has("error"):
		if response_dict1["result"]["value"].size() == 0:
			owner_token_account = Pubkey.new_associated_token_address(gameOwner, token_mint.to_string())
		else:
			owner_token_account = Pubkey.new_from_string(response_dict1["result"]["value"][0]["pubkey"])
	
	var skinTokenAccount = Pubkey.new_associated_token_address(Pubkey.new_from_string(keypair.get_public_string()), skin_mint.to_string())
	
	var metaplex_program = Pubkey.new_from_string("metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s");
	
	var skin_metadata = Pubkey.new_pda_bytes(
		[
			"metadata".to_utf8_buffer(),
			metaplex_program.to_bytes(),
			skin_mint.to_bytes()
		],
		metaplex_program.to_string()
	)
	
	var skin_edition = Pubkey.new_pda_bytes(
		[
			"metadata".to_utf8_buffer(),
			metaplex_program.to_bytes(),
			skin_mint.to_bytes(),
			"edition".to_utf8_buffer(),
		],
		metaplex_program.to_string()
	)
	
	var collection_mint = Pubkey.new_pda_bytes(
		[
			"collection_mint".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		$AnchorProgram.get_pid()
	)
	
	var collection_metadata = Pubkey.new_pda_bytes(
		[
			"metadata".to_utf8_buffer(),
			metaplex_program.to_bytes(),
			collection_mint.to_bytes()
		],
		metaplex_program.to_string()
	)
	
	var collection_edition = Pubkey.new_pda_bytes(
		[
			"metadata".to_utf8_buffer(),
			metaplex_program.to_bytes(),
			collection_mint.to_bytes(),
			"edition".to_utf8_buffer(),
		],
		metaplex_program.to_string()
	)
	
	var leaderboardPDA = Pubkey.new_from_string(leaderboard_pda.to_string())
	var score = int($Player/Player/UI/Score.text) + int($Player/Player/UI/Coins.text) * 10
	var ix = idl.build_instruction("purchaseRandomSkin", 
		[
			Pubkey.new_from_string(keypair.get_public_string()), 
			token_mint,
			project_data_pda,
			player_token_account,
			owner_token_account,
			gameOwner,
			skin_mint,
			skinTokenAccount,
			skin_metadata,
			skin_edition,
			collection_mint,
			collection_metadata,
			collection_edition,
			extra_seed_bytes,
			game_authority_pda,
		
			Pubkey.new_from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"), 
			metaplex_program,
			Pubkey.new_from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"), 
			SystemProgram.get_pid(), 
			Pubkey.new_from_string("SysvarRent111111111111111111111111111111111")
		], 
		{})
	tx.add_instruction(ix)
	tx.set_payer(keypair)
	tx.update_latest_blockhash()
	tx.sign_and_send()
	print('sent')
	var response = await tx.transaction_response_received
	print(response)
	if response.has("result"):
		var alarm = sonic_alarm.instantiate()
		alarm.text = "Successfully opened the chest!"
		add_child(alarm)
		
		$MainMenu/Inventory/OpenChest/CPUParticles2D.restart()
		$MainMenu/Inventory/OpenChest/CPUParticles2D2.restart()
		
		$Reward.play()
		
		await get_tree().create_timer(1.0).timeout
		
		for i in range(5):
			var node_s = get_node("MainMenu/Inventory/Card" + str(i+2))
			node_s.get_node("Selected").visible = false
			node_s.get_node("ColorRect2").visible = false
			node_s.get_node("ColorRect").visible = false
			
			node_s.get_node("Info").text = "*"
			node_s.get_node("Type").text = "#"
			node_s.get_node("Name").text = "#"
			
			node_s.modulate.a = 0.2
		
		_on_inventory_pressed()
	else:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "Something went wrong...\nCheck your balance, internet connection.\nRestart game and start again!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		$MainMenu/Loading.visible = true


func _on_card_gui_input(event: InputEvent, name: int) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var node = get_node("MainMenu/Inventory/Card" + str(name))
			
			if not node.get_node("Panel/TextureRect").texture:
				return
			
			var boo: String = node.get_node("Name").text.strip_edges()

			if boo.length() > 0:
				var type = boo
				
				$PlayerData.type_rocket = type
				$PlayerData.save_game()
				$Player/Player._ready()
				$BoosterSpawner._ready()
				
				for i in range(6):
					var node_s = get_node("MainMenu/Inventory/Card" + str(i+1))
					node_s.get_node("Selected").visible = false
					node_s.get_node("ColorRect2").visible = false
					node_s.get_node("ColorRect").visible = false
				
				node.get_node("Selected").visible = true
				node.get_node("ColorRect2").visible = true
				node.get_node("ColorRect").visible = true
			


func _on_save_result_pressed() -> void:
	$Player/Player/UI/DeadControl/Control/Skip.visible = false
	$Player/Player/UI/DeadControl/Control/SaveResult.disabled = true
	
	await has_internet_connection()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No internet connection!\nCheck your provider and restart game!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		return
	
	await has_access_to_rpc()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No RPC connection!\nSonic Devnet is not responsing...\nCheck news, try again later!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		return
	
	var extra_seed_bytes = Pubkey.new_pda_bytes(
		[
			$SolanaClient.get_meta("extra_seeds").to_utf8_buffer(),
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	);
	
	var token_mint = Pubkey.new_pda_bytes(
		[
			"token_mint".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		$AnchorProgram.get_pid()
	)
	
	var leaderboard_pda = Pubkey.new_pda_bytes(
		[
			"leaderboard".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		$AnchorProgram.get_pid()
	)
	
	var game_authority_pda = Pubkey.new_pda_bytes(
		[
			"game_authority".to_utf8_buffer()
		],
		$AnchorProgram.get_pid()
	)
	
	var tx := Transaction.new()
	add_child(tx)
	
	client.get_token_accounts_by_owner(keypair.get_public_string(), token_mint.to_string(), "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
	var response_dict: Dictionary = await client.http_response_received
	var player_token_account;
	
	if not response_dict.has("error"):
		if response_dict["result"]["value"].size() == 0:
			player_token_account = Pubkey.new_associated_token_address(Pubkey.new_from_string(keypair.get_public_string()), token_mint.to_string())
		else:
			player_token_account = Pubkey.new_from_string(response_dict["result"]["value"][0]["pubkey"])
	
	var leaderboardPDA = Pubkey.new_from_string(leaderboard_pda.to_string())
	var score = int($Player/Player/UI/Score.text) + int($Player/Player/UI/Coins.text) * 10
	var ix = idl.build_instruction("writeResult", [Pubkey.new_from_string(keypair.get_public_string()), leaderboardPDA, extra_seed_bytes, player_token_account, token_mint, game_authority_pda, Pubkey.new_from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"), Pubkey.new_from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"), SystemProgram.get_pid(), Pubkey.new_from_string("SysvarRent111111111111111111111111111111111")], {'score': score })
	tx.add_instruction(ix)
	tx.set_payer(keypair)
	tx.update_latest_blockhash()
	tx.sign_and_send()
	print('sent')
	var response = await tx.transaction_response_received
	
	if response.has("result"):
		var alarm = sonic_alarm.instantiate()
		alarm.text = "Successfully recorded results!\nYou got " + str(score * 1) + " Orbitals\nCheck updated leaderboard!"
		add_child(alarm)
		
		$Player/Player/UI/DeadControl/Control/SaveResult/CPUParticles2D.restart()
		$Player/Player/UI/DeadControl/Control/SaveResult/CPUParticles2D2.restart()
		
		$Reward.play()
		
		$Player/Player/UI/DeadControl/Control/ParcTimer.start()
		
	
	
	else:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "Something went wrong..."
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		$Player/Player/UI/DeadControl/Control/ParcTimer.start()
	


func _on_parc_timer_timeout() -> void:
	RenderingServer.set_default_clear_color(Color.WHITE)
	get_tree().paused = false
	get_tree().call_deferred("reload_current_scene")


func _on_upgrades_pressed() -> void:
	$MainMenu/Loading.visible = true
	
	await has_internet_connection()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No internet connection!\nCheck your provider and restart game!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		$MainMenu/Loading.visible = false
		return
	
	await has_access_to_rpc()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No RPC connection!\nSonic Devnet is not responsing...\nCheck news, try again later!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		$MainMenu/Loading.visible = false
		return
		
	var max_upgrades = -1
	var balance = 0
	
	var pk_string = keypair.get_public_string()
	var extra_seed_bytes = Pubkey.new_pda_bytes(
		[
			$SolanaClient.get_meta("extra_seeds").to_utf8_buffer(),
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	);
	
	var token_mint = Pubkey.new_pda_bytes(
		[
			"token_mint".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		$AnchorProgram.get_pid()
	)
	client.get_token_accounts_by_owner(keypair.to_pubkey().to_string(), "", "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
	var response_dict: Dictionary = await client.http_response_received
	
	if response_dict.has('result'):
		var wallet_tokens: Array[Dictionary]
		for token in response_dict["result"]["value"]:
			var token_byte_data = SolanaUtils.bs64_decode(token["account"]["data"][0])
			var token_data:Dictionary = parse_token_data(token_byte_data)
			
			if token_data["amount"] == 0:
				continue
			
			wallet_tokens.append(token_data)
		
		for asset in wallet_tokens:
			if asset.mint == token_mint.to_string():
				balance = asset.amount / (10**6)
				$MainMenu/Upgrades/Balance.text = "Your Orbitals: " + str(asset.amount / (10**6)) + " ⛁"
	
	var leaderboard = Pubkey.new_pda_bytes(
		[
			"leaderboard".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		$AnchorProgram.get_pid()
	)
	
	idl.fetch_account("Leaderboard", leaderboard.to_string())
	var account_data = await $AnchorProgram.account_fetched
	
	var flag_founded = false
	
	if account_data.has("players"):
		for player_table in account_data.players:
			if pk_string == player_table.pubkey.to_string():
				max_upgrades = player_table.upgrades
				
				var alarm = sonic_alarm.instantiate()
				alarm.text = "Player information fetched succesfully!"
				add_child(alarm)
				
				flag_founded = true
	else:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "Some error occurred..."
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		$MainMenu/Loading.visible = false
		return
		
	if not flag_founded:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "Some error occurred..."
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		$MainMenu/Loading.visible = false
		return
	
	if max_upgrades >= 24:
		$MainMenu/Upgrades/BuyUpgrade.text = "You can't buy anymore"
		$MainMenu/Upgrades/BuyUpgrade.disabled = true
	else:
		$MainMenu/Upgrades/BuyUpgrade.text = "Buy upgrade"
		$MainMenu/Upgrades/BuyUpgrade.disabled = false
	
	if balance < 10000:
		$MainMenu/Upgrades/BuyUpgrade.disabled = true
		$MainMenu/Upgrades/BuyUpgrade.text = "Not enough Orbitals!"
	else:
		$MainMenu/Upgrades/BuyUpgrade.disabled = false
		$MainMenu/Upgrades/BuyUpgrade.text = "Buy upgrade"
	
	var upg_speed = $PlayerData.upg_speed
	var upg_rotation = $PlayerData.upg_rotation
	var upg_boost_duration = $PlayerData.upg_boost_duration
	var upg_boost_speed = $PlayerData.upg_boost_speed
	
	$MainMenu/Upgrades/SpeedTextureBar.value = upg_speed
	$MainMenu/Upgrades/RotationTextureBar.value = upg_rotation
	$MainMenu/Upgrades/BoostDurationTextureBar.value = upg_boost_duration
	$MainMenu/Upgrades/BoostSpeedTextureBar.value = upg_boost_speed
	
	var type = get_node("PlayerData").type_rocket
	
	var textures = [
		preload("res://Assets/rockets/0.png"),
		preload("res://Assets/rockets/1.png"),
		preload("res://Assets/rockets/2.png"),
		preload("res://Assets/rockets/3.png"),
		preload("res://Assets/rockets/4.png"),
		preload("res://Assets/rockets/5.png"),
		preload("res://Assets/rockets/6.png"),
		preload("res://Assets/rockets/7.png"),
		preload("res://Assets/rockets/8.png")
	]
	
	match type:
		"RKT-SR":
			$MainMenu/Upgrades/RocketImage/TextureRect.texture = textures[8]
		"RKT-B":
			$MainMenu/Upgrades/RocketImage/TextureRect.texture = textures[7]
		"RKT-S":
			$MainMenu/Upgrades/RocketImage/TextureRect.texture = textures[6]
		"RKT-T":
			$MainMenu/Upgrades/RocketImage/TextureRect.texture = textures[5]
		"RKT-E":
			$MainMenu/Upgrades/RocketImage/TextureRect.texture = textures[4]
		"RKT-3":
			$MainMenu/Upgrades/RocketImage/TextureRect.texture = textures[3]
		"RKT-2":
			$MainMenu/Upgrades/RocketImage/TextureRect.texture = textures[2]
		"RKT-1":
			$MainMenu/Upgrades/RocketImage/TextureRect.texture = textures[1]
		_:
			$MainMenu/Upgrades/RocketImage/TextureRect.texture = textures[0]
	
	$MainMenu/Upgrades.visible = true
	$MainMenu/StartGame.visible = false
	
	$MainMenu/Upgrades/UpgradesBalance.text = "Max upgrades: " + str(max_upgrades) + "/24"
	$MainMenu/Upgrades/YouHave.text = "Available to upgrade: " + str(upg_speed+upg_rotation+upg_boost_speed+upg_boost_duration) + "/" + str(max_upgrades)
	
	$MainMenu/Loading.visible = false

func _on_close_upgrade_pressed() -> void:
	$MainMenu/Upgrades.visible = false
	$MainMenu/StartGame.visible = true


func _on_plus_upgrade_gui_input(event: InputEvent, type: String) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var upg_speed = $PlayerData.upg_speed
			var upg_rotation = $PlayerData.upg_rotation
			var upg_boost_duration = $PlayerData.upg_boost_duration
			var upg_boost_speed = $PlayerData.upg_boost_speed
			
			var max_upgrades = int($MainMenu/Upgrades/YouHave.text.split("/")[1])
			
			if (upg_speed + upg_rotation + upg_boost_duration + upg_boost_speed) >= max_upgrades:
				return
			
			if type == "speed":
				if $PlayerData.upg_speed >= 10:
					return
					
				$PlayerData.upg_speed += 1
				$MainMenu/Upgrades/SpeedTextureBar.value = $PlayerData.upg_speed
			if type == "rotation":
				if $PlayerData.upg_rotation >= 10:
					return
					
				$PlayerData.upg_rotation += 1
				$MainMenu/Upgrades/RotationTextureBar.value = $PlayerData.upg_rotation
			if type == "boost_speed":
				if $PlayerData.upg_boost_speed >= 10:
					return
					
				$PlayerData.upg_boost_speed += 1
				$MainMenu/Upgrades/BoostSpeedTextureBar.value = $PlayerData.upg_boost_speed
			if type == "boost_duration":
				if $PlayerData.upg_boost_duration >= 10:
					return
					
				$PlayerData.upg_boost_duration += 1
				$MainMenu/Upgrades/BoostDurationTextureBar.value = $PlayerData.upg_boost_duration
			
			$MainMenu/Upgrades/YouHave.text = "Available to upgrade: " + str(upg_speed+upg_rotation+upg_boost_speed+upg_boost_duration + 1) + "/" + str(max_upgrades)
			
			var upgr = upgrade_part.instantiate()
			$MainMenu/Upgrades/RocketImage.add_child(upgr)
			upgr.position = $MainMenu/Upgrades/RocketImage/Marker2D.position
			upgr.restart()
			$PlayerData.save_game()


func _on_return_all_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			$PlayerData.upg_speed = 0
			$PlayerData.upg_rotation = 0
			$PlayerData.upg_boost_duration = 0
			$PlayerData.upg_boost_speed = 0
			
			$PlayerData.save_game()
			
			var max_upgrades = $MainMenu/Upgrades/YouHave.text.split("/")[1]
			$MainMenu/Upgrades/YouHave.text = "Available to upgrade: " + "0/" + str(max_upgrades)
			
			$MainMenu/Upgrades/SpeedTextureBar.value = 0
			$MainMenu/Upgrades/RotationTextureBar.value = 0
			$MainMenu/Upgrades/BoostSpeedTextureBar.value = 0
			$MainMenu/Upgrades/BoostDurationTextureBar.value = 0
			


func _on_buy_upgrade_pressed() -> void:
	$MainMenu/Loading.visible = true
	
	await has_internet_connection()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No internet connection!\nCheck your provider and restart game!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		$MainMenu/Loading.visible = false
		return
	
	await has_access_to_rpc()
	if not internet_status:
		var alarm = sonic_alarm.instantiate()
		alarm.text = "No RPC connection!\nSonic Devnet is not responsing...\nCheck news, try again later!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		$MainMenu/Loading.visible = false
		return
	
	var player_pk = keypair.to_pubkey()
	
	var extra_seed_bytes = Pubkey.new_pda_bytes(
		[
			$SolanaClient.get_meta("extra_seeds").to_utf8_buffer(),
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	);
	
	var gameOwner = Pubkey.new_from_string($SolanaClient.get_meta("game_owner"))
	var leaderboard_pda = Pubkey.new_pda_bytes(
		[
			"leaderboard".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	)
	
	var token_mint = Pubkey.new_pda_bytes(
		[
			"token_mint".to_utf8_buffer(),
			extra_seed_bytes.to_bytes()
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	)
	
	var game_authority = Pubkey.new_pda_bytes(
		[
			"game_authority".to_utf8_buffer()
		],
		Pubkey.new_from_string($AnchorProgram.get_pid())
	)
	var systemProgram = SystemProgram.get_pid()
	
	var tx := Transaction.new()
	add_child(tx)
	
	client.get_token_accounts_by_owner(keypair.get_public_string(), token_mint.to_string(), "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
	var response_dict: Dictionary = await client.http_response_received
	var player_token_account;
	
	if not response_dict.has("error"):
		if response_dict["result"]["value"].size() == 0:
			player_token_account = Pubkey.new_associated_token_address(Pubkey.new_from_string(keypair.get_public_string()), token_mint.to_string())
		else:
			player_token_account = Pubkey.new_from_string(response_dict["result"]["value"][0]["pubkey"])
	
	client.get_token_accounts_by_owner(gameOwner.to_string(), token_mint.to_string(), "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
	var response_dict1: Dictionary = await client.http_response_received
	var owner_token_account;
	
	if not response_dict1.has("error"):
		if response_dict1["result"]["value"].size() == 0:
			owner_token_account = Pubkey.new_associated_token_address(gameOwner, token_mint.to_string())
		else:
			owner_token_account = Pubkey.new_from_string(response_dict1["result"]["value"][0]["pubkey"])
	
	print("here")
	var ix = idl.build_instruction("buyUpgrade", [Pubkey.new_from_string(keypair.get_public_string()), player_token_account, owner_token_account, leaderboard_pda, extra_seed_bytes, gameOwner, token_mint, game_authority, Pubkey.new_from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"), Pubkey.new_from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"), SystemProgram.get_pid(), Pubkey.new_from_string("SysvarRent111111111111111111111111111111111")], {})
	tx.add_instruction(ix)
	tx.set_payer(keypair)
	tx.update_latest_blockhash()
	tx.sign_and_send()
	
	var response = await tx.transaction_response_received
	
	if response.has("result"):
		var alarm = sonic_alarm.instantiate()
		alarm.text = "Successfully bought the upgrade!"
		add_child(alarm)
		
		$MainMenu/Upgrades/BuyUpgrade/CPUParticles2D.restart()
		$MainMenu/Upgrades/BuyUpgrade/CPUParticles2D2.restart()
		
		$Reward.play()
		
		await get_tree().create_timer(1.0).timeout
		
		_on_upgrades_pressed()
	else:
		print(response)
		var alarm = sonic_alarm.instantiate()
		alarm.text = "Something went wrong...\nCheck your balance, internet connection.\nRestart game and start again!"
		alarm.get_node("Control/Timer").wait_time = 50
		add_child(alarm)
		
		$MainMenu/Loading.visible = false
