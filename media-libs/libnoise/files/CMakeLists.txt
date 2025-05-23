CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

PROJECT(libnoise)

SET (LIBNOISE_SRC
	src/latlon.cpp
	src/model/cylinder.cpp
	src/model/line.cpp
	src/model/plane.cpp
	src/model/sphere.cpp
	src/module/abs.cpp
	src/module/add.cpp
	src/module/billow.cpp
	src/module/blend.cpp
	src/module/cache.cpp
	src/module/checkerboard.cpp
	src/module/clamp.cpp
	src/module/const.cpp
	src/module/curve.cpp
	src/module/cylinders.cpp
	src/module/displace.cpp
	src/module/exponent.cpp
	src/module/invert.cpp
	src/module/max.cpp
	src/module/min.cpp
	src/module/modulebase.cpp
	src/module/multiply.cpp
	src/module/perlin.cpp
	src/module/power.cpp
	src/module/ridgedmulti.cpp
	src/module/rotatepoint.cpp
	src/module/scalebias.cpp
	src/module/scalepoint.cpp
	src/module/select.cpp
	src/module/spheres.cpp
	src/module/terrace.cpp
	src/module/translatepoint.cpp
	src/module/turbulence.cpp
	src/module/voronoi.cpp
	src/noisegen.cpp
)

set (BASE_HEADERS
	src/basictypes.h
	src/exception.h
	src/interp.h
	src/latlon.h
	src/mathconsts.h
	src/misc.h
	src/noise.h
	src/noisegen.h
	src/vectortable.h
)

SET (MODEL_HEADERS
	src/model/cylinder.h
	src/model/line.h
	src/model/model.h
	src/model/plane.h
	src/model/sphere.h
)

SET (MODULE_HEADERS
	src/module/abs.h
	src/module/add.h
	src/module/billow.h
	src/module/blend.h
	src/module/cache.h
	src/module/checkerboard.h
	src/module/clamp.h
	src/module/const.h
	src/module/curve.h
	src/module/cylinders.h
	src/module/displace.h
	src/module/exponent.h
	src/module/invert.h
	src/module/max.h
	src/module/min.h
	src/module/module.h
	src/module/modulebase.h
	src/module/multiply.h
	src/module/perlin.h
	src/module/power.h
	src/module/ridgedmulti.h
	src/module/rotatepoint.h
	src/module/scalebias.h
	src/module/scalepoint.h
	src/module/select.h
	src/module/spheres.h
	src/module/terrace.h
	src/module/translatepoint.h
	src/module/turbulence.h
	src/module/voronoi.h
)

ADD_LIBRARY (noise SHARED ${LIBNOISE_SRC})
SET_TARGET_PROPERTIES (noise PROPERTIES VERSION 1.0.0)
INSTALL(TARGETS noise DESTINATION "${CMAKE_INSTALL_LIBDIR}")
INSTALL(FILES ${BASE_HEADERS} DESTINATION "include/noise")
INSTALL(FILES ${MODEL_HEADERS} DESTINATION "include/noise/model")
INSTALL(FILES ${MODULE_HEADERS} DESTINATION "include/noise/module")
