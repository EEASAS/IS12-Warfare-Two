/*
	Click code cleanup
	~Sayu
*/

// 1 decisecond click delay (above and beyond mob/next_move)
/mob/var/next_click = 0

/*
	Before anything else, defer these calls to a per-mobtype handler.  This allows us to
	remove istype() spaghetti code, but requires the addition of other handler procs to simplify it.

	Alternately, you could hardcode every mob's variation in a flat ClickOn() proc; however,
	that's a lot of code duplication and is hard to maintain.

	Note that this proc can be overridden, and is in the case of screen objects.
*/

/atom/Click(var/location, var/control, var/params) // This is their reaction to being clicked on (standard proc)
	var/datum/click_handler/click_handler = usr.GetClickHandler()
	click_handler.OnClick(src, params)

/atom/DblClick(var/location, var/control, var/params)
	var/datum/click_handler/click_handler = usr.GetClickHandler()
	click_handler.OnDblClick(src, params)

/*
	Standard mob ClickOn()
	Handles exceptions: middle click, modified clicks, mech actions

	After that, mostly just check your state, check whether you're holding an item,
	check whether you're adjacent to the target, then pass off the click to whoever
	is recieving it.
	The most common are:
	* mob/UnarmedAttack(atom,adjacent) - used here only when adjacent, with no item in hand; in the case of humans, checks gloves
	* atom/attackby(item,user) - used only when adjacent
	* item/afterattack(atom,user,adjacent,params) - used both ranged and adjacent
	* mob/RangedAttack(atom,params) - used only ranged, only used for tk and laser eyes but could be changed
*/
/mob/proc/ClickOn(var/atom/A, var/params)

	if(world.time <= next_click) // Hard check, before anything else, to avoid crashing
		return

	next_click = world.time + 1

	var/list/L = params2list(params) //convert params into a list
	var/dragged = L["drag"] //grab what mouse button they are dragging with, if any.
	if(dragged && !L[dragged]) //check to ensure they aren't using drag clicks to aimbot
		return //if they are dragging, and they clicked with a different mouse button, reject the click as it will always go the atom they are currently dragging, even if out of view and not under the mouse

	var/list/modifiers = params2list(params)
	if(modifiers["shift"] && modifiers["ctrl"])
		CtrlShiftClickOn(A)
		return 1
	if(modifiers["ctrl"] && modifiers["alt"])
		CtrlAltClickOn(A)
		return 1
	if(modifiers["middle"] && modifiers["shift"])
		ShiftMiddleClickOn(A)
		return 1
	if(modifiers["shift"] && modifiers["right"])
		ShiftRightClickOn(A)
		return 1
	if(modifiers["alt"] && modifiers["right"])
		AltRightClickOn(A)
		return 1
	if(modifiers["shift"])
		ShiftClickOn(A)
		return 0
	if(modifiers["alt"]) // alt and alt-gr (rightalt)
		AltClickOn(A)
		return 1
	if(modifiers["ctrl"])
		CtrlClickOn(A)
		return 1

	if(!canClick()) // in the year 2000...
		return

	if(lying && istype(A, /turf/) && !istype(A, /turf/space/))
		if(!get_active_hand())//Should make getting up stairs easier.
			scramble(A)

	if(stat || paralysis || stunned) //|| weakened)
		return

	face_atom(A) // change direction to face what you clicked on

	if(modifiers["middle"])//This goes below everything else because of how middle click is used.
		MiddleClickOn(A)
		return

	if(modifiers["right"])
		RightClickOn(A)
		return

	if(istype(loc, /obj/mecha))
		if(!locate(/turf) in list(A, A.loc)) // Prevents inventory from being drilled
			return
		var/obj/mecha/M = loc
		return M.click_action(A, src)

	if(restrained())
		setClickCooldown(10)
		RestrainedClickOn(A)
		return 1

	if(in_throw_mode)
		if(isturf(A) || isturf(A.loc))
			throw_item(A)
			trigger_aiming(TARGET_CAN_CLICK)
			return 1
		throw_mode_off()

	var/obj/item/W = get_active_hand()

	if(W == A) // Handle attack_self
		W.attack_self(src)
		trigger_aiming(TARGET_CAN_CLICK)
		if(hand)
			update_inv_l_hand(0)
		else
			update_inv_r_hand(0)
		return 1

	//Atoms on your person
	// A is your location but is not a turf; or is on you (backpack); or is on something on you (box in backpack); sdepth is needed here because contents depth does not equate inventory storage depth.
	var/sdepth = A.storage_depth(src)
	if((!isturf(A) && A == loc) || (sdepth != -1 && sdepth <= 1))
		if(W)
			var/resolved = W.resolve_attackby(A, src, params, FALSE)
			if(!resolved && A && W)
				W.afterattack(A, src, 1, params) // 1 indicates adjacency
		else
			if(ismob(A)) // No instant mob attacking
				setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
			UnarmedAttack(A, 1)

		trigger_aiming(TARGET_CAN_CLICK)
		return 1

	if(!isturf(loc)) // This is going to stop you from telekinesing from inside a closet, but I don't shed many tears for that
		return

	//Atoms on turfs (not on your person)
	// A is a turf or is on a turf, or in something on a turf (pen in a box); but not something in something on a turf (pen in a box in a backpack)
	sdepth = A.storage_depth_turf()
	if(isturf(A) || isturf(A.loc) || (sdepth != -1 && sdepth <= 1))
		if(A.Adjacent(src)) // see adjacent.dm
			if(W)
				// Return 1 in attackby() to prevent afterattack() effects (when safely moving items for example)
				var/resolved = W.resolve_attackby(A,src, params)
				if(!resolved && A && W)
					W.afterattack(A, src, 1, params) // 1: clicking something Adjacent
			else
				if(ismob(A)) // No instant mob attacking
					setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
				UnarmedAttack(A, 1)

			trigger_aiming(TARGET_CAN_CLICK)
			return
		else // non-adjacent click
			if(W)
				W.afterattack(A, src, 0, params) // 0: not Adjacent
			else
				RangedAttack(A, params)

			trigger_aiming(TARGET_CAN_CLICK)
	return 1

/mob/proc/setClickCooldown(var/timeout)
	next_move = max(world.time + timeout, next_move)

/mob/proc/canClick()
	if(config.no_click_cooldown || next_move <= world.time)
		return 1
	return 0

// Default behavior: ignore double clicks, the second click that makes the doubleclick call already calls for a normal click
/mob/proc/DblClickOn(var/atom/A, var/params)
	return

/*
	Translates into attack_hand, etc.

	Note: proximity_flag here is used to distinguish between normal usage (flag=1),
	and usage when clicking on things telekinetically (flag=0).  This proc will
	not be called at ranged except with telekinesis.

	proximity_flag is not currently passed to attack_hand, and is instead used
	in human click code to allow glove touches only at melee range.
*/
/mob/proc/UnarmedAttack(var/atom/A, var/proximity_flag)
	return

/mob/living/UnarmedAttack(var/atom/A, var/proximity_flag)

	if(!ticker)
		to_chat(src, "You cannot attack people before the game has started.")
		return 0

	if(stat)
		return 0

	return 1

/*
	Ranged unarmed attack:

	This currently is just a default for all mobs, involving
	laser eyes and telekinesis.  You could easily add exceptions
	for things like ranged glove touches, spitting alien acid/neurotoxin,
	animals lunging, etc.
*/
/mob/proc/RangedAttack(var/atom/A, var/params)
	if(!mutations.len) return
	if((LASER in mutations) && a_intent == I_HURT)
		LaserEyes(A) // moved into a proc below
	else if(TK in mutations)
		setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		A.attack_tk(src)
/*
	Restrained ClickOn

	Used when you are handcuffed and click things.
	Not currently used by anything but could easily be.
*/
/mob/proc/RestrainedClickOn(var/atom/A)
	return

/*
	Middle click
	Only used for swapping hands
*/
/mob/proc/MiddleClickOn(var/atom/A)
	A.MiddleClick(src)
	return

/mob/proc/RightClickOn(var/atom/A)
	A.RightClick(src)

/mob/proc/ShiftRightClickOn(var/atom/A)
	A.ShiftRightClick(src)

/atom/proc/MiddleClick(var/mob/M)
	middle_click_intent_check(M)
	return
// In case of use break glass


/mob/proc/ShiftMiddleClickOn(var/atom/A)
	A.ShiftMiddleClick(src)
	return

/atom/proc/ShiftMiddleClick(var/mob/user)
	user.pointed(src)

/*
	Shift click
	For most mobs, examine.
	This is overridden in ai.dm
*/
/mob/proc/ShiftClickOn(var/atom/A)
	A.ShiftClick(src)
	return
/atom/proc/ShiftClick(var/mob/user)
	if(user.client && user.client.eye == user)
		user.examinate(src)
	return

/atom/proc/ShiftRightClick(var/mob/user)
	return //I dont know where we will use it

/*
	Ctrl click
	For most objects, pull
*/
/mob/proc/CtrlClickOn(var/atom/A)
	A.CtrlClick(src)
	return
/atom/proc/CtrlClick(var/mob/user)
	return

/atom/movable/CtrlClick(var/mob/user)
	if(Adjacent(user))
		if (ishuman(user))
			var/mob/living/carbon/human/H = user
			var/obj/item/organ/external/temp = H.organs_by_name[BP_R_HAND]
			var/hashands = (temp && temp.is_usable())
			if (!hashands)
				temp = H.organs_by_name[BP_L_HAND]
				hashands = (temp && temp.is_usable())
			if (!hashands)
				return
		user.start_pulling(src)

/*
	Alt click
	Unused except for AI
*/
/mob/proc/AltClickOn(var/atom/A)
	A.AltClick(src)

/atom/proc/AltClick(var/mob/user)
	var/turf/T = get_turf(src)
	if(T && (isturf(loc) || isturf(src)) && user.TurfAdjacent(T))
		if(user.listed_turf == T)
			user.listed_turf = null
		else
			user.listed_turf = T
			user.client.statpanel = "Turf"
	return 1

/mob/proc/AltRightClickOn(var/atom/A)
	A.AltRightClick(src)

/atom/proc/AltRightClick(var/mob/user)
	return


/atom/proc/RightClick(var/mob/user)
	return

/mob/proc/TurfAdjacent(var/turf/T)
	return T.AdjacentQuick(src)

/mob/observer/ghost/TurfAdjacent(var/turf/T)
	if(!isturf(loc) || !client)
		return FALSE
	return z == T.z && (get_dist(loc, T) <= client.view)

/*
	Control+Shift click
	Unused except for AI
*/
/mob/proc/CtrlShiftClickOn(var/atom/A)
	A.CtrlShiftClick(src)
	return

/atom/proc/CtrlShiftClick(var/mob/user)
	return

/*
	Control+Alt click
*/
/mob/proc/CtrlAltClickOn(var/atom/A)
	A.CtrlAltClick(src)
	return

/atom/proc/CtrlAltClick(var/mob/user)
	return

/*
	Misc helpers

	Laser Eyes: as the name implies, handles this since nothing else does currently
	face_atom: turns the mob towards what you clicked on
*/
/mob/proc/LaserEyes(atom/A)
	return

/mob/living/LaserEyes(atom/A)
	setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	var/turf/T = get_turf(src)

	var/obj/item/projectile/beam/LE = new (T)
	LE.icon = 'icons/effects/genetics.dmi'
	LE.icon_state = "eyelasers"
	playsound(usr.loc, 'sound/weapons/taser2.ogg', 75, 1)
	LE.launch_projectile(A)
/mob/living/carbon/human/LaserEyes()
	if(nutrition>0)
		..()
		nutrition = max(nutrition - rand(1,5),0)
		handle_regular_hud_updates()
	else
		to_chat(src, "<span class='warning'>You're out of energy!  You need food!</span>")

// Simple helper to face what you clicked on, in case it should be needed in more than one place
/mob/proc/face_atom(var/atom/A)
	if(!A || !x || !y || !A.x || !A.y) return
	var/dx = A.x - x
	var/dy = A.y - y
	if(!dx && !dy) return

	var/direction
	if(abs(dx) < abs(dy))
		if(dy > 0)	direction = NORTH
		else		direction = SOUTH
	else
		if(dx > 0)	direction = EAST
		else		direction = WEST
	if(direction != dir)
		if(facing_dir)
			facing_dir = direction
		facedir(direction)

/obj/screen/click_catcher
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "click_catcher"
	plane = CLICKCATCHER_PLANE
	mouse_opacity = 2
	screen_loc = "CENTER-7,CENTER-7"

/proc/create_click_catcher()
	. = list()
	for(var/i = 0, i<15, i++)
		for(var/j = 0, j<15, j++)
			var/obj/screen/click_catcher/CC = new()
			CC.screen_loc = "NORTH-[i],EAST-[j]"
			. += CC

/obj/screen/click_catcher/Click(location, control, params)
	var/list/modifiers = params2list(params)
	if(modifiers["middle"] && istype(usr, /mob/living/carbon))
		var/mob/living/carbon/C = usr
		C.swap_hand()
	else
		var/turf/T = screen_loc2turf(screen_loc, get_turf(usr))
		if(T)
			T.Click(location, control, params)
	. = 1

/*
	Custom click handling
*/

/mob
	var/datum/stack/click_handlers

/mob/Destroy()
	if(click_handlers)
		click_handlers.QdelClear()
		QDEL_NULL(click_handlers)
	. = ..()

var/const/CLICK_HANDLER_NONE                 = 0
var/const/CLICK_HANDLER_REMOVE_ON_MOB_LOGOUT = 1
var/const/CLICK_HANDLER_ALL                  = (~0)

/datum/click_handler
	var/mob/user
	var/flags = 0

/datum/click_handler/New(var/mob/user)
	..()
	src.user = user
	if(flags & (CLICK_HANDLER_REMOVE_ON_MOB_LOGOUT))
		GLOB.logged_out_event.register(user, src, /datum/click_handler/proc/OnMobLogout)

/datum/click_handler/Destroy()
	if(flags & (CLICK_HANDLER_REMOVE_ON_MOB_LOGOUT))
		GLOB.logged_out_event.unregister(user, src, /datum/click_handler/proc/OnMobLogout)
	user = null
	. = ..()

/datum/click_handler/proc/Enter()
	return

/datum/click_handler/proc/Exit()
	return

/datum/click_handler/proc/OnMobLogout()
	user.RemoveClickHandler(src)

/datum/click_handler/proc/OnClick(var/atom/A, var/params)
	return

/datum/click_handler/proc/OnDblClick(var/atom/A, var/params)
	return

/datum/click_handler/default/OnClick(var/atom/A, var/params)
	user.ClickOn(A, params)

/datum/click_handler/default/OnDblClick(var/atom/A, var/params)
	user.DblClickOn(A, params)

/mob/proc/GetClickHandler(var/datum/click_handler/popped_handler)
	if(!click_handlers)
		click_handlers = new()
	if(click_handlers.is_empty())
		PushClickHandler(/datum/click_handler/default)
	return click_handlers.Top()

/mob/proc/RemoveClickHandler(var/datum/click_handler/click_handler)
	if(!click_handlers)
		return

	var/was_top = click_handlers.Top() == click_handler

	if(was_top)
		click_handler.Exit()
	click_handlers.Remove(click_handler)
	qdel(click_handler)

	if(!was_top)
		return
	click_handler = click_handlers.Top()
	if(click_handler)
		click_handler.Enter()

/mob/proc/PopClickHandler()
	if(!click_handlers)
		return
	RemoveClickHandler(click_handlers.Top())

/mob/proc/PushClickHandler(var/datum/click_handler/new_click_handler_type)
	if((initial(new_click_handler_type.flags) & CLICK_HANDLER_REMOVE_ON_MOB_LOGOUT) && !client)
		return FALSE
	if(!click_handlers)
		click_handlers = new()
	var/datum/click_handler/click_handler = click_handlers.Top()
	if(click_handler)
		click_handler.Exit()

	click_handler = new new_click_handler_type(src)
	click_handler.Enter()
	click_handlers.Push(click_handler)

/mob/proc/scramble(var/atom/A)
	var/direction
	if(stat || buckled || paralysis || stunned || sleeping || (status_flags & FAKEDEATH) || restrained() || pulledby)
		return
	for(var/obj/item/grab/G in grabbed_by)
		if(G.stop_move())
			return
	if(!istype(src.loc, /turf/))
		return
	if(!A || !x || !y || !A.x || !A.y)
		return
	if(scrambling)
		return
	if(!has_limbs)
		to_chat(src, "<span class='danger'>You can't even move yourself - you have no limbs!</span>")
	var/dx = A.x - x
	var/dy = A.y - y
	if(!dx && !dy) return

	if(abs(dx) < abs(dy))
		if(dy > 0)	direction = NORTH
		else		direction = SOUTH
	else
		if(dx > 0)	direction = EAST
		else		direction = WEST
	if(direction)
		if(locate(/obj/structure/bridge, get_step(src,direction) && !in_trench)) // WARTWO EDIT - TEMPORARY SOLUTION FOR PEOPLE JUST VANISHING UNDER THE BRIDGE WHEN CRAWLING, TO-DO: REWRITE BRIDGES SOMEDAY
			return // NO YOU WONT CRAWL UNDER THE BRIDGE FROM UPTOP!!!
		scrambling = 1
		if(do_after(src, 10))
			Move(get_step(src,direction))
			scrambling = 0
			dir = 2
			src.visible_message("<span class='danger'><b>[src.name]</b> crawls!</span>")
			playsound(src, 'sound/effects/crawl1.ogg', 50, 1, -(world.view - 2))
		else
			scrambling = 0

/atom/proc/middle_click_intent_check(var/mob/M)
	if(M.middle_click_intent == "kick")
		return kick_act(M)
	else if(M.middle_click_intent == "jump")
		jump_act(src, M)
	else
		M.swap_hand()