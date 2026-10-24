# Midnamer

A Mac editor for `.midnam` files: the bank and patch names of your MIDI modules, effects units and synths, as
Digital Performer shows them in its patch menus.

<!-- help:start -->
## What it does

Digital Performer (DP) can show the real names of the presets in your external MIDI gear instead of plain program
numbers. It reads them from `.midnam` files (MIDI Name Documents). Midnamer lets you open, create and edit those files
comfortably — banks, patch names, bank select values, channels — and install them where DP looks for them.

It is inspired by CherryPicker, a discontinued editor that no longer runs on current macOS, and follows its layout.

## Requirements

- A Mac with macOS 13 Ventura or later, Apple silicon or Intel.
- Digital Performer. Tested with DP 11.36; other programs that read `.midnam` files may work too.

## Installing

1. Unzip **Midnamer-<version>.zip** and move **Midnamer.app** to your Applications folder.
2. The first time, macOS refuses to open it because it does not come from the App Store or an identified developer.
   Try to open it once, then go to **System Settings ▸ Privacy & Security** and click **Open Anyway**. You only
   need to do this once.
3. To update, replace the old Midnamer.app with the new one. Your settings are kept.

## Quick start

1. **Open a file** with **File ▸ Open…** (⌘O) or by dropping it on the app. The files DP uses are in
   `/Library/Audio/MIDI Devices/MOTU/<Manufacturer>/`. Or create a new one with **File ▸ New** (⌘N): a short
   assistant asks for the manufacturer and model and whether all banks play on every channel.
2. **Edit** banks and patches (see below). Everything can be undone with ⌘Z.
3. **Save** with ⌘S. Midnamer never saves on its own.
4. **Install in DP** with **File ▸ Install in DP…** (⌘I). It copies the file to DP's folder for that manufacturer,
   under the name you will see in DP. If the model is not yet in any device list, it can add it to its own file,
   `<Manufacturer> (Midnamer).middev`, so that the model appears in the lists of DP and Audio MIDI Setup. Before
   replacing anything it asks, keeps a copy of the old file, and tells you how to undo it.
5. **In DP:** the device must exist in **Audio MIDI Setup** with that manufacturer and model (if the model is not in
   the list, type both exactly). Then, in DP's **Bundles** window, **MIDI Devices** tab, open the device's
   **MIDI Device Properties ▸ Patches** and choose the file in **Master Names**. After changing a file, restart DP or
   choose the file again in Master Names.

## The document window

Each file opens in a window with five tabs. **Preview** shows the exact file that will be saved.

### Patch Banks

The list of banks, in the order DP shows them.

- Double-click a name to rename it (names must be unique). Tab / ↓ go to the next bank, ⇧Tab / ↑ to the previous one.
- **S0** and **S32** are the bank select values (CC 0 and CC 32); “-” means not used. Double-click them to change
  them; you choose whether the bank's patches get the new values too (all of them, or only those with or without
  their own bank selects).
- **Channel Set** chooses which channels the bank plays on. With several banks selected, changing one changes all.
- **+** adds a bank, **−** deletes the selected ones, and dragging reorders them.
- A **red** name is an empty bank; a **blue** one has patches whose bank select differs from the bank's.
- **P** opens the bank's patch list.
- **Merge** joins the selected banks into a new one (hold Option when clicking Add to also keep the originals).
- **Zap Dups** removes repeated patches. With banks selected, it keeps those and removes their repeats from the other
  banks; with nothing selected, it removes from the banks with bank selects the patches that are already in a bank
  without them (a custom bank). This helps DP remember which custom bank you picked a preset from.
- **Import** brings patch lists from other `.midnam` files in a folder (DP's folder for the manufacturer by default).
- **Find** searches patches by name across all banks and makes a new bank from the results.
- Drag banks to another open document to copy them there, with their patches.

**Sub-banks.** To group banks the way DP shows them as a tree, select banks and choose **Edit ▸ Indent Bank** (⌘→)
to put them under the bank above, or **Outdent Bank** (⌘←) to take them out. Midnamer adds the “├ ” and “└ ” signs
and keeps them right when you add, move, rename or delete banks. **Mark as All Patches** adds a “• ” to the bank that
holds every preset. The same commands are in the right-click menu.

### Patch lists

Click **P** on a bank to open its patches: B0, B32, number, name and Ascii, all editable with a double-click.

- Tab / ⇧Tab move between cells, ↑ / ↓ between patches.
- Click a column title to sort by it; that is the order of DP's menu.
- **+** adds patches. Pasting text (⌘V) or dropping it adds one patch per line (or per comma, tab or quoted name).
- **−** or Delete removes them; **Renumber** renumbers all patches or the selected ones.
- Drag patches to reorder them, or to another bank's list — in the same file or another one — to copy them.
- **Find** filters by name; in the magnifier's menu, **Select Matches** selects them instead.
- Right-click (or **Edit ▸ New Bank from Selection…**) to copy the selected patches into a new bank.
- **Copy...** copies the list as text (name, number, bank selects…) to paste elsewhere, for example in Logic.

### Device

Manufacturer and model, modes and channel sets: which groups of channels exist and which channels are active (for
example `1-9, 11-16`). **Audition Ch** is the channel used to audition patches.

### MIDI (audition)

Choose the **Device Out** and tick **Enable MIDI**. Selecting a patch in a list then sends its bank select and program
change to the module, so you hear it. **Test Note** also plays a short note (for sound modules; leave it off for
effects units). Midnamer only sends bank select, program change and the test note — never SysEx or anything that
changes the module's memory.

### Controllers

Names for MIDI controllers (CC 0–127). DP 11.36 does not show them, but other programs may.

### Categories

Sets of bank names, such as GM categories. **Dup** makes an editable copy; **Add To Banks** creates an empty bank for
each name, to fill by dragging patches into it.

## Keyboard shortcuts

- ⌘N new file (assistant) · ⌘O open · ⌘S save · ⇧⌘S save as · ⌘W close
- ⌘I install in DP
- ⌘Z undo · ⇧⌘Z redo
- ⌘→ indent bank · ⌘← outdent bank (Patch Banks tab)

## What Midnamer changes on your Mac

- Only the files you save, and — with Install in DP and after asking — the `.midnam` and `.middev` files in
  `/Library/Audio/MIDI Devices/MOTU/<Manufacturer>/`.
- Copies of every file it replaces go to `~/Library/Application Support/Midnamer/Backups/`.
- To remove a model it added, delete its `<Manufacturer> (Midnamer).middev` (or the older
  `(CherryPicker).middev`, which it keeps using if you already have one).

## Limitations

- Note lists (drum note names) cannot be edited yet.
- Files must be UTF-8 (all current `.midnam` files are).
- A channel set always keeps at least one bank: the file format requires it.
<!-- help:end -->

## License

Midnamer is free software under the GNU General Public License v3.0 (see `LICENSE`). It is an independent project,
not affiliated with Alterspective (CherryPicker) or MOTU (Digital Performer); their names are used only to say what it
works with.

Project documentation (in Spanish): [`docs/00_MASTER_INDEX.md`](docs/00_MASTER_INDEX.md).
