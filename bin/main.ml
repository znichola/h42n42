let () = print_endline "Hello, World!"


(**
    Creeps are little creatures that roam the land.
    Their state is:
        - ID
        - seed value, used for random calculations
        - position
        - direction vector
        - time left to move
        - healthState : healthy, contaminated, beserk, mean

    I am thinking about reprisenting creep states are seperate arrays that get
    processed individually. 
    Advantage: removes this info from state, and
    seperates their behaviour. A simulation is then a composition of each creep
    vector calculated out.
    Disadvantage: spreads out behaviour, makes it harder to reason about? And
    still need to pass combinations of these lists for some calcs.

    Steps to calculate:
        Healthy creeps movement
        Contaminated creeps movement X Healthy pos, intersect
        Beserk creeps movement X Health pos, intersect
        Mean creeps movement X Healthy pos, seek to pos

        Healthy movement :: Healthy -> Healthy

        Contaminated movement :: (Healthy, Contaminated) -> (Healthy, Contaminated)

        Beserk movement :: (Healthy, Beserk) -> (Healthy, Beserk)

        Mean movement :: (Healthy, Mean) -> (Healthy, Mean)
*)

type vec = {x: int; y: int}

type creep = {id: int; pos: vec} (* plus other stuff*)


