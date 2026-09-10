WOODLAND OUTPOST
================

A compact 2D survival-management game made with Godot.

Winter is approaching. Explore a procedurally generated woodland, gather
supplies, manage hunger and backpack space, and complete your cabin before
time runs out.


CURRENT RELEASE
---------------

Version 0.2.3 — The Hunger & Camp Management Update

This release turns food and resource storage into active parts of the survival
loop. Hunger is now visible and decreases throughout the day, food is eaten
manually, and the backpack has a dedicated visual inventory.

Returning to camp now opens a proper management screen where carried supplies,
stored resources, and construction requirements can be inspected together.
Resources no longer disappear into storage automatically: the player chooses
what to deposit, retrieve, carry, or reserve for construction.


THE OBJECTIVE
-------------

Complete the cabin before winter arrives.

To survive, you must balance four competing needs:

- Explore far enough to find the resources you need.
- Gather wood and stone for each construction stage.
- Carry food and eat before Hunger reaches zero.
- Return to camp to store supplies and build safely.

Victory normally arrives around Day 6 during a successful run. Winter arrives
after Day 7, so every expedition matters.


HOW TO PLAY
-----------

1. Explore the forest and locate berries, trees, and rocks.
2. Hold E near a resource to gather it.
3. Watch Hunger and eat carried Food before it reaches zero.
4. Use the backpack view to inspect your current load and remaining capacity.
5. Return to camp and press E to open the camp-management screen.
6. Deposit resources individually, or use Deposit All for convenience.
7. Retrieve stored resources when you want to prepare a different load.
8. Use stored wood and stone to construct the next camp stage.
9. Complete the cabin before winter arrives.

Gathering progress is preserved if you release E or move away. You can return
to the same unfinished resource and continue later.


CONTROLS
--------

Move:                    WASD or arrow keys
Gather / interact:       Hold E
Open / close backpack:   Tab
Eat Food:                F
Close interface / pause: Esc
Toggle fullscreen:       Alt + Enter

Escape closes the active backpack or camp interface before opening the pause
menu.


HUNGER
------

Hunger begins at 100 and gradually decreases while game time is running.
Reaching zero Hunger ends the game.

Food must now be eaten deliberately instead of being consumed automatically at
the end of each day. Eating restores Hunger and provides sound, animation, and
HUD feedback. The interface also warns the player as Hunger approaches a
dangerous level.

Hunger and the day cycle pause while the backpack, camp screen, main menu, or
other major interfaces are open.


THE BACKPACK
------------

The backpack carries a maximum of 12 kg. Press Tab to open its visual inventory.

Each kilogram is represented by one physical space:

Food
  Weight: 1 kg per unit
  Gathering time: 3 seconds
  Backpack space: 1 cell

Wood
  Weight: 2 kg per unit
  Gathering time: 4 seconds
  Backpack space: 2 connected cells

Stone
  Weight: 3 kg per unit
  Gathering time: 6 seconds
  Backpack space: 3 connected cells

Large resource icons span all the cells they occupy, making it possible to
understand the current load without calculating the weight manually.

Backpack capacity creates an important tradeoff: carrying Food makes an
expedition safer, but leaves less room for construction materials.


CAMP MANAGEMENT
---------------

Press E near the camp to open the camp-management screen.

The left side displays the current backpack. The right side displays camp
storage and the requirements for the next construction stage.

Available actions:

- Click a resource in the backpack to deposit one unit.
- Use Deposit All to move the complete load into camp storage.
- Use Take One to retrieve a stored resource.
- Build the next camp stage when all required materials are stored.

Retrieving an item respects its weight. For example, Stone cannot be taken if
the backpack has fewer than 3 kg available.

The interface updates immediately after gathering, eating, depositing,
retrieving, or spending resources on construction.


THE FOREST
----------

The world is a procedurally generated 72 × 44 tile woodland with a
player-following camera.

Resource distribution is influenced by distance from camp:

- Starter wood and food can be found reasonably close to camp.
- Stone encourages longer expeditions.
- Spacing rules keep important resources physically accessible.
- Generation guarantees enough total resources to complete the game.

Decorative woodland clusters, undergrowth, flowers, branches, mushrooms,
saplings, logs, and stumps make the forest denser without turning every visual
object into an expensive gameplay node.

Gathered resources leave visual traces behind:

- A depleted tree becomes a stump.
- A depleted berry bush becomes an empty bush.
- A depleted rock leaves a hole in the ground.


WHAT IS NEW IN VERSION 0.2.3
----------------------------

- A visible Hunger meter that decreases throughout the day.
- Starvation as a new loss condition.
- Manual eating with the F key.
- Hunger warnings and dedicated eating feedback.
- A full-screen visual backpack opened with Tab.
- Twelve backpack spaces representing the 12 kg capacity.
- Resource icons that visibly span one, two, or three spaces.
- A new two-panel camp-management interface.
- Live backpack, camp-storage, and construction information.
- Manual individual resource deposits.
- A Deposit All shortcut.
- Individual retrieval of stored resources.
- Backpack-capacity validation during retrieval.
- Immediate visual feedback after transfers.
- Correct modal-interface priority for Tab and Escape.
- Removal of the old automatic-deposit system.
- Updated tutorial and control information.


DEVELOPMENT STATUS
------------------

I know that Woodland Outpost is still a small and slightly silly game—but that
is part of the fun!

This project is an experiment and, most importantly, my way of learning how to
make games with Godot. I am developing it one mechanic at a time, trying ideas,
making mistakes, learning why the first solution was sometimes a terrible
solution, and gradually turning the result into a more complete game.

The artwork is still simple and currently relies partly on AI-assisted assets
because visual art is not my strongest skill. I would like to improve its
consistency and personality as the project develops.

If you play Woodland Outpost and have an idea, encounter a bug, or think
something could be more enjoyable, please let me know. Feedback has already
influenced several major changes, and it can help shape what comes next.



LEARNING RESOURCES AND ACKNOWLEDGEMENTS
---------------------------------------

Woodland Outpost is also a learning project. These resources have been
especially helpful during development:

Godot documentation
https://docs.godotengine.org/en/stable/

Godot's first 2D game tutorial
https://docs.godotengine.org/en/stable/getting_started/first_2d_game/index.html

The r/godot community
https://www.reddit.com/r/godot/

GDQuest on YouTube
https://www.youtube.com/@Gdquest

GDQuest's Godot beginner learning path
https://www.gdquest.com/library/godot_getting_started_list_beginner/

Thank you to the Godot developers, documentation contributors, educators, and
community members who share their knowledge and make learning game development
possible.


FEEDBACK
--------

Did Hunger change how you planned an expedition? Was the visual backpack easy
to understand? Did the camp-management screen make storing resources more
meaningful? Did eating feel useful or too mechanical?

Player feedback will help determine the next version of Woodland Outpost.
