/mob
	density = 1
	plane = MOB_PLANE

	appearance_flags = PIXEL_SCALE
	animate_movement = 2
	movable_flags = MOVABLE_FLAG_PROXMOVE

	virtual_mob = /mob/observer/virtual/mob

	var/list/client_images = list() // List of images applied to/removed from the client on login/logout
	var/datum/mind/mind

	var/lastKnownIP = null
	var/computer_id = null

	var/stat = 0 //Whether a mob is alive or dead. TODO: Move this to living - Nodrak

	var/obj/screen/hands = null
	var/obj/screen/pullin = null
	var/obj/screen/purged = null
	var/obj/screen/internals = null
	var/obj/screen/oxygen = null
	var/obj/screen/i_select = null
	var/obj/screen/m_select = null
	var/obj/screen/toxin = null
	var/obj/screen/fire = null
	var/obj/screen/bodytemp = null
	var/obj/screen/healths = null
	var/obj/screen/throw_icon = null
	var/obj/screen/nutrition_icon = null
	var/obj/screen/hydration_icon = null
	var/obj/screen/pressure = null
	var/obj/screen/pain = null
	var/obj/screen/gun/item/item_use_icon = null
	var/obj/screen/gun/radio/radio_use_icon = null
	var/obj/screen/gun/move/gun_move_icon = null
	var/obj/screen/gun/run/gun_run_icon = null
	var/obj/screen/gun/mode/gun_setting_icon = null
	var/obj/screen/stamina_icon = null
	var/obj/screen/kick_icon = null
	var/obj/screen/jump_icon = null
	var/obj/screen/noise = null
	var/obj/screen/fixeye = null
	var/obj/screen/rest = null
	var/obj/screen/combat_icon = null
	var/obj/screen/combat_intent_icon = null
	var/obj/screen/atk_intent_icon = null
	var/obj/screen/surrender = null
	var/obj/screen/happiness_icon = null
	var/obj/screen/wield_icon = null

	var/obj/screen/noise2 = null//unused
	var/obj/screen/noise3 = null//unused

	var/obj/screen/movable/ability_master/ability_master = null

	/*A bunch of this stuff really needs to go under their own defines instead of being globally attached to mob.
	A variable should only be globally attached to turfs/objects/whatever, when it is in fact needed as such.
	The current method unnecessarily clusters up the variable list, especially for humans (although rearranging won't really clean it up a lot but the difference will be noticable for other mobs).
	I'll make some notes on where certain variable defines should probably go.
	Changing this around would probably require a good look-over the pre-existing code.
	*/
	var/obj/screen/zone_sel/zone_sel = null

	var/use_me = 1 //Allows all mobs to use the me verb by default, will have to manually specify they cannot
	var/damageoverlaytemp = 0
	var/obj/machinery/machine = null
	var/poll_answer = 0.0
	var/sdisabilities = 0	//Carbon
	var/disabilities = 0	//Carbon

	var/atom/movable/pulling = null
	var/other_mobs = null
	var/next_move = null
	var/transforming = null	//Carbon
	var/hand = null
	var/real_name = null

	var/bhunger = 0			//Carbon

	var/druggy = 0			//Carbon
	var/confused = 0		//Carbon
	var/sleeping = 0		//Carbon
	var/resting = 0			//Carbon
	//var/in_trench = 0       //For /mob/living/Bump stuff.
	var/doing_something = FALSE
	var/lying = 0
	var/lying_prev = 0
	var/commiting_trench_kiss = 0
	var/canmove = 1
	//Allows mobs to move through dense areas without restriction. For instance, in space or out of holder objects.
	var/incorporeal_move = 0 //0 is off, 1 is normal, 2 is for ninjas.
	var/unacidable = 0
	var/list/pinned = list()            // List of things pinning this creature to walls (see living_defense.dm)
	var/list/embedded = list()          // Embedded items, since simple mobs don't have organs.
	var/list/languages = list()         // For speaking/listening.
	var/species_language = null			// For species who want reset to use a specified default.
	var/only_species_language  = 0		// For species who can only speak their default and no other languages. Does not effect understanding.
	var/list/speak_emote = list("says") // Verbs used when speaking. Defaults to 'say' if speak_emote is null.
	var/emote_type = 1		// Define emote default type, 1 for seen emotes, 2 for heard emotes
	var/facing_dir = null   // Used for the ancient art of moonwalking.

	var/name_archive //For admin things like possession

	var/timeofdeath = 0

	var/bodytemperature = 310.055	//98.7 F
	var/default_pixel_x = 0
	var/default_pixel_y = 0

	var/music_lastplayed = "null"

	var/a_intent = I_HELP//Living
	var/defense_intent = I_DODGE//Living. For dodging and parrying.
	var/m_intent = "run"//Living
	var/atk_intent = I_FEINT//Human
	var/middle_click_intent = null //For doing different things with middle click.
	var/combat_mode = 0//Living
	var/using_alt_hud = 0 //For the lunahud.
	var/silent = null 		//Living. Can't talk. Value goes down every life proc.
	var/obj/buckled = null//Living
	var/obj/item/l_hand = null//Living
	var/obj/item/r_hand = null//Living
	var/obj/item/back = null//Human/Monkey
	var/obj/item/storage/s_active = null//Carbon
	var/obj/item/clothing/mask/wear_mask = null//Carbon
	var/obj/item/clothing/chest_holster = null//For your chest holster.
	var/age = 30		//Player's age (pure fluff)


//	var/datum/hud/hud_used = null

	var/list/grabbed_by = list()

	var/in_throw_mode = 0

	var/inertia_dir = 0


//	var/job = null//Living

	var/can_pull_size = ITEM_SIZE_NO_CONTAINER // Maximum w_class the mob can pull.
	var/can_pull_mobs = MOB_PULL_SAME          // Whether or not the mob can pull other mobs.

	var/datum/dna/dna = null//Carbon
	var/list/active_genes=list()
	var/list/mutations = list() //Carbon -- Doohl
	//see: setup.dm for list of mutations

	var/radiation = 0.0//Carbon

	var/voice_name = "unidentifiable voice"

	var/faction = "neutral" //Used for checking whether hostile simple animals will attack you, possibly more stuff later
	var/blinded = null
	var/ear_deaf = null		//Carbon

//The last mob/living/carbon to push/drag/grab this mob (mostly used by slimes friend recognition)
	var/mob/living/carbon/LAssailant = null

	mouse_drag_pointer = MOUSE_ACTIVE_POINTER

	var/update_icon = 1 //Set to 1 to trigger update_icons() at the next life() call

	var/status_flags = CANSTUN|CANWEAKEN|CANPARALYSE|CANPUSH	//bitflags defining which status effects can be inflicted (replaces canweaken, canstun, etc)

	var/area/lastarea = null

	var/digitalcamo = 0 // Can they be tracked by the AI?

	var/obj/control_object //Used by admins to possess objects. All mobs should have this var

	//Whether or not mobs can understand other mobtypes. These stay in /mob so that ghosts can hear everything.
	var/universal_speak = 0 // Set to 1 to enable the mob to speak to everyone -- TLE
	var/universal_understand = 0 // Set to 1 to enable the mob to understand everyone, not necessarily speak

	//If set, indicates that the client "belonging" to this (clientless) mob is currently controlling some other mob
	//so don't treat them as being SSD even though their client var is null.
	var/mob/teleop = null

	var/turf/listed_turf = null  	//the current turf being examined in the stat panel
	var/list/shouldnt_see = list()	//list of objects that this mob shouldn't see in the stat panel. this silliness is needed because of AI alt+click and cult blood runes

	var/mob_size = MOB_MEDIUM
	var/throw_multiplier = 1

	var/paralysis = 0
	var/stunned = 0
	var/weakened = 0
	var/drowsyness = 0.0//Carbon

	var/memory = ""
	var/flavor_text = ""

	var/nabbing = 0  // Whether a creature with a CAN_NAB tag is grabbing normally or in nab mode.

	var/has_limbs = 1//For crawling

	var/scrambling = 0//For crawling.

	var/crouching = FALSE //For crouching.

	var/emote_cd = 0//Emote cooldown.

	var/communing_with_dead = FALSE //Let's you talk in dsay without being an admin, or dead.

	var/warfare_faction = null //The warfare faction they're apart of. Used by humans and ghosts primarily. Placed all the way up here so that when you logout as something other than a human you don't get team switched.

	var/breathe_tick = 0 // Used for gas mask delays.

	var/datum/backstory/backstory = null // The backstory of the mob, if any. Lets us check if they have a specific backstory, or some other bs if i need it.