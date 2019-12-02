#!/bin/bash
source /usr/local/ece361-lib

if [[ $# -ne 1 ]]; then
    EXERCISE_CMD=$(basename $0) # Works w/ symbolic links
    bold_red "ERROR: Expecting exactly one parameter (the lab #)"
    bold_blue "Usage format:"
    blue "\t${EXERCISE_CMD} <lab #>"
    exit 1
else
    LAB_NUM=$1
fi

# Sanity check of lab number
checkLabNum ${LAB_NUM}
if [[ $? -ne 0 ]]; then
    exit 1
fi

# Open SSH connection
sshEECGOpenSess
if [[ $? -ne 0 ]]; then
    exit 1
fi

MOUNT_DIR=/usr/local/tester
sudo mkdir -p ${MOUNT_DIR}

# Mount (unmount first, just to be safe...)
# TODO: REMOTE PATH TO MOUNT NEEDS TO BE CHANGED TO REFLECT PATH PROVIDED BY EECG
sudo fusermount -q -u ${MOUNT_DIR}
sudo sshfs -o allow_other,reconnect ${SSHFLAGS} ${UTORID}@${EECG_HOST}:/guest/l/linthom1/ece361/2020s/ece361-automark ${MOUNT_DIR}

# Run exerciser. If files are missing, will prompt student if they want to continue.
# Possible return statuses from exerciser:
#   - 0: All good
#   - 1: Files were missing, bail out
#   - 10: Files were missing, ignore and continue
bold_blue "Running exerciser..."
${MOUNT_DIR}/run-public-tests.sh ${LAB_NUM}
RET=$?
if [[ $RET -eq 0 || $RET -eq 10 ]]; then
    if [[ $RET -eq 10 ]]; then
        # Export IGNORE_MISSING_FILES to be used in submit script
        export IGNORE_MISSING_FILES=yes
    fi

    # Run submit
    # Export SSH-related env vars so child processes can re-use them
    #   - ece361submit may call remote-submit which requires SSH
    echo
    bold_blue "Running submission..."
    export CTRL_PATH SSHFLAGS UTORID EECG_HOST
    ${MOUNT_DIR}/ece361submit.sh ${LAB_NUM}
elif [[ $RET -eq 1 ]]; then
    bold_blue "Not ignoring missing files, skipping submit..."
fi

# Unmount
sudo fusermount -q -u ${MOUNT_DIR}

# Clean-up SSH control master
sshEECGCloseSess

