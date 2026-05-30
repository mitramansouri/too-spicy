enum ButtonType {EASY_MODE, BLOCKED_ART, HOW_TO_PLAY, OPTIONS, CREDITS, QUIT}

const ButtonName = {
	ButtonType.EASY_MODE: "Play Template", 
	ButtonType.BLOCKED_ART: "Blocked Art", 
	ButtonType.HOW_TO_PLAY: "How to Play", 
	ButtonType.OPTIONS: "Options", 
	ButtonType.CREDITS: "Credits",
	ButtonType.QUIT: "Quit"
}

const SPICE_SALT := "salt"
const SPICE_PEPPER := "pepper"
const SPICE_PAPRIKA := "paprika"
const SPICE_TURMERIC := "turmeric"
const SPICE_CINNAMON := "cinnamon"
const SPICE_HERBS := "herbs"
const SPICE_BLUEBERRY := "blueberry"
const SPICE_GARLIC := "garlic"
const SPICE_CHILI := "chili"
const SPICE_LIME := "lime"

const spices := [
	{
		"id": SPICE_SALT,
		"name": "Salt",
		"color": Color.WHITE
	},
	{
		"id": SPICE_PEPPER,
		"name": "Pepper",
		"color": Color.BLACK
	},
	{
		"id": SPICE_PAPRIKA,
		"name": "Paprika",
		"color": Color.RED
	},
	{
		"id": SPICE_TURMERIC,
		"name": "Turmeric",
		"color": Color.YELLOW
	},
	{
		"id": SPICE_CINNAMON,
		"name": "Cinnamon",
		"color": Color(0.45, 0.25, 0.1)
	},
	{
		"id": SPICE_HERBS,
		"name": "Herbs",
		"color": Color.GREEN
	},
	{
		"id": SPICE_BLUEBERRY,
		"name": "Blueberry Powder",
		"color": Color(0.0, 0.45, 1.0)
	},
	{
		"id": SPICE_GARLIC,
		"name": "Garlic Powder",
		"color": Color(0.96, 0.92, 0.70)
	},
	{
		"id": SPICE_CHILI,
		"name": "Chili Powder",
		"color": Color(1.0, 0.45, 0.0)
	},
	{
	"id": SPICE_LIME,
	"name": "Lime Zest",
	"color": Color(0.62, 0.76, 0.00)
	}
]

const spice_by_id := {
	SPICE_SALT: {
		"id": SPICE_SALT,
		"name": "Salt",
		"color": Color.WHITE
	},
	SPICE_PEPPER: {
		"id": SPICE_PEPPER,
		"name": "Pepper",
		"color": Color.BLACK
	},
	SPICE_PAPRIKA: {
		"id": SPICE_PAPRIKA,
		"name": "Paprika",
		"color": Color.RED
	},
	SPICE_TURMERIC: {
		"id": SPICE_TURMERIC,
		"name": "Turmeric",
		"color": Color.YELLOW
	},
	SPICE_CINNAMON: {
		"id": SPICE_CINNAMON,
		"name": "Cinnamon",
		"color": Color(0.45, 0.25, 0.1)
	},
	SPICE_HERBS: {
		"id": SPICE_HERBS,
		"name": "Herbs",
		"color": Color.GREEN
	},
	SPICE_BLUEBERRY: {
		"id": SPICE_BLUEBERRY,
		"name": "Blueberry Powder",
		"color": Color(0.0, 0.45, 1.0)
	},
	SPICE_GARLIC: {
	"id": SPICE_GARLIC,
	"name": "Garlic Powder",
	"color": Color(0.96, 0.92, 0.70)
	},
	SPICE_CHILI: {
	"id": SPICE_CHILI,
	"name": "Chili Powder",
	"color": Color(1.0, 0.45, 0.0)
	},
	SPICE_LIME: {
	"id": SPICE_LIME,
	"name": "Lime Zest",
	"color": Color(0.62, 0.76, 0.00)
	}
}

const TEMPLATE_WHALE := "whale"
const TEMPLATE_CUPCAKE := "cupcake"
const TEMPLATE_CANDLE := "candle"
const TEMPLATE_TURTLE := "small_turtle"

const template_order := [
	TEMPLATE_CUPCAKE,
	TEMPLATE_CANDLE,
	TEMPLATE_TURTLE,
	TEMPLATE_WHALE
]

const templates := {
	TEMPLATE_CUPCAKE: {
		"id": TEMPLATE_CUPCAKE,
		"name": "Cupcake",
		"description": "A small beginner cupcake with frosting and a wrapper.",
		"grid_width": 9,
		"grid_height": 18,
		"cell_size": 34,
		"bucket_width": 2,
		"bucket_height": 1,
		"spices_per_sprinkle": 2,
		"max_falling_spices": 5,
		"fall_interval": 0.45,
		"spawn_interval": 0.75,
		"allowed_spices": [
			SPICE_PAPRIKA,
			SPICE_SALT,
			SPICE_CINNAMON
		],
		"sections": {
			1: "Frosting",
			2: "Sprinkle",
			3: "Wrapper"
		},
		"section_spices": {
			1: SPICE_PAPRIKA,
			2: SPICE_SALT,
			3: SPICE_CINNAMON
		},
		"preview_colors": {
			1: Color.RED,
			2: Color.WHITE,
			3: Color(0.45, 0.25, 0.1)
		},
		"shape": [
	[0, 0, 1, 1, 1, 0, 0],
	[0, 1, 1, 2, 1, 1, 0],
	[1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1],
	[0, 3, 3, 3, 3, 3, 0],
	[0, 3, 3, 3, 3, 3, 0],
	[0, 3, 3, 3, 3, 3, 0]
]
	},

TEMPLATE_CANDLE: {
	"id": TEMPLATE_CANDLE,
	"name": "Mushroom",
	"description": "A cute simple mushroom without the black outline.",
	"grid_width": 12,
	"grid_height": 18,
	"cell_size": 28,
	"bucket_width": 2,
	"bucket_height": 1,
	"spices_per_sprinkle": 2,
	"max_falling_spices": 8,
	"fall_interval": 0.45,
	"spawn_interval": 0.75,
	"allowed_spices": [
		SPICE_PAPRIKA,
		SPICE_SALT,
		SPICE_GARLIC
	],
	"sections": {
		1: "Cap",
		2: "Spots",
		3: "Stem"
	},
	"section_spices": {
		1: SPICE_PAPRIKA,
		2: SPICE_SALT,
		3: SPICE_GARLIC
	},
	"preview_colors": {
		1: Color.RED,
		2: Color.WHITE,
		3: Color(0.96, 0.92, 0.70)
	},
	"shape": [
		[0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0],
		[0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
		[0, 0, 1, 1, 2, 1, 1, 2, 1, 1, 0, 0],
		[0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
		[1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1],
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		[0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
		[0, 0, 1, 1, 1, 3, 3, 1, 1, 1, 0, 0],
		[0, 0, 0, 3, 3, 3, 3, 3, 3, 0, 0, 0],
		[0, 0, 0, 3, 3, 3, 3, 3, 3, 0, 0, 0],
		[0, 0, 0, 3, 3, 3, 3, 3, 3, 0, 0, 0]
	]
},
TEMPLATE_TURTLE: {
	"id": TEMPLATE_TURTLE,
	"name": "Small Turtle",
	"description": "A tiny simple turtle with a dark shell and light body.",
	"grid_width": 11,
	"grid_height": 16,
	"cell_size": 36,
	"bucket_width": 2,
	"bucket_height": 1,
	"spices_per_sprinkle": 3,
	"max_falling_spices": 8,
	"fall_interval": 0.45,
	"spawn_interval": 0.8,
	"allowed_spices": [
		SPICE_HERBS,
		SPICE_LIME,
		SPICE_PEPPER
	],
	"sections": {
		1: "Shell",
		2: "Body",
		3: "Eye"
	},
	"section_spices": {
		1: SPICE_HERBS,
		2: SPICE_LIME,
		3: SPICE_PEPPER
	},
	"preview_colors": {
		1: Color.GREEN,
		2: Color(0.62, 0.76, 0.00),
		3: Color.BLACK
	},
	"shape": [
		[0, 0, 0, 1, 1, 0, 0, 2, 2, 0],
		[0, 1, 1, 1, 1, 1, 0, 2, 3, 2],
		[0, 1, 1, 1, 1, 1, 1, 2, 2, 2],
		[2, 1, 1, 1, 1, 1, 1, 2, 2, 0],
		[0, 2, 2, 2, 2, 2, 2, 0, 0, 0],
		[0, 2, 2, 0, 0, 2, 2, 0, 0, 0]
	]
},

	TEMPLATE_WHALE: {
		"id": TEMPLATE_WHALE,
		"name": "Whale",
		"description": "A simple three-spice blue whale.",
		"grid_width": 14,
		"grid_height": 20,
		"cell_size": 30,
		"bucket_width": 2,
		"bucket_height": 1,
		"spices_per_sprinkle": 3,
		"max_falling_spices": 8,
		"fall_interval": 0.45,
		"spawn_interval": 0.75,
		"allowed_spices": [
			SPICE_BLUEBERRY,
			SPICE_SALT,
			SPICE_PEPPER
		],
		"sections": {
			1: "Outline",
			2: "Body",
			3: "White Details"
		},
		"section_spices": {
			1: SPICE_PEPPER,
			2: SPICE_BLUEBERRY,
			3: SPICE_SALT
		},
		"preview_colors": {
			1: Color.BLACK,
			2: Color(0.0, 0.45, 1.0),
			3: Color.WHITE
		},
		"shape": [
			[0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0],
			[0, 0, 1, 2, 2, 2, 2, 2, 1, 0, 0, 1, 0, 1],
			[0, 1, 2, 2, 2, 2, 2, 2, 2, 1, 0, 2, 1, 2],
			[1, 2, 2, 3, 1, 2, 2, 2, 2, 2, 1, 2, 2, 2],
			[1, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2],
			[1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1],
			[1, 3, 3, 3, 2, 2, 3, 3, 2, 2, 2, 1, 0, 0],
			[0, 1, 3, 3, 3, 1, 3, 3, 1, 1, 1, 0, 0, 0],
			[0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0]
		]
	}
}


static func get_template(template_id: String) -> Dictionary:
	if templates.has(template_id):
		return templates[template_id]

	return templates[TEMPLATE_CUPCAKE]


static func get_spices_for_ids(spice_ids: Array) -> Array:
	var result := []

	for spice_id in spice_ids:
		if spice_by_id.has(spice_id):
			result.append(spice_by_id[spice_id])

	return result
