#!/usr/bin/env bash
# The project's pipeline on one toolchain, run by .github/workflows/matrix.yml on each toolchain of the fobos
# [scaffold] matrix, with the fortran-toolchains environment contract: FC, CC, CXX, TOOLCHAIN, TOOLCHAIN_OS and
# TOOLCHAIN_FAMILY (gnu, nvf, intel). Created once by fobis scaffold, then the project's: edit it freely. The same
# script runs locally, in `docker run <image>` and in CI.
set -euo pipefail
echo "toolchain: $TOOLCHAIN ($TOOLCHAIN_OS, $TOOLCHAIN_FAMILY), FC=$FC"
fobis build --mode "tests-$TOOLCHAIN_FAMILY"
bash scripts/run_tests.sh
# the OpenMP target device layer (-DHERALD_OMP): built and run where gfortran is, on the host branch
if [[ "$TOOLCHAIN_FAMILY" == gnu ]]; then
  fobis build --mode tests-gnu-omp
  bash scripts/run_tests.sh --exe-dir exe-omp
fi
# the OpenACC device layer (-DHERALD_OAC): built with nvfortran -acc and run on the host device type, which the
# variable asks for explicitly (the hosted runners have no GPU; the device branch runs only on a machine with one)
if [[ "$TOOLCHAIN_FAMILY" == nvf ]]; then
  fobis build --mode tests-nvf-oac
  ACC_DEVICE_TYPE=host bash scripts/run_tests.sh --exe-dir exe-oac
fi
