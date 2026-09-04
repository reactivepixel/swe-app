#!/usr/bin/env bash
# create-assignment-repo.sh
# Create FullSailGameStudies/SWE_App_<username> from SWE_App_Template
# and invite that user as a write collaborator.
#
# Usage:
#   ./create-assignment-repo.sh <github-username>
#   ./create-assignment-repo.sh jdoe --clone

set -euo pipefail

ORG="FullSailGameStudies"
TEMPLATE="reactivepixel/SWE_App_Template"
REPO_PREFIX="SWE_App_"
PERMISSION="push"   # pull | triage | push | maintain | admin

usage() {
  cat <<EOF
Usage: $0 <github-username> [options]

Creates ${ORG}/${REPO_PREFIX}<username> from ${TEMPLATE}
and invites <username> as a collaborator (${PERMISSION}).

Options:
  --public          Create a public repo (default: private)
  --private         Create a private repo (default)
  --internal        Create an internal org repo
  --clone           Clone the new repo into the current directory
  --all-branches    Copy all template branches, not just default
  --desc TEXT       Repository description
  --prefix TEXT     Repo name prefix (default: ${REPO_PREFIX})
  --permission PERM Collaborator permission (default: ${PERMISSION})
  -h, --help        Show this help

Examples:
  $0 jdoe
  $0 jdoe --clone
  $0 jdoe --prefix SWE3312_
EOF
  exit "${1:-0}"
}

[[ $# -lt 1 ]] && usage 1
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage 0

USERNAME="$1"
shift

VISIBILITY="--private"
CLONE=""
ALL_BRANCHES=""
DESCRIPTION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --public)       VISIBILITY="--public"; shift ;;
    --private)      VISIBILITY="--private"; shift ;;
    --internal)     VISIBILITY="--internal"; shift ;;
    --clone)        CLONE="--clone"; shift ;;
    --all-branches) ALL_BRANCHES="--include-all-branches"; shift ;;
    --desc)         DESCRIPTION="$2"; shift 2 ;;
    --prefix)       REPO_PREFIX="$2"; shift 2 ;;
    --permission)   PERMISSION="$2"; shift 2 ;;
    -h|--help)      usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

if [[ ! "${USERNAME}" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]]; then
  echo "Invalid GitHub username: ${USERNAME}" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found. Install: https://cli.github.com/" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated. Run: gh auth login" >&2
  exit 1
fi

REPO_NAME="${REPO_PREFIX}${USERNAME}"
FULL_NAME="${ORG}/${REPO_NAME}"

echo "==> Creating ${FULL_NAME} from template ${TEMPLATE}"

create_args=(
  repo create "${FULL_NAME}"
  --template "${TEMPLATE}"
  ${VISIBILITY}
)

[[ -n "${CLONE}" ]] && create_args+=(--clone)
[[ -n "${ALL_BRANCHES}" ]] && create_args+=(--include-all-branches)
[[ -n "${DESCRIPTION}" ]] && create_args+=(--description "${DESCRIPTION}")

gh "${create_args[@]}"

echo "==> Inviting @${USERNAME} with permission=${PERMISSION}"

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${ORG}/${REPO_NAME}/collaborators/${USERNAME}" \
  -f permission="${PERMISSION}" \
  --silent

echo "==> Done"
echo "    Repo:  https://github.com/${FULL_NAME}"
echo "    User:  https://github.com/${USERNAME}"
echo "    Role:  ${PERMISSION}"