#!/bin/bash
# Copyright (c) 2022-2023, NVIDIA CORPORATION.

set -euo pipefail

. /opt/conda/etc/profile.d/conda.sh

rapids-logger "Generate C++ testing dependencies"
rapids-dependency-file-generator \
  --output conda \
  --file_key test_cpp \
  --matrix "cuda=${RAPIDS_CUDA_VERSION%.*};arch=$(arch)" | tee env.yaml

rapids-mamba-retry env create --force -f env.yaml -n test

# Temporarily allow unbound variables for conda activation.
set +u
conda activate test
set -u

RAPIDS_CUDA_MAJOR="${RAPIDS_CUDA_VERSION%%.*}"
LIBRMM_CHANNEL=$(rapids-get-artifact ci/rmm/pull-request/1223/042a67e/rmm_conda_cpp_cuda${RAPIDS_CUDA_MAJOR}_$(arch).tar.gz)
LIBRAFT_CHANNEL=$(rapids-get-artifact ci/raft/pull-request/1388/7bddaee/raft_conda_cpp_cuda${RAPIDS_CUDA_MAJOR}_$(arch).tar.gz)
# LIBCUMLPRIMS_CHANNEL=$(rapids-get-artifact ci/cumlprims_mg/pull-request/129/85effb7/cumlprims_mg_conda_cpp_cuda${RAPIDS_CUDA_MAJOR}_$(arch).tar.gz)

CPP_CHANNEL=$(rapids-download-conda-from-s3 cpp)
RAPIDS_TESTS_DIR=${RAPIDS_TESTS_DIR:-"${PWD}/test-results"}/
mkdir -p "${RAPIDS_TESTS_DIR}"

if [ "${RAPIDS_CUDA_MAJOR}" == 12 ]; then
cat << EOF > /opt/conda/.condarc
auto_update_conda: False
channels:
  - rapidsai
  - rapidsai-nightly
  - dask/label/dev
  - pytorch
  - nvidia
  - conda-forge
always_yes: true
number_channel_notices: 0
conda_build:
  set_build_id: false
  root_dir: /tmp/conda-bld-workspace
  output_folder: /tmp/conda-bld-output
EOF
fi

rapids-print-env

# debug: remove cuda 12 packages from conda-forge that are being combined with nvidia channel ones
conda remove --force cuda-cccl_linux-64 cuda-cudart cuda-cudart-dev cuda-cudart-dev_linucuda-cudart-static  cuda-cudart-static_lincuda-profiler-api cuda-version libcublas libcublas-dev libcurand libcurand-dev libcusolver          libcusolver-dev libcusparse libcusparse-dev libnvjitlink

rapids-mamba-retry install \
  --channel "${CPP_CHANNEL}" \
  --channel "${LIBRMM_CHANNEL}" \
  --channel "${LIBRAFT_CHANNEL}" \
  libcuml libcuml-tests

conda list

rapids-logger "Check GPU usage"
nvidia-smi

EXITCODE=0
trap "EXITCODE=1" ERR
set +e

# Run libcuml gtests from libcuml-tests package
rapids-logger "Run gtests"
for gt in "$CONDA_PREFIX"/bin/gtests/libcuml/* ; do
    test_name=$(basename ${gt})
    echo "Running gtest $test_name"
    ${gt} --gtest_output=xml:${RAPIDS_TESTS_DIR}
done

rapids-logger "Test script exiting with value: $EXITCODE"
exit ${EXITCODE}
