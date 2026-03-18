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

## Workflow consigliato (utente finale)

1. Scarica `Vekir-full.zip` dall'ultima release.
2. Estrai in root SD.
3. Avvia `kefir-updater` (installer Kefir).
4. A fine installer, Vekir viene schedulato automaticamente:
reboot su TegraExplorer -> apply script -> reboot finale.
5. (Opzionale) tieni un pack Venom in `sd:/venom/` per override file dinamici.

## Update Pipeline (importante)

Vekir usa la pipeline di update di **Kefir**.

- Update pack/sistema: usa `kefir-updater`
- Uberhand updater è volutamente disattivato in Vekir per evitare falsi `Processing -> Done` su componenti non tracciati da repo

Per download diretto del pack Vekir è supportato anche **AIO Switch Updater**:
- `AIO -> Custom Downloads -> [PACK] Vekir (Latest)`

## Nuova Versione Kefir (maintainer flow)

Quando esce una nuova versione Kefir:

1. Scarica il nuovo zip Kefir ufficiale.
2. Esegui il builder:

```bash
./scripts/build_vekir_full.sh --kefir-zip /percorso/Kefir.zip --version 19.0.X
```

3. Trovi l'output in:
- `.release/Vekir-full-19.0.X.zip` (oppure `.release/Vekir-full.zip`)
4. Carica il file come asset release GitHub (puoi rinominarlo `Vekir.zip` per il link `latest/download/Vekir.zip`).

Il builder applica automaticamente la chain:
`Kefir installer -> schedule Vekir apply -> TegraExplorer -> reboot finale`.

## Automazione GitHub (build + release)

Il workflow `.github/workflows/vekir-auto-release.yml` pubblica solo su esecuzione manuale:
- usa la release Kefir pin-nata e validata dal maintainer
- usa i componenti Venom gia inclusi nel repository
- builda `Vekir-full`
- pubblica release GitHub con:
  - `Vekir.zip` (link stabile per `latest/download`)
  - `Vekir-full-kfX-vxY.zip` (versionato)

Modalità:
- `Manuale`: GitHub -> Actions -> `Vekir Auto Release` -> Run workflow

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
