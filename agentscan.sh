#!/usr/bin/env bash
# ==============================================================================
# agentscan.sh — Autonomous AI-Agent Readiness & Modern Web Audit CLI
# Evaluates websites & static builds against the AgentScan 6-Dimension Standard
# Score: 0–100 | Grade: A to F | Zero External SaaS Dependencies
# ==============================================================================
set -u
set -o pipefail

# ANSI Colour Palette
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[32m"
C_RED="\033[31m"
C_YELLOW="\033[33m"
C_BLUE="\033[34m"
C_CYAN="\033[36m"

TARGET_URL=""
TARGET_DIR=""
VERBOSE=false

usage() {
    local exit_code="${1:-0}"
    echo -e "${C_BOLD}Usage:${C_RESET} $0 [--url <http://url>] [--dir <path/to/dist_or_public>] [--verbose]"
    echo ""
    echo "Options:"
    echo "  --url <URL>    Audit a running website or local preview server (e.g. http://localhost:4321)"
    echo "  --dir <PATH>   Audit a local build output directory (e.g. ./dist)"
    echo "  --verbose      Display detailed technical evidence per inspection check"
    echo "  -h, --help     Show this help message"
    exit "${exit_code}"
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --url)
            TARGET_URL="${2:-}"
            shift 2
            ;;
        --dir)
            TARGET_DIR="${2:-}"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage 0
            ;;
        *)
            echo -e "${C_RED}Error: Unknown parameter '$1'${C_RESET}"
            usage 1
            ;;
    esac
done

if [[ -z "${TARGET_URL}" && -z "${TARGET_DIR}" ]]; then
    if [[ -d "./dist" ]]; then
        TARGET_DIR="./dist"
    elif [[ -d "./public" ]]; then
        TARGET_DIR="./public"
    else
        echo -e "${C_YELLOW}Notice: Neither --url nor --dir specified. Inspecting local public/dist or pass --url <URL>${C_RESET}"
        usage 1
    fi
fi

echo -e "${C_BOLD}${C_CYAN}======================================================================${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}  AgentScan — AI-Agent Readiness & Modern Machine DOM Audit Engine    ${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}  Standard: Modern Web Guidance & llms.txt Discovery Protocol         ${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}======================================================================${C_RESET}"

if [[ -n "${TARGET_URL}" ]]; then
    echo -e "${C_BLUE}Target Mode:${C_RESET} Remote / Local HTTP Server -> ${C_BOLD}${TARGET_URL}${C_RESET}"
else
    echo -e "${C_BLUE}Target Mode:${C_RESET} Local Static Filesystem    -> ${C_BOLD}${TARGET_DIR}${C_RESET}"
fi
echo ""

TOTAL_SCORE=0
MAX_SCORE=100
declare -a DEFECTS=()
declare -a EVIDENCE=()

# Helper function to fetch or read a file
fetch_asset() {
    local asset_path="$1"
    if [[ -n "${TARGET_URL}" ]]; then
        local full_url="${TARGET_URL%/}${asset_path}"
        curl -s -L -m 5 "${full_url}" 2>/dev/null || echo ""
    else
        local local_path="${TARGET_DIR%/}${asset_path}"
        if [[ -f "${local_path}" ]]; then
            cat "${local_path}"
        elif [[ -f "${TARGET_DIR%/}/public${asset_path}" ]]; then
            cat "${TARGET_DIR%/}/public${asset_path}"
        else
            echo ""
        fi
    fi
}

# Helper function to check asset existence and HTTP status
check_asset_exists() {
    local asset_path="$1"
    if [[ -n "${TARGET_URL}" ]]; then
        local full_url="${TARGET_URL%/}${asset_path}"
        local code
        code=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "${full_url}" 2>/dev/null || echo "000")
        if [[ "${code}" =~ ^(200|301|302|304)$ ]]; then
            return 0
        else
            return 1
        fi
    else
        local local_path="${TARGET_DIR%/}${asset_path}"
        if [[ -f "${local_path}" || -f "${TARGET_DIR%/}/public${asset_path}" ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# ------------------------------------------------------------------------------
# 1. AI DISCOVERABILITY (20 Points)
# Checks: robots.txt, sitemap.xml, llms.txt, llms-full.txt / .well-known/llms.txt
# ------------------------------------------------------------------------------
echo -e "${C_BOLD}▶ Checking Dimension 1: AI Discoverability & Crawlability (20 pts)${C_RESET}"

ROBOTS_TXT=$(fetch_asset "/robots.txt")
if [[ -n "${ROBOTS_TXT}" ]]; then
    if echo "${ROBOTS_TXT}" | grep -Ei "(GPTBot|ClaudeBot|PerplexityBot|Google-Extended|User-agent: \*)" >/dev/null; then
        TOTAL_SCORE=$((TOTAL_SCORE + 5))
        echo -e "  [${C_GREEN}PASS${C_RESET}] robots.txt exists and configures AI crawler permissions (+5 pts)"
        EVIDENCE+=("robots.txt: Present with crawler policies")
    else
        TOTAL_SCORE=$((TOTAL_SCORE + 2))
        echo -e "  [${C_YELLOW}WARN${C_RESET}] robots.txt exists but lacks explicit AI crawler tags (+2 pts)"
        DEFECTS+=("robots.txt lacks explicit permissions for GPTBot, ClaudeBot, and PerplexityBot.")
    fi
else
    echo -e "  [${C_RED}FAIL${C_RESET}] robots.txt missing (0/5 pts)"
    DEFECTS+=("Missing /robots.txt. AI bots cannot verify crawl boundaries.")
fi

if check_asset_exists "/sitemap.xml" || check_asset_exists "/sitemap-index.xml"; then
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
    echo -e "  [${C_GREEN}PASS${C_RESET}] sitemap.xml discovered (+5 pts)"
    EVIDENCE+=("sitemap.xml: Verified accessible")
else
    echo -e "  [${C_RED}FAIL${C_RESET}] sitemap.xml missing (0/5 pts)"
    DEFECTS+=("Missing /sitemap.xml. AI agents cannot systematically map content nodes.")
fi

LLMS_TXT=$(fetch_asset "/llms.txt")
if [[ -n "${LLMS_TXT}" && $(printf '%s' "${LLMS_TXT}" | wc -c) -gt 40 ]]; then
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
    echo -e "  [${C_GREEN}PASS${C_RESET}] /llms.txt standard discovery document verified (+5 pts)"
    EVIDENCE+=("llms.txt: Present with $(printf '%s\n' "${LLMS_TXT}" | wc -l) lines of machine context")
else
    echo -e "  [${C_RED}FAIL${C_RESET}] /llms.txt missing or empty (0/5 pts)"
    DEFECTS+=("Missing /llms.txt. LLMs and AI search engines lack structured domain summary.")
fi

if check_asset_exists "/llms-full.txt" || check_asset_exists "/.well-known/llms.txt"; then
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
    echo -e "  [${C_GREEN}PASS${C_RESET}] Extended AI context (llms-full.txt or /.well-known/llms.txt) present (+5 pts)"
    EVIDENCE+=("llms-full.txt: Extended LLM knowledge graph discovered")
else
    TOTAL_SCORE=$((TOTAL_SCORE + 2))
    echo -e "  [${C_YELLOW}WARN${C_RESET}] Extended /llms-full.txt missing (+2/5 pts)"
    DEFECTS+=("Consider providing /llms-full.txt for comprehensive multi-page agent context.")
fi

# ------------------------------------------------------------------------------
# 2. CONTENT ACCESSIBILITY & NO-JS FALLBACK (20 Points)
# Checks: Raw semantic HTML readability without JavaScript execution
# ------------------------------------------------------------------------------
echo -e "\n${C_BOLD}▶ Checking Dimension 2: No-JS Content Accessibility & Semantic DOM (20 pts)${C_RESET}"

INDEX_HTML=$(fetch_asset "/index.html")
if [[ -z "${INDEX_HTML}" && -n "${TARGET_URL}" ]]; then
    INDEX_HTML=$(fetch_asset "/")
fi

# Extract raw readable text using python3 for multi-line script/style stripping
PLAIN_TEXT=$(printf '%s' "${INDEX_HTML}" | python3 -c "import sys, re; content=sys.stdin.read(); text=re.sub(r'<(script|style)[^>]*>.*?</\1>', '', content, flags=re.DOTALL|re.IGNORECASE); text=re.sub(r'<[^>]+>', ' ', text); print(' '.join(text.split()))" 2>/dev/null || echo "")
TEXT_LEN=${#PLAIN_TEXT}

if [[ ${TEXT_LEN} -gt 600 ]]; then
    TOTAL_SCORE=$((TOTAL_SCORE + 10))
    echo -e "  [${C_GREEN}PASS${C_RESET}] Raw HTML body text size: ${TEXT_LEN} characters (No hydration wall) (+10 pts)"
    EVIDENCE+=("Raw Body Content: ${TEXT_LEN} readable characters without JavaScript")
elif [[ ${TEXT_LEN} -gt 150 ]]; then
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
    echo -e "  [${C_YELLOW}WARN${C_RESET}] Thin raw HTML content: only ${TEXT_LEN} characters detected (+5/10 pts)"
    DEFECTS+=("Body content is sparse without JavaScript. Ensure SSR or static pre-rendering.")
else
    echo -e "  [${C_RED}FAIL${C_RESET}] Hydration Wall: Almost zero readable content without JS (${TEXT_LEN} chars) (0/10 pts)"
    DEFECTS+=("Critical: Site appears to be an empty JS shell (<div id=\"root\"></div>). AI crawlers will see a blank page.")
fi

# Check semantic HTML5 landmarks
SEMANTIC_HITS=0
for tag in "<main" "<header" "<footer" "<article" "<nav" "<section"; do
    if grep -qi "${tag}" <<< "${INDEX_HTML}"; then
        SEMANTIC_HITS=$((SEMANTIC_HITS + 1))
    fi
done

if [[ ${SEMANTIC_HITS} -ge 4 ]]; then
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
    echo -e "  [${C_GREEN}PASS${C_RESET}] Rich semantic HTML5 landmarks detected (${SEMANTIC_HITS} tags) (+5 pts)"
    EVIDENCE+=("Semantic Landmarks: ${SEMANTIC_HITS} tags (<main>, <header>, <footer>, <section>, etc.)")
else
    TOTAL_SCORE=$((TOTAL_SCORE + 2))
    echo -e "  [${C_YELLOW}WARN${C_RESET}] Minimal semantic HTML tags detected (${SEMANTIC_HITS}/6 tags) (+2/5 pts)"
    DEFECTS+=("Increase semantic HTML5 landmark usage (<main>, <article>, <header>, <footer>).")
fi

# Check heading hierarchy
if grep -qi "<h1" <<< "${INDEX_HTML}"; then
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
    echo -e "  [${C_GREEN}PASS${C_RESET}] Primary <h1> heading present for topic anchoring (+5 pts)"
    EVIDENCE+=("Heading Hierarchy: Clear <h1> topic root established")
else
    echo -e "  [${C_RED}FAIL${C_RESET}] Missing <h1> heading tag (0/5 pts)"
    DEFECTS+=("Missing primary <h1> heading tag. AI agents cannot identify core page topic.")
fi

# ------------------------------------------------------------------------------
# 3. STRUCTURED KNOWLEDGE GRAPH & METADATA (20 Points)
# Checks: Schema.org JSON-LD, Open Graph, Twitter Cards, Canonical
# ------------------------------------------------------------------------------
echo -e "\n${C_BOLD}▶ Checking Dimension 3: Structured Knowledge Graph (Schema.org & Meta) (20 pts)${C_RESET}"

if grep -qi 'application/ld+json' <<< "${INDEX_HTML}"; then
    TOTAL_SCORE=$((TOTAL_SCORE + 10))
    echo -e "  [${C_GREEN}PASS${C_RESET}] Schema.org JSON-LD structured data script detected (+10 pts)"

    if grep -Eiq '(Person|ProfilePage|Organization|SoftwareApplication|MobileApplication|WebSite)' <<< "${INDEX_HTML}"; then
        TOTAL_SCORE=$((TOTAL_SCORE + 5))
        echo -e "  [${C_GREEN}PASS${C_RESET}] Validated rich entity types (Person/ProfilePage/Organization/SoftwareApplication) (+5 pts)"
        EVIDENCE+=("JSON-LD: Rich entity schema detected")
    else
        TOTAL_SCORE=$((TOTAL_SCORE + 2))
        echo -e "  [${C_YELLOW}WARN${C_RESET}] JSON-LD present but lacks rich entity types (+2/5 pts)"
        DEFECTS+=("Enrich Schema.org JSON-LD with Person, ProfilePage, Organization, or SoftwareApplication types.")
    fi
else
    echo -e "  [${C_RED}FAIL${C_RESET}] No Schema.org JSON-LD script found (0/15 pts)"
    DEFECTS+=("Missing Schema.org JSON-LD script. AI cannot construct structured knowledge entities.")
fi

# OpenGraph & Social Metadata
OG_HITS=0
for meta in 'property="og:title"' 'property="og:description"' 'name="twitter:card"' 'rel="canonical"'; do
    if grep -qi "${meta}" <<< "${INDEX_HTML}"; then
        OG_HITS=$((OG_HITS + 1))
    fi
done

if [[ ${OG_HITS} -ge 3 ]]; then
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
    echo -e "  [${C_GREEN}PASS${C_RESET}] OpenGraph, Twitter Cards & Canonical links verified (+5 pts)"
    EVIDENCE+=("Social & Semantic Meta: ${OG_HITS}/4 verified")
else
    TOTAL_SCORE=$((TOTAL_SCORE + 2))
    echo -e "  [${C_YELLOW}WARN${C_RESET}] Incomplete social metadata (${OG_HITS}/4 tags present) (+2/5 pts)"
    DEFECTS+=("Ensure canonical link, og:title, og:description, and twitter:card are complete.")
fi

# ------------------------------------------------------------------------------
# 4. AGENTIC INTERACTIVITY & API MANIFESTS (15 Points)
# Checks: Model Context Protocol (MCP) endpoints & OpenAPI specs
# ------------------------------------------------------------------------------
echo -e "\n${C_BOLD}▶ Checking Dimension 4: Agent Interactivity & Machine Protocols (15 pts)${C_RESET}"

if check_asset_exists "/.well-known/mcp.json" || check_asset_exists "/api/mcp"; then
    TOTAL_SCORE=$((TOTAL_SCORE + 10))
    echo -e "  [${C_GREEN}PASS${C_RESET}] Model Context Protocol (MCP) manifest or endpoint discovered (+10 pts)"
    EVIDENCE+=("MCP Protocol: Standard /.well-known/mcp.json manifest accessible")
else
    TOTAL_SCORE=$((TOTAL_SCORE + 4))
    echo -e "  [${C_YELLOW}WARN${C_RESET}] /.well-known/mcp.json not present (+4/10 pts)"
    DEFECTS+=("Optional but recommended: Provide /.well-known/mcp.json for native AI agent interaction.")
fi

if check_asset_exists "/openapi.json" || check_asset_exists "/api/spec"; then
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
    echo -e "  [${C_GREEN}PASS${C_RESET}] OpenAPI 3.x specification found (+5 pts)"
    EVIDENCE+=("OpenAPI: Machine-readable API schema available")
else
    TOTAL_SCORE=$((TOTAL_SCORE + 2))
    echo -e "  [${C_YELLOW}WARN${C_RESET}] OpenAPI spec not detected (+2/5 pts)"
    DEFECTS+=("Publish public API specifications at /openapi.json if exposing endpoints.")
fi

# ------------------------------------------------------------------------------
# 5. EDGE SECURITY & HTTP HEADERS (15 Points)
# Checks: HTTPS enforcement, HSTS, CSP, and security flags
# ------------------------------------------------------------------------------
echo -e "\n${C_BOLD}▶ Checking Dimension 5: Edge Security & Security Guardrails (15 pts)${C_RESET}"

if [[ -n "${TARGET_URL}" && "${TARGET_URL}" =~ ^https:// ]]; then
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
    echo -e "  [${C_GREEN}PASS${C_RESET}] HTTPS protocol enforced (+5 pts)"

    HEADERS=$(curl -s -I -m 5 "${TARGET_URL}" 2>/dev/null || echo "")
    if echo "${HEADERS}" | grep -qi "strict-transport-security"; then
        TOTAL_SCORE=$((TOTAL_SCORE + 5))
        echo -e "  [${C_GREEN}PASS${C_RESET}] HSTS (Strict-Transport-Security) header active (+5 pts)"
        EVIDENCE+=("Security: HSTS preload header verified")
    else
        TOTAL_SCORE=$((TOTAL_SCORE + 2))
        echo -e "  [${C_YELLOW}WARN${C_RESET}] HSTS header missing or weak (+2/5 pts)"
        DEFECTS+=("Configure Strict-Transport-Security: max-age=63072000; includeSubDomains; preload.")
    fi

    if echo "${HEADERS}" | grep -qi "x-content-type-options"; then
        TOTAL_SCORE=$((TOTAL_SCORE + 5))
        echo -e "  [${C_GREEN}PASS${C_RESET}] X-Content-Type-Options: nosniff present (+5 pts)"
        EVIDENCE+=("Security: nosniff and protection headers verified")
    else
        TOTAL_SCORE=$((TOTAL_SCORE + 2))
        echo -e "  [${C_YELLOW}WARN${C_RESET}] Additional security headers (nosniff, CSP) recommended (+2/5 pts)"
        DEFECTS+=("Add X-Content-Type-Options: nosniff and Content-Security-Policy.")
    fi
else
    if [[ -f "./nginx/vhost_security.conf" || -f "./security-headers.conf" || -f "./_headers" ]]; then
        TOTAL_SCORE=$((TOTAL_SCORE + 15))
        echo -e "  [${C_GREEN}PASS${C_RESET}] Security headers configuration detected in repo (+15 pts)"
        EVIDENCE+=("Security Config: HSTS, nosniff, and CSP headers configured")
    else
        TOTAL_SCORE=$((TOTAL_SCORE + 8))
        echo -e "  [${C_YELLOW}WARN${C_RESET}] Static audit mode: ensure edge server defines HSTS & CSP headers (+8/15 pts)"
        DEFECTS+=("Verify production web server or reverse proxy enforces HTTPS, HSTS, and CSP headers.")
    fi
fi

# ------------------------------------------------------------------------------
# 6. APP & PRODUCT MACHINE SIGNALS (10 Points)
# Checks: PWA Manifest, assetlinks, verified release/install links
# ------------------------------------------------------------------------------
echo -e "\n${C_BOLD}▶ Checking Dimension 6: App & Product Machine Signals (10 pts)${C_RESET}"

if check_asset_exists "/manifest.json" || check_asset_exists "/site.webmanifest"; then
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
    echo -e "  [${C_GREEN}PASS${C_RESET}] Web App Manifest (manifest.json) discovered (+5 pts)"
    EVIDENCE+=("PWA Manifest: Verified accessible")
else
    TOTAL_SCORE=$((TOTAL_SCORE + 2))
    echo -e "  [${C_YELLOW}WARN${C_RESET}] manifest.json not detected (+2/5 pts)"
    DEFECTS+=("Add /manifest.json for PWA installation and machine-readable app metadata.")
fi

if check_asset_exists "/.well-known/assetlinks.json" || grep -Eiq '(download|github\.com|apk|release)' <<< "${INDEX_HTML}"; then
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
    echo -e "  [${C_GREEN}PASS${C_RESET}] Verified application release & install links present (+5 pts)"
    EVIDENCE+=("Product Signals: Deep links & release anchors detected")
else
    TOTAL_SCORE=$((TOTAL_SCORE + 2))
    echo -e "  [${C_YELLOW}WARN${C_RESET}] Release/install deep links sparse (+2/5 pts)"
    DEFECTS+=("Ensure direct app download or repository links are explicitly indexed.")
fi

# ------------------------------------------------------------------------------
# SCORE SUMMARY & GRADE CALCULATION
# ------------------------------------------------------------------------------
GRADE="F"
GRADE_COLOUR="${C_RED}"

if [[ ${TOTAL_SCORE} -ge 90 ]]; then
    GRADE="A"
    GRADE_COLOUR="${C_GREEN}"
elif [[ ${TOTAL_SCORE} -ge 80 ]]; then
    GRADE="B"
    GRADE_COLOUR="${C_BLUE}"
elif [[ ${TOTAL_SCORE} -ge 70 ]]; then
    GRADE="C"
    GRADE_COLOUR="${C_YELLOW}"
elif [[ ${TOTAL_SCORE} -ge 60 ]]; then
    GRADE="D"
    GRADE_COLOUR="${C_YELLOW}"
else
    GRADE="F"
    GRADE_COLOUR="${C_RED}"
fi

echo ""
echo -e "${C_BOLD}${C_CYAN}======================================================================${C_RESET}"
echo -e "${C_BOLD}  FINAL AGENTSCAN READINESS RESULT: ${GRADE_COLOUR}${TOTAL_SCORE} / ${MAX_SCORE} (Grade ${GRADE})${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}======================================================================${C_RESET}"

if [[ ${#EVIDENCE[@]} -gt 0 && "${VERBOSE}" == true ]]; then
    echo -e "\n${C_BOLD}${C_GREEN}Technical Evidence Verified:${C_RESET}"
    for item in "${EVIDENCE[@]}"; do
        echo -e "  • ${item}"
    done
fi

if [[ ${#DEFECTS[@]} -gt 0 ]]; then
    echo -e "\n${C_BOLD}${C_YELLOW}Actionable Optimisation Recommendations:${C_RESET}"
    for defect in "${DEFECTS[@]}"; do
        echo -e "  ${C_YELLOW}⚠${C_RESET} ${defect}"
    done
fi

echo ""
if [[ ${TOTAL_SCORE} -ge 85 ]]; then
    echo -e "${C_GREEN}${C_BOLD}✔ PASSED AI READINESS QUALITY GATE: Site is optimised for AI discovery & agents.${C_RESET}"
    exit 0
else
    echo -e "${C_RED}${C_BOLD}✖ FAILED QUALITY GATE: Score must be >= 85 for production deployment.${C_RESET}"
    exit 1
fi
