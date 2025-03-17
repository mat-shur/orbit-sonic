extends Node

const PROGRAM_ID = "dBAbBm4vRcY1EDDVRpuxWcYE1X6XAYAJKX5chZdhBDK"
const GAME_OWNER_PUBKEY = "JBs7WaxHM6thNedF3DAZNmmHMsWTHVLAaiAjpbLbtAno"

@export var guard_settings:CandyGuardAccessList

static func get_leaderboard_pda(game_owner: Pubkey) -> Pubkey:
	var seed_prefix = "leaderboard".to_utf8_buffer()
	var owner_bytes = game_owner.to_bytes()
	
	var seeds = [seed_prefix, owner_bytes]
	
	var program_id = Pubkey.new_from_string(PROGRAM_ID)
	return Pubkey.new_pda_bytes(seeds, program_id)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var filepath = "res://wallet6.json"
	var keypair: Keypair

	if FileAccess.file_exists(filepath):
		keypair = Keypair.new_from_file(filepath)
		print("Ключова пара завантажена з файлу.")
	else:
		keypair = Keypair.new_random()
		keypair.save_to_file(filepath)
		print("Створено нову ключову пару та збережено у файл.")
	
	var pk_string: String = keypair.get_public_string()
	
	print("Your wallet: ", pk_string)
	
	var client = $SolanaClient;
	var idl = $AnchorProgram;
	var machine = $MplCandyMachine
	
	var response;
	
	machine.get_candy_machine_info(Pubkey.new_from_string("GCW8uJDcfo3ihaR65g8hF7Xydxw1rnVZeNspK29jmTpX"))
	var candy_machine_data: CandyMachineData  = await machine.account_fetched

	var nft_keypair: Keypair = Keypair.new_random()
	var mint_keypair: Keypair = Keypair.new_random()
	
	#client.get_token_accounts_by_owner(keypair.to_pubkey().to_string(), "", "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
	#var response_dict:Dictionary = await client.http_response_received
	#
	#var wallet_tokens:Array[Dictionary]
	#for token in response_dict["result"]["value"]:
		#var token_byte_data = SolanaUtils.bs64_decode(token["account"]["data"][0])
		#var token_data:Dictionary = parse_token_data(token_byte_data)
		#print(token_data)
		##remove token accounts which no longer hold an NFT
		#if token_data["amount"] == 0:
			#continue
		#wallet_tokens.append(token_data)
	#
	#for asset in wallet_tokens:
		#$MplTokenMetadata.get_mint_metadata(asset.mint)
		#var metadata = await $MplTokenMetadata.metadata_fetched
		#if metadata.get_collection().get_key().to_string() == "5A92usDubLajmhwSgx45aMaXvmiy5N5eUiZ5TouQi6qj":
			#print(metadata.get_token_name())
			#print(metadata.get_uri())


	#guard_settings = {
		#"token2022Payment": {
			#"amount": 1000,
			#"mint": Pubkey.new_from_string("DQpctGneThkHvA3h2W33wZ3mHi9YqvnWcmGrLRQPJAhj"),
			#"destinationAta": Pubkey.new_from_string("J8h2wh4rq4emgU31p8FyBkpGMh79Gdgkx13TFkTjSHwP")
		#}
	#}
	
	var ix: Instruction = MplCandyGuard.mint(
		Pubkey.new_from_string("GCW8uJDcfo3ihaR65g8hF7Xydxw1rnVZeNspK29jmTpX"),
		Pubkey.new_from_string("EoUmSKz45y8bkAtrnZatyTVxbTSCucBXKyX7Z7yEW8K6"),
		keypair.to_pubkey(),
		keypair,
		nft_keypair,
		keypair,
		candy_machine_data.collection_mint,
		candy_machine_data.authority,
		guard_settings,
		"chest"
	)
	
	var tx := Transaction.new()
	add_child(tx)
	tx.add_instruction(ix)
	tx.set_payer(keypair)
	tx.update_latest_blockhash()
	await tx.blockhash_updated
	tx.sign_and_send()
	var result = await tx.transaction_response_received
	print(result)



func parse_token_data(data: PackedByteArray) -> Dictionary:
	# Ensure that the data has a minimum length
	if data.size() < 64:
		print("Invalid token data")
		return {}
	
	# Extract the mint address (first 32 bytes)
	var mint_address = SolanaUtils.bs58_encode(data.slice(0, 32))
	var owner_address = SolanaUtils.bs58_encode(data.slice(32, 64))

	# Extract the amount (next 8 bytes) and convert it to a 64-bit integer
	var amount_bytes = data.slice(64, 72)
	var amount = amount_bytes.decode_u64(0)
	
	return {"mint":mint_address,"owner":owner_address,"amount":amount}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
