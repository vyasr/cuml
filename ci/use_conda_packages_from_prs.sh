#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0

# Temporary: download libraft and libcuvs conda artifacts from open PRs
# that add symbol visibility controls.
#
# - rapidsai/raft#3019: restrict RAFT_EXPORT to core/ and raft_runtime/
# - rapidsai/cuvs#2101: add symbol visibility controls to cuvs
#
# Remove this file and all `source ./ci/use_conda_packages_from_prs.sh` calls
# once those PRs are merged and the nightly picks them up.

LIBRAFT_CHANNEL=$(rapids-get-pr-artifact raft 3019 cpp conda)
LIBCUVS_CHANNEL=$(rapids-get-pr-artifact cuvs 2101 cpp conda)

# For rattler builds: prepend to RAPIDS_PREPENDED_CONDA_CHANNELS so that
# rapids-rattler-channel-string picks them up with strict channel priority.
RAPIDS_PREPENDED_CONDA_CHANNELS=(
    "${LIBRAFT_CHANNEL}"
    "${LIBCUVS_CHANNEL}"
)
export RAPIDS_PREPENDED_CONDA_CHANNELS

# For mamba/conda installs: prepend to the system-wide channel list.
for _channel in "${RAPIDS_PREPENDED_CONDA_CHANNELS[@]}"; do
    conda config --system --add channels "${_channel}"
done
