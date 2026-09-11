# Woodland Outpost v0.2.0 : A Bigger Forest and Better Expeditions!

Hey everyone!

A little while ago, I started thinking about how to make Woodland Outpost more enjoyable and give the player a proper challenge.

The first version was working, but super silly. Gathering resources was ultra quick, the map was utterly small, and the player could transfer  everything to the camp without worrying too much. It was possible to complete the game, but there were not many interesting decisions along the way.

So I started experimenting with a few ideas and those experiments have now become **Woodland Outpost v0.2.0: The Exploration & Gathering Update!**

## Gathering now require a little effort. Maybe.

In the previous version, gathering was instantaneous: approach a resource, press a button, and receive it.

Now, the player must hold `E` while gathering, and every resource requires a different amount of time:

- Food takes 3 seconds.
    
- Wood takes 4 seconds.
    
- Stone takes 6 seconds.
    

A progress bar appears above the resource, and your progress is preserved if you stop gathering or move away, so you can return later and continue from where you left off. And holding `E` also allows you to gather multiple units continuously, so you can stand aside to a tree and "cutting" it down.

But timing alone was not enough. During my first playtest, gathering technically worked but it still felt a little boring!

So I added player movement, resource animations, different sounds, particles, and a clear collection popup. Now every gathering action has much more feedback and feels far more satisfying.

## I definetely have pick a bigger backpack...

The player can no longer carry unlimited resources.

The backpack has a maximum capacity of **12 kg**, and every resource has a different weight:

- Food weighs 1 kg.
    
- Wood weighs 2 kg.
    
- Stone weighs 3 kg.
    

This creates a first decision while exploring: **Should I continue searching, or should I return to camp and deposit what I already have?**

The backpack seemed restrictive but fair during my playtests, and it finally gives the player a good reason to return to camp regularly.

## Still not a proper forest...but is something...

The world has grown from a small single-screen area into a procedural map measuring **72 × 44 tiles**.

The camera now follows the player, and resources are distributed according to their distance from camp:

- Some wood and food are guaranteed nearby.
    
- Additional supplies can appear throughout the forest.
    
- Stone is found at least 12 tiles away from camp.
    

The generator also keeps enough space between resources, preventing dense walls and helping ensure that every resource remains accessible.

Every generated map contains enough materials to complete the game, plus an additional safety margin. The forest is scarcer and more challenging, but every world should still be winnable. Or at least, this is true *IF* my calculation aren't wrong. Let me know if a miscalculated something!

I feel that the map is still super small, and the forest is still terrible empty. But step by step I hope to make it a little less ugly and a little more big, let's see. 
## I have to admit, my first option was a map. Or a compass. Not this!

Exploring a larger world created another problem: it became much easier to lose the camp!

To help with navigation, I added an off-screen camp indicator. When the camp leaves the visible area, a golden arrow points toward it and displays the approximate distance in feets (is feets or feet also for multiples? Sorry, I came from a metric contry!), that are basically tiles. 

You still need to explore and remember where useful resources are, but returning home should no longer become frustrating.

I have to be honest, I'm not super happy about the arrow: the first option was to add a minimap in the bottom right corner of the map, but seems a huge time-consuming challenge for me, and at least for now is I believe that I can put this option aside. Then I consider to add a nice compass in the middle of the top bar but... again, I face tons of difficulties. So, the arrow is the solution that I find out (thanks https://inputrandomness.com/! )

## Mmmm, are you tell me something that I don't get? 

When enough resources have been deposited for the next construction stage, the game now displays a larger "milestone" notification.

Gathering, depositing, and construction should therefore feel like parts of one connected progression loop rather than separate systems.

The game also includes a new contextual tutorial. Instead of interrupting the player with a large instruction screen, it introduces movement, gathering, backpack weight, depositing, and construction as those mechanics become relevant.

Once completed, the tutorial will not appear again unless its saved progress is reset.

## How does the new balance feel?

I completed a full playtest with the new systems:

- I reached the first construction stage around Day 2.
    
- I reached the second stage around Day 4.
    
- I completed the cabin around Day 6.
    
- Food remained manageable.
    
- The 12 kg backpack felt fair.
    
- Distant stone created meaningful expeditions.
    
- Gathering felt much more satisfying after adding the new feedback.
    

This is very close to the progression I was hoping for: enough pressure to require some planning, but still with a small margin before winter arrives.

## Hey! That's a tutorial!

I also realized that, after adding all these new mechanics, the original instructions were farto be enough clear!

Woodland Outpost now includes a proper contextual tutorial: instead of stopping the game and presenting everything at once, it introduces each mechanic when it becomes relevant.

It begins with movement, then guides the player through gathering, backpack capacity, returning resources to camp, and starting construction. Each message remains visible until the corresponding action is completed, so the player can learn by actually playing.

Once the tutorial is finished, the game remembers it (or it should remember) and does not show it again in future sessions. The complete instructions remain available through the **How To Play** menu if anyone needs a reminder.

It is a small addition, but I hope it makes the first expedition much clearer and more welcoming!
## Still a little experiment!

I know that Woodland Outpost is still a small and slightly silly game but that is part of the fun!

This project is an experiment and my way of learning how to make games with Godot. I’m building it one mechanic at a time, testing ideas, making mistakes, and gradually turning it into something more complete and enjoyable.

If you try the new version, please let me know what you think!

Did you complete the cabin before winter? Did the backpack feel fair? Did you enjoy the longer expeditions? And, most importantly, was gathering satisfying?

Follow me on this little development journey and if you have ideas about how Woodland Outpost could improve, I would love to hear them!