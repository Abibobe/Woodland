The original provisional durations of up to 60 seconds per unit would currently make victory mathematically unrealistic:

- 35 Wood required
- 15 Stone required
- 7 Food consumed
- At least 11 backpack deliveries
- Only 7 days × 90 seconds = 630 seconds

For the first complete playtest, set these values in `resource_node.gd`:

```
@export_range(0.1, 120.0, 0.0) var food_gather_duration := 3.0
@export_range(0.1, 120.0, 0.1) var wood_gather_duration := 4.0
@export_range(0.1, 120.0, 0.1) var stone_gather_duration := 6.0
```

Approximate minimum gathering time becomes:

|Resource|Units|Duration|Total|
|---|---|---|---|
|Food|7|3 sec|21 sec|
|Wood|35|4 sec|140 sec|
|Stone|15|6 sec|90 sec|
|**Total**|**57**||**251 sec**|

That leaves roughly 379 seconds for exploration, returning to camp, depositing, and construction.

Run one complete game with these values and observe:

- Whether food can reliably be delivered before the end of Day 1.
- Whether the 12-unit backpack feels restrictive but fair.
- Whether distant stone creates meaningful expeditions.
- Whether gathering feels satisfying instead of repetitive.
- Which camp stage is normally reached around Days 2, 4, and 6.

This gives us a defensible baseline. We should only increase gathering durations if full victories still leave too much unused time.