class_name EnemyData
extends Resource

enum EnemyType {
	NORMAL,
	ELITE,
	BOSS
}

enum ActionIntent {
	ATTACK,         # Saldırı yapacak
	DEFEND,         # Kendine kalkan basacak
	BUFF,           # Kendi gücünü artıracak
	DEBUFF,         # Oyuncuya zehir/kanama/zayıflık atacak
	SPECIAL         # Katman bossuna özel mekanik
}

@export_group("Genel Düşman Bilgileri")
@export var enemy_name: String = "Cave Goblin"
@export var enemy_type: EnemyType = EnemyType.NORMAL
@export var max_hp: int = 30
@export var sprite_texture: Texture2D

@export_group("Katman & Irk Bilgisi")
@export var floor_level: int = 1 # 1: Orklar/Goblinler, 2: Cüceler vb.

@export_group("Davranış ve Niyet Değerleri")
@export var base_attack_damage: int = 7
@export var base_block_amount: int = 5
@export var action_pattern: Array[ActionIntent] = [
	ActionIntent.ATTACK,
	ActionIntent.DEFEND,
	ActionIntent.ATTACK
]
