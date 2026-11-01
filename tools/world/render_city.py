#!/usr/bin/env python3
"""Render the exact JSON plan exported by the Luau generator (matplotlib required)."""
from __future__ import annotations

import json
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

ROOT = Path(__file__).resolve().parents[2]
PLAN_PATH = ROOT / "tools/world/generated-plan.json"
OUT = ROOT / "tools/world/renders"
OUT.mkdir(parents=True, exist_ok=True)
PLAN = json.loads(PLAN_PATH.read_text())
PALETTE = {
    "historic-terrace": "#c8b18f",
    "corner-shop": "#d5b995",
    "church": "#b9ae97",
    "market": "#a7835f",
    "civic": "#d0c2a4",
    "tower": "#b39e80",
    "hotel": "#c1aa8d",
}


def rect_for_street(street: dict) -> tuple[float, float, float, float]:
    length = street["finish"] - street["start"]
    if street["axis"] == "x":
        return street["start"], street["center"] - street["width"] / 2, length, street["width"]
    return street["center"] - street["width"] / 2, street["start"], street["width"], length


def draw_plan() -> None:
    fig, ax = plt.subplots(figsize=(13, 12), dpi=180, facecolor="#ece9df")
    ax.set_facecolor("#9eae83")
    g = PLAN["ground"]
    ax.add_patch(
        Rectangle(
            (g["centerX"] - g["width"] / 2, g["centerZ"] - g["depth"] / 2),
            g["width"],
            g["depth"],
            color="#a6b28b",
            zorder=0,
        )
    )
    # A subtle site grid communicates the bounded walkable slice rather than implying the full map.
    for x in range(-700, 701, 100):
        ax.axvline(x, color="#748365", lw=0.35, alpha=0.25, zorder=0)
    for z in range(-800, 1001, 100):
        ax.axhline(z, color="#748365", lw=0.35, alpha=0.25, zorder=0)

    for street in PLAN["streets"]:
        x, z, w, d = rect_for_street(street)
        road_color = "#42474a" if street["kind"] == "arterial" else "#626568"
        ax.add_patch(Rectangle((x, z), w, d, color=road_color, zorder=1))
        sidewalk_w = 3.5
        if street["axis"] == "x":
            for side in (-1, 1):
                sz = street["center"] + side * (street["width"] / 2 + sidewalk_w / 2)
                ax.add_patch(Rectangle((street["start"], sz - sidewalk_w / 2), street["finish"] - street["start"], sidewalk_w, color="#d4cdbb", zorder=2))
        else:
            for side in (-1, 1):
                sx = street["center"] + side * (street["width"] / 2 + sidewalk_w / 2)
                ax.add_patch(Rectangle((sx - sidewalk_w / 2, street["start"]), sidewalk_w, street["finish"] - street["start"], color="#d4cdbb", zorder=2))

    for block in PLAN["blocks"]:
        ax.add_patch(
            Rectangle(
                (block["minX"], block["minZ"]),
                block["maxX"] - block["minX"],
                block["maxZ"] - block["minZ"],
                fill=False,
                edgecolor="#78826b",
                lw=0.5,
                alpha=0.7,
                zorder=3,
            )
        )
    for b in PLAN["buildings"] + PLAN["landmarks"]:
        color = PALETTE.get(b["style"], "#c4b08e")
        alpha = 0.98 if b["landmark"] else 0.87
        edge = "#493f35" if b["landmark"] else "#756955"
        angle = b["rotation"]
        width, depth = (b["depth"], b["width"]) if angle == 90 else (b["width"], b["depth"])
        ax.add_patch(
            Rectangle(
                (b["x"] - width / 2, b["z"] - depth / 2),
                width,
                depth,
                facecolor=color,
                edgecolor=edge,
                linewidth=0.65 if b["landmark"] else 0.28,
                alpha=alpha,
                zorder=4 if b["landmark"] else 3.5,
            )
        )
        if b["landmark"]:
            ax.text(b["x"], b["z"], b["name"], fontsize=5.4, ha="center", va="center", color="#251f1a", zorder=5)

    plaza = PLAN["plaza"]
    ax.add_patch(Rectangle((plaza["centerX"] - plaza["width"] / 2, plaza["centerZ"] - plaza["depth"] / 2), plaza["width"], plaza["depth"], facecolor="#aaa28d", edgecolor="#f2ebdc", lw=1.5, zorder=5))
    ax.scatter([plaza["centerX"]], [plaza["centerZ"] + 28], s=32, marker="o", color="#537b83", edgecolor="#e5ddca", linewidth=0.8, zorder=6)
    station = PLAN["station"]
    ax.add_patch(Rectangle((station["centerX"] - station["width"] / 2, station["entryZ"]), station["width"], station["depth"] * 0.55, facecolor="#b8a789", edgecolor="#3c3630", lw=1.3, zorder=4))
    ax.add_patch(Rectangle((station["centerX"] - station["width"] / 2 - 18, station["forecourtZ"] - 20), station["width"] + 36, 45, facecolor="#c9c0ab", edgecolor="none", zorder=3))
    route = PLAN["route"]
    ax.plot([p["x"] for p in route], [p["z"] for p in route], color="#c54635", lw=2.2, marker="o", markersize=2.5, zorder=7, label=f"Acceptance walk · {PLAN['stats']['routeLength']:.0f} studs")
    ax.scatter([route[0]["x"]], [route[0]["z"]], marker="*", s=85, color="#f0bf55", edgecolor="#392e22", zorder=8, label="Sidewalk spawn")
    ax.scatter([route[-1]["x"]], [route[-1]["z"]], marker="s", s=25, color="#4e7480", edgecolor="white", zorder=8, label="Concourse")

    ax.text(-665, 930, "DISTRICT A  /  HISTORIC CENTRE SLICE", fontsize=10, fontweight="bold", color="#293128")
    ax.text(-665, 890, "200 blockout buildings   ·   12 landmarks   ·   20 blocks", fontsize=7.5, color="#293128")
    ax.text(145, 975, "CENTRAL STATION", fontsize=7.5, fontweight="bold", color="#332d26")
    ax.annotate("Old Town Square", (plaza["centerX"], plaza["centerZ"]), xytext=(plaza["centerX"] + 96, plaza["centerZ"] + 32), fontsize=7, arrowprops={"arrowstyle": "-", "color": "#554d41"})

    ax.set_xlim(-740, 740)
    ax.set_ylim(-700, 1015)
    ax.set_aspect("equal", adjustable="box")
    ax.set_xlabel("West  ←  world X (studs)  →  East", labelpad=8)
    ax.set_ylabel("North  ←  world Z (studs)  →  South", labelpad=8)
    ax.set_title("CIVITAS · walkable core blockout / generated plan", loc="left", fontsize=14, fontweight="bold", color="#252b26", pad=14)
    ax.grid(False)
    ax.legend(loc="lower left", frameon=True, facecolor="#f0ede3", edgecolor="#c4bbab", fontsize=7)
    for spine in ax.spines.values():
        spine.set_color("#59614f")
    fig.tight_layout()
    fig.savefig(OUT / "district-a-plan.png", bbox_inches="tight")
    plt.close(fig)


def cuboid_faces(cx: float, cy: float, cz: float, width: float, height: float, depth: float, rotation: float = 0) -> list[list[tuple[float, float, float]]]:
    corners = [
        (-width / 2, 0, -depth / 2),
        (width / 2, 0, -depth / 2),
        (width / 2, 0, depth / 2),
        (-width / 2, 0, depth / 2),
        (-width / 2, height, -depth / 2),
        (width / 2, height, -depth / 2),
        (width / 2, height, depth / 2),
        (-width / 2, height, depth / 2),
    ]
    import math

    a = math.radians(rotation)
    transformed = []
    for x, y, z in corners:
        tx, tz = x * math.cos(a) - z * math.sin(a), x * math.sin(a) + z * math.cos(a)
        transformed.append((cx + tx, cy + y, cz + tz))
    indices = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    return [[transformed[i] for i in face] for face in indices]


def add_box(ax, cx, y, cz, width, height, depth, color, edge="#51483b", rotation=0, alpha=1.0):
    faces = cuboid_faces(cx, y, cz, width, height, depth, rotation)
    ax.add_collection3d(Poly3DCollection(faces, facecolors=color, edgecolors=edge, linewidths=0.14, alpha=alpha))


def draw_street_view(filename: str, camera_x: float, camera_z: float, title: str, target_x: float, target_z: float, target_y: float) -> None:
    """A deterministic pinhole-camera render: street-eye views without Studio or Blender."""
    import math
    from matplotlib.patches import Polygon as Poly2D

    width_px, height_px = 1500, 900
    fig, ax = plt.subplots(figsize=(12.5, 7.5), dpi=160, facecolor="#e9e6dd")
    ax.set_facecolor("#d6dfdf")
    ax.set_xlim(0, width_px)
    ax.set_ylim(height_px, 0)
    ax.axis("off")

    camera = (camera_x, 8.0, camera_z)
    look = (target_x - camera_x, target_y - camera[1], target_z - camera_z)
    norm = math.sqrt(sum(value * value for value in look))
    forward = tuple(value / norm for value in look)
    up_world = (0.0, 1.0, 0.0)
    right = (forward[2], 0.0, -forward[0])
    right_norm = math.sqrt(right[0] ** 2 + right[2] ** 2)
    right = (right[0] / right_norm, 0.0, right[2] / right_norm)
    up = (
        forward[1] * right[2] - forward[2] * right[1],
        forward[2] * right[0] - forward[0] * right[2],
        forward[0] * right[1] - forward[1] * right[0],
    )
    focal = 780.0
    horizon_y = 330.0
    queued = []

    def project(point):
        rel = (point[0] - camera[0], point[1] - camera[1], point[2] - camera[2])
        depth = sum(rel[i] * forward[i] for i in range(3))
        if depth <= 8:
            return None
        horizontal = sum(rel[i] * right[i] for i in range(3))
        vertical = sum(rel[i] * up[i] for i in range(3))
        return (width_px / 2 + focal * horizontal / depth, horizon_y - focal * vertical / depth, depth)

    def queue_polygon(points, color, edge="none", line=0.35, alpha=1.0):
        projected = [project(point) for point in points]
        if any(point is None for point in projected):
            return
        xy = [(point[0], point[1]) for point in projected]
        if max(x for x, _ in xy) < -100 or min(x for x, _ in xy) > width_px + 100:
            return
        if max(y for _, y in xy) < -100 or min(y for _, y in xy) > height_px + 100:
            return
        depth = sum(point[2] for point in projected) / len(projected)
        queued.append((depth, xy, color, edge, line, alpha))

    # A forward-facing ground window avoids any vertex behind the pinhole camera plane.
    queue_polygon([(camera_x - 1500, 0, camera_z + 16), (camera_x + 1500, 0, camera_z + 16), (camera_x + 1500, 0, camera_z + 1800), (camera_x - 1500, 0, camera_z + 1800)], "#8e9d78")
    for street in PLAN["streets"]:
        x, z, w, d = rect_for_street(street)
        if street["axis"] == "z":
            z = max(z, camera_z + 16)
            d = min(z + d, PLAN["streets"][0]["finish"], camera_z + 1800) - z
            if d <= 0:
                continue
        elif street["center"] < camera_z - 10:
            continue
        queue_polygon([(x, .06, z), (x + w, .06, z), (x + w, .06, z + d), (x, .06, z + d)], "#454a4d" if street["kind"] == "arterial" else "#626568")
        sw = 3.5
        if street["axis"] == "x":
            for side in (-1, 1):
                sc = street["center"] + side * (street["width"] / 2 + sw / 2)
                queue_polygon([(street["start"], .12, sc - sw / 2), (street["finish"], .12, sc - sw / 2), (street["finish"], .12, sc + sw / 2), (street["start"], .12, sc + sw / 2)], "#d4cbb8")
        else:
            for side in (-1, 1):
                sc = street["center"] + side * (street["width"] / 2 + sw / 2)
                queue_polygon([(sc - sw / 2, .12, z), (sc + sw / 2, .12, z), (sc + sw / 2, .12, z + d), (sc - sw / 2, .12, z + d)], "#d4cbb8")

    # A thin, far-to-near painter's pass produces readable facade planes for each blockout mass.
    for building in PLAN["buildings"] + PLAN["landmarks"]:
        if building["z"] < min(camera_z, target_z) - 160 or building["z"] > max(camera_z, target_z) + 220:
            continue
        faces = cuboid_faces(building["x"], 0, building["z"], building["width"], building["height"], building["depth"], building["rotation"])
        base = PALETTE.get(building["style"], "#c4b08e")
        for face_index, face in enumerate(faces):
            shades = ("#d0bc9c", "#b59e7e", "#c5ae8d", "#a89172", "#baa382", "#927f68")
            queue_polygon(face, shades[face_index], edge="#665947", line=0.45)
        if building["landmark"] and building["style"] == "tower":
            for face in cuboid_faces(building["x"], building["height"], building["z"], building["width"] * .42, 8, building["depth"] * .42):
                queue_polygon(face, "#80694f", edge="#5d4c3a", line=0.45)
            for face in cuboid_faces(building["x"], building["height"] + 8, building["z"], 7, 12, 7):
                queue_polygon(face, "#5e6b70", edge="#4a5356", line=0.35)

    # Square paving, fountain, station concourse shell and the forecourt's four colonnade pillars.
    sq = PLAN["plaza"]
    queue_polygon([(sq["centerX"] - sq["width"] / 2, .16, sq["centerZ"] - sq["depth"] / 2), (sq["centerX"] + sq["width"] / 2, .16, sq["centerZ"] - sq["depth"] / 2), (sq["centerX"] + sq["width"] / 2, .16, sq["centerZ"] + sq["depth"] / 2), (sq["centerX"] - sq["width"] / 2, .16, sq["centerZ"] + sq["depth"] / 2)], "#aaa28e", edge="#eee7d7", line=1.2)
    st = PLAN["station"]
    for face in cuboid_faces(st["centerX"], 0, st["concourseZ"], st["width"] - 20, 19, st["depth"] * .55):
        queue_polygon(face, "#bba987", edge="#655b4d", line=.55)
    for side in (-1, 1):
        for face in cuboid_faces(st["centerX"] + side * (st["width"] / 2 - 7), 0, st["concourseZ"], 8, 19, st["depth"] * .55):
            queue_polygon(face, "#c8b692", edge="#655b4d", line=.5)
    for offset in (-56, -28, 28, 56):
        for face in cuboid_faces(st["centerX"] + offset, 0, st["entryZ"] - 18, 5, 20, 5):
            queue_polygon(face, "#ddd0b4", edge="#7a6e59", line=.4)

    # Painter order is back-to-front; polygon geometry matches the footprints and heights in the plan.
    for _, points, color, edge, line, alpha in sorted(queued, key=lambda item: item[0], reverse=True):
        ax.add_patch(Poly2D(points, closed=True, facecolor=color, edgecolor=edge, linewidth=line, alpha=alpha))

    # Opaque title/footer bands keep street geometry from colliding with evidence labels.
    ax.add_patch(plt.Rectangle((0, 0), width_px, 104, color="#e9e6dd", zorder=20))
    ax.add_patch(plt.Rectangle((0, height_px - 54), width_px, 54, color="#e9e6dd", zorder=20))
    ax.text(48, 48, title, fontsize=16, fontweight="bold", color="#252b26", zorder=21)
    ax.text(48, 78, "GENERATED MASSING  /  COLLIDABLE STREET FABRIC  /  CONCEPT RENDER, NOT ROBLOX STUDIO", fontsize=8, color="#53584f", zorder=21)
    ax.text(48, height_px - 23, "CIVITAS  ·  WORLD / STRATA", fontsize=8, color="#53584f", zorder=21)
    ax.text(width_px - 48, height_px - 23, f"{PLAN['stats']['buildingCount']} buildings   |   {PLAN['stats']['landmarkCount']} landmarks", fontsize=8, color="#53584f", ha="right", zorder=21)
    fig.subplots_adjust(left=0, right=1, bottom=0, top=1)
    fig.savefig(OUT / filename, dpi=160, facecolor=fig.get_facecolor())
    plt.close(fig)

def main() -> None:
    if not PLAN_PATH.exists():
        raise SystemExit("Missing generated-plan.json; run lune run tools/world/export_plan.luau first")
    draw_plan()
    draw_street_view(
        "street-view-grid.png",
        -360,
        -580,
        "STREET VIEW 01  /  north grid approach to the old town",
        -360,
        100,
        18,
    )
    draw_street_view(
        "street-view-station.png",
        120,
        420,
        "STREET VIEW 02  /  central station forecourt and concourse shell",
        120,
        940,
        24,
    )
    print("Rendered:", *(str(path.relative_to(ROOT)) for path in sorted(OUT.glob("*.png"))))


if __name__ == "__main__":
    main()
