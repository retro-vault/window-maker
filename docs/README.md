# Window Maker documentation

Four sections, by what you are trying to do.

## [building/](building/) — compiling and installing

- [building/README.md](building/README.md) — the CMake build: requirements,
  the staged `bin/` tree, running under Xephyr, VS Code integration, build
  options, and system installation.

## [using/](using/) — running and configuring Window Maker

- [using/FAQ](using/FAQ) — the Window Maker FAQ
- [using/i18n.md](using/i18n.md) — internationalisation: locales, fonts,
  input methods, and how to enable them
- [using/definable-cursor.md](using/definable-cursor.md) — configuring the
  mouse cursors

## [man/](man/) — manual pages

Sources for the pages installed as `man wmaker`, `man WPrefs`, and so on,
plus Czech, Russian and Slovak translations. `wmaker.1` and `wmsetbg.1` are
generated at build time from `wmaker.in` and `wmsetbg.in`, because they
document options that only exist in some configurations.

After a build they are staged in `bin/share/man`:

```bash
man -M bin/share/man wmaker
```

## [development/](development/) — contributing and project history

- [development/TODO](development/TODO) — what still needs doing
- [development/BUGS](development/BUGS) — known problems
- [development/BUGFORM](development/BUGFORM) — bug report template
- [development/submitting-patches.txt](development/submitting-patches.txt) —
  how to prepare a patch the maintainers can apply
- [development/email-clients.txt](development/email-clients.txt) — configuring
  mail clients not to mangle patches
- [development/NEWS](development/NEWS) — user-visible changes per release
- [development/ChangeLog](development/ChangeLog) — detailed change history
- [development/AUTHORS](development/AUTHORS) — credits

## Not here

Documentation that belongs to a single component stays with it:

- `lib/wrlib/README`, `lib/WINGs/README`, `src/apps/WPrefs/README`,
  `data/WindowMaker/README` and `README.themes`, `tools/README` — component notes
- the per-component `po/README` files — translator notes
- `lib/WINGs/NEWS` and `lib/wrlib/NEWS` — per-library API/ABI change logs
