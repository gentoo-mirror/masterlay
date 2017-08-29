# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils git-r3 cmake-utils

DESCRIPTION="Structure-from-Motion (SfM) and Multi-View Stereo (MVS) pipeline with a graphical and command-line interface."
HOMEPAGE="https://colmap.github.io/"

SRC_URI="https://demuc.de/colmap/vocab_tree-65536.bin -> vocabulary-tree-64K.bin
		https://demuc.de/colmap/vocab_tree-262144.bin -> vocabulary-tree-256K.bin
		https://demuc.de/colmap/vocab_tree-1048576.bin -> vocabulary-tree-1M.bin"

EGIT_REPO_URI="https://github.com/colmap/colmap.git"
EGIT_BRANCH="dev"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="dev-cpp/gflags
		media-libs/freeglut
		dev-cpp/glog
		media-libs/freeimage
		sci-libs/ceres-solver
		dev-cpp/eigen
		dev-util/nvidia-cuda-toolkit"

RDEPEND="${DEPEND}"

src_prepare() {
	eapply ${FILESDIR}/nvm-export.patch
	eapply ${FILESDIR}/regex.patch
	cmake-utils_src_prepare
}

src_configure() {
	addwrite /dev/nvidia-uvm
	addwrite /dev/nvidiactl

	local mycmakeargs=(
		-DCUDA_ENABLED=ON
		-DCUDA_HOST_COMPILER=/opt/cuda/bin/gcc
		-DCUDA_TOOLKIT_ROOT_DIR=/opt/cuda
		-DTESTS_ENABLED=OFF
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_INSTALL_PREFIX=/usr
		-DCUDA_NVCC_FLAGS="--compiler-options -fPIC"
	)

	cmake-utils_src_configure
}

src_install() {
	addwrite /dev/nvidia0

	cmake-utils_src_install
	insinto /usr/share/${PN}
	for vocab_tree in ${DISTDIR}/vocabulary-tree-*.bin ; do
		newins ${vocab_tree} ${vocab_tree##*/}
	done

	make_desktop_entry colmap "Colmap"
}