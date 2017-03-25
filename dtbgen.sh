#!/bin/bash
# simple bash script for generating dtb image

# root directory of universal7420 kernel git repo (default is this script's location)
RDIR=$HOME/Nougat-Kernel

# directory containing cross-compile arm64 toolchain
TOOLCHAIN=$HOME/toolchains/googlegcc4.9

# device dependant variables
PAGE_SIZE=2048
DTB_PADDING=0

export ARCH=arm64
export CROSS_COMPILE=$TOOLCHAIN/bin/aarch64-linux-android-

BDIR=$RDIR
OUTDIR=$BDIR/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts
DTBDIR=$OUTDIR/dtb
DTCTOOL=$BDIR/scripts/dtc/dtc
INCDIR=$RDIR/include

ABORT()
{
	[ "$1" ] && echo "Error: $*"
	exit 1
}

cd "$RDIR" || ABORT "Failed to enter $RDIR!"
	
[ -x "$DTCTOOL" ] ||
ABORT "You need to run ./build.sh first!"

[ -x "${CROSS_COMPILE}gcc" ] ||
ABORT "Unable to find gcc cross-compiler at location: ${CROSS_COMPILE}gcc"

[ "$1" ] && DEVICE=$1
[ "$2" ] && VARIANT=$2
[ "$DEVICE" ] || DEVICE=zenlte
[ "$VARIANT" ] || VARIANT=usa

case $DEVICE in
noblelte)
	case $VARIANT in
	xx|eur|duos)
		DTSFILES="exynos7420-noblelte_eur_open_09"
		;;
	zt|chn)
		DTSFILES="exynos7420-noblelte_chn_09"
		;;
	chnmdm|mdm)
		DTSFILES="exynos7420-noblelte_chn_mdm_09"
		;;
	jpn)
		DTSFILES="exynos7420-noblelte_jpn_09"
		;;
	kor|ktt|skt|lgt)
		DTSFILES="exynos7420-noblelte_kor_09"
		;;
	usa|tmo|can|att)
		DTSFILES="exynos7420-noblelte_usa_09"
		;;
	cdma|spr|usc|vzw)
		DTSFILES="exynos7420-noblelte_usa_cdma_09"
		;;
	sea|xtc)
		DTSFILES="exynos7420-noblelte_sea_xtc_09"
		;;
	*) ABORT "Unknown variant of $DEVICE: $VARIANT" ;;
	esac
	DTBH_PLATFORM_CODE=0x50a6
	DTBH_SUBTYPE_CODE=0x217584da
	;;
zenlte)
	case $VARIANT in
	eur|duos)
		DTSFILES="exynos7420-zenlte_eur_open_09"
		;;
	zt|chn)
		DTSFILES="exynos7420-zenlte_chn_09"
		;;
	chnmdm|mdm)
		DTSFILES="exynos7420-zenlte_chn_mdm_09"
		;;
	jpn)
		DTSFILES="exynos7420-zenlte_jpn_03"
		;;
	kor|ktt|skt|lgt)
		DTSFILES="exynos7420-zenlte_kor_09"
		;;
	usa|tmo|can|att)
		DTSFILES="exynos7420-zenlte_usa_09"
		;;
	cdma|spr|usc|vzw)
		DTSFILES="exynos7420-zenlte_usa_cdma_09"
		;;
	*) ABORT "Unknown variant of $DEVICE: $VARIANT" ;;
	esac
	DTBH_PLATFORM_CODE=0x50a6
	DTBH_SUBTYPE_CODE=0x217584da
	;;
zerolte)
	case $VARIANT in
	eur|duos)
		DTSFILES="exynos7420-zerolte_eur_open_08"
		;;
	zt|chn)
		DTSFILES="exynos7420-zerolte_chn_02"
		;;
	jpn)
		DTSFILES="exynos7420-zerolte_jpn_06"
		;;
	kor|ktt|skt|lgt)
		DTSFILES="exynos7420-zerolte_kor_07"
		;;
	usa|tmo|can|att)
		DTSFILES="exynos7420-zerolte_usa_07"
		;;
	cdma|spr|usc|vzw)
		DTSFILES="exynos7420-zerolte_usa_cdma_05"
		;;
	*) ABORT "Unknown variant of $DEVICE: $VARIANT" ;;
	esac
	DTBH_PLATFORM_CODE=0x50a6
	DTBH_SUBTYPE_CODE=0x217584da
	;;
zeroflte)
	case $VARIANT in
	eur|duos)
		DTSFILES="exynos7420-zeroflte_eur_open_07"
		;;
	zt|chn)
		DTSFILES="exynos7420-zeroflte_chn_04"
		;;
	jpn)
		DTSFILES="exynos7420-zeroflte_jpn_04"
		;;
	kor|ktt|skt|lgt)
		DTSFILES="exynos7420-zeroflte_kor_07"
		;;
	usa|tmo|can|att)
		DTSFILES="exynos7420-zeroflte_usa_05"
		;;
	cdma|spr|usc|vzw)
		DTSFILES="exynos7420-zeroflte_usa_cdma_03"
		;;
	*) ABORT "Unknown variant of $DEVICE: $VARIANT" ;;
	esac
	DTBH_PLATFORM_CODE=0x50a6
	DTBH_SUBTYPE_CODE=0x217584da
	;;
*) ABORT "Unknown device: $DEVICE" ;;
esac

mkdir -p "$OUTDIR" "$DTBDIR"

rm -f "$DTBDIR/"*

echo "Processing dts files..."

for dts in $DTSFILES; do
	echo "=> Processing: ${dts}.dts"
	"${CROSS_COMPILE}cpp" -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/${dts}.dts" > "$DTBDIR/${dts}.dts"
	echo "=> Generating: ${dts}.dtb"
	$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "$DTBDIR/${dts}.dtb" "$DTBDIR/${dts}.dts"
done

echo "Generating dtb.img..."
scripts/dtbTool/dtbTool -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE --platform $DTBH_PLATFORM_CODE --subtype $DTBH_SUBTYPE_CODE || ABORT

echo "Done."
