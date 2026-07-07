# Changelog

## [Unreleased]

## [2.0.0] - 2026-07-07

### Changed
- Replaced PyPI virtual environment install with Docker image (`cgp-cnvkit:1.0.0`) to ensure reproducible CNVkit environment and eliminate Ubuntu 24.04 system-package conflicts
- CNVkit version: master commit `fc65941d` (packaged in Docker image)
- Expanded sanity check comments to explain NLINES and MEDIAN_DEPTH checks

### Removed
- Virtual environment install step (superseded by Docker)

## [1.0.0] - 2026-05-27

### Added
- Initial release
- CNVkit amplicon-mode coverage for tumour-only CGP panel samples
- Virtual environment install to avoid Ubuntu 24.04 system package conflicts
- Median depth sanity check: fails if output has <1,000 lines or median depth = 0
