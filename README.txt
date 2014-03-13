Minetest mod "Creatures"
=======================
by BlockMen (c) 2014

Version: 1.1 Beta

About
~~~~~
This mod adds 2 hostile and 1 friendly mob to Minetest, so far zombies, ghosts and sheeps.

Zombies can spawn to every day-time in the world as long there is not to much light.
So you will find some in caves, dark forests and ofc a lot at night. If they notice you they will attack.
Zombies have 20 HP (like players) and drop rotten flesh randomly.

Ghosts only spawn at night-time. Also they don't spawn underground and are a bit more rare than zombies.
They are flying in the world and attack you aswell if they notice you.
Ghosts have 12 HP and don't drop any items atm (might be changed if i have an idea what they could drop).

Sheeps spawn only at day-time and are friendly mobs. They remain around 5 minutes in the world unless there
are other sheeps around, then there is no fixed limit. If there is grass (dirt with grass) they eat the grass
and get new wool that way.
Sheeps have 8 HP and drop 1-2 wool when punched. They need to eat grass until they can produce new wool.

They can't harm you in your house (in case there is no door open). If it becomes day both mobs will take damage
by the sunlight, so they will die after a while.


Notice: Weapons and tools get damaged when hitting a zombie or ghost. The wearout is calculated on the damage amout
of the tools/weapons. The more damage they can do that longer they can be used.

Example: 
- Diamond Sword: 1500 uses
- Wooden Sword: 30 uses




License of source code, textures and mesh model: WTFPL
------------------------------------------------------
(c) Copyright BlockMen (2014)


Licenses of sounds
------------------
following sounds are created by Under7dude (freesound.org)
- creatures_zombie.1.ogg, CC0
- creatures_zombie.2.ogg, CC0
- creatures_zombie.3.ogg, CC0
- creatures_zombie_death.ogg, CC0

following sounds are created by confusion_music (freesound.org)
- creatures_sheep.1.ogg, CC-BY 3.0
- creatures_sheep.2.ogg, CC-BY 3.0

following sound is created by Yuval (freesound.org)
- creatures_sheep.3.ogg,  CC-BY 3.0

All other sounds (c) Copyright BlockMen (2014), CC-BY 3.0

Changelog:
----------
# 1.0.1
 - fixed incompatibility with pyramids mod

# 1.1
 - new mob: sheep
 - fixed crash caused by unknown node
 - fixed spawning, added spawn limit
 - fixed weapon & tool damage
 - tweaked and restructured code
 - ghosts only spawn on grass and desert-sand blocks
 - ghosts have now 12 HP (instead 15 HP)
 - zombies don't jump over fences anymore

This program is free software. It comes without any warranty, to
the extent permitted by applicable law. You can redistribute it
and/or modify it under the terms of the Do What The Fuck You Want
To Public License, Version 2, as published by Sam Hocevar. See
http://sam.zoy.org/wtfpl/COPYING for more details.
