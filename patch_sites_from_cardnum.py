"""
Genereert SQL UPDATE statements voor de Supabase sites tabel
op basis van cards-dc.json (authoritative MECCG data).

Bijgewerkte velden: type, near_haven, path, mps
"""

import json
import urllib.request

CARDNUM_URL = 'https://raw.githubusercontent.com/rezwits/cardnum/master/fdata/cards-dc.json'
OUT_FILE = r'C:\Users\jbuytaer\Documents\Muzad Dev\Meccg-game\update_sites.sql'

print("Downloaden cards-dc.json...")
with urllib.request.urlopen(CARDNUM_URL) as r:
    cards = json.loads(r.read().decode('utf-8'))

print(f"  {len(cards)} kaarten geladen.")

# Filter siteskaarten
sites = [c for c in cards if (c.get('Primary') or '').strip().lower() == 'site']
print(f"  {len(sites)} sitekaarten gevonden.")

def esc(val):
    """Escape single quotes voor SQL."""
    if val is None:
        return 'NULL'
    return "'" + str(val).replace("'", "''") + "'"

lines = [
    "-- Automatisch gegenereerd door patch_sites_from_cardnum.py",
    "-- Update sites tabel vanuit cards-dc.json",
    "",
    "-- Stap 1: kolommen toevoegen indien nog niet aanwezig",
    "ALTER TABLE sites ADD COLUMN IF NOT EXISTS path text;",
    "ALTER TABLE sites ADD COLUMN IF NOT EXISTS playable text;",
    "",
    "-- Stap 2: data updaten",
]

updated = 0
skipped = 0

for c in sites:
    name = (c.get('NameEN') or '').strip()
    if not name:
        skipped += 1
        continue

    alignment  = (c.get('Alignment') or '').strip()    # Hero / Minion / Balrog / ...
    site_type  = (c.get('Site') or '').strip()          # Free-hold / Haven / ...  (c.Site!)
    near_haven = (c.get('Haven') or '').strip() or None # Nearest Haven (c.Haven!)
    path       = (c.get('Path') or '').strip() or None  # b w / f w / ...
    playable   = (c.get('Playable') or '').strip() or None
    region     = (c.get('Region') or '').strip() or None

    if not site_type:
        skipped += 1
        continue

    set_parts = [f"type={esc(site_type)}"]
    if near_haven is not None:
        set_parts.append(f"near_haven={esc(near_haven)}")
    if path is not None:
        set_parts.append(f"path={esc(path)}")
    if playable is not None:
        set_parts.append(f"playable={esc(playable)}")
    if region is not None:
        set_parts.append(f"region={esc(region)}")

    # Geen alignment in WHERE: type is hetzelfde voor alle versies van dezelfde site
    sql = f"UPDATE sites SET {', '.join(set_parts)} WHERE name={esc(name)};"
    lines.append(sql)
    updated += 1

lines.append("")
lines.append(f"-- {updated} UPDATE statements gegenereerd, {skipped} overgeslagen.")

with open(OUT_FILE, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f"\nKlaar: {updated} updates -> {OUT_FILE}")
print(f"Overgeslagen: {skipped}")
print(f"\nVoer update_sites.sql uit in de Supabase SQL Editor.")
