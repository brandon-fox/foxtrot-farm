# Foxtrot Farm and Firewood

One-page landing site for Foxtrot Farm and Firewood. Static HTML, no build step, hosted free on GitHub Pages.

## Spec

[features/](features/): landing page, custom domain, hosting switch, action pinning.

## Open items (VERIFY)

- Domain ownership: foxtrot.farm shows as registered, owner unknown. Rename `CNAME.pending` to `CNAME` only once the domain is confirmed ours.
- Location line ("Long Island, New York"): confirm it is fine to show.
- Contact method for 2027 (business email or form).
- Optional single link to the owner's portfolio site.

## Deploy

Pushing to `main` deploys through `.github/workflows/static.yml` (Settings > Pages > Source: GitHub Actions).

## Contributing

- Once per clone: `pip install -r requirements-dev.txt && pre-commit install`.
- Rules: [docs/decisions](docs/decisions). Required checks on `main` enforce them.
