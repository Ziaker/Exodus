class_name SurvivalData
extends RefCounted

## Dados isolados do modo Survival (for fun / sandbox de combate).
## Não faz parte da lore nem toca no ProgressStore do jogo principal.

const WORLD_SCENE := "res://scenes/survival/SurvivalWorld.tscn"
const BATTLE_SCENE := "res://scenes/survival/SurvivalBattle.tscn"
const LOCATION_NAME := "SURVIVAL ARENA"

const REF_PICTURES := "res://Shin Megami Tensei VX The Genesis/Shin Megami Tensei The Genesis/Graphics/Pictures/"
const BATTLERS_DIR := "res://assets/graphics/battlers/"
const SILHOUETTES_DIR := "res://assets/generated/survival/"

## Pool de habilidades roguelike do modo: qualquer uma pode cair como recompensa.
const SURVIVAL_SKILLS: Array[StringName] = [
	&"pixie_dust", &"frost_breath", &"hellfire", &"spirit_bolt", &"curse_ray", &"shadow_bite",
	&"fang_flurry", &"heavy_crush", &"howl", &"primal_roar", &"mend", &"dark_siphon",
	&"soul_pierce", &"twin_fang", &"war_cry", &"venom_cloud", &"mind_blast", &"frost_lance",
	&"thunder_call", &"life_drain", &"spirit_wave", &"crushing_blow", &"ember_touch", &"renew",
	&"void_gaze", &"blade_dance", &"stone_grasp",
]

## Nomes em hebraico das habilidades não identificadas (D-052 / Ra'am).
const HEBREW_SKILLS := {
	&"pixie_dust": "אבק פיה", &"frost_breath": "נשימת כפור", &"hellfire": "אש גיהנום",
	&"spirit_bolt": "סימן רוח", &"curse_ray": "קרן קללה", &"shadow_bite": "נשיכת צל",
	&"fang_flurry": "סערת ניבים", &"heavy_crush": "מעיכה כבדה", &"howl": "יללה",
	&"primal_roar": "שאגה קדומה", &"mend": "תיקון", &"dark_siphon": "מתנה אפלה",
	&"soul_pierce": "חדירת נשמה", &"twin_fang": "ניב כפול", &"war_cry": "זעקת מלחמה",
	&"venom_cloud": "ענן ארס", &"mind_blast": "שאיבת מוח", &"frost_lance": "רומח כפור",
	&"thunder_call": "קריאת רעם", &"life_drain": "ניקוז חיים", &"spirit_wave": "עלוקת נשמה",
	&"crushing_blow": "מכת סיום", &"ember_touch": "התפרצות גחלת", &"renew": "חידוש",
	&"void_gaze": "מבט הריק", &"blade_dance": "מחול להבים", &"stone_grasp": "אחיזת אבן",
}

static func hebrew_skill(skill: StringName) -> String:
	return String(HEBREW_SKILLS.get(skill, "???"))


const MAX_CONTINUES := 3
const STARTING_MACCA := 40
const STARTING_BEADS := 1
const STARTING_CHAKRAS := 1
const CHASE_RADIUS := 6

## Itens disponíveis na barra de opções do Curandeiro / Vendedor.
const SHOP_ITEMS := [
	{"id": "bead", "name": "BEAD", "price": 20, "kind": "hp", "amount": 20,
		"label": "BEAD (+20 HP) - 20M", "info": "Restores 20 HP to one ally in battle."},
	{"id": "chakra", "name": "CHAKRA", "price": 20, "kind": "en", "amount": 10,
		"label": "CHAKRA (+10 EN) - 20M", "info": "Restores 10 EN to one ally in battle."},
	# D-072: consumíveis novos (estoque rotativo da loja por estrato).
	{"id": "medicine", "name": "MEDICINE", "price": 45, "kind": "hp", "amount": 50,
		"label": "MEDICINE (+50 HP) - 45M", "info": "Restores 50 HP to one ally in battle."},
	{"id": "soma", "name": "SOMA", "price": 110, "kind": "full", "amount": 0,
		"label": "SOMA (FULL) - 110M", "info": "Fully restores HP and EN (or PP) of one ally."},
	{"id": "blast", "name": "BLAST STONE", "price": 35, "kind": "damage", "amount": 18,
		"label": "BLAST STONE (18 DMG) - 35M", "info": "Deals 18 fixed damage to one foe."},
]
## Sempre à venda; os outros 2 do estoque giram por estrato.
const SHOP_FIXED := ["bead", "chakra"]
const SHOP_ROTATING := ["medicine", "soma", "blast"]
## Preço de relíquia à venda no santuário (sobe por estrato).
const RELIC_BASE_PRICE := 90
## D-068: a cura do santuário é grátis uma vez por estrato; depois custa isto × estrato.
const HEAL_PRICE_PER_STRATUM := 15

## D-070: afixos de elite com efeito real.
const ELITE_AFFIXES := ["BRUTAL", "SWIFT", "STONE", "BURNING", "VAMPIRIC"]
const ELITE_CHANCE := 0.20
const ELITE_CHANCE_OMEN := 0.35

## D-074: figuras SMT dos eventos (só no teste, como o atendente; D-018).
const EVENT_DEFS := {
	"altar": {"name": "BLOOD ALTAR", "picture": REF_PICTURES + "生贄01.png",
		"text": "A starving altar. It will trade a relic for your blood."},
	"spirit": {"name": "WANDERING SPIRIT", "picture": REF_PICTURES + "霊体♀.png",
		"text": "A pale spirit offers rest, or a colder communion."},
	"oracle": {"name": "HOODED ORACLE", "picture": REF_PICTURES + "神の使い.png",
		"text": "The oracle sells secrets and dares you to gamble your flesh."},
	"merchant": {"name": "FROST MERCHANT", "picture": REF_PICTURES + "901-店員ジャックフロスト【1】.png",
		"text": "Hee-ho! A wandering merchant with one rare relic."},
}

## Atributos base do grupo no Survival. D-101 (criador 2026-11-25: "SP parecido"): o dano soma um
## sorteio de até a diferença de SP, e o SP é a soma dos sete atributos (HP e EN incluídos). A ficha
## antiga (HP 140, EN 32: SP 205) contra inimigos de SP 59 a 139 fazia o Fallen matar em menos de
## 1 golpe e ignorar 65 a 72% dos golpes. Agora o Fallen começa com a média dos 7 inimigos do
## estrato 1 (HP 25,7 EN 11,7 ATK 7 MAK 7 DEF 5,6 MEF 6,3 AGI 8,7 -> SP 73 contra 72) e a Yoch com a
## mesma proporção que tem no jogo base (29/46).
const FALLEN_BASE := {
	"max_hp": 26, "max_en": 12, "atk": 7, "mak": 7, "defense": 6, "mef": 6, "agi": 9,
}
const YOCH_BASE := {
	"max_hp": 17, "max_en": 0, "atk": 8, "mak": 3, "defense": 6, "mef": 3, "agi": 8, "pp": 2,
}

## Mapa 25x21 exclusivo do Survival Mode: santuário central com 4 saídas e 4 grandes alas.
## '#' parede, '.' chão, 'S' início (12, 10) olhando para o Norte (de frente para o NPC).
const MAZE: Array[String] = [
	"#########################", # 0
	"#.....#...#...#...#.....#", # 1
	"#.###.#.#.#.#.#.#.#.###.#", # 2
	"#.#.....#...#...#.....#.#", # 3
	"#.#.###.###.#.###.###.#.#", # 4
	"#...#.......#.......#...#", # 5
	"###.#.#####...#####.#.###", # 6
	"#...#.#...........#.#...#", # 7
	"#.#...#..###.###..#...#.#", # 8
	"#.#.###..#.....#..###.#.#", # 9
	"#...........S...........#", # 10
	"#.#.###..#.....#..###.#.#", # 11
	"#.#...#..###.###..#...#.#", # 12
	"#...#.#...........#.#...#", # 13
	"###.#.#####...#####.#.###", # 14
	"#...#.......#.......#...#", # 15
	"#.#.###.###.#.###.###.#.#", # 16
	"#.#.....#...#...#.....#.#", # 17
	"#.###.#.#.#.#.#.#.#.###.#", # 18
	"#.....#...#...#...#.....#", # 19
	"#########################", # 20
]

## Zona segura do santuário (x: 10..14, y: 9..11): demônios não entram aqui.
const SAFE_ZONE := Rect2i(10, 9, 5, 3)

## NPC único no santuário: Curandeiro (sprite SMT) + Vendedor na mesma barra de opções.
const NPCS := [
	{
		"id": "sanctuary_keeper",
		"role": "sanctuary",
		"cell": Vector2i(12, 9),
		"picture": REF_PICTURES + "P99_メシア01.png",
		"name": "SANCTUARY KEEPER",
		"pages": ["Welcome to the Survival Arena. Rest or stock up before facing the 35 demons."],
	},
]

## 35 demônios de SMT com sprites reais, status distintos e habilidades placeholder distintas.
const DEMONS := [
	{
		"id": "pixie", "name": "PIXIE", "tier": 1, "macca": 25,
		"picture": BATTLERS_DIR + "Fairy Pixie.png",
		"silhouette": SILHOUETTES_DIR + "pixie.png",
		"cell": Vector2i(12, 7),
		"stats": {"max_hp": 18, "max_en": 10, "atk": 5, "mak": 7, "defense": 4, "mef": 6, "agi": 9},
		"skills": [&"pixie_dust", &"mend"],
		"affinity": BattleMath.Affinity.WEAK,
	},
	{
		"id": "jack_frost", "name": "JACK FROST", "tier": 1, "macca": 25,
		"picture": BATTLERS_DIR + "Fairy Jack Frost.png",
		"silhouette": SILHOUETTES_DIR + "jack_frost.png",
		"cell": Vector2i(12, 13),
		"stats": {"max_hp": 22, "max_en": 12, "atk": 5, "mak": 8, "defense": 5, "mef": 7, "agi": 7},
		"skills": [&"frost_breath", &"spirit_bolt"],
		"affinity": BattleMath.Affinity.WEAK,
	},
	{
		"id": "pyro_jack", "name": "PYRO JACK", "tier": 1, "macca": 30,
		"picture": BATTLERS_DIR + "Fairy Pyro Jack.png",
		"silhouette": SILHOUETTES_DIR + "pyro_jack.png",
		"cell": Vector2i(7, 10),
		"stats": {"max_hp": 24, "max_en": 12, "atk": 6, "mak": 9, "defense": 5, "mef": 6, "agi": 6},
		"skills": [&"hellfire", &"howl"],
		"affinity": BattleMath.Affinity.WEAK,
	},
	{
		"id": "cerberus", "name": "CERBERUS", "tier": 2, "macca": 35,
		"picture": BATTLERS_DIR + "Beast Cerberus.png",
		"silhouette": SILHOUETTES_DIR + "cerberus.png",
		"cell": Vector2i(17, 10),
		"stats": {"max_hp": 32, "max_en": 10, "atk": 10, "mak": 4, "defense": 8, "mef": 5, "agi": 8},
		"skills": [&"fang_flurry", &"primal_roar"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "oni", "name": "ONI", "tier": 2, "macca": 35,
		"picture": BATTLERS_DIR + "Brute Oni.png",
		"silhouette": SILHOUETTES_DIR + "oni.png",
		"cell": Vector2i(7, 7),
		"stats": {"max_hp": 38, "max_en": 10, "atk": 11, "mak": 3, "defense": 9, "mef": 4, "agi": 5},
		"skills": [&"heavy_crush", &"howl"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "garuda", "name": "GARUDA", "tier": 2, "macca": 35,
		"picture": BATTLERS_DIR + "Avian Garuda.png",
		"silhouette": SILHOUETTES_DIR + "garuda.png",
		"cell": Vector2i(17, 7),
		"stats": {"max_hp": 28, "max_en": 12, "atk": 8, "mak": 6, "defense": 6, "mef": 6, "agi": 12},
		"skills": [&"spirit_bolt", &"shadow_bite"],
		"affinity": BattleMath.Affinity.WEAK,
	},
	{
		"id": "anubis", "name": "ANUBIS", "tier": 2, "macca": 40,
		"picture": BATTLERS_DIR + "Avatar Anubis.png",
		"silhouette": SILHOUETTES_DIR + "anubis.png",
		"cell": Vector2i(7, 13),
		"stats": {"max_hp": 34, "max_en": 14, "atk": 8, "mak": 7, "defense": 8, "mef": 7, "agi": 8},
		"skills": [&"curse_ray", &"mend"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "chimera", "name": "CHIMERA", "tier": 2, "macca": 40,
		"picture": BATTLERS_DIR + "Avatar Chimera.png",
		"silhouette": SILHOUETTES_DIR + "chimera.png",
		"cell": Vector2i(17, 13),
		"stats": {"max_hp": 36, "max_en": 12, "atk": 10, "mak": 7, "defense": 7, "mef": 6, "agi": 7},
		"skills": [&"hellfire", &"fang_flurry"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "andras", "name": "ANDRAS", "tier": 2, "macca": 40,
		"picture": BATTLERS_DIR + "Fallen Andras.png",
		"silhouette": SILHOUETTES_DIR + "andras.png",
		"cell": Vector2i(10, 5),
		"stats": {"max_hp": 30, "max_en": 11, "atk": 10, "mak": 5, "defense": 6, "mef": 5, "agi": 10},
		"skills": [&"shadow_bite", &"curse_ray"],
		"affinity": BattleMath.Affinity.WEAK,
	},
	{
		"id": "succubus", "name": "SUCCUBUS", "tier": 2, "macca": 40,
		"picture": BATTLERS_DIR + "Night Succubus.png",
		"silhouette": SILHOUETTES_DIR + "succubus.png",
		"cell": Vector2i(14, 5),
		"stats": {"max_hp": 26, "max_en": 15, "atk": 5, "mak": 10, "defense": 5, "mef": 9, "agi": 9},
		"skills": [&"pixie_dust", &"dark_siphon"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "ganesha", "name": "GANESHA", "tier": 3, "macca": 45,
		"picture": BATTLERS_DIR + "Yoma Ganesha.png",
		"silhouette": SILHOUETTES_DIR + "ganesha.png",
		"cell": Vector2i(10, 15),
		"stats": {"max_hp": 44, "max_en": 13, "atk": 9, "mak": 6, "defense": 10, "mef": 7, "agi": 4},
		"skills": [&"heavy_crush", &"mend"],
		"affinity": BattleMath.Affinity.RESIST,
	},
	{
		"id": "vritra", "name": "VRITRA", "tier": 3, "macca": 45,
		"picture": BATTLERS_DIR + "Dragon Vritra.png",
		"silhouette": SILHOUETTES_DIR + "vritra.png",
		"cell": Vector2i(14, 15),
		"stats": {"max_hp": 46, "max_en": 14, "atk": 9, "mak": 10, "defense": 9, "mef": 8, "agi": 5},
		"skills": [&"frost_breath", &"hellfire"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "wyvern", "name": "WYVERN", "tier": 3, "macca": 45,
		"picture": BATTLERS_DIR + "Drake Wyvern.png",
		"silhouette": SILHOUETTES_DIR + "wyvern.png",
		"cell": Vector2i(3, 10),
		"stats": {"max_hp": 36, "max_en": 11, "atk": 9, "mak": 7, "defense": 7, "mef": 6, "agi": 9},
		"skills": [&"fang_flurry", &"hellfire"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "lich", "name": "LICH", "tier": 3, "macca": 50,
		"picture": BATTLERS_DIR + "Haunt Lich.png",
		"silhouette": SILHOUETTES_DIR + "lich.png",
		"cell": Vector2i(21, 10),
		"stats": {"max_hp": 32, "max_en": 18, "atk": 5, "mak": 12, "defense": 6, "mef": 11, "agi": 6},
		"skills": [&"curse_ray", &"dark_siphon"],
		"affinity": BattleMath.Affinity.RESIST,
	},
	{
		"id": "matador", "name": "MATADOR", "tier": 3, "macca": 55,
		"picture": BATTLERS_DIR + "Fiend Matador.png",
		"silhouette": SILHOUETTES_DIR + "matador.png",
		"cell": Vector2i(3, 5),
		"stats": {"max_hp": 42, "max_en": 14, "atk": 12, "mak": 6, "defense": 8, "mef": 6, "agi": 13},
		"skills": [&"shadow_bite", &"primal_roar"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "mara", "name": "MARA", "tier": 4, "macca": 60,
		"picture": BATTLERS_DIR + "Tyrant Mara.png",
		"silhouette": SILHOUETTES_DIR + "mara.png",
		"cell": Vector2i(21, 5),
		"stats": {"max_hp": 50, "max_en": 16, "atk": 12, "mak": 9, "defense": 10, "mef": 8, "agi": 7},
		"skills": [&"hellfire", &"heavy_crush", &"howl"],
		"affinity": BattleMath.Affinity.RESIST,
	},
	{
		"id": "loki", "name": "LOKI", "tier": 4, "macca": 60,
		"picture": BATTLERS_DIR + "Vile Loki.png",
		"silhouette": SILHOUETTES_DIR + "loki.png",
		"cell": Vector2i(3, 15),
		"stats": {"max_hp": 42, "max_en": 16, "atk": 9, "mak": 12, "defense": 7, "mef": 9, "agi": 11},
		"skills": [&"frost_breath", &"spirit_bolt", &"shadow_bite"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "zouchouten", "name": "ZOUCHOUTEN", "tier": 4, "macca": 60,
		"picture": BATTLERS_DIR + "Kishin Zouchouten.png",
		"silhouette": SILHOUETTES_DIR + "zouchouten.png",
		"cell": Vector2i(21, 15),
		"stats": {"max_hp": 48, "max_en": 14, "atk": 13, "mak": 5, "defense": 11, "mef": 5, "agi": 6},
		"skills": [&"heavy_crush", &"primal_roar", &"fang_flurry"],
		"affinity": BattleMath.Affinity.RESIST,
	},
	{
		"id": "lakshmi", "name": "LAKSHMI", "tier": 4, "macca": 65,
		"picture": BATTLERS_DIR + "Megami Lakshmi.png",
		"silhouette": SILHOUETTES_DIR + "lakshmi.png",
		"cell": Vector2i(1, 1),
		"stats": {"max_hp": 38, "max_en": 20, "atk": 6, "mak": 12, "defense": 7, "mef": 11, "agi": 7},
		"skills": [&"dark_siphon", &"spirit_bolt", &"pixie_dust"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "hel", "name": "HEL", "tier": 4, "macca": 75,
		"picture": BATTLERS_DIR + "Reaper Hel.png",
		"silhouette": SILHOUETTES_DIR + "hel.png",
		"cell": Vector2i(23, 19),
		"stats": {"max_hp": 54, "max_en": 18, "atk": 11, "mak": 13, "defense": 10, "mef": 10, "agi": 7},
		"skills": [&"curse_ray", &"hellfire", &"dark_siphon"],
		"affinity": BattleMath.Affinity.RESIST,
	},
	{
		"id": "high_pixie", "name": "HIGH PIXIE", "tier": 3, "macca": 45,
		"picture": BATTLERS_DIR + "Fairy High Pixie.png",
		"silhouette": SILHOUETTES_DIR + "high_pixie.png",
		"cell": Vector2i(3, 1),
		"stats": {"max_hp": 30, "max_en": 16, "atk": 6, "mak": 10, "defense": 6, "mef": 8, "agi": 10},
		"skills": [&"spirit_wave", &"renew"],
		"affinity": BattleMath.Affinity.WEAK,
	},
	{
		"id": "nekomata", "name": "NEKOMATA", "tier": 3, "macca": 50,
		"picture": BATTLERS_DIR + "Beast Nekomata.png",
		"silhouette": SILHOUETTES_DIR + "nekomata.png",
		"cell": Vector2i(21, 1),
		"stats": {"max_hp": 34, "max_en": 13, "atk": 9, "mak": 8, "defense": 7, "mef": 7, "agi": 10},
		"skills": [&"twin_fang", &"venom_cloud"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "shuten_douji", "name": "SHUTEN-DOUJI", "tier": 4, "macca": 60,
		"picture": BATTLERS_DIR + "Brute Shuten-Douji.png",
		"silhouette": SILHOUETTES_DIR + "shuten_douji.png",
		"cell": Vector2i(5, 3),
		"stats": {"max_hp": 46, "max_en": 15, "atk": 12, "mak": 7, "defense": 10, "mef": 6, "agi": 7},
		"skills": [&"crushing_blow", &"war_cry"],
		"affinity": BattleMath.Affinity.RESIST,
	},
	{
		"id": "phoenix", "name": "PHOENIX", "tier": 4, "macca": 65,
		"picture": BATTLERS_DIR + "Avian Phoenix.png",
		"silhouette": SILHOUETTES_DIR + "phoenix.png",
		"cell": Vector2i(19, 3),
		"stats": {"max_hp": 40, "max_en": 18, "atk": 8, "mak": 12, "defense": 8, "mef": 11, "agi": 11},
		"skills": [&"thunder_call", &"renew"],
		"affinity": BattleMath.Affinity.WEAK,
	},
	{
		"id": "barong", "name": "BARONG", "tier": 3, "macca": 50,
		"picture": BATTLERS_DIR + "Avatar Barong.png",
		"silhouette": SILHOUETTES_DIR + "barong.png",
		"cell": Vector2i(11, 3),
		"stats": {"max_hp": 42, "max_en": 12, "atk": 10, "mak": 6, "defense": 10, "mef": 6, "agi": 6},
		"skills": [&"stone_grasp", &"war_cry"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "orobas", "name": "OROBAS", "tier": 3, "macca": 50,
		"picture": BATTLERS_DIR + "Fallen Orobas.png",
		"silhouette": SILHOUETTES_DIR + "orobas.png",
		"cell": Vector2i(13, 3),
		"stats": {"max_hp": 36, "max_en": 14, "atk": 8, "mak": 9, "defense": 8, "mef": 8, "agi": 9},
		"skills": [&"soul_pierce", &"life_drain"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "incubus", "name": "INCUBUS", "tier": 3, "macca": 50,
		"picture": BATTLERS_DIR + "Night Incubus.png",
		"silhouette": SILHOUETTES_DIR + "incubus.png",
		"cell": Vector2i(9, 7),
		"stats": {"max_hp": 32, "max_en": 16, "atk": 7, "mak": 11, "defense": 6, "mef": 9, "agi": 9},
		"skills": [&"mind_blast", &"dark_siphon"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "quetzalcoatl", "name": "QUETZALCOATL", "tier": 4, "macca": 65,
		"picture": BATTLERS_DIR + "Dragon Quetzalcoatl.png",
		"silhouette": SILHOUETTES_DIR + "quetzalcoatl.png",
		"cell": Vector2i(15, 7),
		"stats": {"max_hp": 48, "max_en": 16, "atk": 10, "mak": 11, "defense": 10, "mef": 9, "agi": 8},
		"skills": [&"thunder_call", &"spirit_wave"],
		"affinity": BattleMath.Affinity.RESIST,
	},
	{
		"id": "leviathan", "name": "LEVIATHAN", "tier": 5, "macca": 80,
		"picture": BATTLERS_DIR + "Drake Leviathan.png",
		"silhouette": SILHOUETTES_DIR + "leviathan.png",
		"cell": Vector2i(3, 9),
		"stats": {"max_hp": 56, "max_en": 18, "atk": 13, "mak": 10, "defense": 12, "mef": 9, "agi": 6},
		"skills": [&"crushing_blow", &"void_gaze", &"renew"],
		"affinity": BattleMath.Affinity.RESIST,
	},
	{
		"id": "vampire", "name": "VAMPIRE", "tier": 4, "macca": 60,
		"picture": BATTLERS_DIR + "Haunt Vampire.png",
		"silhouette": SILHOUETTES_DIR + "vampire.png",
		"cell": Vector2i(21, 9),
		"stats": {"max_hp": 38, "max_en": 17, "atk": 9, "mak": 12, "defense": 7, "mef": 10, "agi": 10},
		"skills": [&"life_drain", &"soul_pierce"],
		"affinity": BattleMath.Affinity.WEAK,
	},
	{
		"id": "white_rider", "name": "WHITE RIDER", "tier": 5, "macca": 85,
		"picture": BATTLERS_DIR + "Fiend White Rider.png",
		"silhouette": SILHOUETTES_DIR + "white_rider.png",
		"cell": Vector2i(3, 11),
		"stats": {"max_hp": 52, "max_en": 16, "atk": 14, "mak": 7, "defense": 11, "mef": 7, "agi": 13},
		"skills": [&"blade_dance", &"thunder_call"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "beelzebub", "name": "BEELZEBUB", "tier": 5, "macca": 95,
		"picture": BATTLERS_DIR + "Tyrant Beelzebub.png",
		"silhouette": SILHOUETTES_DIR + "beelzebub.png",
		"cell": Vector2i(19, 13),
		"stats": {"max_hp": 60, "max_en": 20, "atk": 14, "mak": 14, "defense": 12, "mef": 11, "agi": 8},
		"skills": [&"void_gaze", &"venom_cloud", &"renew"],
		"affinity": BattleMath.Affinity.RESIST,
	},
	{
		"id": "pazuzu", "name": "PAZUZU", "tier": 4, "macca": 65,
		"picture": BATTLERS_DIR + "Vile Pazuzu.png",
		"silhouette": SILHOUETTES_DIR + "pazuzu.png",
		"cell": Vector2i(3, 13),
		"stats": {"max_hp": 44, "max_en": 15, "atk": 10, "mak": 12, "defense": 9, "mef": 9, "agi": 12},
		"skills": [&"ember_touch", &"frost_lance"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "isis", "name": "ISIS", "tier": 4, "macca": 65,
		"picture": BATTLERS_DIR + "Megami Isis.png",
		"silhouette": SILHOUETTES_DIR + "isis.png",
		"cell": Vector2i(21, 13),
		"stats": {"max_hp": 42, "max_en": 20, "atk": 8, "mak": 13, "defense": 8, "mef": 12, "agi": 8},
		"skills": [&"renew", &"mind_blast"],
		"affinity": BattleMath.Affinity.NORMAL,
	},
	{
		"id": "izanami", "name": "IZANAMI", "tier": 5, "macca": 90,
		"picture": BATTLERS_DIR + "Reaper Izanami.png",
		"silhouette": SILHOUETTES_DIR + "izanami.png",
		"cell": Vector2i(12, 19),
		"stats": {"max_hp": 58, "max_en": 19, "atk": 12, "mak": 14, "defense": 11, "mef": 11, "agi": 7},
		"skills": [&"void_gaze", &"life_drain", &"venom_cloud"],
		"affinity": BattleMath.Affinity.RESIST,
	},
]


static func demon_by_id(id: String) -> Dictionary:
	for entry in DEMONS:
		if String(entry.id) == id:
			return entry
	for entry in human_defs():
		if String(entry.id) == id:
			return entry
	return {}


# ------------------------------------------------------------------ D-107 humanos

## D-107 (criador 2026-11-25): em cada estrato há 1 grupo só de humanos ("humanos normais, sem lore
## nem nada"). Humanos não se juntam a mazikim, rezam com PP como a Yoch (sem EN), usam PRAY, SANVERIM,
## NECHAMAH e CHEREV (id interno cherav) e NÃO podem ser absorvidos. Arte: o modelo de NPC humano do jogo (P15).
const HUMAN_COUNT := 3
## Modelos de NPC humano do jogo (SMT VX, Pictures): P15 é o "[PLACEHOLDER] HUMAN" do teste de dungeon,
## P10 a mulher de uniforme azul e P19 o homem de terno vermelho. Só mazikim são silhuetas: humanos usam a
## própria arte colorida, na batalha e no mapa (o grupo no mapa mostra o P15).
const HUMAN_SPRITES := [
	{"name": "HUMAN A", "picture": REF_PICTURES + "P15.png"},
	{"name": "HUMAN B", "picture": REF_PICTURES + "P10.png"},
	{"name": "HUMAN C", "picture": REF_PICTURES + "P19.png"},
]
const HUMAN_SKILLS: Array[StringName] = [&"pray", &"sanverim", &"nechamah", &"cherav"]
## Parte do SP esperado do estrato em cada atributo (sem EN: humanos rezam com PP).
const HUMAN_SHARES := {"max_hp": 0.38, "atk": 0.12, "mak": 0.16, "defense": 0.12, "mef": 0.10, "agi": 0.12}
const HUMAN_MACCA := 30

static var _human_cache: Array = []


static func human_group_id(stratum: int) -> String:
	return "humans_s%d" % stratum


static func is_human_id(id: String) -> bool:
	return id.begins_with("human")


## Grupo (humans_sN) a que um humano (human_sN_x) pertence.
static func human_group_of(id: String) -> String:
	if id.begins_with("humans_s"):
		return id
	if id.begins_with("human_s") and id.length() >= 8:
		return human_group_id(int(id.substr(7, 1)))
	return ""


static func human_unit_ids(stratum: int) -> Array[String]:
	var out: Array[String] = []
	for i in HUMAN_COUNT:
		out.append("human_s%d_%s" % [stratum, String("abc")[i]])
	return out


## Os 15 humanos (3 por estrato) e os 5 grupos que aparecem no mapa.
static func human_defs() -> Array:
	if not _human_cache.is_empty():
		return _human_cache
	for stratum in range(1, SurvivalStrata.COUNT + 1):
		var par := SurvivalStrata.par_sp(stratum)
		var stats := {"max_en": 0}
		var spent := 0
		for key in HUMAN_SHARES:
			if key == "max_hp": continue
			stats[key] = maxi(1, int(round(float(par) * float(HUMAN_SHARES[key]))))
			spent += int(stats[key])
		stats["max_hp"] = maxi(1, par - spent)
		var ids := human_unit_ids(stratum)
		for i in HUMAN_COUNT:
			var sprite: Dictionary = HUMAN_SPRITES[i]
			_human_cache.append({
				"id": ids[i], "name": String(sprite.name), "tier": stratum, "macca": HUMAN_MACCA,
				"picture": String(sprite.picture),
				"stats": stats.duplicate(), "skills": HUMAN_SKILLS, "affinity": BattleMath.Affinity.NORMAL,
				"human": true,
			})
		var lead: Dictionary = HUMAN_SPRITES[0]
		_human_cache.append({
			"id": human_group_id(stratum), "name": "HUMANS", "tier": stratum, "macca": 0,
			"picture": String(lead.picture),
			"stats": {}, "skills": [], "human_group": true,
		})
	return _human_cache


## Células possíveis para demônios: chão, fora do santuário e do ponto inicial.
## O labirinto é conectado (teste BFS), então qualquer uma é alcançável.
static func demon_cells(seed: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in MAZE.size():
		for x in MAZE[y].length():
			var c := Vector2i(x, y)
			if MAZE[y][x] == "." and not SAFE_ZONE.has_point(c) and c != Vector2i(12, 10):
				cells.append(c)
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(seed) % 2147483647
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Vector2i = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp
	return cells


## D-066: só os demônios do estrato, nas células do layout da semente.
static func stratum_enemy_defs(seed: int, stratum: int) -> Array:
	var cells: Dictionary = SurvivalStrata.layout(seed, stratum).demons
	var out: Array = []
	for id in SurvivalStrata.ids_for(stratum):
		var entry := demon_by_id(id)
		out.append({
			"id": id,
			"name": String(entry.name),
			"cell": cells[id],
			"picture": String(entry.silhouette),
			"warden": SurvivalStrata.warden_of(stratum) == id,
		})
	# D-107: o grupo de humanos do estrato.
	var group_id := human_group_id(stratum)
	var group := demon_by_id(group_id)
	out.append({
		"id": group_id,
		"name": String(group.name),
		"cell": cells[group_id],
		"picture": String(group.picture),
		"warden": false,
	})
	return out


static func overworld_enemy_defs(seed: int = -1) -> Array:
	var cells: Array[Vector2i] = []
	if seed >= 0:
		cells = demon_cells(seed)
	var out: Array = []
	for i in DEMONS.size():
		var entry: Dictionary = DEMONS[i]
		out.append({
			"id": String(entry.id),
			"name": String(entry.name),
			"cell": cells[i] if seed >= 0 and i < cells.size() else entry.cell,
			"picture": String(entry.silhouette),
		})
	return out


static func daily_seed() -> int:
	var d := Time.get_date_dict_from_system(true)
	return int(d.year) * 10000 + int(d.month) * 100 + int(d.day)


## Elite é determinístico por semente + id: mesmo seed, mesmo demônio elite.
## Guardiões nunca são elites (já têm o próprio reforço, D-066). OMEN 3 sobe a chance.
static func is_elite(seed: int, id: String, omen: int = 0) -> bool:
	if SurvivalStrata.is_warden(id) or is_human_id(id):
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = (absi(seed) + absi(id.hash()) * 13) % 2147483647
	return rng.randf() < (ELITE_CHANCE_OMEN if omen >= 3 else ELITE_CHANCE)


static func elite_affix(seed: int, id: String) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = (absi(seed) + absi(id.hash()) * 13 + 1) % 2147483647
	return String(ELITE_AFFIXES[rng.randi_range(0, ELITE_AFFIXES.size() - 1)])


## D-101: os inimigos acompanham o herói. A diferença entre o SP atual do Fallen e o SP esperado dele
## no estrato (a média dos inimigos do estrato) é somada ao inimigo, repartida pelos sete atributos
## na proporção que ele já tem; HP e EN entram como no SP. Com o herói no esperado, nada muda. Um
## inimigo nunca cai abaixo de metade do próprio SP nem de 1 em cada atributo (EN fica em 0 se era 0).
static func follow_hero(stats: UnitStats, hero_sp: int, par_sp: int) -> void:
	var own := stats.sp_value()
	var target := maxi(own / 2, own + hero_sp - par_sp)
	if target == own: return
	var keys := ["max_hp", "max_en", "atk", "mak", "defense", "mef", "agi"]
	var scale := float(target) / float(own)
	for k in keys:
		var base := int(stats.get(k))
		stats.set(k, 0 if base == 0 else maxi(1, int(round(float(base) * scale))))
	# O arredondamento pode errar alguns pontos: o HP absorve a diferença.
	stats.max_hp = maxi(1, stats.max_hp + target - stats.sp_value())


## D-070/D-066/D-075: aplica elite, guardião e OMEN aos status do inimigo.
## Retorna as habilidades extras e a afinidade (pode mudar com STONE).
static func empower(stats: UnitStats, id: String, seed: int, omen: int) -> Dictionary:
	var extra: Array[StringName] = []
	var affinity: int = int(demon_by_id(id).get("affinity", BattleMath.Affinity.NORMAL))
	var tag := ""
	if SurvivalStrata.is_warden(id):
		tag = "WARDEN"
		stats.max_hp = int(round(float(stats.max_hp) * 1.5))
		stats.atk += 2
		stats.mak += 2
		stats.defense += 2
		stats.mef += 2
		if omen >= 5:
			stats.atk += 3
			stats.mak += 3
	elif is_elite(seed, id, omen):
		var affix := elite_affix(seed, id)
		tag = "ELITE:" + affix
		stats.max_hp += 12
		stats.atk += 3
		stats.mak += 2
		stats.defense += 2
		match affix:
			"BRUTAL": stats.atk += 4
			"SWIFT": stats.agi += 5
			"STONE":
				stats.defense += 4
				affinity = BattleMath.Affinity.RESIST
			"BURNING": extra.append(&"ember_touch")
			"VAMPIRIC": extra.append(&"life_drain")
	if omen >= 1:
		stats.max_hp = int(round(float(stats.max_hp) * 1.15))
	return {"skills": extra, "affinity": affinity, "tag": tag}


static func battle_label(id: String, seed: int, omen: int) -> String:
	var def := demon_by_id(id)
	var base := String(def.get("name", id))
	if SurvivalStrata.is_warden(id):
		return "WARDEN " + base
	if is_elite(seed, id, omen):
		# D-119 (criador 2026-11-26): "apenas remove, deixe so os nomes deles normais".
		return base
	return base


## D-072: estoque da loja no estrato (2 fixos + 2 dos 3 rotativos).
static func shop_stock(seed: int, stratum: int) -> Array[String]:
	var out: Array[String] = []
	out.assign(SHOP_FIXED)
	var rot: Array = SHOP_ROTATING.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = (absi(seed) + stratum * 31_337) % 2147483647
	rot.remove_at(rng.randi_range(0, rot.size() - 1))
	for id in rot:
		out.append(String(id))
	return out


## Preço com inflação por estrato e descontos de relíquia (−25% / MAMMON −50%).
static func price(base: int, stratum: int, state: Dictionary) -> int:
	var p := float(base) * (1.0 + 0.15 * float(clampi(stratum, 1, 5) - 1))
	if SurvivalRelics.party_has(state, "mammon"):
		p *= 0.5
	elif SurvivalRelics.party_has(state, "shop_discount"):
		p *= 0.75
	return maxi(1, int(round(p)))


## Combate de teste: lutas com 1, 2 ou 3 demônios conforme o tier do encontrado.
## O demônio tocado no mapa sempre abre a luta; os reforços vêm da mesma lista.
static func encounter_for(id: String, defeated: Array = []) -> Array[String]:
	# D-107: tocar o grupo de humanos abre uma luta só com os 3 humanos do estrato.
	if id.begins_with("humans_s"):
		return human_unit_ids(int(id.substr(8, 1)))
	var found := -1
	for i in DEMONS.size():
		if String(DEMONS[i].id) == id:
			found = i
			break
	if found < 0:
		return []
	var lead: Dictionary = DEMONS[found]
	var tier := int(lead.tier)
	var count := 1
	if tier >= 3:
		count = 2
	if tier >= 5:
		count = 3
	# D-066: guardião sempre traz 2 escoltas.
	if SurvivalStrata.is_warden(id):
		count = 3
	var out: Array[String] = [id]
	# D-066: escoltas do MESMO estrato, ainda vivas (antes vinham de qualquer tier).
	var mates := SurvivalStrata.ids_for(SurvivalStrata.stratum_of(id))
	var start := mates.find(id)
	for step in range(1, mates.size()):
		if out.size() >= count:
			break
		var pick: String = mates[(start + step * 3) % mates.size()]
		if pick == id or out.has(pick) or defeated.has(pick) or SurvivalStrata.is_warden(pick):
			continue
		out.append(pick)
	return out


static func shop_item(id: String) -> Dictionary:
	for item in SHOP_ITEMS:
		if String(item.id) == id:
			return item
	return {}
