# AI Looting Script Roadmap
## ASAP
- [X] Handle issue of last player vehicle possibly being too far away and units trying to run KM's away to drop off loot
- [X] Handle issue of last player vehicle being destroyed, then loot order given
- [X] AI just holds loot if player vehicle gets destroyed or never got in one??
## Fast follow
- Standardize function names
- Refactor functions to separate scripts and set up functions library
## Future
- Units can loot all items from bodies
- Script options to limit what gets looted
- Looting AI can only store up to his extra load from clothing??
- If the above, multi-trip looting
- Looting from other sources? I.e cars
# Completed tasks
- [X] Decide method to store current/last leader vehicle so AI can drop off loot
  - Currently, vehicle is sent at the time action is run and does not change
- [X] Calculate vehicle used cargo to determine if new weapon can be added
- [X] Make edits to take advantage of saving player vehicle so player doesn't necessarily be in it
- [X] Higher-level scope to work with multiple units via faux queue and worker paradigm