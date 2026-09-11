WOODLAND OUTPOST
================

A compact 2D survival-management game made with Godot.

Winter is approaching. Explore a procedurally generated forest, gather
supplies, return them to camp, and complete your cabin before time runs out.


CURRENT RELEASE
---------------

Version 0.2.0 — The Exploration & Gathering Update

This release expands Woodland Outpost's original gameplay loop with a larger
world, more deliberate gathering, limited carrying capacity, clearer
navigation, and contextual onboarding.


HOW TO PLAY
-----------

1. Explore the forest and locate wood, stone, and food.
2. Hold the interaction key near a resource to gather it.
3. Watch your backpack weight: it can carry a maximum of 12 kg.
4. Return to camp to deposit the resources you are carrying.
5. Use deposited materials to improve the camp.
6. Complete the cabin before winter arrives.

Gathering progress is preserved if you stop or move away, so you can return to
an unfinished resource later.


CONTROLS
--------

Move:               WASD or arrow keys
Gather / interact:  Hold E or ENTER
Pause:              Esc
Toggle fullscreen:  Alt + Enter


RESOURCES AND BACKPACK WEIGHT
-----------------------------

Food
  Weight: 1 kg per unit
  Gathering time: 3 seconds
  Distribution: Starter supplies available near camp

Wood
  Weight: 2 kg per unit
  Gathering time: 4 seconds
  Distribution: Starter supplies available near camp

Stone
  Weight: 3 kg per unit
  Gathering time: 6 seconds
  Distribution: Found at least 12 tiles from camp

The backpack holds 12 kg, so every expedition involves a choice: continue
exploring or return to camp and secure the resources already collected.


WHAT IS NEW IN VERSION 0.2.0
----------------------------

- A larger 72 × 44 tile procedural world.
- A player-following camera with correct world limits.
- Distance-based resource placement and greater scarcity.
- Guaranteed resource quantities that keep every generated world winnable.
- Minimum spacing between resources to prevent inaccessible clusters.
- A 12 kg backpack with different weights for each resource.
- Automatic resource depositing when returning to camp.
- Timed gathering with visible progress.
- Gathering that can be stopped and resumed without losing progress.
- Continuous gathering while the interaction key remains held.
- Player and resource gathering animations.
- Resource-specific sounds and particle effects.
- Clear collection and construction milestone feedback.
- An off-screen camp indicator with distance information.
- Contextual first-game instructions that react to player actions.
- Improved game balance, with a typical victory around Day 6.


DEVELOPMENT STATUS
------------------

I know that Woodland Outpost is still a small and slightly silly game—but that
is part of the fun!

This project is an experiment and, most importantly, my way of learning how to
make games with Godot. I am building it one mechanic at a time, testing new
ideas, making mistakes, and gradually turning it into something more complete
and enjoyable.

There is still plenty I would like to improve, so follow me on this little
development journey!

If you play the game and have an idea, find a problem, or think something could
be more fun, please let me know. Your suggestions could help shape the next
version of Woodland Outpost!


RUNNING THE GODOT PROJECT
-------------------------

The project is developed with Godot 4.7 and GDScript.

1. Install Godot 4.7 or a compatible Godot 4 release.
2. Clone or download the project repository.
3. Import the folder containing project.godot into the Godot Project Manager.
4. Open the project and run its main scene.


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

Did you complete the cabin before winter? Did the backpack feel fair? Were
distant resources satisfying to find?

Player feedback will help shape the next version of Woodland Outpost.
