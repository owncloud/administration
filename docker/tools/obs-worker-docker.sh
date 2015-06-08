#! /bin/bash
#
# run an obs-worker in a simple docker container.
# (C) 2015 jw@owncloud.com
#
# Distribute under GPL-2.0 or ask.

obs_server=$1
test -z "$obs_server" && obs_server="s2.int.owncloud.com"

OBS_SRC_SERVER="$OBS_SERVER:5352"
OBS_REPO_SERVERS="$OBS_SERVER:5252"

SUSE_BASE_IMAGE="opensuse:13.2"
PACKAGES="aaa_base curl perl-XML-Parser vim-base less"

IMAGE_NAME=obs-worker-opensuse

self=$(basename $0)
dir=$(dirname $0)
case $dir in
  /*) ;;
  *) dir=$(pwd)/$dir ;;
esac

port=$(echo ${RANDOM}000 | sed -s 's@\(...\).*@22\1@')

if [ ! -d /docker ]; then
  echo preparing docker container ...
  echo -e "FROM $SUSE_BASE_IMAGE\nRUN zypper in -y $PACKAGES" | docker build -t $IMAGE_NAME -

  echo entering docker container ...
  ## must run without NAT here.
  set -x
  docker run -ti -p $port:$port -v $dir/$self:/docker/$self -e OBS_SERVER=$obs_server -e OBS_WORKER_PORT=$port obs-worker-opensuse sh /docker/$self
  echo ... exiting docker container.
  exit 0
fi

echo obs-worker port: $OBS_WORKER_PORT
echo obs src server:  $OBS_SRC_SERVER

cat <<EOF >> /etc/sysconfig/obs-server
#
# NOTE: all these options can be also declared in /etc/buildhost.config on each worker differently.
#

## Path:        Applications/OBS
## Description: The OBS backend code directory
## Type:        string
## Default:     ""
## Config:      OBS
#
# An empty dir will lead to the fall back directory, typically /usr/lib/obs/server/
#
OBS_BACKENDCODE_DIR=""

## Path:        Applications/OBS
## Description: The base for OBS communication directory
## Type:        string
## Default:     ""
## Config:      OBS
#
# An empty dir will lead to the fall back directory, typically /srv/obs/run
#
OBS_RUN_DIR=""

## Path:        Applications/OBS
## Description: The base for OBS logging directory
## Type:        string
## Default:     ""
## Config:      OBS
#
# An empty dir will lead to the fall back directory, typically /srv/obs/log
#
OBS_LOG_DIR=""

## Path:        Applications/OBS
## Description: The base directory for OBS
## Type:        string
## Default:     ""
## Config:      OBS
#
# An empty dir will lead to the fall back directory, typically /srv/obs
#
OBS_BASE_DIR=""

## Path:        Applications/OBS
## Description: Automatically setup api and webui for OBS server, be warned, this will replace config files !
## Type:        ("yes" | "no")
## Default:     "no"
## Config:      OBS
#
# This is usally only enabled on the OBS Appliance
#
OBS_API_AUTOSETUP="no"
#
# NOTE: all these options can be also declared in /etc/buildhost.config on each worker differently.
#

## Path:        Applications/OBS
## Description: define source server host to be used
## Type:        string
## Default:     ""
## Config:      OBS
#
# An empty setting will point to localhost:5352 by default
#
OBS_SRC_SERVER="$OBS_SRC_SERVER"

## Path:        Applications/OBS
## Description: define repository server host to be used
## Type:        string
## Default:     ""
## Config:      OBS
#
# An empty setting will point to localhost:5252 by default
#
OBS_REPO_SERVERS="$OBS_REPO_SERVERS"

## Path:        Applications/OBS
## Description: define number of build instances
## Type:        integer
## Default:     0
## Config:      OBS
#
# 0 instances will automatically use the number of CPU's
#
OBS_WORKER_INSTANCES="1"

## Path:        Applications/OBS
## Description: define names of build instances for z/VM
## Type:        string
## Default:     ""
## Config:      OBS
#
# The names of the workers as defined in z/VM. These must have two minidisks
# assigned, and have a secondary console configured to the local machine: 
# 0150 is the root device
# 0250 is the swap device
#
#OBS_WORKER_INSTANCE_NAMES="LINUX075 LINUX076 LINUX077"
OBS_WORKER_INSTANCE_NAMES=""

## Path:        Applications/OBS
## Description: The base directory, where sub directories for each worker will get created
## Type:        string
## Default:     ""
## Config:      OBS
#
#
OBS_WORKER_DIRECTORY="/space/obs-worker"

## Path:        Applications/OBS
## Description: The base for port numbers used by worker instances
## Type:        integer
## Default:     "0"
## Config:      OBS
#
# 0 means let the operating system assign a port number
#
OBS_WORKER_PORTBASE="$OBS_WORKER_PORT"

## Path:        Applications/OBS
## Description: Number of parallel compile jobs per worker
## Type:        integer
## Default:     "1"
## Config:      OBS
#
# this maps usually to "make -j1" during build
#
OBS_WORKER_JOBS="1"

## Path:        Applications/OBS
## Description: Run in test mode (build results will be ignore, no job blocking)
## Type:        ("yes" | "")
## Default:     ""
## Config:      OBS
#
OBS_WORKER_TEST_MODE=""

## Path:        Applications/OBS
## Description: define one or more labels for the build host.
## Type:        string
## Default:     ""
## Config:      OBS
#
# A label can be used to build specific packages only on dedicated hosts.
# For example for benchmarking.
#
OBS_WORKER_HOSTLABELS=""

## Path:        Applications/OBS
## Description: Register in SLP server
## Type:        ("yes" | "no")
## Default:     "yes"
## Config:      OBS
#
#
OBS_USE_SLP="no"

## Path:        Applications/OBS
## Description: Use a common cache directory for downloaded packages
## Type:        string
## Default:     ""
## Config:      OBS
#
# Enable caching requires a given directory here. Be warned, content will be
# removed there !
# 
OBS_CACHE_DIR="/space/obs-worker-cache"

## Path:        Applications/OBS
## Description: Defines the package cache size
## Type:        size in MB
## Default:     ""
## Config:      OBS
#
# Set the size to 50% of the maximum usable size of this partition
#
OBS_CACHE_SIZE="2000"

## Path:        Applications/OBS
## Description: Defines the nice level of running workers
## Type:        integer
## Default:     18
## Config:      OBS
# 
# Nicenesses range from -20 (most favorable  scheduling) to 19 (least
# favorable).
# Default to 18 as some testsuites depend on being able to switch to
# one priority below (19) _and_ having changed the numeric level
# (so going from 19->19 makes them fail).
#
OBS_WORKER_NICE_LEVEL=18

## Path:        Applications/OBS
## Description: Set used VM type by worker
## Type:        ("auto" | "xen" | "kvm" | "lxc" | "zvm" | "emulator:$arch" | "emulator:$arch:$script" | "none")
## Default:     "auto"
## Config:      OBS
#
#
OBS_VM_TYPE="none"

## Path:        Applications/OBS
## Description: Set kernel used by worker (kvm)
## Type:        ("none" | "/boot/vmlinuz" | "/foo/bar/vmlinuz)
## Default:     "none"
## Config:      OBS
#
# For z/VM this is normally /boot/image
#
OBS_VM_KERNEL="none"

## Path:        Applications/OBS
## Description: Set initrd used by worker (kvm)
## Type:        ("none" | "/boot/initrd" | "/foo/bar/initrd-foo)
## Default:     "none"
## Config:      OBS
#
# for KVM, you have to create with (example for openSUSE 11.2):
#
# export rootfstype="ext4"
# mkinitrd -d /dev/null -m "ext4 binfmt_misc virtio_pci virtio_blk" -k vmlinuz-2.6.31.12-0.2-default -i initrd-2.6.31.12-0.2-default-obs_worker
#
# a working initrd file which includes virtio and binfmt_misc for OBS in order to work fine
#
# for z/VM, the build script will create a initrd at the given location if
# it does not yet exist.
# 
OBS_VM_INITRD="none"

## Path:        Applications/OBS
## Description: Autosetup for XEN/KVM/TMPFS disk (root) - Filesize in MB
## Type:        integer
## Default:     "4096"
## Config:      OBS
#
#
OBS_VM_DISK_AUTOSETUP_ROOT_FILESIZE="4096"

## Path:        Applications/OBS
## Description: Autosetup for XEN/KVM disk (swap) - Filesize in MB
## Type:        integer
## Default:     "1024"
## Config:      OBS
#
#
OBS_VM_DISK_AUTOSETUP_SWAP_FILESIZE="1024"

## Path:        Applications/OBS
## Description: Filesystem to use for autosetup {none,ext4}=ext4, ext3=ext3
## Type:        string
## Default:     "ext3"
## Config:      OBS
#
#
OBS_VM_DISK_AUTOSETUP_FILESYSTEM="ext3"

## Path:        Applications/OBS
## Description: Filesystem mount options to use for autosetup
## Type:        string
## Default:     ""
## Config:      OBS
#
#
OBS_VM_DISK_AUTOSETUP_MOUNT_OPTIONS=""

## Path:        Applications/OBS
## Description: Enable build in memory
## Type:        ("yes" | "")
## Default:     ""
## Config:      OBS
#
# WARNING: this requires much memory!
#
OBS_VM_USE_TMPFS=""

## Path:        Applications/OBS
## Description: Memory allocated for each VM (512) if not set
## Type:        integer
## Default:     ""
## Config:      OBS
#
#
OBS_INSTANCE_MEMORY=""

## Path:        Applications/OBS
## Description: Enable storage auto configuration
## Type:        ("yes" | "")
## Default:     ""
## Config:      OBS
#
# WARNING: this may destroy data on your hard disk !
# This is usually only used on mass deployed worker instances
#
OBS_STORAGE_AUTOSETUP=""

## Path:        Applications/OBS
## Description: Setup LVM via obsstoragesetup
## Type:        ("take_all" | "use_obs_vg" | "none")
## Default:     "use_obs_vg"
## Config:      OBS
#
# take_all: WARNING: all LVM partitions will be used and all data erased !
# use_obs_vg:  A lvm volume group named "OBS" will be re-setup for the workers.
#
OBS_SETUP_WORKER_PARTITIONS="use_obs_vg"

## Path:        Applications/OBS
## Description: Size in MB when creating LVM partition for cache partition
## Type:        integer
## Default:     ""
## Config:      OBS
#
#
OBS_WORKER_CACHE_SIZE=""

## Path:        Applications/OBS
## Description: Size in MB when creating LVM partition for each worker root partition
## Type:        integer
## Default:     ""
## Config:      OBS
#
#
OBS_WORKER_ROOT_SIZE=""

## Path:        Applications/OBS
## Description: Size in MB when creating LVM partition for each worker swap partition
## Type:        integer
## Default:     ""
## Config:      OBS
#
#
OBS_WORKER_SWAP_SIZE=""

## Path:        Applications/OBS
## Description: URL to a ssh pub key to allow root user login
## Type:        string
## Default:     ""
## Config:      OBS
#
# This is usually used on mass (PXE) deployed workers)
#
OBS_ROOT_SSHD_KEY_URL=""

## Path:        Applications/OBS
## Description: URL to a script to be downloaded and executed
## Type:        string
## Default:     ""
## Config:      OBS
#
# This is a hook for doing special things in your setup at boot time
#
OBS_WORKER_SCRIPT_URL=""
EOF

if test -e /etc/sysconfig/proxy; then
  . /etc/sysconfig/proxy
  export http_proxy="$HTTP_PROXY"
  export HTTPS_PROXY
  export NO_PROXY
fi
if test -e /etc/sysconfig/obs-server; then
  # optional on workers
  . /etc/sysconfig/obs-server
fi

if [ -z "$OBS_WORKER_DIRECTORY" ]; then
    OBS_WORKER_DIRECTORY="/var/cache/obs/worker"
fi

mkdir -p "$OBS_WORKER_DIRECTORY"

if [ -z "$OBS_RUN_DIR" ]; then
    OBS_RUN_DIR="/var/run/obs"
fi
if [ -z "$OBS_LOG_DIR" ]; then
    OBS_LOG_DIR="/var/log/obs"
fi
if [ -z "$OBS_REPO_SERVERS" ]; then
    OBS_REPO_SERVERS="localhost:5252"
fi

if [ -n "$OBS_WORKER_TEST_MODE" ]; then
    OBS_TEST="--test"
fi
if [ -n "$OBS_WORKER_JOBS" ]; then
    OBS_JOBS="--jobs $OBS_WORKER_JOBS"
fi
if [ -n "$OBS_WORKER_THREADS" ]; then
    OBS_THREADS="--threads $OBS_WORKER_THREADS"
fi
if [ -n "$OBS_WORKER_NICE_LEVEL" ]; then
    OBS_NICE=$OBS_WORKER_NICE_LEVEL
else
    OBS_NICE=18
fi

REPO_PARAM=
for i in $OBS_REPO_SERVERS; do
    REPO_PARAM="$REPO_PARAM --reposerver http://$i"
    WORKER_CODE="http://$i"
done

obsrundir="$OBS_RUN_DIR"
workerdir="$obsrundir"/worker
workerbootdir="$workerdir"/boot
OBS_WORKER_OPT=""

if [ -n "$OBS_CACHE_SIZE" -a -n "$OBS_CACHE_DIR" ]; then
    OBS_WORKER_OPT="--cachedir $OBS_CACHE_DIR"
    mkdir -p $OBS_CACHE_DIR
    OBS_WORKER_OPT="$OBS_WORKER_OPT --cachesize $OBS_CACHE_SIZE"
fi

if [ -n "$OBS_WORKER_LOCALKIWI_DIRECTORY" ]; then
    OBS_WORKER_OPT="$OBS_WORKER_OPT --localkiwi $OBS_WORKER_LOCALKIWI_DIRECTORY --arch local"
fi

[ -z "$OBS_INSTANCE_MEMORY" ] && OBS_INSTANCE_MEMORY=512

# fetch worker sources from server
echo "Fetching initial worker code from $WORKER_CODE"
mkdir -p "$workerbootdir"
pushd "$workerbootdir" > /dev/null
I=0
while ! curl -s "$WORKER_CODE"/getworkercode | cpio --quiet --extract ; do
  # we need to wait for rep server maybe
  I=$(( $I + 1 ))
  if test "3" -lt "$I"; then
    echo "ERROR: Unable to reach rep server $WORKER_CODE!"
    exit 1
  fi
  sleep 10
done
ln -s . XML 
chmod 755 bs_worker

I=0

R=$OBS_WORKER_DIRECTORY/root_$I
mkdir -p $workerdir/$I

set -x
./bs_worker --port $OBS_WORKER_PORT --root $R --statedir $workerdir/$I $REPO_PARAM &
ps -efww
bash
