# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{7,8} )

inherit check-reqs cmake-utils python-single-r1 pax-utils flag-o-matic git-r3 xdg

DESCRIPTION="3D Creation/Animation/Publishing System"
HOMEPAGE="http://www.blender.org/"

EGIT_REPO_URI="https://git.blender.org/blender.git"
EGIT_BRANCH="blender-v2.82-release"
#EGIT_COMMIT="7c2217cd126a97df9b1c305f79a605f25c06a229"

LICENSE="|| ( GPL-2 BL )"
KEYWORDS="~amd64"
SLOT="0"
MY_PV="$(ver_cut 1-2)"

IUSE_DESKTOP="-portable +blender +X +nls -ndof -player"
IUSE_GPU="+opengl +optix cuda opencl -sm_30 -sm_35 -sm_50 -sm_52 -sm_61 -sm_70 -sm_75"
IUSE_LIBS="+cycles -sdl jack openal freestyle -osl +openvdb +opensubdiv +opencolorio +openimageio +collada -alembic +fftw +oidn"
IUSE_CPU="openmp embree +sse"
IUSE_TEST="-valgrind -debug -doc"
IUSE_IMAGE="-dpx -dds +openexr jpeg2k tiff +hdr"
IUSE_CODEC="avi +ffmpeg -sndfile +quicktime"
IUSE_COMPRESSION="-lzma +lzo"
IUSE_MODIFIERS="+fluid +smoke +oceansim"
IUSE="${IUSE_DESKTOP} ${IUSE_GPU} ${IUSE_LIBS} ${IUSE_CPU} ${IUSE_TEST} ${IUSE_IMAGE} ${IUSE_CODEC} ${IUSE_COMPRESSION} ${IUSE_MODIFIERS}"

REQUIRED_USE="${PYTHON_REQUIRED_USE}
	fluid  ( fftw )
	oceansim ( fftw )
	smoke ( fftw )
	tiff ( openimageio )
	openexr ( openimageio )
	cuda? ( cycles openimageio )
	cycles? ( openexr tiff openimageio opencolorio )
	osl? ( cycles )
	embree? ( cycles )
	oidn? ( cycles )"

LANGS="en ar bg ca cs de el es es_ES fa fi fr he hr hu id it ja ky ne nl pl pt pt_BR ru sr sr@latin sv tr uk zh_CN zh_TW"
for X in ${LANGS} ; do
	IUSE+=" linguas_${X}"
	REQUIRED_USE+=" linguas_${X}? ( nls )"
done

RDEPEND="${PYTHON_DEPS}
	dev-libs/jemalloc
	$(python_gen_cond_dep '
		>=dev-python/numpy-1.10.1[${PYTHON_MULTI_USEDEP}]
		dev-python/requests[${PYTHON_MULTI_USEDEP}]
	')
	sys-libs/zlib
	smoke? ( sci-libs/fftw:3.0 )
	media-libs/freetype
	media-libs/libpng:0=
	virtual/libintl
	virtual/jpeg:0=
	dev-libs/boost[nls?,threads(+)]
	opengl? (
		virtual/opengl
		media-libs/glew:*
		virtual/glu
	)
	X? (
		x11-libs/libXi
		x11-libs/libX11
		x11-libs/libXxf86vm
	)
	opencolorio? ( media-libs/opencolorio )
	cycles? (
		openimageio? ( >=media-libs/openimageio-1.1.5 )
		cuda? ( dev-util/nvidia-cuda-toolkit )
		osl? ( media-libs/osl )
		embree? ( media-libs/embree )
		openvdb? ( media-gfx/openvdb[${PYTHON_SINGLE_USEDEP},-abi4-compat]
		dev-cpp/tbb )
	)
	optix? ( dev-libs/optix )
	sdl? ( media-libs/libsdl[sound,joystick] )
	tiff? ( media-libs/tiff:0 )
	openexr? ( media-libs/openexr )
	ffmpeg? ( >=media-video/ffmpeg-2.2[x264,xvid,mp3,encode,jpeg2k?] )
	jpeg2k? ( media-libs/openjpeg:0 )
	jack? ( media-sound/jack2 )
	sndfile? ( media-libs/libsndfile )
	collada? ( media-libs/opencollada )
	ndof? (
		app-misc/spacenavd
		dev-libs/libspnav
	)
	quicktime? ( media-libs/libquicktime )
	valgrind? ( dev-util/valgrind )
	lzma? ( app-arch/lzma )
	lzo? ( dev-libs/lzo )
	alembic? ( media-gfx/alembic )
	opencl? ( app-eselect/eselect-opencl )
	opensubdiv? ( media-libs/opensubdiv )
	nls? ( virtual/libiconv )
	oidn? ( media-libs/oidn )"

DEPEND="${RDEPEND}
	dev-cpp/eigen:3
	nls? ( sys-devel/gettext )
	doc? (
		dev-python/sphinx
		app-doc/doxygen[-nodot(-),dot(+)]
	)"

CMAKE_BUILD_TYPE="Release"

blender_check_requirements() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp

	if use doc; then
		CHECKREQS_DISK_BUILD="4G" check-reqs_pkg_pretend
	fi
}

pkg_pretend() {
	blender_check_requirements
}

pkg_setup() {
	blender_check_requirements
	python-single-r1_pkg_setup
}

src_prepare() {
	eapply_user
	eapply "${FILESDIR}"/blender-doxyfile.patch

	cmake-utils_src_prepare

	# remove some bundled deps
	rm -r \
		extern/glew \
		extern/glew-es \
		extern/Eigen3 \
		extern/lzma \
		extern/lzo \
		extern/gtest \
		|| die

	default

	# we don't want static glew, but it's scattered across
	# multiple files that differ from version to version
	# !!!CHECK THIS SED ON EVERY VERSION BUMP!!!
	local file
	while IFS="" read -d $'\0' -r file ; do
		sed -i -e '/-DGLEW_STATIC/d' "${file}" || die
	done < <(find . -type f -name "CMakeLists.txt")

	# Disable MS Windows help generation. The variable doesn't do what it
	# it sounds like.
	sed -e "s|GENERATE_HTMLHELP      = YES|GENERATE_HTMLHELP      = NO|" \
	    -i doc/doxygen/Doxyfile || die
	ewarn "$(echo "Remaining bundled dependencies:";
			( find extern -mindepth 1 -maxdepth 1 -type d; ) | sed 's|^|- |')"
	# linguas cleanup
	local i
	if ! use nls; then
		rm -r "${S}"/release/datafiles/locale || die
	else
		if [[ -n "${LINGUAS+x}" ]] ; then
			cd "${S}"/release/datafiles/locale/po
			for i in *.po ; do
				mylang=${i%.po}
				has ${mylang} ${LINGUAS} || { rm -r ${i} || die ; }
			done
		fi
	fi

	# cleanup addons
	for a in $(ls "${S}"/release/scripts/addons_contrib/); do
		if [[ -d "${S}"/release/scripts/addons/${a} || -f "${S}"/release/scripts/addons/${a} ]]; then
			ewarn "Duplicate ${a}, removing"
			rm -r "${S}"/release/scripts/addons_contrib/${a}
		fi
	done
}

src_configure() {
	append-flags -funsigned-char -fno-strict-aliasing
	append-lfs-flags
	#append-cppflags -DOPENVDB_ABI_VERSION_NUMBER=4
	append-cppflags -DOPENVDB_ABI_VERSION_NUMBER=5
	local MYCMAKEARGS=(-DCMAKE_TOOLCHAIN_FILE="")

	local mycmakeargs=""
	#CUDA Kernel Selection
	local CUDA_ARCH=""
	if use cuda; then
		for CA in 30 35 50 52 61 70 75; do
			if use sm_${CA}; then
				if [[ -n "${CUDA_ARCH}" ]] ; then
					CUDA_ARCH="${CUDA_ARCH};sm_${CA}"
				else
					CUDA_ARCH="sm_${CA}"
				fi
			fi
		done

		#If a kernel isn't selected then all of them are built by default
		if [ -n "${CUDA_ARCH}" ] ; then
			mycmakeargs+=(
				-DCYCLES_CUDA_BINARIES_ARCH=${CUDA_ARCH}
			)
		fi

		mycmakeargs+=(
			-DWITH_CYCLES_CUDA=ON
			-DWITH_CYCLES_CUDA_BINARIES=ON
			-DCUDA_TOOLKIT_ROOT_DIR=/opt/cuda
			-DCUDA_NVCC_EXECUDABLE=/opt/cuda/bin/nvcc
		)
	fi

	if use optix; then
		mycmakeargs+=(
			-OPTIX_ROOT_DIR=/opt/optix
			-DOPTIX_INCLUDE_DIR=/opt/optix/include
			-DWITH_CYCLES_DEVICE_OPTIX=ON
		)
	fi

	mycmakeargs+=(
		-DCMAKE_INSTALL_PREFIX=/usr
		-DPYTHON_VERSION=${EPYTHON/python/}
		-DPYTHON_LIBRARY=$(python_get_library_path)
		-DPYTHON_INCLUDE_DIR=$(python_get_includedir)
		-DWITH_PYTHON_INSTALL=$(usex portable)
		-DWITH_PYTHON_INSTALL_NUMPY=$(usex portable)
		-DWITH_PYTHON_INSTALL_REQUESTS=$(usex portable)
		-DWITH_PYTHON_MODULE=$(usex !X)
		-DWITH_HEADLESS=$(usex !X)
		-DWITH_BLENDER=$(usex blender)
		-DWITH_ALEMBIC=$(usex alembic)
		-DWITH_CODEC_AVI=$(usex avi)
		-DWITH_CODEC_FFMPEG=$(usex ffmpeg)
		-DWITH_CODEC_SNDFILE=$(usex sndfile)
		-DWITH_FFTW3=$(usex fftw)
		-DWITH_CPU_SSE=$(usex sse)
		-DWITH_CYCLES=$(usex cycles)
		-DWITH_CYCLES_DEVICE_CUDA=$(usex cuda)
		-DWITH_CYCLES_DEVICE_OPENCL=$(usex opencl)
		-DWITH_CYCLES_EMBREE=$(usex embree)
		-DWITH_CYCLES_NATIVE_ONLY=$(usex cycles)
		-DWITH_CYCLES_NETWORK=OFF
		-DWITH_CYCLES_OSL=$(usex osl)
		-DWITH_CYCLES_STANDALONE=OFF
		-DWITH_CYCLES_STANDALONE_GUI=OFF
		-DWITH_FREESTYLE=$(usex freestyle)
		-DWITH_X11=$(usex X)
		-DWITH_GHOST_XDND=$(usex X)
		-DWITH_IMAGE_CINEON=$(usex dpx)
		-DWITH_IMAGE_DDS=$(usex dds)
		-DWITH_IMAGE_HDR=$(usex hdr)
		-DWITH_IMAGE_OPENEXR=$(usex openexr)
		-DWITH_IMAGE_OPENJPEG=$(usex jpeg2k)
		-DWITH_IMAGE_TIFF=$(usex tiff)
		-DWITH_INPUT_NDOF=$(usex ndof)
		-DWITH_INSTALL_PORTABLE=$(usex portable)
		-DWITH_INTERNATIONAL=$(usex nls)
		-DWITH_JACK=$(usex jack)
		-DWITH_LEGACY_DEPSGRAPH=OFF
		-DWITH_LLVM=$(usex osl)
		-DWITH_LZMA=$(usex lzma)
		-DWITH_LZO=$(usex lzo)
		-DWITH_VALGRIND=$(usex valgrind)
		-DWITH_MOD_FLUID=$(usex fluid)
		-DWITH_MOD_OCEANSIM=$(usex oceansim)
		-DWITH_MOD_SMOKE=$(usex smoke)
		-DWITH_OPENAL=$(usex openal)
		-DWITH_OPENCOLLADA=$(usex collada)
		-DWITH_OPENCOLORIO=$(usex opencolorio)
		-DWITH_OPENGL=$(usex opengl)
		-DWITH_OPENIMAGEIO=$(usex openimageio)
		-DWITH_OPENMP=$(usex openmp)
		-DWITH_OPENSUBDIV=$(usex opensubdiv)
		-DWITH_OPENVDB=$(usex openvdb)
		-DWITH_OPENVDB_BLOSC=$(usex openvdb)
		-DWITH_RAYOPTIMIZATION=$(usex sse)
		-DWITH_SDL=$(usex sdl)
		-DWITH_STATIC_LIBS=$(usex portable)
		-DWITH_SYSTEM_BULLET=OFF
		-DWITH_SYSTEM_EIGEN3=$(usex !portable)
		-DWITH_SYSTEM_GLES=$(usex !portable)
		-DWITH_SYSTEM_GLEW=$(usex !portable)
		-DWITH_SYSTEM_LZO=$(usex !portable)
		-DWITH_PLAYER=OFF
		-DWITH_DEBUG=$(usex debug)
		-DWITH_GHOST_DEBUG=$(usex debug)
		-DWITH_WITH_CYCLES_DEBUG=$(usex debug)
		-DWITH_CXX_GUARDEDALLOC=$(usex debug)
		-DWITH_OPENIMAGEDENOISE=$(usex oidn)
	)

	if use oidn; then
		mycmakeargs+=(
			-DOPENIMAGEDENOISE_COMMON_LIBRARY=/usr/lib64/
			-DOPENIMAGEDENOISE_MKLDNN_LIBRARY=/usr/lib64/
		)
	fi

	cmake-utils_src_configure
}

cmake-utils_src_configure() {
	_cmake_check_build_dir || die
	pushd "${BUILD_DIR}" > /dev/null || die
	"${CMAKE_BINARY}" -G "$(_cmake_generator_to_use)" -DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr" "${mycmakeargs[@]}" "${CMAKE_USE_DIR}" || die "cmake failed"
	popd > /dev/null || die
}

src_compile() {
	cmake-utils_src_compile

	if use doc; then
		einfo "Generating Blender C/C++ API docs ..."
		cd "${CMAKE_USE_DIR}"/doc/doxygen || die
		doxygen -u Doxyfile
		doxygen || die "doxygen failed to build API docs."

		cd "${CMAKE_USE_DIR}" || die
		einfo "Generating (BPY) Blender Python API docs ..."
		"${BUILD_DIR}"/bin/blender --background --python doc/python_api/sphinx_doc_gen.py -noaudio || die "blender failed."

		cd "${CMAKE_USE_DIR}"/doc/python_api || die
		sphinx-build sphinx-in BPY_API || die "sphinx failed."
	fi
}

src_test() { :; }

src_install() {
	# Pax mark blender for hardened support.
	pax-mark m "${CMAKE_BUILD_DIR}"/bin/blender

	if use doc; then
		docinto "html/API/python"
		dodoc -r "${CMAKE_USE_DIR}"/doc/python_api/BPY_API/.

		docinto "html/API/blender"
		dodoc -r "${CMAKE_USE_DIR}"/doc/doxygen/html/.
	fi

	cmake-utils_src_install

	# fix doc installdir
	docinto "html"
	dodoc "${CMAKE_USE_DIR}"/release/text/readme.html
	rm -r "${ED%/}"/usr/share/doc/blender || die

	python_fix_shebang "${ED%/}/usr/bin/blender-thumbnailer.py"
	python_optimize "${ED%/}/usr/share/blender/${MY_PV}/scripts"
}

pkg_postinst() {
	elog
	elog "Blender compiles from master thunk by default"
	elog
	elog "There is some my prefer blender settings as patches"
	elog "find them in cg/local-patches/blender/"
	elog "To apply someone copy them in "
	elog "/etc/portage/patches/media-gfx/blender/"
	elog "or create simlink"
	elog
	xdg_pkg_postinst
}

pkg_postrm() {
	xdg_pkg_postrm

	ewarn ""
	ewarn "You may want to remove the following directory."
	ewarn "~/.config/${PN}/${MY_PV}/cache/"
	ewarn "It may contain extra render kernels not tracked by portage"
	ewarn ""
}
