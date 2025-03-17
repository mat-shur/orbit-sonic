extends Node2D


func _ready() -> void:
	$AnchorProgram.fetch_account("Leaderboard", "Hn6oEJKKWQM3NQrDJooDTxtdsUjUz1wwaHUiLFrqTBuk")
	var data = await $AnchorProgram.account_fetched
	print(data)
