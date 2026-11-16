# Binary patches

16 idempotent, self-verifying patches for **Cities: Skylines II `1.6.2f1`** (re-derived 2026-10-10; 1.6.0f1 before that) running
under Wine on macOS. Each is a workaround for a defect in Wine (mostly), Colossal.IO, or the
Paradox SDK — see [`../docs/patch-inventory.md`](../docs/patch-inventory.md) for what each one
fixes and who owns the real bug.

```sh
bash ../repatch.sh                                   # the default wrapper's game folder
CS2_GAME_DIR="/path/to/Cities Skylines II" bash ../repatch.sh   # a game folder somewhere else
```

`setup.sh` and the launcher run exactly this.

## Which patches the game needs

**The game needs ten of these and nothing else.** With them it reaches the main menu, loads a city and
downloads mods (boot-verified on 1.6.2f1, 2026-10-10). `setup.sh` and the launcher apply exactly those ten.

The other six tolerate a file-error defect that Wine 10 had and that some third-party Wine 11 builds bring
back. They are off by default; `CS2_ERRNO_PATCHES=1 bash ../repatch.sh` applies all sixteen.

**Licence checks are out of scope.** Wine 10 also failed a valid signature in `BCryptVerifySignature` (root
cause **R3**), so on that engine the game's UI middleware rejected its own valid licence. Wine 11 fixed that,
and that is the fix: see [`../docs/wine-bugs/`](../docs/wine-bugs/).
This repository has never contained a way around that check, the project keeps none, and pull requests
adding one are declined.

## Safety properties

- **Self-verifying.** Every patch checks exactly what it is about to change before writing — a byte
  fingerprint, or (the five `PDX.SDK.dll` patches since 1.6.2f1, and the six errno patches of
  `mscorlib.dll`) the target method found **by name** with its full original IL matched. A game update
  that moves or changes the code makes the patch **refuse and tell you** rather than corrupt the binary.
- **Backed up.** A `.bak` is made before the first write to a file whose fix is not yet in, never from a
  file that already holds it. After a game update a `.bak` can be the previous build's: do not copy one
  back by hand, have Steam verify the game's files.
- **Idempotent.** Re-running is a no-op.
- **Revertible.** `patch_fshandle.py <dir> --revert`, or restore from `.bak`.
- **Dry-runnable.** Several accept `--dry-run`. The six errno patches take `--form` instead, which prints
  the method they would change and writes nothing (below).

## If a game update breaks them

A script that finds nothing of its own patch in a file, and cannot put it there because of what the file
holds (the code it changes is absent, changed, there more or fewer times than expected, or leaves no
room), writes nothing and **exits 3**: not for this build. Any other refusal is exit 1, and so is a file
that holds part of a script's patch in a way that does not add up. `repatch.sh` names the exit-3 scripts
on a `NO FIX YET FOR THIS BUILD:` line with what the player may see without each, and exits 3 when
nothing else failed; setup then finishes the install and says a fix is not out yet (exit 5). The design
is `docs/plans/patch-outcomes.md` at the repository's root.

The six errno scripts (`patch_dirdel`, `patch_dirhandle`, `patch_delfile`, `patch_delrec`,
`patch_dirrec_nx`, `patch_delchild`) are held to the same test as the five `PDX.SDK.dll` scripts: each
finds its method of `mscorlib.dll` by name and requires the whole method to be the one it was written
for before it looks at its own site. The whole method is carried as one sha256, of the method's
**by-name form**: its IL one line an instruction, every metadata token as the name it resolves to, and
one line for each known patch site, so the form is the same whether a site is patched or not. A method
that changed, or a file that is not this `mscorlib.dll`, is exit 3 with nothing written, also when the
script's own bytes happen to read as patched. A method that only moved is patched where it now is. A
file `dnfile` cannot read as a .NET file ends in its traceback, exit 1. They are off by default, and
each takes about two seconds to read the file. The design is [`../docs/plans/errno-by-name.md`](../docs/plans/errno-by-name.md).

The four form texts are in [`errno-forms/`](errno-forms/) (`rdr.txt` `RemoveDirectoryRecursive`, `rdi.txt`
`RemoveDirectoryInternal`, `df.txt` `DeleteFile`, `cdh.txt` `CreateDirectoryHandle`), as build 26404411
has them. `<script> --form <mscorlib.dll or the game's folder>` prints the form of that script's method
in a file and writes nothing: exit 0 when it is the recorded one, 3 when it is not. So when a game update
changes one of these methods, compare:

```sh
diff errno-forms/rdr.txt <(python3 patch_dirdel.py --form "/path/to/Cities Skylines II")
```

When the method changed so far that no form can be made (a site holds neither its original nor its
patched bytes), the first line begins with `#` and gives the reason, and the body follows decoded as one
piece, so the site lines of the committed text show as differences beside the real ones. Setup does not
install `errno-forms/`: it is for whoever works in a checkout.

The other ten's offsets and patterns need re-deriving after such an update. `dis_pdx.py` is the IL
disassembler used to find them:

```sh
python3 dis_pdx.py <path/to/PDX.SDK.dll> '<CreateFileStream>d__25' MoveNext
```

It reads the file with `dnfile`, which ships in [`_vendor/`](_vendor/README.md) beside the patch scripts: no
virtual environment and no `pip`.

Method rules that kept this from going wrong, the hard way:

- **Prefer in-place edits** (identical byte count) over relocating a method body — no branch-target,
  offset or exception-clause shifts to get wrong.
- **Never relocate a `.ctor`** — it breaks early-init type resolution even when the IL is valid.
- **Check stack balance on both branch paths**, or you get `Invalid IL at IL_xxxx` at runtime, not
  at patch time.
- **Boot-verify anything touching `mscorlib`** — it is on the boot path.
