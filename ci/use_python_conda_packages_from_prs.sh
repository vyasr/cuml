#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0

# Temporary: download Python conda artifacts from open PRs
# that add symbol visibility controls.
#
# - rapidsai/raft#3019: restrict RAFT_EXPORT to core/ and raft_runtime/
# - rapidsai/cuvs#2101: add symbol visibility controls to cuvs
#
# Remove this file and all `source ./ci/use_python_conda_packages_from_prs.sh` calls
# once those PRs are merged and the nightly picks them up.

# Python packages (pylibraft, raft-dask, cuvs)
PYRAFT_CHANNEL=$(rapids-get-pr-artifact raft 3019 python conda --stable)
PYCUVS_CHANNEL=$(rapids-get-pr-artifact cuvs 2101 python conda --stable)

# Ensure arrays exist for set -u shells
RAPIDS_PREPENDED_CONDA_CHANNELS=("${RAPIDS_PREPENDED_CONDA_CHANNELS[@]:-}")
PR_CONDA_PREPEND_CHANNEL_ARGS=("${PR_CONDA_PREPEND_CHANNEL_ARGS[@]:-}")

# For rattler builds: prepend to RAPIDS_PREPENDED_CONDA_CHANNELS so that
# rapids-rattler-channel-string picks them up with strict channel priority.
RAPIDS_PREPENDED_CONDA_CHANNELS+=(
    "${PYRAFT_CHANNEL}"
    "${PYCUVS_CHANNEL}"
)
export RAPIDS_PREPENDED_CONDA_CHANNELS

# For rapids-dependency-file-generator: build an array of --prepend-channel
# args so test/docs scripts can inject them before rapidsai-nightly.
# shellcheck disable=SC2034  # used by scripts that source this file
PR_CONDA_PREPEND_CHANNEL_ARGS+=(
    --prepend-channel "${PYRAFT_CHANNEL}"
    --prepend-channel "${PYCUVS_CHANNEL}"
)

# For mamba/conda installs: also prepend to the system-wide channel list
# as a fallback for scripts that don't use rapids-dependency-file-generator.
for _channel in "${PYRAFT_CHANNEL}" "${PYCUVS_CHANNEL}"; do
    conda config --system --add channels "${_channel}"
done
