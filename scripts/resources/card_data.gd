class_name CardData
extends Resource

# --- NADİRLİK VE TÜR SİSTEMİ ---
# Eşyalardaki 5 nadirliğe ek olarak kartlara özel 6. seviye (MYTHIC) eklendi.
enum CardRarity {
	COMMON,     # Sadece temel statlar
	RARE,       # Temel statlar + Özel Durum (Condition)
	EPIC,       # Temel statlar + Özel Durum + 1 Ekstra Etki
	MYSTIC,     # Temel statlar + Özel Durum + 2 Ekstra Etki (Daha yüksek oranlar)
	LEGENDARY,  # Katlanarak artan statlar ve çoklu efektler
	MYTHIC      # 6. Nadirlik: Savaşın kurallarını değiştiren eşsiz mekanikler
}

enum CardType { ATTACK, DEFENSE, SKILL, POWER }

@export_group("Temel Bilgiler")
@export var id: String = ""
@export var card_name: String = "Yeni Kart"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var energy_cost: int = 1
@export var type: CardType = CardType.ATTACK
@export var rarity: CardRarity = CardRarity.COMMON

# --- KATMAN 1: YAYGIN (COMMON) VE ÜZERİ ---
@export_group("1. Temel Statlar")
@export var base_damage: int = 0
@export var base_shield: int = 0
@export var base_heal: int = 0

# --- KATMAN 2: NADİR (RARE) VE ÜZERİ ---
@export_group("2. Özel Durum Efsunları (Condition)")
# Kartın ekstra güç kazanması için gereken ön koşullar
enum ConditionType { NONE, IF_ENEMY_WEAKENED, IF_ENEMY_VULNERABLE, IF_HP_BELOW_50, IF_PREVIOUS_CARD_ATTACK }
@export var condition_trigger: ConditionType = ConditionType.NONE
@export var condition_bonus_damage: int = 0
@export var condition_bonus_shield: int = 0

# --- KATMAN 3: EPİK (EPIC) VE ÜZERİ ---
@export_group("3. Ekstra Etkiler (Efektler & Debufflar)")
# Düşmana uygulanacak debufflar
@export_range(0.0, 1.0) var apply_vulnerability: float = 0.0 # Kırılganlık ekleme
@export_range(0.0, 1.0) var apply_weaken: float = 0.0 # Zayıflatma ekleme
@export_range(0.0, 1.0) var apply_stun_chance: float = 0.0 # Sersemletme şansı

# Karaktere uygulanacak bufflar
@export_range(0.0, 1.0) var apply_strength_buff: float = 0.0 # Kuvvet artışı
@export_range(0.0, 1.0) var apply_lifesteal: float = 0.0 # Can çalma
