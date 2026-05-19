#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0

# Temporary: download libraft and libcuvs wheel artifacts from open PRs
# that add symbol visibility controls.
#
# - rapidsai/raft#3019: restrict RAFT_EXPORT to core/ and raft_runtime/
# - rapidsai/cuvs#2101: add symbol visibility controls to cuvs
#
# Remove this file and all `source ./ci/use_wheels_from_prs.sh` calls
# once those PRs are merged and the nightly picks them up.

source rapids-init-pip

RAPIDS_PY_CUDA_SUFFIX=$(rapids-wheel-ctk-name-gen "${RAPIDS_CUDA_VERSION}")

LIBRAFT_WHEELHOUSE=$(
    RAPIDS_PY_WHEEL_NAME="libraft_${RAPIDS_PY_CUDA_SUFFIX}" rapids-get-pr-artifact raft 3019 cpp wheel
)

LIBCUVS_WHEELHOUSE=$(
    RAPIDS_PY_WHEEL_NAME="libcuvs_${RAPIDS_PY_CUDA_SUFFIX}" rapids-get-pr-artifact cuvs 2101 cpp wheel
)

cat >> "${PIP_CONSTRAINT}" <<EOF
libraft-${RAPIDS_PY_CUDA_SUFFIX} @ file://$(echo "${LIBRAFT_WHEELHOUSE}"/libraft_*.whl)
libcuvs-${RAPIDS_PY_CUDA_SUFFIX} @ file://$(echo "${LIBCUVS_WHEELHOUSE}"/libcuvs_*.whl)
EOF
