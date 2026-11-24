# qd-agentscan-cli

Zero-dependency Bash CLI for auditing websites and static build directories against the **AgentScan 6-Dimension AI-Agent Readiness Standard** (0–100 score, Grade A–F, exit code `0` on `>= 85`).

## Dimensions Checked

1. **AI Discoverability & Crawlability (20 pts)**: `/robots.txt` AI crawler rules (`GPTBot`, `ClaudeBot`, `PerplexityBot`, `Google-Extended`), `/sitemap.xml` / `/sitemap-index.xml`, `/llms.txt`, and `/llms-full.txt` / `/.well-known/llms.txt`.
2. **No-JS Content Accessibility & Semantic DOM (20 pts)**: Raw readable text length without JavaScript hydration, semantic HTML5 landmarks (`<main>`, `<header>`, `<footer>`, `<article>`, `<nav>`, `<section>`), and `<h1>` topic anchoring.
3. **Structured Knowledge Graph & Metadata (20 pts)**: Schema.org `application/ld+json` entity types, OpenGraph, Twitter Cards, and canonical `<link>` tags.
4. **Agent Interactivity & Machine Protocols (15 pts)**: `/.well-known/mcp.json` / `/api/mcp` and `/openapi.json` / `/api/spec`.
5. **Edge Security & HTTP Headers (15 pts)**: HTTPS, `Strict-Transport-Security`, and `X-Content-Type-Options: nosniff` (live URL mode) or edge header config files (`_headers`, `nginx/vhost_security.conf`, `security-headers.conf`) in static mode.
6. **App & Product Machine Signals (10 pts)**: `/manifest.json` / `/site.webmanifest` and `/.well-known/assetlinks.json` or release anchors.

## Requirements

- `bash` (4.0+)
- `curl` (for `--url` mode)
- `python3` (for stripping `<script>` / `<style>` tags in No-JS text extraction)

## Usage

```bash
# Audit a local static build output directory
./agentscan.sh --dir ./dist --verbose

# Audit a live HTTPS site or local preview server
./agentscan.sh --url https://example.com --verbose
```

Exit status is `0` when the score is `>= 85`, and `1` otherwise, making it suitable as a CI/CD deployment quality gate.

## License

[MIT](./LICENSE)
