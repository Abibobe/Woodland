At the moment, every substantial tree or bush represents gameplay value. Increasing those counts would damage the balance you already like. Instead, we can make the woodland visually denser with scenery that cannot be gathered.

## Proposed approach: decorative undergrowth

Add several new non-interactive decoration types:

- Small saplings
- Leafy shrubs without berries
- Tree stumps
- Fallen logs
- Small clusters of weeds
- Dry leaves
- Tiny wildflowers
- Moss patches

These would:

- Have no resource value.
- Have no interaction prompt.
- Usually have no collision.
- Never occupy the same area as gatherable resources.
- Leave the camp and important paths readable.
- Appear in natural clusters rather than uniformly.

## Avoiding player confusion

Decorative vegetation must look different from resources:

|Harvestable resource|Decorative equivalent|
|---|---|
|Large, mature tree|Small sapling or stump|
|Berry bush with red berries|Plain green shrub|
|Large grey rock|Tiny pebbles or mossy stone|
|Gathering bar and prompt|No response|

This preserves the visual language: mature trees, berry bushes, and large rocks remain clearly valuable.

## Density layers

I would build the richer forest in three layers:

1. **Ground cover**  
    Grass, flowers, leaves, mushrooms, moss and ferns. We can increase this considerably.
2. **Undergrowth**  
    Saplings, plain shrubs, stumps and fallen logs. These occupy more visual space and will solve most of the emptiness.
3. **Dense woodland pockets**  
    Selected areas receive heavier vegetation, while paths, soil patches, camp surroundings and resource approaches stay open.

That creates contrast: small clearings surrounded by dense vegetation feel much more like a woodland than an evenly scattered field.

## Important design decision

For the first version, I recommend making the new undergrowth **non-colliding**. Colliding decorative trees could alter travel time, block resource access, and unintentionally change the Day 2–4–6 balance.

Once the visual distribution feels good, we could make only occasional fallen logs or dense thickets block movement.

## Suggested initial density

A good baseline for the `72 × 44` map would be:

- Existing small decorations: increase density from `0.32` to around `0.42`.
- Decorative shrubs: approximately `90`.
- Saplings: approximately `65`.
- Stumps: approximately `18`.
- Fallen logs: approximately `12`.
- Moss/leaf patches: approximately `80`.

These sound like large numbers, but they are tiny, non-interactive drawings distributed over more than 3,000 tiles.

The result should be a forest where the player still navigates freely, resources remain balanced and recognizable, but open grass no longer dominates the view.

The next phase should therefore be **Phase 11.1 — Decorative undergrowth**, starting with saplings and plain shrubs because they will make the biggest visual difference.