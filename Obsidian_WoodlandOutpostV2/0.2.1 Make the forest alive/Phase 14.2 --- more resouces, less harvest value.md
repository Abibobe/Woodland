That is a genuinely interesting idea. Mathematically, it preserves the total resources:

|Resource|Current|Proposed|Total unchanged|
|---|---|---|---|
|Wood|28 trees × 3|84 trees × 1|84|
|Stone|10 rocks × 3|30 rocks × 1|30|
|Food|8 bushes × 3|24 bushes × 1|24|

It would make the map visually richer while changing the gathering experience:

- More exploration between individual units.
- Less time standing at one node continuously.
- More frequent gathering completions.
- Resources become a substantial part of the forest scenery.
- Depleted nodes disappear much more frequently.

The total theoretical gathering time remains unchanged because every unit still takes the same duration.

## Recommended settings

In `resource_spawner.gd`:

```
@export_range(0, 300) var tree_count: int = 84
@export_range(0, 150) var rock_count: int = 30
@export_range(0, 150) var bush_count: int = 24
```

Set:

```
@export_range(1, 10) var units_per_resource := 1
```

Remember to update any Inspector overrides on `ResourceSpawner`; scene values override script defaults.

## Don’t triple the nearby guarantees

Keep starter resources controlled:

```
nearby_tree_count = 12
nearby_bush_count = 6
```

Otherwise, placing 36 trees and 18 bushes near camp would make the starting area excessively crowded.

The remaining resources will still make the wider map much denser.

## Update the winnability calculation

Your existing calculation already supports this. With:

```
units_per_resource = 1
```

the automatic minimums become:

```
53 trees
23 rocks
11 bushes
```

Your configured counts of `84`, `30`, and `24` remain safely above those minimums.

## Cluster placement adjustment

With 138 resource nodes, a two-tile exclusion around every resource would remove most valid cluster positions.

In `ForestClusterLayer`, set:

```
Resource Clearance: 0
```

Clusters may visually surround resources, but they cannot be centred directly on a resource cell. Since resource sprites render above the cluster layer, they should remain visible.

## Possible concern: gathering value

A large mature tree disappearing after producing only one piece of wood may feel slightly strange. I would test it as proposed first. If it feels unsatisfying, two alternatives are:

- Leave a temporary stump after depletion.
- Use `2` units per resource and roughly `1.5×` the node counts.

My preference is to test your full `3× nodes / 1 unit each` idea. It preserves the economy but meaningfully changes exploration and should make the woodland feel much more substantial. Keepñado