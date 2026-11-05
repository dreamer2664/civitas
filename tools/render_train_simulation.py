#!/usr/bin/env python3
"""Visualise deterministic pure-Luau prototype telemetry; not a Studio render."""
from pathlib import Path
import json
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

root = Path(__file__).resolve().parents[1]
data = json.loads((root / 'tools/train-simulation-evidence.json').read_text())
times = [p['time'] for p in data]
speeds = [p['speedKph'] for p in data]
distances = [p['distanceStuds'] for p in data]
plt.rcParams.update({'font.size': 11, 'font.family': 'DejaVu Sans', 'text.color': '#eef1f3', 'axes.labelcolor': '#aeb8c1', 'xtick.color': '#aeb8c1', 'ytick.color': '#aeb8c1'})
fig, axs = plt.subplots(2, 1, figsize=(12, 7), sharex=True, facecolor='#0e1216')
fig.subplots_adjust(left=.1, right=.96, top=.78, bottom=.12, hspace=.25)
fig.text(.1, .93, 'CIVITAS  /  TRAIN MOTION PROTOTYPE', fontsize=19, weight='bold')
fig.text(.1, .875, 'Deterministic simulation evidence  •  not a Roblox Studio render or live service', color='#aeb8c1', fontsize=10)
for ax in axs:
    ax.set_facecolor('#161c22')
    ax.grid(color='#3a4550', alpha=.55, linewidth=.7)
    for spine in ax.spines.values(): spine.set_visible(False)
    ax.axvspan(0,12,color='#2a9696',alpha=.1)
    ax.axvspan(12,30,color='#c99a2e',alpha=.08)
    ax.axvspan(30,40,color='#5c8ac8',alpha=.08)
axs[0].plot(times, speeds, color='#84add2', linewidth=2.5)
axs[0].set_ylabel('Speed  /  km/h')
axs[0].set_ylim(bottom=0)
axs[1].plot(times, distances, color='#d3c09c', linewidth=2.5)
axs[1].set_ylabel('Position  /  studs')
axs[1].set_xlabel('Simulation time  /  seconds')
for x, label in [(6,'POWER'),(21,'SERVICE BRAKE'),(35,'DOORS OPEN')]:
    axs[0].text(x, 1.05, label, transform=axs[0].get_xaxis_transform(), ha='center', color='#aeb8c1', fontsize=9, weight='bold')
out = root / 'tools/world/renders/train-simulation-evidence.png'
fig.savefig(out, dpi=150, facecolor=fig.get_facecolor())
print(f'Rendered {out.relative_to(root)}')
