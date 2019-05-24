# pico8

backups for all of my pico8 games :)

## Source Control

I have a bash command that runs the following:

```
cd ~/Library/Application\ Support/pico-8/carts
git add *
git commit -m "`date`"
git push origin master
```

## Tips

### Exporting cartrage

- `fn+f2` to capture cart image
- `save cart-name.bin` to get app

## Current Projects

For now I'm using this to track the current state of what I'm working on. Most recent game should be at the top.

### Rouge

- done: player movement, wall collision
- done: scrolling
- done: item pick up, drop, throw (for hp, mana, poison, paralize, invisibility)
- done: basic enemy movement and attack
- done: normal layer and special layer cell auto generation
- done: items and enemies hide in grass
- done: basic hud (hp, mana, xp, log)

- todo: leveling system (attack power=level?)
- todo: new level after door
- todo: spike damage
- todo: advanced potions (eg fire damage)
- todo: if fire damage will be a thing, need to do fire spreading
- todo: enemy status indicators (psn, par, on fire, etc)
- todo: spells (will player hold multiple spells, will they be accessed from menu or quick select?). if from menu, consider removing "log" from menu since it probably isnt needed for a simple game like this. Either way, I should show active spell in hud?
- todo: death and restart
