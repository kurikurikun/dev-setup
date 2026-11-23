# dev-setup

One command to set up a Mac for working on move-ment's apps with Claude Code:

```bash
curl -fsSL https://raw.githubusercontent.com/kurikurikun/dev-setup/main/setup.sh | bash
```

- Clones [Peripheral Speed](https://github.com/kurikurikun/peripheral-speed), [Day Offload](https://github.com/kurikurikun/day-offload), [CallNotes](https://github.com/kurikurikun/callnotes), the move-ment website, filminginjapan, tesutemo, crew-book, minpaku-register and LoopLapse into `~/Developer` (outside iCloud).
- Copies each site's `.env.local` (never in git) from its old iCloud folder in `~/Documents/claude/` if one is there.
- Installs `hooks/dev-autopull.sh` as a Claude Code SessionStart hook: a session started inside `~/Developer/<repo>` fast-forwards that repo from GitHub. It never merges or touches uncommitted work, and reports instead when it can't pull.

Safe to run again. Notarized releases still happen only on the Mac with the Developer ID certificate.
