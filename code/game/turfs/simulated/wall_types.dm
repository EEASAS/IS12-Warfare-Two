/turf/simulated/wall/r_wall
	icon_state = "rgeneric"
	walltype = "rwall"
	icon_state = "rwall0"
	//mineral = "reinforced_m"
/turf/simulated/wall/r_wall/New(var/newloc)
	..(newloc) //3strong
/turf/simulated/wall/ocp_wall
	icon_state = "rgeneric"

/turf/simulated/wall/concrete
	name = "concrete wall"
	desc = "An old concrete wall. For when metal just isn't good enough."
	icon_state = "concrete0"
	walltype = "concrete"
	mineral = "rust"
	plane = WALL_PLANE
	integrity = 500 //Tough bois

/turf/simulated/wall/concrete/New()
	. = ..()
	dir = set_dir(pick(GLOB.alldirs))

/turf/simulated/wall/concrete/ex_act(severity)
	. = ..()
	if(1)
		qdel(src)
	if(2)
		qdel(src)
	if(3)
		integrity -= 200

/turf/simulated/wall/concrete/strong
	desc = "Looks much stronger than a paper sheet."
	integrity = 7500

/turf/simulated/wall/perspecticrete
	name = "concrete wall"
	desc = "An old concrete wall. For when metal just isn't good enough."
	icon_state = "perspecticrete0"
	walltype = "perspecticrete"
	mineral = "rust"
	plane = WALL_PLANE
	integrity = 2500 //Tough bois

/turf/simulated/wall/perspecticrete/bullet_act(obj/item/projectile/Proj)
	return FALSE
// Use C4 instead ^^

/turf/simulated/wall/concrete/strong/oldcrete
	icon = 'icons/turf/oldcrete.dmi'

/turf/simulated/wall/concrete/oldcrete
	icon = 'icons/turf/oldcrete.dmi'

/turf/simulated/wall/rust
	desc = "An old rusty wall. It's definitely seen better days."
	icon_state = "rust0"
	walltype = "rust"
	mineral = "rust"

/turf/simulated/wall/r_wall/containment
	desc = "A strong containment wall. Used to \"contain\" things"
	icon_state = "containment0"
	walltype = "containment"
	mineral = "containment"

/turf/simulated/wall/ocp_wall/New(var/newloc)
	..(newloc)




/turf/simulated/wall/cult
	icon_state = "cult"
	walltype = "cult"

/turf/simulated/wall/cult/New(var/newloc, var/reinforce = 0)
	..(newloc,)

/turf/simulated/wall/cult/reinf/New(var/newloc)
	..(newloc)

/turf/simulated/wall/cult/dismantle_wall()
	cult.remove_cultiness(CULTINESS_PER_TURF)
	..()

/turf/unsimulated/wall/cult
	name = "cult wall"
	desc = "Hideous images dance beneath the surface."
	icon = 'icons/turf/wall_masks.dmi'
	icon_state = "cult"
/*GAVNO!!!/
/turf/simulated/wall/iron/New(var/newloc)
	..(newloc)
/turf/simulated/wall/uranium/New(var/newloc)
	..(newloc)
/turf/simulated/wall/diamond/New(var/newloc)
	..(newloc)
/turf/simulated/wall/gold/New(var/newloc)
	..(newloc)
/turf/simulated/wall/silver/New(var/newloc)
	..(newloc)
/turf/simulated/wall/phoron/New(var/newloc)
	..(newloc)
/turf/simulated/wall/sandstone/New(var/newloc)
	..(newloc)
/turf/simulated/wall/wood/New(var/newloc)
	..(newloc)
/turf/simulated/wall/ironphoron/New(var/newloc)
	..(newloc)
/turf/simulated/wall/golddiamond/New(var/newloc)
	..(newloc)
/turf/simulated/wall/silvergold/New(var/newloc)
	..(newloc)
/turf/simulated/wall/sandstonediamond/New(var/newloc)
	..(newloc)
*/

// Kind of wondering if this is going to bite me in the butt.
/turf/simulated/wall/voxshuttle/New(var/newloc)
	..(newloc)
/turf/simulated/wall/voxshuttle/attackby()
	return
/turf/simulated/wall/titanium/New(var/newloc)
	..(newloc)

/turf/simulated/wall/alium
	icon_state = "jaggy"
	floor_type = /turf/simulated/floor/fixed/alium

/turf/simulated/wall/alium/New(var/newloc)
	..(newloc)

/turf/simulated/wall/alium/ex_act(severity)
	if(prob(explosion_resistance))
		return
	..()

/turf/simulated/wall/stone
	icon_state = "stone0"
	walltype = "stone"

/turf/simulated/wall/wood
	icon_state = "wood0"
	walltype = "wood"

/turf/simulated/wall/scrap
	icon_state = "scrap0"
	walltype = "scrap"