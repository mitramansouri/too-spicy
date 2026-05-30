enum ButtonType {EASY_MODE, BLOCKED_ART, HOW_TO_PLAY, OPTIONS, CREDITS, QUIT}

const ButtonName = {
	ButtonType.EASY_MODE: "Easy Mode", 
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
	}
}

const TEMPLATE_MUSHROOM := "mushroom"

const template_order := [
	TEMPLATE_MUSHROOM
]

const templates := {
	TEMPLATE_MUSHROOM: {
		"id": TEMPLATE_MUSHROOM,
		"name": "Mushroom",
		"description": "A very simple three-spice mushroom.",
		"grid_width": 9,
		"grid_height": 18,
		"cell_size": 34,
		"bucket_width": 2,
		"bucket_height": 1,
		"spices_per_sprinkle": 2,
		"max_falling_spices": 5,
		"fall_interval": 0.65,
		"spawn_interval": 0.6,
		"allowed_spices": [
			SPICE_PAPRIKA,
			SPICE_SALT,
			SPICE_CINNAMON
		],
		"sections": {
			1: "Cap",
			2: "Spots",
			3: "Stem"
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
			[0, 0, 1, 1, 1, 1, 1, 0, 0],
			[0, 1, 1, 1, 2, 1, 1, 1, 0],
			[1, 1, 2, 1, 1, 1, 2, 1, 1],
			[1, 1, 1, 1, 1, 1, 1, 1, 1],
			[0, 1, 1, 1, 1, 1, 1, 1, 0],
			[0, 0, 0, 3, 3, 3, 0, 0, 0],
			[0, 0, 0, 3, 3, 3, 0, 0, 0],
			[0, 0, 0, 0, 3, 0, 0, 0, 0]
		]
	}
}


static func get_template(template_id: String) -> Dictionary:
	if templates.has(template_id):
		return templates[template_id]

	return templates[TEMPLATE_MUSHROOM]


static func get_spices_for_ids(spice_ids: Array) -> Array:
	var result := []

	for spice_id in spice_ids:
		if spice_by_id.has(spice_id):
			result.append(spice_by_id[spice_id])

	return result
