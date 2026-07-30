#!/bin/bash
#SBATCH --job-name=sphinx
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=sphinx-%j.out
#SBATCH --error=sphinx-%j.err

set -euo pipefail

if [[ -z "${SPHINX_OUTPUT_ROOT:-}" ]]; then
    echo "SPHINX_OUTPUT_ROOT is required and must point to writable scratch storage." >&2
    exit 2
fi
SPHINX_REPO_ROOT="${SLURM_SUBMIT_DIR}"
if [[ ! -f "${SPHINX_REPO_ROOT}/setupSPHINX.m" ]]; then
    echo "Submit this job from the SPHINX repository root." >&2
    exit 2
fi
module purge
module load "${SPHINX_MATLAB_MODULE:-matlab/R2024a}"
cd "${SPHINX_REPO_ROOT}"
matlab -singleCompThread -batch \
    "addpath('examples'); result=run_sphinx_headless; disp(result)"
