var/list/mining_walls = list()
var/list/mining_floors = list()

/**********************Mineral deposits**************************/
/turf/unsimulated/mineral
	name = "impassable rock"
	icon = 'icons/turf/walls.dmi'
	icon_state = "rock-dark"
	blocks_air = 1
	density = 1
	opacity = 1

/turf/simulated/mineral //wall piece
	name = "rock"
	icon = 'icons/turf/walls.dmi'
	icon_state = "rock"
	initial_gas = null
	opacity = 1
	density = 1
	blocks_air = 1
	temperature = T0C
	var/mined_turf = /turf/simulated/floor/dirty ///turf/simulated/floor/asteroid
	var/ore/mineral
	var/mined_ore = 0
	var/last_act = 0
	var/emitter_blasts_taken = 0 // EMITTER MINING! Muhehe.

	var/datum/geosample/geologic_data
	var/excavation_level = 0
	var/list/finds
	var/next_rock = 0
	var/archaeo_overlay = ""
	var/excav_overlay = ""
	var/obj/item/last_find
	var/datum/artifact_find/artifact_find
	var/image/ore_overlay
	var/health = 10

	has_resources = 1


/turf/simulated/mineral/New()
	if (!mining_walls["[src.z]"])
		mining_walls["[src.z]"] = list()
	mining_walls["[src.z]"] += src
	spawn(0)
		MineralSpread()
	spawn(2)
		update_icon(1)

/turf/simulated/mineral/Destroy()
	if (mining_walls["[src.z]"])
		mining_walls["[src.z]"] -= src
	return ..()

/turf/simulated/mineral/can_build_cable()
	return !density

/turf/simulated/mineral/is_plating()
	return 1

/turf/simulated/mineral/update_icon(var/update_neighbors)
	if(!mineral)
		SetName(initial(name))
		icon_state = "rock"
	else
		SetName("[mineral.display_name] deposit")

	overlays.Cut()

	for(var/direction in GLOB.cardinal)
		var/turf/turf_to_check = get_step(src,direction)
		if(update_neighbors && istype(turf_to_check,/turf/simulated/floor/asteroid))
			var/turf/simulated/floor/asteroid/T = turf_to_check
			T.updateMineralOverlays()
		else if(istype(turf_to_check,/turf/space) || istype(turf_to_check,/turf/simulated/floor || istype(turf_to_check, /turf/simulated/open)))
			var/image/rock_side = image('icons/turf/walls.dmi', "rock_side", dir = turn(direction, 180))
			rock_side.turf_decal_layerise()

			switch(direction)
				if(NORTH)
					rock_side.pixel_y += (world.icon_size - 15)
				if(SOUTH)
					rock_side.pixel_y -= (world.icon_size - 15)
				if(EAST)
					rock_side.pixel_x += (world.icon_size - 15)
				if(WEST)
					rock_side.pixel_x -= (world.icon_size - 15)


			overlays += rock_side

	if(ore_overlay)
		overlays += ore_overlay

	if(excav_overlay)
		overlays += excav_overlay

	if(archaeo_overlay)
		overlays += archaeo_overlay

/turf/simulated/mineral/ex_act(severity)
	return FALSE
	/*switch(severity)
		if(2.0)
			if (prob(70))
				mined_ore = 1 //some of the stuff gets blown up
				GetDrilled()
		if(1.0)
			mined_ore = 2 //some of the stuff gets blown up
			GetDrilled()*/

/turf/simulated/mineral/bullet_act(var/obj/item/projectile/Proj)

	// Emitter blasts
	if(istype(Proj, /obj/item/projectile/beam/emitter))
		emitter_blasts_taken++

		if(emitter_blasts_taken > 2) // 3 blasts per tile
			mined_ore = 1
			GetDrilled()

/turf/simulated/mineral/Bumped(AM)
	. = ..()

	if(istype(AM,/mob/living/silicon/robot))
		var/mob/living/silicon/robot/R = AM
		if(istype(R.module_active,/obj/item/pickaxe))
			attackby(R.module_active,R)

	else if(istype(AM,/obj/mecha))
		var/obj/mecha/M = AM
		if(istype(M.selected,/obj/item/mecha_parts/mecha_equipment/tool/drill))
			M.selected.action(src)

/turf/simulated/mineral/proc/MineralSpread()
	if(mineral && mineral.spread)
		for(var/trydir in GLOB.cardinal)
			if(prob(mineral.spread_chance))
				var/turf/simulated/mineral/target_turf = get_step(src, trydir)
				if(istype(target_turf) && !target_turf.mineral)
					target_turf.mineral = mineral
					target_turf.UpdateMineral()
					target_turf.MineralSpread()


/turf/simulated/mineral/proc/UpdateMineral()
	clear_ore_effects()
	ore_overlay = image('icons/obj/mining.dmi', "rock_[mineral.icon_tag]")
	ore_overlay.appearance_flags = RESET_COLOR
	ore_overlay.turf_decal_layerise()
	update_icon()

//Not even going to touch this pile of spaghetti
/turf/simulated/mineral/attackby(obj/item/W as obj, mob/user as mob)

	//if (!(istype(usr, /mob/living/carbon/human) || ticker) && ticker.mode.name != "monkey")
	//	to_chat(usr, "<span class='warning'>You don't have the dexterity to do this!</span>")
	//	return //Bay I can't believe you still haven't gotten rid of this code block. I'm keeping it just as a big fuck you.

	if (istype(W, /obj/item/device/core_sampler))
		geologic_data.UpdateNearbyArtifactInfo(src)
		var/obj/item/device/core_sampler/C = W
		C.sample_item(src, user)
		return

	if (istype(W, /obj/item/device/depth_scanner))
		var/obj/item/device/depth_scanner/C = W
		C.scan_atom(user, src)
		return

	if (istype(W, /obj/item/device/measuring_tape))
		var/obj/item/device/measuring_tape/P = W
		user.visible_message("<span class='notice'>\The [user] extends [P] towards [src].</span>","<span class='notice'>You extend [P] towards [src].</span>")
		if(do_after(user,10, src))
			to_chat(user, "<span class='notice'>\The [src] has been excavated to a depth of [excavation_level]cm.</span>")
		return

	if (istype(W, /obj/item/pickaxe))
		if(!istype(user.loc, /turf))
			return

		var/obj/item/pickaxe/P = W

		playsound(user, pick(P.drill_sound), 20, 1)

		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			H.adjustStaminaLoss(rand(1,10))
			H.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)

		if(health > 9999)
			if(prob(25))
				to_chat(user, SPAN_YELLOW("Doesn't look like this'll be breaking anytime soon."))
			return

		health -= rand(1,5)

		var/newDepth = excavation_level + P.excavation_amount // Used commonly below
		//handle any archaeological finds we might uncover
		var/fail_message = ""
		if(finds && finds.len)
			var/datum/find/F = finds[1]
			if(newDepth > F.excavation_required) // Digging too deep can break the item. At least you won't summon a Balrog (probably)
				fail_message = ". <b>[pick("There is a crunching noise","[W] collides with some different rock","Part of the rock face crumbles away","Something breaks under [W]")]</b>"

		//to_chat(user, "<span class='notice'>You hit the [src.name] with your [P.name].</span>")//[P.drill_verb][fail_message].</span>")

		if(fail_message && prob(90))
			if(prob(25))
				excavate_find(prob(5), finds[1])
			else if(prob(50))
				finds.Remove(finds[1])
				if(prob(50))
					artifact_debris()

		//if(do_after(user,P.digspeed, src))
		if(health <= 0)
			//if(finds && finds.len)
			//	var/datum/find/F = finds[1]
			//	if(newDepth == F.excavation_required) // When the pick hits that edge just right, you extract your find perfectly, it's never confined in a rock
			//		excavate_find(1, F)
			//	else if(newDepth > F.excavation_required - F.clearance_range) // Not quite right but you still extract your find, the closer to the bottom the better, but not above 80%
			//		excavate_find(prob(80 * (F.excavation_required - newDepth) / F.clearance_range), F)

			//to_chat(user, "<span class='notice'>You finish [P.drill_verb] \the [src].</span>")


			if(newDepth >= 200)
				GetDrilled(1)
				return
				// This means the rock is mined out fully
				//var/obj/structure/boulder/B
				//if(artifact_find)
				//	if( excavation_level > 0 || prob(15) )
						//boulder with an artifact inside
				//		B = new(src)
				//		if(artifact_find)
				//			B.artifact_find = artifact_find
				//	else
				//		artifact_debris(1)
				//else if(prob(5))
				//	//empty boulder
				//	B = new(src)

				//if(B)
				//	GetDrilled(0)
				//else
				//GetDrilled(1)
				//return




			excavation_level += P.excavation_amount
			var/updateIcon = 0

			//archaeo overlays
			if(!archaeo_overlay && finds && finds.len)
				var/datum/find/F = finds[1]
				if(F.excavation_required <= excavation_level + F.view_range)
					archaeo_overlay = "overlay_archaeo[rand(1,3)]"
					updateIcon = 1

			else if(archaeo_overlay && (!finds || !finds.len))
				archaeo_overlay = null
				updateIcon = 1

			//there's got to be a better way to do this
			var/update_excav_overlay = 0
			if(excavation_level >= 150)
				if(excavation_level - P.excavation_amount < 150)
					update_excav_overlay = 1
			else if(excavation_level >= 100)
				if(excavation_level - P.excavation_amount < 100)
					update_excav_overlay = 1
			else if(excavation_level >= 50)
				if(excavation_level - P.excavation_amount < 50)
					update_excav_overlay = 1

			//update overlays displaying excavation level
			if( !(excav_overlay && excavation_level > 0) || update_excav_overlay )
				var/excav_quadrant = round(excavation_level / 50) + 1
				excav_overlay = "overlay_excv[excav_quadrant]_[rand(1,3)]"
				updateIcon = 1

			if(updateIcon)
				update_icon()

			//drop some rocks
			next_rock += P.excavation_amount
			while(next_rock > 50)
				next_rock -= 50
				var/obj/item/ore/O = new(src)
				geologic_data.UpdateNearbyArtifactInfo(src)
				O.geologic_data = geologic_data

	else
		return ..()

/turf/simulated/mineral/examine(mob/user, distance, infix, suffix)
	. = ..()
	if(health > 9999)
		to_chat(user,SPAN_YELLOW("Doesn't look like I can mine through this.."))

/turf/simulated/mineral/proc/clear_ore_effects()
	overlays -= ore_overlay
	ore_overlay = null

/turf/simulated/mineral/proc/DropMineral()
	if(!mineral)
		return

	clear_ore_effects()
	var/obj/item/ore/O = new mineral.ore (src)
	if(geologic_data && istype(O))
		geologic_data.UpdateNearbyArtifactInfo(src)
		O.geologic_data = geologic_data
	return O

/turf/simulated/mineral/proc/GetDrilled(var/artifact_fail = 0)
	//var/destroyed = 0 //used for breaking strange rocks
	if (mineral && mineral.result_amount)

		//if the turf has already been excavated, some of it's ore has been removed
		for (var/i = 1 to mineral.result_amount - mined_ore)
			DropMineral()

	//destroyed artifacts have weird, unpleasant effects
	//make sure to destroy them before changing the turf though
	if(artifact_find && artifact_fail)
		var/pain = 0
		if(prob(50))
			pain = 1
		for(var/mob/living/M in range(src, 200))
			to_chat(M, "<font color='red'><b>[pick("A high pitched [pick("keening","wailing","whistle")]","A rumbling noise like [pick("thunder","heavy machinery")]")] somehow penetrates your mind before fading away!</b></font>")
			if(pain)
				flick("pain",M.pain)
				if(prob(50))
					M.adjustBruteLoss(5)
			else
				M.flash_eyes()
				if(prob(50))
					M.Stun(5)
		radiation_repository.flat_radiate(src, 25, 200)
	//Add some rubble,  you did just clear out a big chunk of rock.

	ChangeTurf(mined_turf)


/turf/simulated/mineral/ChangeTurf(turf/N, tell_universe, force_lighting_update)
	. = ..()
	for(var/direction in GLOB.cardinal)
		var/turf/T = get_step(src,direction)
		T.update_icon(1)


/turf/simulated/mineral/proc/excavate_find(var/prob_clean = 0, var/datum/find/F)

	//many finds are ancient and thus very delicate - luckily there is a specialised energy suspension field which protects them when they're being extracted
	if(prob(F.prob_delicate))
		var/obj/effect/suspension_field/S = locate() in src
		if(!S)
			visible_message("<span class='danger'>[pick("An object in the rock crumbles away into dust.","Something falls out of the rock and shatters onto the ground.")]</span>")
			finds.Remove(F)
			return

	//with skill and luck, players can cleanly extract finds
	//otherwise, they come out inside a chunk of rock
	if(prob_clean)
		var/find = get_archeological_find_by_findtype(F.find_type)
		new find(src)
	else
		var/obj/item/ore/strangerock/rock = new(src, inside_item_type = F.find_type)
		geologic_data.UpdateNearbyArtifactInfo(src)
		rock.geologic_data = geologic_data

	finds.Remove(F)


/turf/simulated/mineral/proc/artifact_debris(var/severity = 0)
	//cael's patented random limited drop componentized loot system!
	//sky's patented not-fucking-retarded overhaul!

	//Give a random amount of loot from 1 to 3 or 5, varying on severity.
	for(var/j in 1 to rand(1, 3 + max(min(severity, 1), 0) * 2))
		switch(rand(1,7))
			if(1)
				var/obj/item/stack/rods/R = new(src)
				R.amount = rand(5,25)

			if(2)
				var/obj/item/stack/material/plasteel/R = new(src)
				R.amount = rand(5,25)

			if(3)
				var/obj/item/stack/material/steel/R = new(src)
				R.amount = rand(5,25)

			if(4)
				var/obj/item/stack/material/plasteel/R = new(src)
				R.amount = rand(5,25)

			if(5)
				var/quantity = rand(1,3)
				for(var/i=0, i<quantity, i++)
					new /obj/item/material/shard(src)

			if(6)
				var/quantity = rand(1,3)
				for(var/i=0, i<quantity, i++)
					new /obj/item/material/shard/phoron(src)

			if(7)
				var/obj/item/stack/material/uranium/R = new(src)
				R.amount = rand(5,25)

/turf/simulated/mineral/random
	name = "Mineral deposit"
	var/mineralSpawnChanceList = list("Uranium" = 5, "Platinum" = 5, "Iron" = 35, "Carbon" = 35, "Diamond" = 1, "Gold" = 5, "Silver" = 5, "Phoron" = 10)
	var/mineralChance = 100 //10 //means 10% chance of this plot changing to a mineral deposit

/turf/simulated/mineral/random/New()
	if (prob(mineralChance) && !mineral)
		var/mineral_name = pickweight(mineralSpawnChanceList) //temp mineral name
		mineral_name = lowertext(mineral_name)
		if (mineral_name && (mineral_name in ore_data))
			mineral = ore_data[mineral_name]
			UpdateMineral()

	. = ..()

/turf/simulated/mineral/random/high_chance
	mineralChance = 100 //25
	mineralSpawnChanceList = list("Uranium" = 10, "Platinum" = 10, "Iron" = 20, "Carbon" = 20, "Diamond" = 2, "Gold" = 10, "Silver" = 10, "Phoron" = 20)

/**********************Asteroid**************************/

// Setting icon/icon_state initially will use these values when the turf is built on/replaced.
// This means you can put grass on the asteroid etc.
/turf/simulated/floor/asteroid
	name = "sand"
	icon = 'icons/turf/flooring/asteroid.dmi'
	icon_state = "asteroid"
	base_name = "sand"
	base_desc = "Gritty and unpleasant."
	base_icon = 'icons/turf/flooring/asteroid.dmi'
	base_icon_state = "asteroid"

	initial_flooring = null
	initial_gas = null
	temperature = TCMB
	var/dug = 0       //0 = has not yet been dug, 1 = has already been dug
	var/overlay_detail
	has_resources = 1

/turf/simulated/floor/asteroid/New()
	if (!mining_floors["[src.z]"])
		mining_floors["[src.z]"] = list()
	mining_floors["[src.z]"] += src
	if(prob(20))
		overlay_detail = "asteroid[rand(0,9)]"

/turf/simulated/floor/asteroid/Destroy()
	if (mining_floors["[src.z]"])
		mining_floors["[src.z]"] -= src
	return ..()

/turf/simulated/floor/asteroid/ex_act(severity)
	switch(severity)
		if(3.0)
			return
		if(2.0)
			if (prob(70))
				gets_dug()
		if(1.0)
			gets_dug()
	return

/turf/simulated/floor/asteroid/is_plating()
	return !density

/turf/simulated/floor/asteroid/attackby(obj/item/W as obj, mob/user as mob)
	if(!W || !user)
		return 0

	var/list/usable_tools = list(
		/obj/item/shovel,
		/obj/item/pickaxe/diamonddrill,
		/obj/item/pickaxe/drill,
		/obj/item/pickaxe/borgdrill
		)

	var/valid_tool
	for(var/valid_type in usable_tools)
		if(istype(W,valid_type))
			valid_tool = 1
			break

	if(valid_tool)
		if (dug)
			to_chat(user, "<span class='warning'>This area has already been dug</span>")
			return

		var/turf/T = user.loc
		if (!(istype(T)))
			return

		to_chat(user, "<span class='warning'>You start digging.</span>")
		playsound(user.loc, 'sound/effects/rustle1.ogg', 50, 1)

		if(!do_after(user,40, src)) return

		to_chat(user, "<span class='notice'>You dug a hole.</span>")
		gets_dug()

	else if(istype(W,/obj/item/storage/ore))
		var/obj/item/storage/ore/S = W
		if(S.collection_mode)
			for(var/obj/item/ore/O in contents)
				O.attackby(W,user)
				return
	else if(istype(W,/obj/item/storage/bag/fossils))
		var/obj/item/storage/bag/fossils/S = W
		if(S.collection_mode)
			for(var/obj/item/fossil/F in contents)
				F.attackby(W,user)
				return

	else
		..(W,user)
	return

/turf/simulated/floor/asteroid/proc/gets_dug()

	if(dug)
		return

	for(var/i=0;i<(rand(3)+2);i++)
		new/obj/item/ore/glass(src)

	dug = 1
	icon_state = "asteroid_dug"
	return

/turf/simulated/floor/asteroid/proc/updateMineralOverlays(var/update_neighbors)

	overlays.Cut()

	var/list/step_overlays = list("n" = NORTH, "s" = SOUTH, "e" = EAST, "w" = WEST)
	for(var/direction in step_overlays)

		if(istype(get_step(src, step_overlays[direction]), /turf/space))
			var/image/aster_edge = image('icons/turf/flooring/asteroid.dmi', "asteroid_edges", dir = step_overlays[direction])
			aster_edge.turf_decal_layerise()
			overlays += aster_edge

		if(istype(get_step(src, step_overlays[direction]), /turf/simulated/mineral))
			var/image/rock_wall = image('icons/turf/walls.dmi', "rock_side", dir = step_overlays[direction])
			rock_wall.turf_decal_layerise()
			overlays += rock_wall

	//todo cache
	if(overlay_detail)
		var/image/floor_decal = image(icon = 'icons/turf/flooring/decals.dmi', icon_state = overlay_detail)
		floor_decal.turf_decal_layerise()
		overlays |= floor_decal

	if(update_neighbors)
		var/list/all_step_directions = list(NORTH,NORTHEAST,EAST,SOUTHEAST,SOUTH,SOUTHWEST,WEST,NORTHWEST)
		for(var/direction in all_step_directions)
			var/turf/simulated/floor/asteroid/A
			if(istype(get_step(src, direction), /turf/simulated/floor/asteroid))
				A = get_step(src, direction)
				A.updateMineralOverlays()

/turf/simulated/floor/asteroid/Entered(atom/movable/M as mob|obj)
	..()
	if(istype(M,/mob/living/silicon/robot))
		var/mob/living/silicon/robot/R = M
		if(R.module)
			if(istype(R.module_state_1,/obj/item/storage/ore))
				attackby(R.module_state_1,R)
			else if(istype(R.module_state_2,/obj/item/storage/ore))
				attackby(R.module_state_2,R)
			else if(istype(R.module_state_3,/obj/item/storage/ore))
				attackby(R.module_state_3,R)
			else
				return

/turf/simulated/floor/asteroid/air
	initial_gas = list("oxygen" = 21.8366, "nitrogen" = 82.1472)
	temperature = 293.15