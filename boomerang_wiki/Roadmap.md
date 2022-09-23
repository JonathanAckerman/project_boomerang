here is a big old list of stuff that needs to be done in no particular order

# Gameplay
- data model for character/enemies/items/etc
- map implementation and design
- collision detection and resolution
- WWE arena sequence
- meta progression
    - this will probably be flushed out more once we have the MVP
- UI system
    - tbd: menus, lists, etc.
    - tbd: inventory
- HUD
    - tbd
- dialogue system
    - linear, voiced dialogue
    - should be able to trigger gameplay state changes (have I met this character, etc.)
- character controller
    - support both keyboard and gamepad
- camera controller
    - fixed on player (maybe eventually we'll move to a focal point model to include strong enemies)
- combat system
    - 4 weapons (one for each girl)
        - each should be distinct in strengths/weaknesses (like estoc vs halberd) and have positioning focused design
        - initial list:
            - hoola-hoop (aka boomerang)
                - AOE control in large spaces
                - can bounce off walls
            - rapier
                - movement in connected line segments
                - maybe can hit multiple enemies if they are lined up?
                - uses enemies for movement, bouncing from one to the next and respacing them as needed
            - boxer
                - close range
                - uses enemies for combat, punching one into another, sort of like pinball
            - yo-yo
                - AOEs centered on character
                - can clump enemies together
                - stun?
    - status effects 
        - interrupt: sort of like a short stun, used to interrupt actions like movement rather than having a combat effect
        - stunned: cannot move or act
        - forced-movement: movement is overriden or influenced
        - fear: makes enemies run away from player (not necessarily linearly, can be a random walk)
            - interrupt enemies who bump into each other
    - I think integer HP would be really interesting, but floating point HP might be better for allowing progression in stats like dmg
- AI
    - pathfinding
    - enemy combat
    - npcs/roaming shopkeepers/etc
    - ally combat #girlsummons

# Game Design
all this stuff will have to be workshopped and probably tweaked later
- player character is a chat stand-in character but they use the weapons provided by the girls. The girls are in the game as Andre-esque shops.
- player should be able to talk to the girls regularly
    - maybe there's a pokemon-esque cell-phone that you can call them up with
        - this should have gameplay effects like an ER summon in a tough fight or something #girlsummons
- each weapon the player can use should provide:
    - a combat centric movement mechanic
    - a traversal movement micro-dynamic to engage with (eg: Rolling in zelda, staying on the charging strip in DS)
    - a redemption arc dynamic in combat (eg: Axe-Throwing)
- ^artsy-fartsy-warning each weapon should reflect the personality of the girl in the mechanic
    - the boomerang has a sort of "attention-seeking" quality to it, so the out-going girl can use it as a way to revel in being the center of attention
    - the rapier is all about avoidance and spacing, so we give that to the quiet or tsundere girl

# Tech
- graphics engine
    - we'll have to decide on 2d vs 3d, on the one hand 3d can sell itself visually on the otherhand the vtubers will be 2d so maybe 2d art across the board will fit better (and be less work)
- payment service
- security
- launcher
- store
- optimistic replication
- game server
- login server
- user database

# Business
- LLC formation

# Vtuber Agency
- find a way to broadcast to a pool of talent

