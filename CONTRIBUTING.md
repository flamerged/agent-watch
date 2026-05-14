# Contributing

Thanks for taking a look at Agent Watch.

## Development

Run checks before opening a pull request:

```sh
./scripts/check.sh
```

Keep changes local-first and privacy-conscious. The plugin should not send telemetry, read broad filesystem locations, or print secrets. New integrations should have short timeouts and tolerate missing tools.

## Pull Requests

- Keep changes focused.
- Use a Conventional Commit PR title. `fix:` and `perf:` trigger patch releases, `feat:` triggers minor releases, and breaking changes trigger major releases.
- Include a short description of the agent/backend behavior being added.
- Include before/after menu output when changing display behavior, with private paths or tokens removed.
