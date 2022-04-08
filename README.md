# AI Looting Script Roadmap
## ASAP
- [ ] Make edits to take advantage of saving player vehicle so player doesn't necessarily be in it
- [ ] Higher-level scope to work with multiple units via faux queue and worker paradigm
## Fast follow
- Standardize function names
- Refactor functions to separate scripts and set up functions library
## Future
- Units can loot all items from bodies
- Script options to limit what gets looted
- Looting AI can onlly store up to his extra load from clothing??
- If the above, multi-trip looting
- Looting from other sources? I.e cars
- AI just holds loot if player vehicle gets destroyed or never got in one??
# Completed tasks
- [X] Decide method to store current/last leader vehicle so AI can drop off loot
  - Currently, vehicle is sent at the time action is run and does not change
- [X] Calculate vehicle used cargo to determine if new weapon can be added