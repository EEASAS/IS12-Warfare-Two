/mob/living/carbon/human/gib()
	for(var/obj/item/organ/I in internal_organs)
		I.removed(src)
		if(istype(loc,/turf))
			I.throw_at(get_edge_target_turf(src,pick(GLOB.alldirs)),rand(1,3),30)

	for(var/obj/item/organ/external/E in src.organs)
		E.droplimb(0,DROPLIMB_EDGE,1)

	sleep(1)

	for(var/obj/item/I in src)
		drop_from_inventory(I)
		I.throw_at(get_edge_target_turf(src,pick(GLOB.alldirs)), rand(1,3), round(30/I.w_class))

	..(species.gibbed_anim)
	gibs(loc, dna, null, species.get_flesh_colour(src), species.get_blood_colour(src))

/mob/living/carbon/human/dust()
	if(species)
		..(species.dusted_anim, species.remains_type)
	else
		..()

/mob/living/carbon/human/death(gibbed,deathmessage="seizes up and falls limp...", show_dead_message = "You have died.")

	if(is_npc)
		walk_to(src, 0)

	if(stat == DEAD) return

	BITSET(hud_updateflag, HEALTH_HUD)
	BITSET(hud_updateflag, STATUS_HUD)
	BITSET(hud_updateflag, LIFE_HUD)

	//backs up lace if available.
	var/obj/item/organ/internal/stack/s = get_organ(BP_STACK)
	if(s)
		s.do_backup()

	//Handle species-specific deaths.
	species.handle_death(src)



	//Handle brain slugs.
	var/obj/item/organ/external/head = get_organ(BP_HEAD)
	var/mob/living/simple_animal/borer/B

	for(var/I in head.implants)
		if(istype(I,/mob/living/simple_animal/borer))
			B = I
	if(B)
		if(!B.ckey && ckey && B.controlling)
			B.ckey = ckey
			B.controlling = 0
		if(B.host_brain.ckey)
			ckey = B.host_brain.ckey
			B.host_brain.ckey = null
			B.host_brain.SetName("host brain")
			B.host_brain.real_name = "host brain"

		verbs -= /mob/living/carbon/proc/release_control

	callHook("death", list(src, gibbed))

	if(ticker && ticker.mode)
		sql_report_death(src)
		ticker.mode.check_win()

	. = ..(gibbed,"no message")
	if(!gibbed)
		handle_organs()
		if(species.death_sound)
			playsound(loc, species.death_sound, 80, 1, 1)
		spawn(50)
			if(bowels >= 30)
				handle_shit()
			if(bladder >= 30)
				handle_piss()
	unlock_achievement(new/datum/achievement/dead())
	sound_to(src, sound(null, repeat = 1, wait = 0, volume = 70, channel = 4))
	sound_to(src, sound(null, repeat = 1, wait = 0, volume = 70, channel = 3))
	sound_to(src, sound(null, repeat = 1, wait = 0, volume = 50, channel = 6))
	remove_coldbreath()
	handle_warfare_death()
	GLOB.total_deaths++
	handle_hud_list()
	if(prob(1))
		sound_to(src, sound('sound/effects/death.ogg', volume = 50))

	if(!GLOB.first_death)
		GLOB.first_death = real_name
	if(!GLOB.first_death_happened)
		GLOB.first_death_happened = TRUE
	if(!GLOB.final_words)
		GLOB.final_words = last_words

/mob/living/carbon/human/proc/ChangeToHusk()
	if(HUSK in mutations)	return

	if(f_style)
		f_style = "Shaved"		//we only change the icon_state of the hair datum, so it doesn't mess up their UI/UE
	if(h_style)
		h_style = "Bald"
	update_hair(0)

	mutations.Add(HUSK)
	for(var/obj/item/organ/external/E in organs)
		E.disfigured = 1
	update_body(1)
	return

/mob/living/carbon/human/proc/Drain()
	ChangeToHusk()
	mutations |= HUSK
	return

/mob/living/carbon/human/proc/ChangeToSkeleton()
	if(SKELETON in src.mutations)	return

	if(f_style)
		f_style = "Shaved"
	if(h_style)
		h_style = "Bald"
	update_hair(0)

	mutations.Add(SKELETON)
	for(var/obj/item/organ/external/E in organs)
		E.disfigured = 1
	update_body(1)
	return
