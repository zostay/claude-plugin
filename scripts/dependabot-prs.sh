#!/usr/bin/env bash
#
# Fetch open Dependabot PRs for the current repository and their merge readiness.
# Outputs one JSON object per line (JSONL), sorted by oldest first.
#
# Output fields:
#   number, title, branch, mergeable, checks_pass, review_decision, url
#
# checks_pass is true/false when status check info is available, or null when
# the token lacks checks:read permission (statusCheckRollup inaccessible).
#

set -euo pipefail

# Check that gh CLI is available
if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI is not installed or not in PATH." >&2
  exit 1
fi

# Check that we're in a git repository and can determine the remote
repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null) || {
  echo "Error: unable to determine repository. Are you in a git repo with a GitHub remote?" >&2
  exit 1
}

base_fields="number,title,headRefName,mergeable,reviewDecision,url"

# Try fetching with statusCheckRollup (requires checks:read token permission).
# If that fails, fall back to fetching without it.
has_checks=true
pr_json=$(gh pr list \
  --author "app/dependabot" \
  --state open \
  --limit 100 \
  --json "${base_fields},statusCheckRollup" 2>/dev/null) || {
  has_checks=false
  pr_json=$(gh pr list \
    --author "app/dependabot" \
    --state open \
    --limit 100 \
    --json "${base_fields}" 2>/dev/null) || {
    echo "Error: failed to list Dependabot PRs. Check that you have access to ${repo}." >&2
    exit 1
  }
}

# Check if any PRs were found
pr_count=$(echo "$pr_json" | jq 'length')
if [ "$pr_count" -eq 0 ]; then
  echo "No open Dependabot PRs for ${repo}."
  exit 0
fi

# Emit JSONL, oldest first (gh returns newest first, so reverse)
if [ "$has_checks" = true ]; then
  echo "$pr_json" | jq -c 'reverse | .[] | {
    number: .number,
    title: .title,
    branch: .headRefName,
    mergeable: .mergeable,
    checks_pass: (
      if (.statusCheckRollup | length) == 0 then
        true
      else
        [.statusCheckRollup[] | .status == "COMPLETED" and (.conclusion == "SUCCESS" or .conclusion == "NEUTRAL")] | all
      end
    ),
    review_decision: .reviewDecision,
    url: .url
  }'
else
  echo "$pr_json" | jq -c 'reverse | .[] | {
    number: .number,
    title: .title,
    branch: .headRefName,
    mergeable: .mergeable,
    checks_pass: null,
    review_decision: .reviewDecision,
    url: .url
  }'
fi
