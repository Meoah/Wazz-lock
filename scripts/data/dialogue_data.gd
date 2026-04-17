class_name DialogueData

## Names
const NAME_MAIN_CHARACTER = "Jeremy"
const NAME_MOB_BOSS = "Mob Boss"
const NAME_BAIT_VENDOR = "Barry"
const UNKNOWN = "Unknown"

## Image Paths
const IMAGE_MOB_BOSS_DEFAULT = NodePath("res://assets/textures/ui/dialogue/character_portraits/mobboss.png")
const IMAGE_MAIN_CHARACTER_DEFAULT = NodePath("res://assets/textures/ui/dialogue/character_portraits/jeremy_portrait.png")

const DEFAULT_SPEAKER_PROFILE : Dictionary = {
	"beep_key": "dialogue_typewriter_beep",
	"beep_volume_linear": 0.2,
	"beep_base_pitch_scale": 1.0,
	"beep_pitch_jitter": 0.06,
	"beep_min_interval": 0.03,
	"beep_chance": 0.85,
	"beep_ignore_characters": " \n\t.,!?;:()[]{}\"'"
}

const SPEAKER_PROFILES : Dictionary = {
	NAME_MAIN_CHARACTER: {"beep_base_pitch_scale": 1.08},
	NAME_MOB_BOSS: {"beep_base_pitch_scale": 0.3, "beep_chance": 0.65}
}

# Getter functions.
static func get_dialogue(id : int) -> Dictionary : return DIALOGUE_ID.get(id, {})
static func get_profile(speaker_name : String) -> Dictionary:
	var key_name : String = speaker_name
	var profile : Dictionary = DEFAULT_SPEAKER_PROFILE.duplicate(true)
	
	if SPEAKER_PROFILES.has(key_name):
		for each_key in SPEAKER_PROFILES[key_name].keys():
			profile[each_key] = SPEAKER_PROFILES[key_name][each_key]
	
	return profile

# Table of Contents. When refrencing dialogue, use the ID accociated to locate the data.
const DIALOGUE_ID : Dictionary[int,Dictionary] = {
	0000 : DEBUG_EXAMPLE,
	0001 : INTRO,
	0002 : BAIT_SHOP,
	0102 : JERRY_LICENSE_1,
	0103 : JERRY_LICENSE_2,
	0104 : JERRY_LICENSE_3,
	0105 : CAMPFIRE_MEAL,
	0106 : CAMPFIRE_COOLDOWN,
	0107 : FOODSTALL_TEASER,
}

## Dialogue data
const KEY_NAME : String = "name"
const KEY_TEXT : String = "text"
const KEY_IMAGE_L : String = "image_left"
const KEY_IMAGE_R : String = "image_right"
const KEY_BGM : String = "bgm"
const KEY_SFX : String = "sfx"
const KEY_GOTO : String = "goto"
const KEY_OPTION_A : String = "option_a"
const KEY_OPTION_A_GOTO : String = "option_a_goto"
const KEY_OPTION_B : String = "option_b"
const KEY_OPTION_B_GOTO: String = "option_b_goto"
const KEY_PARAMETERS : String = "parameters"
const KEY_RETURN : String = "return"
const KEY_SIGNAL : String = "signal"

const PARAMETER_SIGNAL_ON_EXIT : String = "signal_on_exit"

# Format is as follows:
#	KEY_NAME : USE A CONST -> String
#	KEY_TEXT : String
#	KEY_IMAGE : USE A CONST -> NodePath
#	KEY_BGM : String
#	KEY_SFX : TODO audio class????
#	KEY_GOTO : int
#	KEY_OPTION_A : String
#	KEY_OPTION_A_GOTO : int
#	KEY_OPTION_B : String
#	KEY_OPTION_B_GOTO : int
#	KEY_PARAMETERS : Array[String]
#	KEY_RETURN : Bool
#	KEY_SIGNAL : Array[String]
#
# Valid parameters include:
#	PARAMETER_SIGNAL_ON_EXIT : Emits the signal on exit instead of during dialogue.
# 
# If return is true, it will end the dialogue there.
# Signal will attempt to emit these as signals from SignalBus

const DEBUG_EXAMPLE : Dictionary = {
	0000 : {
		KEY_RETURN : true,
		KEY_TEXT : "If you're seeing THIS at all, something really broke."
	},
	0001 : {
		KEY_TEXT : "If you're seeing this and not trying to debug, something has gone wrong."
	},
	0002 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_BGM : "res://assets/audio/bgm/the_frog_is_talking.ogg",
		KEY_TEXT : "Yo kid, where's my money?",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_PARAMETERS : ["shaking", "emote_rage"]
	},
	0003 : {
		KEY_NAME : NAME_MAIN_CHARACTER,
		KEY_TEXT : "Oh shit, do I pay him??",
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_OPTION_A : "Yes",
		KEY_OPTION_A_GOTO : 0005,
		KEY_OPTION_B : "No (This is a bad idea)",
		KEY_OPTION_B_GOTO : 0004,
	},
	0004 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "A wise guy I see. Time to swim with the fishes.",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_RETURN : true,
		KEY_PARAMETERS : [PARAMETER_SIGNAL_ON_EXIT],
		KEY_SIGNAL : ["player_dies"]
	},
	0005 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "That's right kid, cough up the dough.",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_RETURN : true,
		KEY_PARAMETERS : [PARAMETER_SIGNAL_ON_EXIT],
		KEY_SIGNAL : ["run_intro"]
	}
}


const INTRO : Dictionary = {
	0001 : {
		KEY_NAME : UNKNOWN,
		KEY_TEXT : "*Knock Knock Knock*",
	},
	0002 : {
		KEY_NAME : NAME_MAIN_CHARACTER,
		KEY_TEXT : "H- Hello? Is this where I can purchase a fishing license?",
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT
	},
	0003 : {
		KEY_NAME : UNKNOWN,
		KEY_TEXT : "You come to me... ",
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT
	},
	0004 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_BGM : "res://assets/audio/bgm/the_frog_is_talking.ogg",
		KEY_TEXT : "On this beautiful sunny day...",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
	},
	0005 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "Asking for a fishing license?",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
	},
	0006 : {
		KEY_NAME : NAME_MAIN_CHARACTER,
		KEY_TEXT : "Oh, am I in the wrong place?",
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
	},
	0007 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "No we got 'em here.",
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
	},
	0008 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "It'll just cost ya...",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0009 : {
		KEY_NAME : NAME_MAIN_CHARACTER,
		KEY_TEXT : "Oh Great! How much does it cost?",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0010 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "For a small fish in a big pond like yourself?",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0011 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "Five Hundred",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0012 : {
		KEY_NAME : NAME_MAIN_CHARACTER,
		KEY_TEXT : "FIVE HUNDRED!?!?",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0013 : {
		KEY_NAME : NAME_MAIN_CHARACTER,
		KEY_TEXT : "I don't have that kind of money...",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0014 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "It's alright little guppy...",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0015 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "We can loan ya the dough...",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0016 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "Just dont miss a payment...",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0017 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "Or it'll be you swimming with the fishes...",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0018 : {
		KEY_NAME : NAME_MAIN_CHARACTER,
		KEY_TEXT : "Oh... I see.",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0019 : {
		KEY_NAME : NAME_MAIN_CHARACTER,
		KEY_TEXT : "Well... Im confident enough to pull through!",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0020 : {
		KEY_NAME : NAME_MAIN_CHARACTER,
		KEY_TEXT : "There should be plenty of fish in the sea, right!",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0021 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "Sure kid...",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
	},
	0022 : {
		KEY_NAME : NAME_MOB_BOSS,
		KEY_TEXT : "Just don't miss a payment",
		KEY_IMAGE_R : IMAGE_MOB_BOSS_DEFAULT,
		KEY_IMAGE_L : IMAGE_MAIN_CHARACTER_DEFAULT,
		KEY_RETURN : true,
		KEY_PARAMETERS : [PARAMETER_SIGNAL_ON_EXIT],
		KEY_SIGNAL : ["run_intro"]
	}
}



const BAIT_SHOP : Dictionary = {
	0000 : {
		KEY_RETURN : true,
		KEY_TEXT : "If you're seeing THIS at all, something really broke."
	},
	0001 : {
		KEY_NAME : NAME_BAIT_VENDOR,
		KEY_TEXT : "'sup man. I found some bait. Gonna cost ya though.",
		KEY_RETURN : true,
		KEY_PARAMETERS : [PARAMETER_SIGNAL_ON_EXIT],
		KEY_SIGNAL : ["start_bait_shop"]
	},
}

const JERRY_LICENSE_1 : Dictionary = {
	0001 : {
		KEY_NAME : "Felix",
		KEY_TEXT : "Hey Jeremy!\nWe'll make it through this, just gotta get enough money to pay the boss right?"
	},
	0002 : {
		KEY_NAME : "Felix",
		KEY_TEXT : "Just keep going what you do best and fish! I heard that the further out you cast, the higher value the fish, so aim far!"
	},
	0003 : {
		KEY_NAME : "Felix",
		KEY_TEXT : "Don't forget to rest as well. Can't exactly fish when you can't even stay awake right? Have a break, a meal, or just go to sleep when you're tired, alright?",
		KEY_RETURN : true
	}
}

const JERRY_LICENSE_2 : Dictionary = {
	0001 : {
		KEY_NAME : "Felix",
		KEY_TEXT : "Another overpriced license.. Oh well, we'll make it through as always.",
	},
	0002 : {
		KEY_NAME : "Felix",
		KEY_TEXT : "Luckily we brought our new gadget along. Your lure shoots so far now!"
	},
	0003 : {
		KEY_NAME : "Felix",
		KEY_TEXT : "That guy came along with us as well.. said he got some special bait you can try. Shady guy.. If you don't want to buy from him, you could always.. uh.. dig and scavange through..",
	},
	0004 : {
		KEY_NAME : "Felix",
		KEY_TEXT : "..THAT.",
	},
	0005 : {
		KEY_NAME : "Felix",
		KEY_TEXT : "I'm sure there's some worms in there if you're lucky.",
		KEY_RETURN : true
	}
}

const JERRY_LICENSE_3 : Dictionary = {
	0001 : {
		KEY_NAME : "Felix",
		KEY_TEXT : "There's something in the waters.. I guess that's why they sent us here. Our sources tells us that our target's fond of this 'Magic Bait'.. Maybe that weird guy has some for sale?",
		KEY_RETURN : true
	}
}

const CAMPFIRE_MEAL : Dictionary = {
	0001 : {
		KEY_NAME : "Campfire",
		KEY_TEXT : "Jeremy has a quick meal. +25 stamina. 30 minutes pass.",
		KEY_RETURN : true
	}
}

const CAMPFIRE_COOLDOWN : Dictionary = {
	0001 : {
		KEY_NAME : "Campfire",
		KEY_TEXT : "Still too full for another meal. Come back later.",
		KEY_RETURN : true
	}
}

const FOODSTALL_TEASER : Dictionary = {
	0001 : {
		KEY_NAME : "Food Stall",
		KEY_TEXT : "Yo. Sorry pal, but I ain't got no ingredents atta moment. Come back later, ya hear? (Not available in the demo, sorry.)",
		KEY_RETURN : true
	}
}
