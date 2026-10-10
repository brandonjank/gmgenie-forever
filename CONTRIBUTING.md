# Contributing

For a bug report, include your client version/build, core fork/revision, client
and server response language, reproduction steps, expected behavior, and the
Lua error text. Include `/gmgenie debug` output when relevant. Remove player
identifiers, IP addresses, account details and credentials before posting.

Install `tests/requirements.txt`, run `python tests/test_gmgenie.py` and build
with `python tools/package.py` before opening a pull request. Describe the
client/core versions you tested and which in-game paths you exercised.

Prefer addon-scoped adapters in `Forever.lua` over replacing Blizzard globals.
Keep original copyright and license notices. Contributions are under GPL v3,
the same license as this project. Avoid committing WTF data, logs, backups or
server-specific configuration.
