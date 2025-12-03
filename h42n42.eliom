let%server application_name = "h42n42"
let%client application_name = Eliom_client.get_application_name ()

let%server () =
  Ocsipersist_settings.set_db_file "local/var/data/h42n42/h42n42_db"

(* Create a module for the application. See
   https://ocsigen.org/eliom/manual/clientserver-applications for more
   information. *)
module%shared App = Eliom_registration.App (struct
    let application_name = application_name
    let global_data_path = Some ["__global_data__"]
  end)

(* As the headers (stylesheets, etc) won't change, we ask Eliom not to update
   the <head> of the page when changing page. (This also avoids blinking when
   changing page in iOS). *)
let%client _ = Eliom_client.persist_document_head ()

(* Define a service for the [] or '/' or root path with a GET method *)
let%server main_service =
  Eliom_service.create ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

(* Insert into the client client context the server defined value *)
let%client main_service = ~%main_service

[%%shared open Eliom_content]
[%%client
open Js_of_ocaml
open Js_of_ocaml_lwt
open Js_of_ocaml.Dom_html
open Html.D
open Lwt.Syntax
]

(* --------------- *)
(* GLOBAL STATE    *)
(* --------------- *)

[%%client
type global_state = {
  mutable mouse_x: int;
  mutable mouse_y: int;
  mutable creet_count: int;
  mutable healthy_count: int;
  mutable tick: int;
  mutable game_over: bool;
}

let global = {
  mouse_x = 0;
  mouse_y = 0;
  creet_count = 0;
  healthy_count = 0;
  tick = 0;
  game_over = false;
}

(* Initialize global mouse tracking *)
let () =
  let rec track_mouse () =
    let open Lwt_js_events in
    let* evt = mousemove window in
    global.mouse_x <- evt##.clientX;
    global.mouse_y <- evt##.clientY;
    track_mouse ()
  in
  Lwt.async track_mouse
]


(* --------------- *)
(* World COMPONENT *)
(* --------------- *)

let%client world_component () =
  Html.D.div
    ~a:[Html.D.a_class ["world"]]
    [ Html.D.div ~a:[Html.D.a_class ["river"]] []
    ; Html.D.div ~a:[Html.D.a_class ["grass"]] []
    ; Html.D.div ~a:[Html.D.a_class ["hospital"]] []
    ]


(* --------------- *)
(* Utils           *)
(* --------------- *)

let%client get_stats () =
  let width = window##.innerWidth in
  let height = window##.innerHeight in
  let total_parts = 6 in (* 1 + 4 + 1 *)
  let part_height = float_of_int height /. float_of_int total_parts in
  (width, height, part_height)

let%client get_section (part_height, y_height) = 
  let river_end = part_height in
  let grass_end = part_height +. (4.0 *. part_height) in
  let section = 
    if y_height < river_end then "River"
    else if y_height < grass_end then "Grass"
    else "Hospital"
  in
  section

let%client get_current_time () =
  let date = new%js Js.date_now in
  (Js.to_float date##getTime) /. 1000.0
  [@@warning "-unused-value-declaration"]


let%client normalize dx dy =
  let mag = sqrt (dx *. dx +. dy *. dy) in
  if mag = 0.0 then (0.0, 0.0)
  else (dx /. mag, dy /. mag)

(* --------------- *)
(* CREET COMPONENT *)
(* --------------- *)

[%%client
type health_status = 
  | Healthy
  | Sick of { lifetime: float }
  | Berserk of { lifetime: float }
  | Mean of { lifetime: float }
[@@warning "-unused-constructor"]

type creet_state = {
  mutable x: float;
  mutable y: float;
  mutable vx: float;
  mutable vy: float;
  id: int;
  mutable health: health_status;
  mutable grabbed: bool;
  element: Html_types.div Html.elt;
}
[@@warning "-unused-field"]
]

(* Global counter for unique IDs *)
let%client next_creet_id = ref 0

let%client generate_unique_id () =
  let id = !next_creet_id in
  next_creet_id := !next_creet_id + 1;
  id

let%client get_creet_speed creet_health =
  let base_speed = match creet_health with
    | Healthy -> 1.0
    | _ -> 0.85
  in
  (* Progressive speed increase: starts at base_speed, caps at 6x base_speed after 7200 ticks*)
  let tick_multiplier = 1.0 +. (3.0 *. (1.0 -. exp (-. float_of_int global.tick /. 7200.0))) in
  base_speed *. tick_multiplier

let%client get_creet_size creet =
  match creet.health with
      | Mean _ -> 34.0
      | Berserk { lifetime } -> 40.0 +. (3.0 *. 40.0) *. (1.0 -. lifetime /. 22.0 )
      | _ -> 40.0

let%client get_creet_css_class creet_health =
  match creet_health with
      | Sick _ -> "sick"
      | Mean _ -> "mean"
      | Berserk _ -> "berserk"
      | _ -> ""

let%client is_point_in_creet creet x y =
  let size = get_creet_size creet in
  let fx = float_of_int x in
  let fy = float_of_int y in
  fx >= creet.x && fx <= creet.x +. size &&
  fy >= creet.y && fy <= creet.y +. size

let%client get_dir_to_healthy creet all_creets =
  let candidates =
    List.fold_left (fun acc other ->
      if other.id = creet.id then acc
      else
        match other.health with
        | Healthy ->
            let dx = other.x -. creet.x in
            let dy = other.y -. creet.y in
            let dist2 = dx *. dx +. dy *. dy in
            (dist2, dx, dy) :: acc
        | _ -> acc
    ) [] all_creets
  in

  match candidates with
  | [] -> None
  | _ ->
      let sorted = List.sort (fun (d1, _, _) (d2, _, _) -> compare d1 d2) candidates in
      let (dist2, dx, dy) = List.hd sorted in
      let mag = sqrt dist2 in
      if mag = 0.0 then None
      else Some (dx /. mag, dy /. mag)

let%client create_creet id start_x start_y =
  let angle = Random.float (2.0 *. Float.pi) in
  let (vx, vy) = normalize (cos angle) (sin angle) in
  let creet_div = div ~a:[ a_class ["creet"] ; a_id (Printf.sprintf "creet-%d" id) ] [ txt "🐛" ]in

  (* Initialize creet *)
  {
    x = start_x;
    y = start_y;
    vx;
    vy;
    id;
    grabbed = false;
    health = Healthy;
    element = creet_div;
  }

let%client update_healthy_count all_creets =
  let count = List.fold_left (fun acc creet ->
    match creet.health with
    | Healthy -> acc + 1
    | _ -> acc
  ) 0 all_creets in
  global.healthy_count <- count;
  if count = 0 then global.game_over <- true

let%client update_creet_position creet all_creets =
  let size = get_creet_size creet in
  let speed = get_creet_speed creet.health in

  let (width, height, _) = get_stats () in
  let width_f = float_of_int width in
  let height_f = float_of_int height in

  if creet.grabbed then (
    (* Follow mouse when grabbed *)
    creet.x <- float_of_int global.mouse_x -. (size /. 2.0);
    creet.y <- float_of_int global.mouse_y -. (size /. 2.0);
  ) else (
    let (vx, vy) = match creet.health with
    (* Mean creets target healthy ones *)
    | Mean _ ->
        (match get_dir_to_healthy creet all_creets with
        | Some (dx, dy) -> (dx, dy)
        | None -> (creet.vx, creet.vy))
    (* Others randomly change direction *)
    | _ ->
        if Random.float 1.0 < 0.01 then
          let angle = Random.float (2.0 *. Float.pi) in
          (normalize (cos angle) (sin angle))
        else
          (creet.vx, creet.vy)
    in
    creet.vx <- vx; creet.vy <- vy;
    creet.x <- creet.x +. (creet.vx *. speed);
    creet.y <- creet.y +. (creet.vy *. speed);
    (* Bounce off walls *)
    if creet.x <= 0.0 || creet.x >= width_f -. size then
      creet.vx <- -.creet.vx;
    if creet.y <= 0.0 || creet.y >= height_f -. size then
      creet.vy <- -.creet.vy;
  );

  (* Clamp position *)
  creet.x <- max 0.0 (min (width_f -. size) creet.x);
  creet.y <- max 0.0 (min (height_f -. size) creet.y);

  (* Update DOM element style *)
  let creet_element = Eliom_content.Html.To_dom.of_div creet.element in
  creet_element##.style##.left := Js.string (Printf.sprintf "%.2fpx" creet.x);
  creet_element##.style##.top := Js.string (Printf.sprintf "%.2fpx" creet.y);
  creet_element##.style##.fontSize := Js.string (Printf.sprintf "%.2fpx" size);

  if creet.grabbed then
    creet_element##.classList##add (Js.string "grabbed")
  else
    creet_element##.classList##remove (Js.string "grabbed")

let%client creets_colliding creet1 creet2 =
  if creet1.id = creet2.id then false
  else
    let size1 = get_creet_size creet1 in
    let size2 = get_creet_size creet2 in
    let dx = creet1.x -. creet2.x in
    let dy = creet1.y -. creet2.y in
    let distance = sqrt (dx *. dx +. dy *. dy) in
    distance < (size1 +. size2) /. 2.0

let%client make_creet_sick creet =
  if creet.grabbed then
    ()
  else (
    let type_chance = Random.float 1.0 in
    let creet_sickness =
      if type_chance < 0.1 then
        Mean { lifetime = 22.2 }
      else if type_chance < 0.2 then
        Berserk { lifetime = 22.2 }
      else
        Sick { lifetime = 22.2 }
    in
    creet.health <- creet_sickness;

    let creet_element = Eliom_content.Html.To_dom.of_div creet.element in
    creet_element##.classList##add (Js.string (get_creet_css_class creet_sickness))
  )

let%client do_disease_transmission creet all_creets =
  match creet.health with
  | Healthy ->
      (* Check if colliding with any sick creet *)
      let sick_collision = List.exists (fun other ->
        match other.health with
        | Healthy -> false
        | _ -> creets_colliding creet other
      ) all_creets in
      
      if sick_collision && Random.float 1.0 < 0.02 then ( make_creet_sick creet )
  | _ -> ()

(* Simulation loop for a single creet using Lwt *)
let%client rec simulate_creet creet all_creets =
  if global.game_over then Lwt.return () else (
  if creet == List.nth !all_creets 0 then (global.tick <- global.tick + 1; update_healthy_count !all_creets);

  let* () = Lwt_js.sleep 0.016 in (* ~60 FPS *)

  (* Decrement lifetime and check for death *)
  let is_dead = match creet.health with
    | Healthy -> false
    | Sick { lifetime } | Berserk { lifetime } | Mean { lifetime } ->
        let new_lifetime = lifetime -. 0.016 in
        if new_lifetime <= 0.0 then true
        else (
          creet.health <- (match creet.health with
            | Sick _ -> Sick { lifetime = new_lifetime }
            | Berserk _ -> Berserk { lifetime = new_lifetime }
            | Mean _ -> Mean { lifetime = new_lifetime }
            | Healthy -> Healthy
          );
          false
        )
  in

  (* If creet died, remove it and stop simulation *)
  if is_dead then (
    let creet_element = Eliom_content.Html.To_dom.of_div creet.element in
    Js.Opt.iter (creet_element##.parentNode) (fun parent ->
      ignore (parent##removeChild (creet_element :> Dom.node Js.t))
    );
    all_creets := List.filter (fun c -> c.id <> creet.id) !all_creets;
    global.creet_count <- List.length !all_creets;
    Lwt.return ()
  ) else (
    update_creet_position creet !all_creets;
    
    (* Check if creet is in the river *)
    let (_, _, part_height) = get_stats () in
    let current_section = get_section (part_height, creet.y) in
    let creet_element = Eliom_content.Html.To_dom.of_div creet.element in

    (match creet.health with
    | Healthy when current_section = "River" ->
        make_creet_sick creet
    | (Sick _ | Berserk _ | Mean _) when creet.grabbed && current_section = "Hospital" ->
        let class_to_remove = get_creet_css_class creet.health in
        creet.health <- Healthy;
        creet_element##.classList##remove (Js.string class_to_remove)
    | _ -> ()
    );

    (* Check for disease transmission *)
    do_disease_transmission creet !all_creets;
    simulate_creet creet all_creets
  ))

(* Creets container component *)
let%client creets_component () =
  let container = div ~a:[a_class ["creets-container"]] [] in
  let creets = ref [] in
  let grabbed_creet = ref None in

  let spawn_creet () =
    let (width, height, _) = get_stats () in
    let id = generate_unique_id () in
    let start_x = Random.float (float_of_int width -. 40.0) in
    let start_y = Random.float (float_of_int height -. 40.0) in
    let creet = create_creet id start_x start_y in

    (* Add creet to container *)
    Eliom_content.Html.Manip.appendChild container creet.element;
    creets := creet :: !creets;
    global.creet_count <- List.length !creets;

    (* Start simulation for this creet *)
    Lwt.async (fun () -> simulate_creet creet creets)
  in

  let rec handle_mousedown () =
    let container_element = Eliom_content.Html.To_dom.of_div container in
    let* evt = Lwt_js_events.mousedown container_element in
    let x = evt##.clientX in
    let y = evt##.clientY in
    (* Check which creet was clicked, if any *)
    (match List.find_opt (fun c -> is_point_in_creet c x y) !creets with
     | Some creet ->
         Dom.preventDefault evt;
         creet.grabbed <- true;
         grabbed_creet := Some creet
     | None -> ());
    handle_mousedown ()
  in
  Lwt.async handle_mousedown;

  let rec handle_mouseup () =
    let* _ = Lwt_js_events.mouseup window in
    (match !grabbed_creet with
     | Some creet -> 
         creet.grabbed <- false;
         grabbed_creet := None
     | None -> ());
    handle_mouseup ()
  in
  Lwt.async handle_mouseup;

  (* Spawn initial creets *)
  for _i = 0 to 12 do
    spawn_creet ()
  done;

  (* Spawn new creets periodically *)
  let rec spawn_loop () =
    let* () = Lwt_js.sleep 3.0 in
    if not global.game_over then (
      spawn_creet ();
      spawn_loop ()
    ) else
      Lwt.return ()
  in
  Lwt.async spawn_loop;

  container


(* ------------- *)
(* HUD COMPONENT *)
(* ------------- *)

let%client hud_component () =
  let stats_container = div ~a:[a_class ["hud-stats"]] [] in

  let update_stats () =
    let (width, height, part_height) = get_stats () in
    let current_section = get_section (part_height, float_of_int global.mouse_y) in
    Eliom_content.Html.Manip.replaceChildren stats_container
      [ div [txt (Printf.sprintf "Resolution: %dx%d" width height)]
      ; div [txt (Printf.sprintf "Mouse: (%d, %d)" global.mouse_x global.mouse_y)]
      ; div [txt (Printf.sprintf "Inside: %s" current_section)]
      ; div [txt (Printf.sprintf "Creets: %d" global.creet_count)]
      ; div [txt (Printf.sprintf "Healthy: %d" global.healthy_count)]
      ; div [txt (Printf.sprintf "Tick: %d" global.tick)]
      ; div [txt (Printf.sprintf "Speed Healthy: %.2f" (get_creet_speed Healthy))]
      ; div [txt (Printf.sprintf "Speed sick: %.2f" (get_creet_speed (Sick { lifetime = 20.0 })))]
      ]
  in

  (* Initial update *)
  update_stats ();

  (* Add resize event listener *)
  Lwt.async (fun () ->
    Lwt_js_events.onresizes (fun _ _ ->
      update_stats ();
      Lwt.return ()
    )
  );

  (* Add mousemove event listener for HUD updates *)
  let rec handle_mousemove () =
    let* _ = Lwt_js_events.mousemove window in
    update_stats ();
    handle_mousemove ()
  in
  Lwt.async handle_mousemove;

  div
    ~a:[a_class ["hud"]]
    [ div
        ~a:[a_class ["hud-content"]]
        [ div [txt (if global.game_over then "GAME OVER" else "simulation running")]
        ; stats_container
        ]
    ]


(* -------------- *)
(* Main COMPONENT *)
(* -------------- *)

(* Register and implement handlers and setup the index layout*)
let%shared () =
  App.register ~service:main_service (fun () () ->
    Lwt.return
      Html.F.(
        html
          (head
             (title (txt "h42n42"))
             [ css_link
                 ~uri:
                   (make_uri
                      ~service:(Eliom_service.static_dir ())
                      ["css"; "h42n42.css"])
                 () ])
          (body 
            [ Html.C.node [%client world_component ()]
            ; Html.C.node [%client 
                let hud = hud_component () in
                let creets = creets_component () in
                div [hud; creets]
              ]
            ])))
