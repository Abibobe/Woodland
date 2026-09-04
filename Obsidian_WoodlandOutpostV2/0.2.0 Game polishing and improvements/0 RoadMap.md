
We want to transform Woodland Outpost from a relaxed gathering game into a more strategic survival experience—without adding combat or changing its peaceful identity.

The new challenge will come from three connected systems:
![[mermaid-diagram.png]]
## Planned modifications

### 1. Longer, resumable gathering

Gathering will no longer complete immediately.

- Each resource requires time to gather.
- A progress bar appears above the selected resource.
- The player presses `E` once to begin gathering.
- Gathering stops when the player:
    - Presses `E` again
    - Moves away
    - Leaves interaction range
    - Opens a menu
- Progress remains saved on that resource.
- Returning later resumes from the previous percentage.
- The resource is awarded only at 100%.
- Gathering animations, sounds, particles, and feedback continue during the process.

Provisional gathering durations:

|Resource|Initial test duration|
|---|---|
|Food|10–15 seconds|
|Wood|25–35 seconds|
|Stone|40–60 seconds|

We will initially test with much shorter times before deciding the final values.

### 2. Weight-based backpack

Gathered resources will first enter the player’s backpack.

Initial configuration:

|Resource|Weight|
|---|---|
|Food|1|
|Wood|2|
|Stone|3|

Initial backpack capacity: **12 weight units**.

Rules:

- Different combinations of resources share the same capacity.
- The HUD shows `Backpack: current weight / maximum weight`.
- Gathering cannot award a resource when there is insufficient space.
- Gathering progress is never lost because the backpack is full.
- A clear **“Backpack full — return to camp”** message appears.
- The existing denied-action sound can accompany the warning.
- Backpack capacity remains fixed in the first version.

### 3. Camp storage and depositing

The existing resource totals will become the camp’s stored supplies.

- Carried resources and deposited resources are tracked separately.
- Returning to the camp automatically deposits the backpack.
- Depositing takes approximately one second.
- The HUD counters animate when resources are transferred.
- A delivery summary appears:

```
Supplies delivered
+4 Wood
+2 Stone
+3 Food
```

- Construction can use only deposited resources.
- The camp reports when the next stage becomes affordable.
- Daily food consumption checks camp storage first.
- If necessary, it can consume food from the backpack afterward.

### 4. Larger map

The procedural woodland will become larger, making expeditions and return journeys more meaningful.

- The camp remains near the centre.
- Trees remain relatively common.
- Berry bushes appear in smaller clusters.
- Stone is less common and generally farther from camp.
- Later-stage materials require longer expeditions.
- The player needs to consider remaining daylight, backpack space, and travel distance.

### 5. Scarcer but guaranteed resources

Resources will be less abundant, but every generated map must remain winnable.

Generation will guarantee minimum quantities based on:

- Total cabin construction requirements
- Expected food consumption
- A safety margin for balancing

A possible starting formula is:

```
Minimum generated amount = required amount × 1.5
```

The generator must also ensure:

- Enough nearby resources to reach the campfire stage
- Some accessible food near camp
- Enough total resources to complete the cabin
- No required resources inside inaccessible locations
- No invalid resource overlaps

### 6. Navigation back to camp

Because the map will be larger, the player needs help finding home.

The first version will include:

- A camp-direction indicator when camp is off-screen
- A recognizable camp area
- Possibly a distance indicator

A full minimap is not part of the initial implementation.

## Implementation plan

### Phase 1 — Prepare the resource data

1. Review the current resource, player, HUD, camp, and game-state scripts.
2. Separate carried resources from camp storage.
3. Define the backpack capacity.
4. Define the weight of each resource.
5. Add functions for:
    - Calculating current weight
    - Checking available capacity
    - Adding carried resources
    - Depositing resources
6. Verify that the old game still runs before connecting the new behaviour.

### Phase 2 — Implement the backpack

7. Add gathered resources to the backpack instead of directly to storage.
8. Prevent collection when there is insufficient space.
9. Add the full-backpack message and sound.
10. Display backpack weight in the HUD.
11. Test different combinations of wood, stone, and food.
12. Verify that capacity calculations remain correct.

### Phase 3 — Implement camp deposits

13. Detect when the player returns to the camp.
14. Transfer carried resources into camp storage.
15. Add the short deposit sequence.
16. Display the delivery summary.
17. Update and animate the resource counters.
18. Make construction use camp storage only.
19. Verify daily food consumption with stored and carried food.

### Phase 4 — Implement resumable gathering

20. Add required gathering time to each resource type.
21. Store gathering progress inside each resource node.
22. Start gathering when `E` is pressed.
23. Stop gathering when the interaction is interrupted.
24. Preserve progress after interruption.
25. Add the progress bar.
26. Connect gathering animation and sounds.
27. Award the resource at 100%.
28. Handle the full-backpack case without losing progress.
29. Test the complete system using short gathering times.

### Phase 5 — Polish gathering

30. Introduce different durations for food, wood, and stone.
31. Add smooth progress-bar animation.
32. Add resource shaking, particles, or impact feedback.
33. Improve start, stop, resume, and completion feedback.
34. Test whether gathering feels strategic rather than boring.
35. Adjust the final durations.

### Phase 6 — Enlarge the world

36. Increase the procedural map dimensions.
37. Confirm that terrain, collisions, camera limits, and spawning still work.
38. Place resources using distance bands around camp.
39. Make stone and some food clusters more distant.
40. Add minimum resource guarantees.
41. Prevent unreachable or overlapping resource placement.
42. Test many generated maps for winnability.

### Phase 7 — Add navigation support

43. Add the off-screen camp-direction indicator.
44. Hide it when the camp is visible.
45. Test it from every part of the enlarged map.
46. Decide whether a distance value is also useful.

### Phase 8 — Balance the complete loop

47. Measure typical expedition duration.
48. Measure how many resources fit in one backpack.
49. Measure how many trips are needed for each camp stage.
50. Adjust:

- Backpack capacity
- Resource weights
- Gathering durations
- Resource abundance
- Map size
- Construction costs
- Food consumption
- Winter deadline

51. Complete multiple victory and defeat playthroughs.
52. Ask external testers whether the challenge feels fair.

## Not included in the first version

To keep the update manageable, we will initially exclude:

- Backpack upgrades
- Tools and gathering-speed upgrades
- A minimap
- Progress decay
- Dropping resources manually
- Multiple backpack types
- Combat or enemies
- Weather
- Stamina
- A cold meter
- Gameplay saving

Those can be reconsidered after testing the new core loop.

## Definition of success

The update succeeds if the player regularly needs to make decisions such as:

- Which resource should I collect first?
- Do I have enough backpack space for that stone?
- Should I finish gathering or return before night?
- Is this distant resource worth the travel time?
- Should I bring food home or prioritize construction materials?
- Can I afford one more expedition before winter?

The target experience is not relentless punishment. It is the feeling that the cabin remains achievable, but every expedition needs a little planning.