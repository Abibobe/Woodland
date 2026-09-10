Hey everyone!

The last time I worked on Woodland Outpost, I made Hunger visible, and AS USUAL, that gave the game permission to ask several uncomfortable questions: How much food am I carrying? How much space is left? Why does a log weigh two kilograms but look exactly like the number `2`? And, most importantly: where do all my supplies actually go when I return to camp?

The answer used to be: **they vanish magically into storage after a short timer. Please do not investigate further.**

It worked, but it was not much of a decision.

Version **0.2.3** replaces that invisible transaction with a visual backpack and a proper camp-management screen. This is the story of why I built it, how the system works, and how a series of huge UI mistakes taught me quite a lot about Godot.

## The theoretical problem: convenience was removing choice

The old gameplay loop was simple:

1. Gather resources.
2. Walk back to camp.
3. Wait briefly.
4. Everything is deposited automatically.
5. Build when the numbers are high enough.

Automatic depositing was convenient, but it also removed the interesting part. The player did not decide what to store, what to keep, or what to take on the next expedition.  The new Hunger system made this weakness much clearer: food now has two competing purposes, since it is useful for survival while exploring but it also occupies precious backpack capacity. 

If every resource is unloaded automatically, the player cannot intentionally keep emergency berries.

If camp storage is only a set of numbers in the HUD, preparing a new load is almost impossible to understand.

So I wanted the camp to answer three questions on one screen:

- What am I carrying?
- What is stored safely at camp?
- What does the next construction stage require?

That became the foundation of the new interface.

## Step one: make weight physical

The backpack can carry **12 kg**:

- Food weighs 1 kg.
- Wood weighs 2 kg.
- Stone weighs 3 kg.

Originally, this was only displayed as a counter such as `8 / 12 KG`. The information was accurate, but the player still had to calculate what was filling the bag.

The new backpack represents every kilogram as one visible cell. Berries occupy one cell, a log stretches across two, and a pile of stone stretches across three. This makes the cost of an item visible before the player has to think about the number.

The grid contains six columns and two rows. Internally, resources are packed from heaviest to lightest. The code looks for a row with enough contiguous space and prevents an item from wrapping across the boundary.

This matters because, without the row check, a two-cell log could begin in the final column of the first row and finish in the first column of the second. Mathematically correct. Spiritually unacceptable.

## Step two: reuse the backpack instead of drawing it twice

The first architectural challenge appeared when I wanted the backpack inside the camp menu.

I could copy all the drawing and packing code into the "camp menu script", but then I would have two backpack implementations. Every future visual change would need to be made twice, and sooner or later one of them would decide that stone weighs seventeen kilograms.

Instead, I extracted the renderer into a reusable `BackpackGrid` component.

The standalone **TAB** screen now handles the window, background, labels, and opening animation. `BackpackGrid` handles only the twelve cells, item placement, icons, and mouse interaction. The camp menu can create another instance of that same component and feed it the same backpack contents. This was a much cleaner design but my first attempt mixed the old and new scripts together.

## Step three: the camp becomes a workspace

The new screen places the backpack on the left and camp information on the right.

The right side combines:

- Stored Food, Wood, and Stone.
- The next construction stage.
- Its resource requirements.
- The build action.
- Controls for retrieving supplies.

The player can click a resource inside the backpack to deposit one unit, use **Deposit All** to unload everything, or take stored resources back for the next expedition. Capacity validation still applies: taking Stone requires 3 kg of free space.

This changes returning to camp from an automatic event into a deliberate phase of the loop:

**Explore -> gather -> return -> reorganize -> build -> prepare -> leave again.**

That is much closer to the kind of small survival-management game I want Woodland Outpost to become.

## UI attempt number one: technically present

![first_attempt](https://img.itch.zone/aW1nLzI5ODk2Mjg3LnBuZw==/original/04Nh1c.png "first_attempt")  

_The first layout technically contained a camp menu. “Contained” is doing heroic work in that sentence._

My first full-screen attempt appeared in the upper-left corner, with compressed labels and controls floating over the world.

The reason was a leftover from the old compact popup: the root `CampMenu` control was still approximately 40 × 40 pixels. I had set the new background and centre container to `Full Rect`, but they were filling the full rectangle of that tiny parent—not the viewport.

The solution was to make the root itself fill the viewport, then apply full anchors to the dark background and centre container. Once the parent had the correct size, the layout system could finally do what I had been confidently asking it to do.

## UI attempt number two: readable, but rather naked

![](https://img.itch.zone/aW1nLzI5ODk2MzAwLnBuZw==/original/D%2FFyIB.png)  

_The structure is working: backpack on the left, storage and construction on the right._

At this stage, the hierarchy was correct and the two-panel idea was visible. The screen could display the empty backpack, stored quantities, and construction requirements together.

It was already much more readable than the old popup, but it still looked like an engineering diagram. Useful, clean, and perhaps slightly worried that somebody might ask it to be charming.

## UI attempt number three: the invisible inventory

![](https://img.itch.zone/aW1nLzI5ODk2MzA3LnBuZw==/original/2mZSBO.png)  

_The item blocks know their sizes, but the textures are missing. Behold: abstract wood._

When resources appeared in the camp backpack, their coloured shapes were correct—but their icons were invisible.

This bug came directly from making `BackpackGrid` reusable. The normal backpack and camp backpack were separate component instances, and exported textures belong to the instance. Assigning the Food, Wood, and Stone textures to the original grid did not magically assign them to the new one.

Once the three icon resources were assigned to the camp instance, the same renderer worked correctly in both places.

It was a useful reminder that shared code does not mean shared Inspector values.

## The finished exchange screen

![](https://img.itch.zone/aW1nLzI5ODk2MzE5LnBuZw==/original/gFyXB9.png)  

_The current result: physical backpack space, visible resources, camp storage, and construction on one screen._

The final layout lets the player read the whole resource situation without leaving the screen or doing mental arithmetic.

A backpack containing one Stone, two Wood, and one Food visibly occupies eight of its twelve kilograms. Camp storage remains quantity-based because it can hold far more than twelve items, while the backpack stays spatial because its limitation is important.

This difference is deliberate:

- The backpack answers: **How much can I carry?**
- Camp storage answers: **How much do I own?**
- Construction answers: **What am I trying to achieve?**

Putting those answers beside each other is what turns the interface into a decision tool.

## The bugs hiding inside a clickable log

Making the resources clickable created another educational problem.

When a player clicked a log, the transfer signal immediately changed the inventory and refreshed the grid. The refresh attempted to call `free()` on the item block that was still processing its own mouse event.

Godot responded with:

`Object is locked and can't be freed.`

Which is a very reasonable objection when an object is asked to destroy itself halfway through answering the door.

Replacing `free()` with `queue_free()` solved it. The clicked block stops accepting input immediately, but its destruction waits until the current event has finished. The inventory can rebuild safely at the end of the frame.

## The backpack that would not let the player leave

During the component refactor, I also accidentally restored an older version of `backpack_view.gd`. Its closing function only called `hide()`.

Visually, the backpack disappeared. Logically, the game was still waiting for a `view_closed` signal that never arrived. Movement, gathering, Hunger, and the day cycle therefore remained disabled.

The corrected flow is:

1. Start the closing animation.
2. Hide the backpack after the tween.
3. Reset its visual state.
4. Emit `view_closed`.
5. Let `GameManager` resume the paused gameplay systems.

That distinction—hidden interface versus completed interface state—was small but important.

## Escape, the enthusiastic multitasker

One final bug appeared when pressing ESC inside the backpack. The backpack closed, but the pause menu opened behind it during the same keypress.

The pause menu was checking `Input.is_action_just_pressed()` from `_process()`. That global polling method still saw Escape even after `GameManager` marked the input event as handled.

I moved pause handling into `_unhandled_input()` and gave modal interfaces priority. Now the flow is explicit:

1. If the backpack is open, ESC closes the backpack.
2. If the camp is open, ESC  belongs to the camp interface.
3. Otherwise, ESC toggles the pause menu.

One key, one action, zero secret menus lurking underneath.

## What changed in v0.2.3

- Hunger is visible and food can be eaten manually.
- TAB opens a visual twelve-space backpack.
- Food, Wood, and Stone visibly occupy one, two, and three cells.
- Backpack rendering is now a reusable UI component.
- The camp has a full-screen management interface.
- Carried and stored resources are visible together.
- Individual resources can be deposited or retrieved.
- Deposit All provides a faster unloading option.
- Retrieval respects the remaining backpack capacity.
- Construction requirements update immediately after transfers.
- Automatic resource depositing has been removed.
- Inventory changes refresh correctly after eating.
- Modal input handling prevents overlapping menus.
- Transfer sounds, hover states, messages, and flashes improve feedback.

## What did this actually improve?

The biggest change is not that the game has another menu. It is that resources now have a visible journey.

They are found in the forest, placed inside limited backpack space, carried home, transferred into storage, and finally spent on construction. Every step is understandable, and several of those steps ask the player to make a choice.

The system still has room to grow. Eating remains somewhat mechanical, and a future version may distinguish quick berries from proper meals prepared at camp. The new camp screen gives that future system a natural home—but I am deliberately stopping here before one innocent meal button develops its own agricultural economy.

For now, I want to see how the new exchange system feels during complete playthroughs.

If you try v0.2.3, I would love to know:

- Do you understand the resource weights without reading the numbers?
- Do you use individual transfers, or mostly Deposit All?
- Do you retrieve Food before a long expedition?
- Does returning to camp now feel like a planning moment?
- Did you manage to open two menus at once in a way I have not yet imagined?

Woodland Outpost remains my small, slightly silly experiment for learning Godot. This update involved reusable components, dynamic UI generation, signals, deferred deletion, input propagation, resource ownership, and several mistakes that made all of those subjects much easier to understand.

Honestly, that is a pretty good result for a feature that began with: “Maybe the player should see when he have to eat something”

Thank you for playing, testing, and sharing your ideas.

See you in the woods!