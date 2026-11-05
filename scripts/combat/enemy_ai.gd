class_name EnemyAI
extends Node

signal intent_determined(intent: EnemyData.ActionIntent, value: int)
signal action_executed(intent: EnemyData.ActionIntent, value: int)

@export var enemy_data: EnemyData
var current_pattern_index: int = 0
var next_intent: EnemyData.ActionIntent
var next_value: int = 0

# Savaş başında düşman verisini yükler
func setup(data: EnemyData) -> void:
	enemy_data = data
	current_pattern_index = 0
	determine_next_intent()

# Bir sonraki tur ne yapacağını hesaplar
func determine_next_intent() -> void:
	if enemy_data == null or enemy_data.action_pattern.is_empty():
		return
		
	next_intent = enemy_data.action_pattern[current_pattern_index]
	
	# Niyete göre değer (Hasar veya Kalkan) belirleme
	match next_intent:
		EnemyData.ActionIntent.ATTACK:
			next_value = enemy_data.base_attack_damage
		EnemyData.ActionIntent.DEFEND:
			next_value = enemy_data.base_block_amount
		_:
			next_value = 0 # Buff/Debuff için statik değerler ileride buraya eklenebilir
			
	intent_determined.emit(next_intent, next_value)

# Düşman sırası geldiğinde eylemi gerçekleştirir
func execute_turn() -> void:
	# Eylemi dışarıya (Savaş Yöneticisine) bildir
	action_executed.emit(next_intent, next_value)
	
	# Döngüyü bir sonraki eyleme geçir (Dizi bitince başa sarar)
	current_pattern_index = (current_pattern_index + 1) % enemy_data.action_pattern.size()
	determine_next_intent()
