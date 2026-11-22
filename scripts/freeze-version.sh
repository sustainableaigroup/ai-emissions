#!/usr/bin/env bash
# Freeze a released version of the report into archive/<code>/.
#
# Usage:  scripts/freeze-version.sh <code> [path/to/release.pdf]
#   e.g.  scripts/freeze-version.sh 1226
#
# Renders the source at tag CAIEC-<code> with the pinned Quarto version,
# copies the output to archive/<code>/, uses the PDF attached to the GitHub
# release (or the path given) instead of a local re-render, makes sure the
# version-banner script is loaded, and writes SHA256SUMS. Commit the result
# through a pull request. Never edit an archive by hand afterwards.

set -euo pipefail

code="${1:?usage: scripts/freeze-version.sh <code> [release.pdf]}"
pdf_override="${2:-}"
tag="CAIEC-${code}"
quarto_pinned="1.10.19"
root="$(git rev-parse --show-toplevel)"
dest="${root}/archive/${code}"

if [ -e "${dest}" ]; then
  echo "archive/${code} already exists. Archives are immutable; stopping." >&2
  exit 1
fi

if [ "$(quarto --version)" != "${quarto_pinned}" ]; then
  echo "Quarto $(quarto --version) found; ${quarto_pinned} required (see deploy.yml)." >&2
  exit 1
fi

git -C "${root}" rev-parse --verify --quiet "refs/tags/${tag}" >/dev/null \
  || git -C "${root}" fetch --quiet origin "refs/tags/${tag}:refs/tags/${tag}"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

git -C "${root}" worktree add --quiet --detach "${work}/src" "${tag}"
(cd "${work}/src" && quarto render >/dev/null)

mkdir -p "${dest}"
cp -R "${work}/src/docs/." "${dest}/"
rm -rf "${dest}/archive" "${dest}/versions.json" "${dest}/version-banner.js"
git -C "${root}" worktree remove --force "${work}/src"

# Replace the locally rendered PDF with the one distributed at release.
pdf_name="$(basename "$(ls "${dest}"/*.pdf | head -n 1)")"
if [ -n "${pdf_override}" ]; then
  cp "${pdf_override}" "${dest}/${pdf_name}"
else
  gh release download "${tag}" --pattern "*.pdf" --dir "${work}/pdf"
  cp "${work}/pdf/"*.pdf "${dest}/${pdf_name}"
fi

# Versions from CAIEC-1226 on load the banner script from source; older
# renders need it added.
if ! grep -q 'version-banner.js' "${dest}/index.html"; then
  python3 - "${dest}/index.html" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
tail = "</body></html>"
assert s.count(tail) == 1
s = s.replace(tail, '<script src="/ai-emissions/version-banner.js" defer></script>\n' + tail)
open(p, "w", encoding="utf-8").write(s)
PY
fi

cat > "${dest}/PROVENANCE.txt" <<EOF
${tag} archive: provenance

Source:   git tag ${tag}, commit $(git -C "${root}" rev-parse --short "${tag}^{commit}")
Frozen:   $(date -u +%Y-%m-%d)
HTML:     rendered from the tagged source with Quarto ${quarto_pinned}
PDF:      the file attached to the GitHub release ${tag}
Integrity: SHA256SUMS lists every file in this folder; the deploy workflow
           verifies it on every build.
EOF

(cd "${dest}" && find . -type f ! -name SHA256SUMS | sort | xargs sha256sum > SHA256SUMS)

echo "Frozen ${tag} into archive/${code}/. Review, then commit via a pull request."
