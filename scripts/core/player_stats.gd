class_name PlayerStats
extends Resource

signal stats_changed
signal health_depleted

# İleride istediğin kadar yeni stat ekleyebileceğin liste:
enum StatType {
	MAX_HP,
	STRENGTH,       # Fiziksel hasar çarpanı
	VITALITY,       # Can bonusu
	AGILITY,        # Kaçınma / Hız
	CRIT_RATE,      # Kritik vuruş şansı (%)
	CRIT_DAMAGE,    # Kritik hasar çarpanı (%)
	LUCK,           # Eşya/Sandık düşürme şansı
	MAGIC_POWER,    # Efsun / Buff gücü
	ACTION_POINTS   # Tur başı oynanabilir kart sayısı (varsayılan 2)
}

@export_group("Anlık Savaş Değerleri")
@export var current_hp: int = 50
@export var current_block: int = 0
@export var available_stat_points: int = 3 # Dağıtılabilir puan

@export_group("Temel Nitelikler (Base Stats)")
# Tüm statları dinamik tutan ana sözlük (Dictionary):
@export var base_stats: Dictionary = {
	StatType.MAX_HP: 50,
	StatType.STRENGTH: 0,
	StatType.VITALITY: 0,
	StatType.AGILITY: 0,
	StatType.CRIT_RATE: 5,        # %5 temel kritik
	StatType.CRIT_DAMAGE: 150,    # %150 temel kritik hasarı
	StatType.LUCK: 0,
	StatType.MAGIC_POWER: 0,
	StatType.ACTION_POINTS: 2     # Tasarladığın tur başı 2 kart oynama hakkı
}

# Ekipman ve Kalıntılardan (Relics) gelen geçici bonuslar:
var modifier_stats: Dictionary = {}

# --- Stat Okuma ve Hesaplama Fonksiyonları ---

func get_stat(stat: StatType) -> int:
	var base = base_stats.get(stat, 0)
	var mod = modifier_stats.get(stat, 0)
	
	# Vitality doğrudan Max HP'ye etki etsin (+5 HP / puan)
	if stat == StatType.MAX_HP:
		var vit = get_stat(StatType.VITALITY)
		return base + mod + (vit * 5)
		
	return base + mod

func upgrade_stat(stat: StatType, amount: int = 1) -> bool:
	if available_stat_points >= amount:
		available_stat_points -= amount
		base_stats[stat] = base_stats.get(stat, 0) + amount
		stats_changed.emit()
		return true
	return false

# --- Savaş ve Can Fonksiyonları ---

func take_damage(amount: int) -> void:
	if current_block > 0:
		if amount <= current_block:
			current_block -= amount
			amount = 0
		else:
			amount -= current_block
			current_block = 0
			
	current_hp = max(0, current_hp - amount)
	stats_changed.emit()
	
	if current_hp <= 0:
		health_depleted.emit()

func add_block(amount: int) -> void:
	current_block += amount
	stats_changed.emit()

func reset_block() -> void:
	current_block = 0
	stats_changed.emit()

func heal(amount: int) -> void:
	var max_health = get_stat(StatType.MAX_HP)
	current_hp = min(max_health, current_hp + amount)
	stats_changed.emit()
