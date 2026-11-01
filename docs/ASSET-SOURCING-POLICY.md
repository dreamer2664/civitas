# ASSET SOURCING POLICY — v1, 2026-11-01

Manager A, on the Director's instruction:

> *"tell the agents in charge of making humans that they can use open source 3d human scans as long
> as they look good. that goes for buildings too, they can use ready made models."*

This supersedes the earlier working assumption that everything must be generated from scratch. It does
**not** relax the vetting rule: sourcing is allowed, importing blind is not.

---

## 1. What may be sourced

| Category | Sourced? | Owner |
|---|---|---|
| Human characters — pedestrians, crowd, station staff | **YES** — open-source scans and rigged characters | atlas II |
| Buildings, whole or modular kits | **YES** | stratum (WORLD · strata) |
| Street props, vegetation, signage, furniture | **YES** | stratum |
| Station components not covered by mason's kit | **YES**, only if mason has not already built it | mason |
| Trains and rolling stock | **NO** — bespoke, ours, already on the rails | mason |

The bar is the Director's: **as long as they look good.** A good sourced asset that matches the art
bible beats a mediocre original one. A sourced asset that looks like an asset flip is worse than a
blockout, because it will still be there in the finished game.

## 2. Licences — allowed and not allowed

**Allowed**
- **CC0 / public domain** — Kenney, Quaternius, Poly Haven, ambientCG.
- **CC-BY** — allowed with attribution recorded in the catalogue and reproduced in a credits file.
- **Roblox Creator Store** free assets, under the Creator Store terms, subject to vetting below.
- **Mixamo** (Adobe) characters and animations, **Ready Player Me** avatars, **MakeHuman** (CC0 base
  meshes) — all fine for characters.

**Not allowed, no exceptions**
- **Research-licence body models** — SMPL, SMPL-X, STAR, and the academic scan datasets built on them.
  These are non-commercial research licences and using one would poison the whole project.
- **Ripped game assets** — anything extracted from another commercial title.
- **Scans of identifiable real people without a release**, whatever the site says about reuse.
- **Anything with no stated licence.** "Found it on a forum" is not a licence.

## 3. Vetting — unchanged, and it is the point

Every sourced file, before it touches the repository:

1. Open it. List every script in it and read them.
2. Grep for `require(`, `HttpService`, `HttpGet`, `loadstring`, `getfenv`, base64 blobs, and any
   obfuscated string. Free-model backdoors are real and they are how these projects get compromised.
3. Check for invisible or hidden parts, parts parented outside the model, and absurd sizes.
4. Record in `assets/catalogue/ASSETS.md`: id or URL, creator, **licence**, triangles, texture size,
   source sha256, verdict — **PASS / REJECT**, and one line of why.
5. Commit the **decimated** export plus the script that produced it. Never the original download.

A single REJECT without a reason is an unfinished entry.

## 4. Budgets — a scan is not a game asset until it is decimated

Roblox rejects meshes over **20,000 triangles**, and a raw photogrammetry human is often 100k+.

| Asset | Triangles | Textures | Notes |
|---|---|---|---|
| Crowd human, near | **4,000–8,000** | 1024², one atlas | rigged to R15 joint names |
| Crowd human, far LOD | ≤ 800 | shares atlas | or a billboard impostor |
| Station staff (named) | 8,000–12,000 | 1024² | distinctive silhouette |
| Building, hero landmark | ≤ 20,000 | 2048² max | one material set |
| Building, ordinary block | 500–3,000 | 512² | modular; instance it, don't duplicate geometry |
| Street prop | 50–800 | shares a palette atlas | never a unique texture each |

Scale is not negotiable: **1 metre = 3.5714286 studs**, Z-up in Blender, pivot at the base centre of
the object, forward axis documented per asset. A sourced building that is 40% too tall is worse than
no building.

## 5. Reproducibility

Sourced is not the same as hand-placed. Every sourced asset must appear in
`assets/catalogue/MANIFEST.json` with source, licence, sha256, decimation command and the file that
instances it. Someone must be able to clone the repo, run the documented commands, and get the same
place file with no manual steps and no unrecorded downloads.

## 6. Who is told what

- **atlas II** — owns humans and crowd. Scans and rigged characters allowed. Needs a crowd of at
  least 12 distinct silhouettes that read at 100 studs, plus the catalogue entries and licence record.
- **stratum (WORLD · strata)** — may use ready-made building models and kits, provided they match the
  art bible, pass vetting, are decimated and are instanced through the generator rather than placed
  by hand.
- **mason** — may source station components you have not built, but trains stay bespoke.
- **WALK · pave** — a sourced asset gets the same collision treatment as a built one: collision on
  massing, none on decoration. If it cannot take collision, it cannot be a wall.
