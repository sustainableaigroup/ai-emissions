# Versioning and Release Policy

This report is a methodology that licensees, auditors and researchers rely on to produce and check reported numbers. Every published version therefore stays available, unchanged, at its own permanent address, and every change between versions is recorded with its effect on results.

## Version Identifiers

Versions are named `CAIEC-MMYY` after the month of release, for example `CAIEC-0926` and `CAIEC-1226`. Each version has

- a git tag and GitHub Release with the same name, with the distributed PDF attached
- a DOI minted by Zenodo from that release (the Zenodo concept DOI always resolves to the latest version)
- a permanent URL, `https://reports.sustainableaigroup.com/ai-emissions/MMYY/`
- an entry in `versions.json`, which drives the version switcher and the "superseded" banner on every page

`https://reports.sustainableaigroup.com/ai-emissions/` always shows the latest version. Citations should use the permanent URL of the version, never the bare address.

A correction that changes a number and cannot wait for the next scheduled release ships as a point release, `CAIEC-MMYY.1`, with its own tag, release, DOI and changelog entry. Typos and broken links wait for the next release.

## What Never Changes

Once a version is released it is not edited. Archived versions live in `archive/MMYY/`, rendered from the release tag, with a `SHA256SUMS` file that the deploy workflow checks on every build. The build fails if any archived file has changed. `archive/0926/PROVENANCE.txt` records the two edits made when the first version was frozen, before this policy existed.

`main` deploys to the live site on every push. Release work is done on a `release/MMYY` branch and merged on release day.

## Change Records

Every change between versions gets an identifier, `CMMYY-NN` (for example `C1226-04`), and one of four types.

| Type | Meaning | Badge in text |
|---|---|---|
| Method | Changes how a quantity is calculated, or the boundary | Yes |
| Data | Updates a parameter value from new evidence | Yes |
| Clarification | Rewords or expands text with no numerical effect | No |
| Editorial | Typos, links, formatting | No |

Each change record states the section, the type, the trigger (the review, disclosure or study that prompted it), the before and after values, and the effect on results. The effect is reported as the percentage change in total kgCO₂e on the fixed reference inventory, for the change on its own and for the release as a whole, so that effects are comparable across releases. Records also say whether the change is likely to be significant enough to prompt recalculation of previously reported periods.

The full record is Annex F (Version History) in the report, written in `_changelog.qmd`, so the PDF carries it. GitHub release notes summarize it and link to the line-by-line comparison between tags (`/compare/CAIEC-0926...CAIEC-1226`).

Method and Data changes are also marked where they occur in the text with a `.change` block, which renders as a "Changed in MMYY" badge in the web version (with a link to the same section in the previous version) and as a marked note in the PDF. Badges only cover changes since the previous version; older history lives in Annex F.

```markdown
::: {.change #C1226-04 type="data" from="0926" anchor="model-development"}
Development allocation updated using the Anthropic S-1 compute disclosure. Raises total emissions by X% on the reference inventory.
:::
```

Section anchors are fixed with explicit IDs (`## 4.1 CLEER Output {#cleer-output}`) so that links between versions survive renamed or renumbered headings. Never change an existing ID.

## Compatibility With CLEER Factor Releases

Each version records the CLEER factor release it is designed for (`cleer_factor_release` in `versions.json`, and the compatibility table in Annex F). Licensees keep factor releases they have received, so they need to know which calculation version applies to which factors.

## Release Checklist

1. Create `release/MMYY` from `main`. Make all changes there.
2. Log every change in `_changelog.qmd` and add `.change` blocks for Method and Data changes. Compute reference-inventory effects.
3. Update the version block at the top of `index.qmd` (version, date, PDF name, permalink, typst output file) and the citation fields, plus `version` and `publication_date` in `.zenodo.json` and `CITATION.cff`.
4. Open a pull request into `main`, review the preview, and merge on release day. The new version goes live at `/ai-emissions/` and `/ai-emissions/MMYY/`.
5. Publish a GitHub Release named `CAIEC-MMYY` on the merge commit, with the PDF downloaded from the live site attached. Zenodo mints the DOI.
6. Update `versions.json` (new entry with DOI and changelog link, `latest`), add the DOI to the citation block and `CITATION.cff`, and run `scripts/freeze-version.sh MMYY` to freeze the new version into `archive/MMYY/`. Merge through a pull request.
7. Check that the previous version now shows the superseded banner and that both permanent URLs and PDFs resolve.
