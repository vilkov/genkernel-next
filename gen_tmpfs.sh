#!/bin/bash
# $Id$

gen_setup_tmpfs() {
    print_info 1 "Setting up TMPFS file system at ${KERNEL_DIR}/RAM"

    if [ "${KERNEL_OUTPUTDIR}" == "${KERNEL_DIR}" ]; then
        RAM_KERNEL_DIR=${KERNEL_DIR}/RAM

        if mount | grep -q "$(readlink -f "${RAM_KERNEL_DIR}")"; then
            umount "${RAM_KERNEL_DIR}" || gen_die 'Could not unmount previously mounted TMPFS file system!'
        fi
    
        rm -rf "${RAM_KERNEL_DIR}" > /dev/null 2>&1
        mkdir "${RAM_KERNEL_DIR}" || gen_die 'Could not make a directory to mount TMPFS file system!'
        mount -t tmpfs tmpfs "${RAM_KERNEL_DIR}" > /dev/null 2>&1 || gen_die 'Could not mount TMPFS file system!'
    
        for i in $(ls -A "${KERNEL_DIR}"); do
            if [ "${i}" != "RAM" -a "${i}" != "source" ]; then
                cp -Rs "${KERNEL_DIR}/${i}" "${RAM_KERNEL_DIR}/${i}" > /dev/null 2>&1 || { umount "${RAM_KERNEL_DIR}" && gen_die 'Could not sync with TMPFS file system!'; }
            fi
        done
        
        ORIG_KERNEL_DIR="${KERNEL_DIR}"
        KERNEL_DIR="${RAM_KERNEL_DIR}"
        KERNEL_OUTPUTDIR="${RAM_KERNEL_DIR}"
    else
        print_info 1 "Command line option --kernel-outputdir have been used. TMPFS file system won't be used to build kernel"
    fi
}

gen_cleanup_tmpfs() {
    if [ "${RAM_KERNEL_DIR}" == "${ORIG_KERNEL_DIR}/RAM" ]; then
        cd "${ORIG_KERNEL_DIR}"
        rsync --checksum --recursive --links --safe-links \
            --exclude='*.o' \
            --exclude='*.cmd' \
            --exclude='*.builtin' \
            --exclude='*.order' \
            --exclude='*.mod' \
        "${RAM_KERNEL_DIR}/" "${ORIG_KERNEL_DIR}/" > /dev/null 2>&1 || { umount "${RAM_KERNEL_DIR}" && gen_die 'Could not sync with TMPFS file system!'; }
        umount "${RAM_KERNEL_DIR}" > /dev/null 2>&1 || gen_die 'Could not unmount TMPFS file system!'
        rm -rf "${RAM_KERNEL_DIR}" > /dev/null 2>&1

        if [ -d "${INSTALL_MOD_PATH}/lib/modules/${KV}" ]; then
            ln -sf "$(readlink -f "${ORIG_KERNEL_DIR}")" "${INSTALL_MOD_PATH}/lib/modules/${KV}/build" || gen_die 'Could not fix path to kernel build directory!'
            ln -sf "$(readlink -f "${ORIG_KERNEL_DIR}")" "${INSTALL_MOD_PATH}/lib/modules/${KV}/source" || gen_die 'Could not fix path to kernel source directory!'
        fi
    fi
}
