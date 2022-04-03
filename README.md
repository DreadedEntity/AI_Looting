# AI Looting Script Roadmap
## ASAP
- [X] Calculate vehicle used cargo to determine if new weapon can be added

~~- Figure out how to pull all items from vehicle cargo~~ Not necessary

~~- Function to summate all item weights and return number~~ Not necessary
- [X] Decide method to store current/last leader vehicle so AI can drop off loot
  - Currently, vehicle is sent at the time action is run and does not change
- [ ] Make edits to take advantage of the above
## Fast follow
- Standardize function names
- Higher-level scope to work with multiple units via faux queue and working paradigm
- Refactor functions to separate scripts and set up functions library
## Future
- Units can loot all items from bodies
- Script options to limit what gets looted
- Looting AI can onlly store up to his extra load from clothing??
- If the above, multi-trip looting
- Looting from other sources? I.e cars
- AI just holds loot if player vehicle gets destroyed or never got in one??
