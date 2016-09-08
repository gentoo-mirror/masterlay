# Copyright 2015 Julian Ospald <hasufell@posteo.de>
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
PYTHON_COMPAT=( python3_5 )

inherit multilib fdo-mime gnome2-utils cmake-utils eutils python-single-r1 versionator \
	   flag-o-matic toolchain-funcs pax-utils check-reqs

DESCRIPTION="3D Creation/Animation/Publishing System"
HOMEPAGE="http://www.blender.org"

SRC_URI="http://download.blender.org/source/${P}.tar.gz"

SLOT="0"
LICENSE="|| ( GPL-2 BL )"
KEYWORDS="~amd64 ~x86"
IUSE="+boost +bullet collada colorio cycles +dds debug doc +elbeem ffmpeg fftw +game-engine \
            jemalloc jpeg2k libav man ndof nls openal openimageio openmp +openexr player sdl \
            sndfile cpu_flags_x86_sse cpu_flags_x86_sse2 test tiff c++0x valgrind jack"
REQUIRED_USE="${PYTHON_REQUIRED_USE}
	player? ( game-engine )
	cycles? ( boost openexr tiff openimageio )
	nls? ( boost )
	game-engine? ( boost )
	^^ ( ffmpeg libav )"

RDEPEND="${PYTHON_DEPS}
	dev-libs/lzo:2
	>=dev-python/numpy-1.10.1[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	>=media-libs/freetype-2.0:2
	media-libs/glew
	media-libs/libpng:0
	media-libs/libsamplerate
	sci-libs/ldl
	sys-libs/zlib
	virtual/glu
	virtual/jpeg:0
	virtual/libintl
	virtual/opengl
	x11-libs/libX11
	x11-libs/libXi
	x11-libs/libXxf86vm
	boost? ( >=dev-libs/boost-1.60[nls?,threads(+)] )
	collada? ( >=media-libs/opencollada-1.6.18 )
	colorio? ( >=media-libs/opencolorio-1.0.9-r2 )
	ffmpeg? ( >=media-video/ffmpeg-2.8.6:0=[x264,mp3,encode,theora,jpeg2k?] )
	libav? ( >=media-video/libav-11.3:0=[x264,mp3,encode,theora,jpeg2k?] )
	fftw? ( sci-libs/fftw:3.0 )
	jack? ( media-sound/jack-audio-connection-kit )
	jemalloc? ( dev-libs/jemalloc )
	jpeg2k? ( media-libs/openjpeg:0 )
	ndof? (
		app-misc/spacenavd
		dev-libs/libspnav
	)
	nls? ( virtual/libiconv )
	openal? ( >=media-libs/openal-1.6.372 )
	openimageio? ( >=media-libs/openimageio-1.6.9 )
	openexr? ( media-libs/ilmbase >=media-libs/openexr-2.2.0 )
	sdl? ( media-libs/libsdl2[sound,joystick] )
	sndfile? ( media-libs/libsndfile )
	tiff? ( media-libs/tiff:0 )
	valgrind? ( dev-util/valgrind )
"
DEPEND="${RDEPEND}
	>=dev-cpp/eigen-3.2.8:3
	doc? (
		app-doc/doxygen[-nodot(-),dot(+),latex]
		dev-python/sphinx[latex]
	)
	nls? ( sys-devel/gettext )"

pkg_pretend() {
	if use openmp && ! tc-has-openmp; then
		eerror "You are using gcc built without 'openmp' USE."
		eerror "Switch CXX to an OpenMP capable compiler."
		die "Need openmp"
	fi

	if use doc; then
		CHECKREQS_DISK_BUILD="4G" check-reqs_pkg_pretend
	fi
}

pkg_setup() {
	python-single-r1_pkg_setup
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2.68-doxyfile.patch \
	       "${FILESDIR}"/${PN}-2.68-fix-install-rules.patch \
	       "${FILESDIR}"/${PN}-2.77-sse2.patch \
	       "${FILESDIR}"/${PN}-2.77-C++0x-build-fix.patch

	# we don't want static glew, but it's scattered across
	# thousand files
	# !!!CHECK THIS SED ON EVERY VERSION BUMP!!!
	sed -i \
		-e '/-DGLEW_STATIC/d' \
		$(find . -type f -name "CMakeLists.txt") || die
}

src_configure() {
	# FIX: forcing '-funsigned-char' fixes an anti-aliasing issue with menu
	# shadows, see bug #276338 for reference
	append-flags -funsigned-char
	append-lfs-flags

	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX=/usr
		-DPYTHON_VERSION="${EPYTHON/python/}"
		-DPYTHON_LIBRARY="$(python_get_library_path)"
		-DPYTHON_INCLUDE_DIR="$(python_get_includedir)"
		-DWITH_INSTALL_PORTABLE=OFF
		-DWITH_PYTHON_INSTALL=OFF
		-DWITH_PYTHON_INSTALL_NUMPY=OFF
		-DWITH_STATIC_LIBS=OFF
		-DWITH_SYSTEM_GLEW=ON
		-DWITH_SYSTEM_OPENJPEG=ON
		-DWITH_SYSTEM_EIGEN3=ON
		-DWITH_SYSTEM_LZO=ON
		$(cmake-utils_use_with boost BOOST)
		$(cmake-utils_use_with bullet BULLET)
		$(cmake-utils_use_with ffmpeg CODEC_FFMPEG)
		$(cmake-utils_use_with sndfile CODEC_SNDFILE)
		$(cmake-utils_use_with c++0x CPP11)
		$(cmake-utils_use_with cycles CYCLES)
		$(cmake-utils_use_with fftw FFTW3)
		$(cmake-utils_use_with game-engine GAMEENGINE)
		$(cmake-utils_use_with dds IMAGE_DDS)
		$(cmake-utils_use_with openexr IMAGE_OPENEXR)
		$(cmake-utils_use_with jpeg2k IMAGE_OPENJPEG)
		$(cmake-utils_use_with tiff IMAGE_TIFF)
		$(cmake-utils_use_with ndof INPUT_NDOF)
		$(cmake-utils_use_with nls INTERNATIONAL)
		$(cmake-utils_use_with jack JACK)
		$(cmake-utils_use_with elbeem MOD_FLUID)
		$(cmake-utils_use_with fftw MOD_OCEANSIM)
		$(cmake-utils_use_with openal OPENAL)
		$(cmake-utils_use_with colorio OPENCOLORIO)
		$(cmake-utils_use_with collada OPENCOLLADA)
		$(cmake-utils_use_with openimageio OPENIMAGEIO)
		$(cmake-utils_use_with openmp OPENMP)
		$(cmake-utils_use_with player PLAYER)
		$(cmake-utils_use_with sdl SDL)
		$(cmake-utils_use_with cpu_flags_x86_sse RAYOPTIMIZATION)
		$(cmake-utils_use_with cpu_flags_x86_sse2 SSE2)
		$(cmake-utils_use_with debug CXX_GUARDEDALLOC)
		$(cmake-utils_use_with debug ASSERT_ABORT)
		$(cmake-utils_use_with test GTESTS)
		$(cmake-utils_use_with man DOC_MANPAGE)
		$(camke-utils_use_with jemalloc MEM_JEMALLOC)
		$(cmake-utils_use_with valgrind MEM_VALGRIND)
	)
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile

	if use doc; then
		einfo "Generating Blender C/C++ API docs ..."
		cd "${CMAKE_USE_DIR}"/doc/doxygen || die
		doxygen -u Doxyfile || die
		doxygen || die "doxygen failed to build API docs."

		cd "${CMAKE_USE_DIR}" || die
		einfo "Generating (BPY) Blender Python API docs ..."
		"${BUILD_DIR}"/bin/blender --background --python doc/python_api/sphinx_doc_gen.py -noaudio || die "blender failed."

		cd "${CMAKE_USE_DIR}"/doc/python_api || die
		sphinx-build sphinx-in BPY_API || die "sphinx failed."
	fi
}

src_test() {
	if use test; then
		einfo "Running Blender Unit Tests ..."
		cd "${BUILD_DIR}"/bin/tests || die
		for f in *_test
		do
			./$f || die
		done
	fi
}

src_install() {
	local i

	# Pax mark blender for hardened support.
	pax-mark m "${CMAKE_BUILD_DIR}"/bin/blender

	if use doc; then
		docinto "API/python"
		dohtml -r "${CMAKE_USE_DIR}"/doc/python_api/BPY_API/*

		docinto "API/blender"
		dohtml -r "${CMAKE_USE_DIR}"/doc/doxygen/html/*
	fi

	# fucked up cmake will relink binary for no reason
	emake -C "${CMAKE_BUILD_DIR}" DESTDIR="${D}" install/fast

	# fix doc installdir
	dohtml "${CMAKE_USE_DIR}"/release/text/readme.html
	rm -r "${ED%/}"/usr/share/doc/blender || die

	python_fix_shebang "${ED%/}"/usr/bin/blender-thumbnailer.py
	python_optimize "${ED%/}"/usr/share/blender/${PV}/scripts
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	elog
	elog "Blender uses python integration. As such, may have some"
	elog "inherit risks with running unknown python scripts."
	elog
	elog "It is recommended to change your blender temp directory"
	elog "from /tmp to /home/user/tmp or another tmp file under your"
	elog "home directory. This can be done by starting blender, then"
	elog "dragging the main menu down do display all paths."
	elog
	ewarn
	ewarn "This ebuild does not unbundle the massive amount of 3rd party"
	ewarn "libraries which are shipped with blender. Note that"
	ewarn "these have caused security issues in the past."
	ewarn "If you are concerned about security, file a bug upstream:"
	ewarn "  https://developer.blender.org/"
	ewarn
	gnome2_icon_cache_update
	fdo-mime_desktop_database_update
}

pkg_postrm() {
	gnome2_icon_cache_update
	fdo-mime_desktop_database_update
}
