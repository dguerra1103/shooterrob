# Brief for modeling one SHOOTERROB weapon

You are a hard-surface weapon modeler on SHOOTERROB, a 5v5 Roblox FPS. Your single job: design and
build ONE weapon model with our scripted Blender kit, to a commercial-quality stylized look, and deliver
it validated. The weapon (game key `<KEY>`, script name `<key>` in lowercase) and its concept are given
in the message that sent you here.

## Pipeline (read these first)
- `tools/blender/sr_kit.py` — the modeling kit (runs headless). Read it fully. API on the `Weapon` object:
  `box(name, center, size, role, bevel, piece=None, rot=None)`,
  `profile(name, [(z,y),...], width, role, bevel, piece=None, x=0.0)` (a side silhouette polygon extruded
  along X — the main tool for aggressive stylized shapes),
  `cyl(name, a, b, radius, role, segments, piece=None)`,
  `ring(name, a, b, radius, inner, role, segments, piece=None)`, `point(name, position)`.
- Finished references: `tools/blender/weapons/arx27.py`, `signal7.py`, `havocpump.py`, `viper.py`. Study
  at least two and LOOK at their renders in `assets/weapons/<Name>/renders/*.jpg` and at
  `assets/weapons/_gallery/00_coleccion.jpg` — that is the house style and the quality bar.
- Build + diagnostic renders (run from the repo root, Git Bash):
  `"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/build_weapon.py -- <key>`
  It writes `assets/weapons/<KEY>/` (`.blend`, `.fbx`, `.glb`, `.mesh.json`) and `renders_diag/*.png`, and
  prints `SR_STATS` (triangles, bounds). `--final` writes the 1080p set to `renders/`; `--no-render` skips.
- Convert for the game: `python -X utf8 tools/blender/to_luau.py <KEY>` → `src/shared/WeaponMeshes/<KEY>.luau`.

## Coordinates and constraints (strict)
- Model in GAME coordinates, in studs: X = right, Y = up, Z = back (the barrel points to **-Z**).
  Origin = the weapon's "Handle" as the game defines it.
- Read the weapon's entry in `src/shared/Weapons.luau` (key `<KEY>`): `Muzzle`, `AimPoint`, `RightHand`,
  `LeftHand` are where the game expects the muzzle tip, the centre of the sight window (or scope
  eyepiece), the grip and the support hand. Also check `Classic.Points` at the end of
  `src/shared/WeaponDesignsClassic.luau`: values there override the entry. Your model MUST match them:
  `Muzzle` at the real muzzle tip (same Z within 0.05 — keep the overall length), `AimPoint` exact with
  the sight built around it, grip and support surface where the hands are. If a value is missing, read
  the weapon's existing part layout in `WeaponDesignsClassic.luau` to place it sensibly.
- Required points: `Muzzle`, `AimPoint`, `Eject` (right side port), `RightHand`, `LeftHand`, `CharmPoint`
  (left side of the receiver/frame).
- Roles (they drive in-game skins): Body, Panel (big accent-colour surfaces), Accent (small glowing
  strips), Accent2, Dark, Metal, Rubber, Lens, Reticle, Trim.
- Moving pieces — only these names: `piece="Mag"` (everything that is removed on reload: magazine, drum,
  energy cell, rocket), `"Slide"` (pistol slide and what rides on it), `"Pump"` (shotgun fore-end),
  `"Bolt"` (bolt; on bolt-actions name the parts `BoltHandle` / `BoltKnob`), `"Charge"` (charging handle).
- In Roblox the model is rebuilt from primitives: `box` → block, `profile` → wedges, `cyl`/`ring` →
  cylinders (a `ring` becomes a solid cylinder plus a Dark core, which also adds a Dark group for its
  piece). Do NOT use `taper` (ignored in-game). Bevels do not survive either, so give shapes character
  with silhouette and layered plates, not only with chamfers. Keep everything solid and
  touching/overlapping: no floating parts, no gaps.
- Budgets unless your message says otherwise: ≤ 2700 triangles, ≤ 190 primitives, ≤ 14 groups (a group =
  one role within one piece; `to_luau` prints primitives and groups). A profile with n points costs up to
  2·(n-2) primitives; a bevelled box ~44 triangles, unbevelled 12 — drop bevels on small details.
- File: `tools/blender/weapons/<key>.py` with `NAME = "<KEY>"`, a `PALETTE` dict and `build(w)`.

## Art direction
"Stylized tactical arcade": the punch of COD Mobile / Fortnite weapons inside Roblox's geometric
language. Aggressive recognizable silhouette, hard surfaces, strong colour blocking, discreet glowing
accents, reads well in first person (the player sees it from behind/above-right). NOT a toy of plain
boxes, NOT photoreal military, NOT a copy of any real or licensed gun — an original SHOOTERROB design.
House identity: near-black blue body, saturated Panel surfaces (house orange unless your message gives
another hue), glowing Accent strips, steel Metal. The weapon must be clearly distinguishable in
silhouette from the seven already made — do not just re-skin the ARX-27 layout.

## Process (required)
1. Read the kit, two reference scripts and their renders, and the weapon's game entry.
2. Write the script; build with diagnostic renders; LOOK at the PNGs (side, threequarter, back34, front,
   top, firstperson).
3. Critique honestly and fix: proportions, floating parts, moving pieces seated, sight usable at
   AimPoint, grip angle, silhouette not generic, colour balance (not all orange, not all black), details
   legible, nothing poking through.
4. At least three build → look → fix rounds. Then `--final`, convert the eight
   `renders/*.png` to JPEG quality 92 (PIL) and delete the PNGs, delete `renders_diag` and any `*.blend1`,
   and run `to_luau.py`.
5. Verify outputs exist and budgets hold.

## Boundaries
Only create/modify `tools/blender/weapons/<key>.py`, `assets/weapons/<KEY>/**` and
`src/shared/WeaponMeshes/<KEY>.luau`. Do not edit the kit, other weapons or any game code; do not touch
Roblox Studio; no git commands that change anything. Other modelers work in parallel with the same kit.

## Report back (short)
Triangles, primitives, groups; points vs the game's values; the colours you chose for Panel/Accent/Trim
(RGB 0-255) so the game palette can match; frank self-assessment with remaining weaknesses; files.
