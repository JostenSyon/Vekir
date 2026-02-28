VEKIR (quick guide)

What it does:
- removes Kefir logo_sloth patch (Nintendo logo override)
- applies Venom-style boot logos
- applies Venom-style HUD (Uberhand/Tesla/ovlmenu)
- adds Uberhand menu: "Vekir > Bootlogo" (Default / Snakes / AMS)
- removes unneeded package entries (Theme / Translate / Settings)
- imports Venom "System Tweaks" tools (if /venom pack is present)
- imports sys-clk backend (module + config + manager) from /venom

UPDATE WORKFLOW (simple)
1) Copy new Kefir files to SD root
2) Run normal Kefir update
3) Copy/update this remix pack to SD root (includes /startup.te)
4) Boot Hekate
5) Run "Vekir Apply" (launches TegraExplorer)
6) Remix auto-runs via /startup.te (no manual navigation)
7) Remix auto-reboots at the end (tries Atmosphere directly)

Manual mode (if needed):
- In TegraExplorer run: /switch/vekir/apply_remix.te

Optional (inside Uberhand HUD):
- If Venom "System Tweaks" is imported, use: System Tweaks -> Hekate -> Bootlogo
- Choose "Vekir Light", "Vekir Black", "Venom Default (OEM)" or "Venom Snakes"
- Default applied by script: Vekir Light

Notes:
- SC Wizard (advanced OC) is NOT imported by default in this remix (safer).
- Basic OC/sys-clk is imported from /venom if present.
- "Vekir" package menu is removed when Venom System Tweaks is available (to avoid duplicate Bootlogo menu).

OPTIONAL SOURCE (recommended)
Put your Venom pack (or only needed files) in:
- /venom/

Used files (if present):
- /venom/bootloader/bootlogo.bmp
- /venom/bootloader/updating.bmp
- /venom/config/uberhand/config.ini
- /venom/config/uberhand/overlays.ini
- /venom/config/uberhand/packages.ini
- /venom/config/tesla/config.ini
- /venom/switch/.overlays/ovlmenu.ovl

Fallback behavior:
- If /venom files are missing, embedded fallback files are used when available.
- Missing files are skipped (no emuMMC changes, no partition changes).
- /startup.te is auto-removed at the end of the remix run.
- Remix does NOT run fix/clean (Kefir updater already does it).

Troubleshooting:
- If HUD did not change, check /venom/switch/.overlays/ovlmenu.ovl exists.
- If Nintendo logo is still patched, check /atmosphere/exefs_patches/logo_sloth was removed.
