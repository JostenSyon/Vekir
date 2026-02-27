# Vekir

`Vekir` è un patch-pack ibrido pensato per chi usa quotidianamente sia Kefir che NX-Venom.

Obiettivo:
- mantenere l'affidabilità e la semplicità di update tipiche di Kefir
- integrare personalizzazione HUD/OC e strumenti utili tipici di NX-Venom
- mantenere boot pulito, debrand e gestione controllata dei file

## Filosofia

Vekir non sostituisce i due progetti originali: li rispetta e li usa come base tecnica.

- `Kefir` come fondazione stabile e pipeline di aggiornamento
- `NX-Venom` come riferimento per HUD, toolset e personalizzazione avanzata

## Struttura Pack

- `bootloader/ini/vekir.ini`: voce Hekate per avvio rapido Vekir
- `startup.te`: autorun TegraExplorer (one-shot)
- `switch/vekir/apply_remix.te`: script principale (debrand + HUD + import selettivi)
- `switch/vekir/commands_menu.ini`: menu comandi safe
- `switch/vekir/system_tweaks_bootlogo_config.ini`: menu bootlogo esteso
- `switch/vekir/bootlogo/`: asset bootlogo Vekir (`Light` / `Black`)

## Workflow consigliato

1. Aggiorna/copia Kefir in root SD.
2. Copia il contenuto di `Vekir/` in root SD.
3. (Opzionale) copia pack Venom in `sd:/venom/`.
4. Avvia da Hekate `Vekir Apply`.
5. Lo script applica patch e reboota automaticamente.

## Update Pipeline (importante)

Vekir usa la pipeline di update di **Kefir**.

- Update pack/sistema: usa `kefir-updater`
- Uberhand updater è volutamente disattivato in Vekir per evitare falsi `Processing -> Done` su componenti non tracciati da repo

## Requisiti pratici

- emuMMC già funzionante
- TegraExplorer disponibile in `sd:/bootloader/payloads/TegraExplorer.bin`
- asset Venom opzionali in `sd:/venom/` per override personalizzati

## Crediti & Progetti Originali

Questo progetto è un omaggio diretto ai maintainer e alle community di:

- Kefir: [rashevskyv/kefir](https://github.com/rashevskyv/kefir)
- Kefir Updater: [rashevskyv/kefir-updater](https://github.com/rashevskyv/kefir-updater)
- NX-Venom: [CatcherITGF/NX-Venom](https://github.com/CatcherITGF/NX-Venom)

Vekir non rivendica paternità sui componenti originali: li integra in modo selettivo per un setup personale coerente e mantenibile.

## Note

- Il menu AIO (`preserve.txt`) serve a preservare file/config scelti durante update via AIO.
- I bootlogo Hekate devono essere BMP `720x1280` a `32-bit`.
- Se copi da macOS, usa lo script `scripts/push_remix_to_switch_sd.sh`: pulisce automaticamente `.DS_Store` e `._*` sulla SD.
