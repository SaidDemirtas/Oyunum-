class_name ItemData
extends Resource

enum ItemCategory { GENERAL, WEAPON, HELMET, ARMOR, BOOTS, NECKLACE }
@export var category: ItemCategory = ItemCategory.GENERAL

enum ItemRarity {
	COMMON,     # Yaygın
	RARE,       # Nadir
	EPIC,       # Epik
	MYSTIC,     # Gizemli
	LEGENDARY   # Efsanevi
}

enum EquipmentSlot {
	HELMET,     # Kask (Debuff ağırlıklı)
	ARMOR,      # Zırh (Blok ağırlıklı)
	WEAPON,     # Silah (Hasar/Kalkan ağırlıklı)
	NECKLACE,   # Kolye (Buff ağırlıklı)
	BOOTS       # Ayakkabı (Kaçınma ağırlıklı)
}

@export_group("Temel Bilgiler")
@export var item_name: String = "Yeni Ekipman"
@export_multiline var item_description: String = ""
@export var slot_type: EquipmentSlot = EquipmentSlot.WEAPON
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var icon: Texture2D

@export_group("1. Temel Statlar")
@export var str_damage: int = 0
@export var bonus_max_hp: int = 0 # Karakterin temel canına kalıcı ekleme

@export_group("2. Anlık & Savunma")
@export var shield: int = 0
@export var bonus_dodge_rate: float = 0.0 # Kaçınma oranı (Eski koddan korundu)

@export_group("3. Şans ve Çarpanlar")
@export_range(0.0, 1.0) var crit_chance: float = 0.0
@export var crit_damage_modifier: float = 0.0 # Varsayılan çarpana eklenecek değer
@export_range(0.0, 1.0) var lifesteal: float = 0.0
@export_range(0.0, 1.0) var stun_chance: float = 0.0

@export_group("4. Buff ve Debufflar")
@export var strength_buff: float = 0.0
@export var vulnerability: float = 0.0
@export var weaken: float = 0.0

@export_group("Kart Havuzu (3 Kart)")
@export var card_pool: Array[CardData] = []
