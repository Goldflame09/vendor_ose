#!/bin/bash

usage()
{
    echo -e ""
    echo -e ${txtbld}"Usage:"${txtrst}
    echo -e "  build-ose.sh [options] device"
    echo -e ""
    echo -e ${txtbld}"  Options:"${txtrst}
    echo -e "    -a  Builds official OSE:"
    echo -e "    -b  Compiles Non-Block zip:"
    echo -e "    -c# Cleaning options:"
    echo -e "        1 - make clean"
    echo -e "        2 - make dirty"
    echo -e "        3 - make magicbrownies"
    echo -e "    -d  Uses dex optimizations"
    echo -e "    -e  Uses OSE optimizations"
    echo -e "    -f  Builds with prebuilt chromium"
    echo -e "    -j# Sets jobs"
    echo -e "    -o# Selects GCC O Level"
    echo -e "        Valid O Levels are"
    echo -e "        1 (Os) or 3 (O3)"
    echo -e "    -p  Builds using pipe"
    echo -e "    -r  Resets source tree before build"
    echo -e "    -s  Syncs before build"
    echo -e "    -v  Verbose build output"
    echo -e ""
    echo -e ${txtbld}"  Example:"${txtrst}
    echo -e "    ./build-ose.sh -c moto_msm8960dt"
    echo -e ""
    exit 1
}

# Colors
. ./vendor/ose/tools/colors

if [ ! -d ".repo" ]; then
    echo -e ${red}"No .repo directory found.  Is this an Android build tree?"${txtrst}
    exit 1
fi
if [ ! -d "vendor/ose" ]; then
    echo -e ${red}"No vendor/ose directory found.  Is this an OSE build tree?"${txtrst}
    exit 1
fi

# Find the output directories
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
thisDIR="${PWD##*/}"

findOUT() {
if [ -n "${OUT_DIR_COMMON_BASE+x}" ]; then
return 1; else
return 0
fi;}

findOUT
RES="$?"

if [ $RES = 1 ];then
    export OUTDIR=$OUT_DIR_COMMON_BASE/$thisDIR
elif [ $RES = 0 ];then
    export OUTDIR=$DIR/out
fi

# Get OS (Linux / Mac OS X)
IS_DARWIN=$(uname -a | grep Darwin)
if [ -n "$IS_DARWIN" ]; then
    CPUS=$(sysctl hw.ncpu | awk '{print $2}')
    DATE=gdate
else
    CPUS=$(grep "^processor" /proc/cpuinfo | wc -l)
    DATE=date
fi

# USE_CCACHE
export USE_CCACHE=1

opt_auth=0
opt_block=0
opt_clean=0
opt_dex=0
opt_ose=0
opt_chromium=0
opt_jobs="$CPUS"
opt_olvl=0
opt_pipe=0
opt_reset=0
opt_sync=0
opt_verbose=0

while getopts "abc:defj:o:prsv" opt; do
    case "$opt" in
    a) opt_auth=1 ;;
    b) opt_block=1 ;;
    c) opt_clean="$OPTARG" ;;
    d) opt_dex=1 ;;
    e) opt_ose=1 ;;
    f) opt_chromium=1 ;;
    j) opt_jobs="$OPTARG" ;;
    o) opt_olvl="$OPTARG" ;;
    p) opt_pipe=1 ;;
    r) opt_reset=1 ;;
    s) opt_sync=1 ;;
    v) opt_verbose=1 ;;
    *) usage
    esac
done
shift $((OPTIND-1))
if [ "$#" -ne 1 ]; then
    usage
fi
device="$1"

if [ "$opt_clean" -eq 1 ]; then
    make clean >/dev/null
    echo -e ""
    echo -e ${bldylw}"Out Is Clean"${txtrst}
    echo -e ""
elif [ "$opt_clean" -eq 2 ]; then
    make dirty >/dev/null
    echo -e ""
    echo -e ${bldylw}"Out Is Dirty"${txtrst}
    echo -e ""
elif [ "$opt_clean" -eq 3 ]; then
    make magicbrownies >/dev/null
    echo -e ""
    echo -e ${bldylw}"Enjoy Your Magical Adventure"${txtrst}
    echo -e ""
fi

# Reset source tree
if [ "$opt_reset" -ne 0 ]; then
    echo -e ""
    echo -e ${bldbylw}"Resetting Source Tree And Removing All Uncommitted Changes"${txtrst}
    repo forall -c "git reset --hard HEAD; git clean -qf"
    echo -e ""
fi

# Sync with latest sources
if [ "$opt_sync" -ne 0 ]; then
    echo -e ""
    echo -e ${bldylw}"Fetching Latest Sources"${txtrst}
    repo sync -j"$opt_jobs"
    echo -e ""
fi

echo -e ""
echo -e "********************************************"

# Build OSE Official
if [ "$opt_auth" -ne 0 ]; then
    echo -e ${cya}"Building ${bldppl}Official OSE"${txtrst}
    echo -e ""
    export OSE_BUILD_TYPE=OFFICIAL
else
    echo -e ""
    echo -e ${bldylw}"Building: ${bldred}Unofficial OSE"${txtrst}
    echo -e ""
fi

# Build Non-Block zip
if [ "$opt_block" -ne 0 ]; then
    echo -e ${bldylw}"Non-Block Build"${txtrst}
    export BLOCK_BASED_OTA=false
else
    echo -e ${bldylw}"Block Build"${txtrst}
fi

# Display pipe
if [ "$opt_pipe" -ne 0 ]; then
    echo -e ${bldylw}"Using Pipe"${txtrst}
fi

# Use prebuilt chromium
if [ "$opt_chromium" -ne 0 ]; then
    echo -e ${bldylw}"Using Prebuilt Chromium"${txtrst}
    export USE_PREBUILT_CHROMIUM=1
    echo -e ""
fi

# Display dex optimizations
if [ "$opt_dex" -ne 0 ]; then
    echo -e ${bldgrn}"Using Dex Optimization"${txtrst}
fi

# Display OSE optimizations
if [ "$opt_ose" -ne 0 ]; then
    echo -e ${bldgrn}"Using OSE Optimization"${txtrst}
fi

# Display optimizations
if [ "$opt_olvl" -eq 1 ]; then
    echo -e ${bldgrn}"Using Os Optimization"${txtrst}
elif [ "$opt_olvl" -eq 3 ]; then
    echo -e ${bldgrn}"Using O3 Optimization"${txtrst}
else
    echo -e ${bldylw}"Using Default GCC Optimization"${txtrst}
fi

echo -e "********************************************"
echo -e ""

rm -f $OUTDIR/target/product/$device/obj/KERNEL_OBJ/.version

# Get time of startup
t1=$($DATE +%s)

# Setup environment
echo -e ${bldblu}"Setting Up Environment"${txtrst}
. build/envsetup.sh

# Remove system folder (this will create a new build.prop with updated build time and date)
rm -f $OUTDIR/target/product/$device/system/build.prop
rm -f $OUTDIR/target/product/$device/system/app/*.odex
rm -f $OUTDIR/target/product/$device/system/framework/*.odex

# Lunch device
echo -e ""
echo -e ${bldblu}"Lunching Device"${txtrst}
lunch "ose_$device-userdebug";

# Start compilation
echo -e ""
echo -e ${bldblu}"Starting Compilation"${txtrst}

# Use dex optimizations
if [ "$opt_dex" -ne 0 ]; then
    export WITH_DEXPREOPT=true
fi

# Use OSE optimizations
if [ "$opt_ose" -ne 0 ]; then
    export OSE_OPTIMIZE=true
fi

# Build Optimizations
if [ "$opt_olvl" -eq 1 ]; then
    export TARGET_USE_O_LEVEL_S=true
elif [ "$opt_olvl" -eq 3 ]; then
    export TARGET_USE_O_LEVEL_3=true
fi

# Use pipe
if [ "$opt_pipe" -ne 0 ]; then
    export TARGET_USE_PIPE=true
fi

# Verbose Build
if [ "$opt_verbose" -ne 0 ]; then
make -j"$opt_jobs" showcommands bacon
else
make -j"$opt_jobs" bacon
fi
echo -e ""

# Cleanup unused built
rm -f $OUTDIR/target/product/$device/ose_*-ota*.zip