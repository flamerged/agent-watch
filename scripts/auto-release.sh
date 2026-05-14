#!/usr/bin/env bash
set -euo pipefail

git fetch --tags --prune origin >/dev/null

ensure_main_branch() {
  if [[ -n "${GITHUB_REF:-}" && "$GITHUB_REF" != "refs/heads/main" ]]; then
    echo "Release script must run on refs/heads/main, not ${GITHUB_REF}." >&2
    exit 1
  fi
}

require_gh_auth() {
  if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub CLI is not authenticated." >&2
    exit 1
  fi
}

build_release_asset() {
  local version="$1"
  local asset_dir
  local asset_path

  asset_dir="$(mktemp -d)"
  asset_path="${asset_dir}/agent-watch.30s.sh"
  cp bin/agent-watch.30s.sh "$asset_path"
  perl -0pi -e "s#(<xbar\\.version>v)[^<]+(</xbar\\.version>)#\${1}${version}\${2}#g; s#(<swiftbar\\.version>v)[^<]+(</swiftbar\\.version>)#\${1}${version}\${2}#g; s#(PLUGIN_VERSION=\")[^\"]+(\")#\${1}${version}\${2}#g" "$asset_path"
  chmod +x "$asset_path"
  printf '%s\n' "$asset_path"
}

latest_tag="$(git describe --tags --match 'v[0-9]*' --abbrev=0 2>/dev/null || true)"
if [[ -n "$latest_tag" ]]; then
  base_version="${latest_tag#v}"
  commit_range="${latest_tag}..HEAD"
else
  base_version="0.0.0"
  commit_range="HEAD"
fi

if [[ ! "$base_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid version format from latest tag: ${latest_tag:-$base_version}" >&2
  exit 1
fi

commit_subjects="$(git log --format=%s "$commit_range")"
commit_bodies="$(git log --format=%B "$commit_range")"

bump=""
if grep -Eq '(^[a-zA-Z]+(\([^)]+\))?!:|^BREAKING CHANGE:($| ))' <<<"$commit_bodies"; then
  bump="major"
elif grep -Eq '^feat(\([^)]+\))?: ' <<<"$commit_subjects"; then
  bump="minor"
elif grep -Eq '^(fix|perf)(\([^)]+\))?: ' <<<"$commit_subjects"; then
  bump="patch"
fi

if [[ -z "$bump" ]]; then
  if [[ -n "$latest_tag" ]] && [[ "$(git rev-list -n1 "$latest_tag" 2>/dev/null)" == "$(git rev-parse HEAD)" ]]; then
    if [[ "${AUTO_RELEASE_DRY_RUN:-0}" == "1" ]]; then
      echo "No new release; latest tag ${latest_tag} already points at HEAD."
      exit 0
    fi

    ensure_main_branch
    require_gh_auth

    if gh release view "$latest_tag" >/dev/null 2>&1; then
      echo "No releasable conventional commits since ${latest_tag}; release already exists."
      exit 0
    fi

    echo "Tag ${latest_tag} already points at HEAD, but its GitHub Release is missing. Creating it."
    asset_path="$(build_release_asset "${latest_tag#v}")"
    gh release create "$latest_tag" "$asset_path#agent-watch.30s.sh" --title "$latest_tag" --generate-notes
    exit 0
  fi

  echo "No releasable conventional commits since ${latest_tag:-repository start}."
  exit 0
fi

IFS=. read -r major minor patch <<<"$base_version"
case "$bump" in
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  patch)
    patch=$((patch + 1))
    ;;
esac

next_version="${major}.${minor}.${patch}"
next_tag="v${next_version}"

if [[ "${AUTO_RELEASE_DRY_RUN:-0}" == "1" ]]; then
  echo "Would create ${next_tag} (${bump}) from ${latest_tag:-repository start}."
  exit 0
fi

ensure_main_branch
require_gh_auth

today="$(date -u +%Y-%m-%d)"
notes_file="$(mktemp)"
{
  if [[ -n "$latest_tag" ]]; then
    printf '## [%s](https://github.com/flamerged/agent-watch/compare/%s...%s) (%s)\n\n' "$next_version" "$latest_tag" "$next_tag" "$today"
  else
    printf '## %s (%s)\n\n' "$next_version" "$today"
  fi

  features="$(grep -E '^feat(\([^)]+\))?: ' <<<"$commit_subjects" | sed -E 's/^feat(\([^)]+\))?: /- /' || true)"
  fixes="$(grep -E '^(fix|perf)(\([^)]+\))?: ' <<<"$commit_subjects" | sed -E 's/^(fix|perf)(\([^)]+\))?: /- /' || true)"
  breaking="$(grep -E '(^[a-zA-Z]+(\([^)]+\))?!:|^BREAKING CHANGE:($| ))' <<<"$commit_bodies" || true)"

  if [[ -n "$breaking" ]]; then
    printf '### Breaking Changes\n\n'
    grep -E '^[a-zA-Z]+(\([^)]+\))?!: ' <<<"$commit_subjects" | sed -E 's/^[a-zA-Z]+(\([^)]+\))?!: /- /' || true
    grep -E '^BREAKING CHANGE:($| )' <<<"$commit_bodies" | sed -E 's/^BREAKING CHANGE: ?/- /' || true
    printf '\n'
  fi
  if [[ -n "$features" ]]; then
    printf '### Features\n\n%s\n\n' "$features"
  fi
  if [[ -n "$fixes" ]]; then
    printf '### Fixes\n\n%s\n\n' "$fixes"
  fi
} > "$notes_file"

asset_path="$(build_release_asset "$next_version")"

created_tag=0
if ! git rev-parse "$next_tag" >/dev/null 2>&1; then
  git tag "$next_tag"
  git push origin "$next_tag"
  created_tag=1
fi

if gh release view "$next_tag" >/dev/null 2>&1; then
  echo "Release ${next_tag} already exists."
  exit 0
fi

if ! gh release create "$next_tag" "$asset_path#agent-watch.30s.sh" --title "$next_tag" --notes-file "$notes_file"; then
  if [[ "$created_tag" == "1" ]]; then
    git push --delete origin "$next_tag" >/dev/null 2>&1 || true
    git tag -d "$next_tag" >/dev/null 2>&1 || true
  fi
  exit 1
fi
