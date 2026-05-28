#!/bin/bash
# cgp-cnvkit-coverage/src/code.sh
# Computes CNVkit on-target coverage for one sample (amplicon mode).
# No antitarget bins — backbone CNV signal is handled by PURPLE.
# Passes the gene panel BED directly to cnvkit.py coverage (no autobin).
# Output: <sample_id>.targetcoverage.cnn
set -eo pipefail

main() {
    echo "=== CGP CNVkit coverage: ${sample_id} ==="
    echo "Instance: $(hostname); CPUs: $(nproc); RAM: $(free -h | awk '/Mem:/{print $2}')"

    # ── Install cnvkit ────────────────────────────────────────────────────────
    echo "[setup] Installing cnvkit..."
    python3 -m venv /tmp/cnvkit-env
    /tmp/cnvkit-env/bin/pip install cnvkit --quiet 2>&1 | tail -3
    export PATH="/tmp/cnvkit-env/bin:$PATH"
    cnvkit.py version

    # ── Stage inputs ──────────────────────────────────────────────────────────
    echo "[inputs] Downloading files..."
    dx download "${tumour_bam}" -o tumour.bam
    dx download "${tumour_bai}" -o tumour.bam.bai
    dx download "${baits}"      -o panel.bed

    NBINS=$(grep -vc "^#" panel.bed || true)
    echo "[inputs] Panel intervals: ${NBINS}"

    # ── Compute coverage ──────────────────────────────────────────────────────
    # Amplicon mode: pass panel BED directly to coverage (no autobin needed).
    # Each target interval becomes one bin. CNVkit weights bins by depth so
    # small exon intervals are down-weighted automatically.
    echo "[coverage] Computing on-target coverage..."
    cnvkit.py coverage tumour.bam panel.bed \
        --processes "$(nproc)" \
        --output "${sample_id}.targetcoverage.cnn"

    # Sanity check
    NLINES=$(wc -l < "${sample_id}.targetcoverage.cnn")
    echo "[coverage] Output lines (incl. header): ${NLINES}"
    [ "${NLINES}" -gt 1000 ] || { echo "ERROR: coverage file too small (${NLINES} lines)"; exit 1; }

    MEDIAN_DEPTH=$(python3 -c "
import csv
depths = []
with open('${sample_id}.targetcoverage.cnn') as f:
    reader = csv.DictReader(f, delimiter='\t')
    for row in reader:
        try: depths.append(float(row.get('depth', 0)))
        except: pass
depths.sort()
print(f'{depths[len(depths)//2]:.1f}' if depths else '0')
")
    echo "[coverage] Median depth: ${MEDIAN_DEPTH}"

    # ── Upload output ─────────────────────────────────────────────────────────
    coverage_cnn=$(dx upload "${sample_id}.targetcoverage.cnn" --brief)
    dx-jobutil-add-output coverage_cnn "${coverage_cnn}" --class=file

    echo "=== Done: ${sample_id} ==="
}
