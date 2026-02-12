# Copilot Instructions

## Project Overview

This repository contains the XtremeIdiots Portal bots, built on BigBrotherBot (B3). It packages the B3 runtime with a custom portal plugin that forwards game-server telemetry to the portal API.

## Repository Layout

- `src/` – Bundled Windows B3 distribution (Python 2.7 binaries, plugins, configs).
- `src/plugins/portal/__init__.py` – Core portal plugin; registers chat, player-connect, map-change, and startup events.
- `src/conf_templates/` – Template INI configs for per-server deployment.
- `src/conf/` – Populated per-server plugin configs.
- `src/extplugins/` – External B3 plugins. `src/plugins/` – Standard B3 plugins.
- `docs/` – Event schema references and documentation.
- `terraform/` – Infrastructure-as-code for Azure resources (Key Vault, APIM, resource health alerts).
- `.github/workflows/` – CI/CD pipelines for code quality, build, deploy (dev/prd), and environment management.

## Core Plugin Behaviour

- The portal plugin posts events to `/OnChatMessage`, `/OnPlayerConnected`, `/OnMapChange`, `/OnServerConnected`, and `/OnMapVote` (via `!like`/`!dislike` commands).
- Authentication uses Azure AD client credentials (tenant/client-id/secret/scope) to obtain a bearer token.
- API calls use `requests` with retry/backoff; failures spool to a local file for replay when connectivity returns.

## Configuration

- `plugin_portal_gameType_serverId.ini` – Game type, server ID, APIM base URL, AAD creds, TLS cert path, and `spoolPath`.
- `gameType_serverId.ini` – B3 bot metadata; references the portal plugin config in `conf/`.

## Infrastructure

- Terraform manages Azure Key Vault, API Management data sources, resource health alerts, and random IDs.
- State is read from remote backends; variables and tfvars are in `terraform/tfvars/`.

## Development Guidelines

- There is no .NET or Node build. Deployment packages the `src/` directory to the target B3 host with server-specific configs.
- No automated tests exist; validate plugin changes against a running B3 instance.
- When changing plugin behaviour, update docs under `docs/` to keep event schemas current.
- Ensure `spoolPath` is writable for offline event persistence. TLS verification uses the configured PEM path.
- The portal plugin depends on the B3 admin plugin being loaded; map vote commands default to admin level 1.

## Terraform Conventions

- Use `data` sources for existing Azure resources (resource groups, client config, remote state).
- Follow the existing file-per-resource pattern (e.g., `key_vault.tf`, `key_vault_secrets.tf`).
- Variables are declared in `variables.tf` with environment-specific values in `terraform/tfvars/`.
