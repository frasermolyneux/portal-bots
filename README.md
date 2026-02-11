# XtremeIdiots Portal - Bots
[![Code Quality](https://github.com/frasermolyneux/portal-bots/actions/workflows/codequality.yml/badge.svg)](https://github.com/frasermolyneux/portal-bots/actions/workflows/codequality.yml)
[![PR Verify](https://github.com/frasermolyneux/portal-bots/actions/workflows/pr-verify.yml/badge.svg)](https://github.com/frasermolyneux/portal-bots/actions/workflows/pr-verify.yml)
[![Deploy Dev](https://github.com/frasermolyneux/portal-bots/actions/workflows/deploy-dev.yml/badge.svg)](https://github.com/frasermolyneux/portal-bots/actions/workflows/deploy-dev.yml)
[![Deploy Prd](https://github.com/frasermolyneux/portal-bots/actions/workflows/deploy-prd.yml/badge.svg)](https://github.com/frasermolyneux/portal-bots/actions/workflows/deploy-prd.yml)

## Documentation
- [B3 Events Documentation](docs/b3-events-documentation.md) - Event system integration, captured payloads, and proposed schemas for portal ingestion.
- [Player and Communication Events](docs/player-and-communication-events.md) - Player lifecycle and chat events captured by the portal bots.

## Overview
Bot plugins and supporting assets that bridge game servers to the XtremeIdiots Portal. Captures B3 (BigBrotherBot) events, normalizes payloads, and forwards telemetry for auditing, chat, and player lifecycle management. Uses client-credential auth to call portal API endpoints and falls back to a local spool when outbound calls fail. Includes event schema references, plugin configuration templates, and operational notes for maintaining the plugins.

## Contributing
Please read the [contributing](CONTRIBUTING.md) guidance; this is a learning and development project.

## Security
Please read the [security](SECURITY.md) guidance; I am always open to security feedback through email or opening an issue.
