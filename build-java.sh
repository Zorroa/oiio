#!/bin/bash
set -x

# Java OIIO wrappers via JavaCPP
#
# We are using the javacpp and javacpp-presets GitHub repositories to package up OIIO for
# use in Java. Javacpp handles the distribution and linking of native libraries to the
# java wrapper code. The linking must be local for this to work at all in Java.
#
# Goal is to build libOpenImageIO.dylib with minimal external dynamic library dependencies.
# Each external dynamic dependency, and its transitive dependencies, must be included in
# the Java .jar bundle, and must use @rpath in the .dylib binary. We can configure the
# @rpath link specification at link time or after the .dylib is created using install_name_tool.
# I have a script that we could modify that uses otool and install_name_tool to recursively
# re-link using @rpath, following each transitive dependency. Ideally, we should link using
# as many static .a files as possible, and then relink any remaining .dylib files.
#
# The Zorroa wex-oiio branch of javacpp-presets contains the Java wrapper generator for
# OIIO along with the build scripts needed to download and build the native OIIO libs.
#     https://github.com/Zorroa/javacpp-presets/tree/wex-oiio
#
# The files that configure the OIIO portions of javacpp-presets are:
#     oiio/cppbuild.sh
#     oiio/pom.xml
#     oiio/src/main/java/org/bytedeco/javacpp/presets/oiio.java
#
# You can build the OIIO native code from the top level of the javacpp-presets repo with:
#     bash cppbuild.sh install oiio
#
# You can build the OIIO native code and the Java wrapper with:
#     mvn clean install --projects .,oiio
#
# Information about how to add a new javacpp native library can be found here:
#     https://github.com/bytedeco/javacpp-presets/wiki/Create-New-Presets
#
# As an example, here's how the caffe dependencies look when building the Caffe .jar file
# for the javacpp-presets:
#
# wex@Regula:lib % otool -L libcaffe.so
# libcaffe.so:
# @rpath/libcaffe.so.1.0.0-rc3 (compatibility version 0.0.0, current version 0.0.0)
# /System/Library/Frameworks/Accelerate.framework/Versions/A/Accelerate (compatibility version 1.0.0, current version 4.0.0)
# @rpath/libcudart.7.5.dylib (compatibility version 0.0.0, current version 7.5.20)
# @rpath/libcublas.7.5.dylib (compatibility version 0.0.0, current version 7.5.20)
# @rpath/libcurand.7.5.dylib (compatibility version 0.0.0, current version 7.5.20)
# /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1226.10.1)
# @rpath/libopencv_core.3.1.dylib (compatibility version 3.1.0, current version 3.1.0)
# @rpath/libopencv_highgui.3.1.dylib (compatibility version 3.1.0, current version 3.1.0)
# @rpath/libopencv_imgproc.3.1.dylib (compatibility version 3.1.0, current version 3.1.0)
# @rpath/libopencv_imgcodecs.3.1.dylib (compatibility version 3.1.0, current version 3.1.0)
# /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/libBLAS.dylib (compatibility version 1.0.0, current version 1.0.0)
# /usr/lib/libc++.1.dylib (compatibility version 1.0.0, current version 120.1.0)
#
# Here's what we have for OIIO currently (omitting OCIO and OpenCV):
#
# otool -L dist/macosx/lib/libOpenImageIO.dylib
# dist/macosx/lib/libOpenImageIO.dylib:
# 	libOpenImageIO.1.7.dylib (compatibility version 1.7.0, current version 1.7.2)
# 	libfreetype.6.dylib (compatibility version 16.0.0, current version 16.0.0)
# 	libpng15.15.dylib (compatibility version 29.0.0, current version 29.0.0)
# 	libz.1.dylib (compatibility version 1.0.0, current version 1.2.7)
# 	/opt/anaconda1anaconda2anaconda3/lib/libtiff.5.dylib (compatibility version 7.0.0, current version 7.0.0)
# 	libjpeg.8.dylib (compatibility version 13.0.0, current version 13.0.0)
# 	/usr/local/opt/webp/lib/libwebp.6.dylib (compatibility version 7.0.0, current version 7.0.0)
# 	/usr/local/opt/libraw/lib/libraw_r.15.dylib (compatibility version 16.0.0, current version 16.0.0)
# 	/usr/lib/libc++.1.dylib (compatibility version 1.0.0, current version 120.1.0)
# 	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1226.10.1)
# 
# We should be able to link against OCIO (or remove it),
#
## Current Status
#
# * The LINKSTATIC OIIO build flag should help us use .a files wherever possible. 
#   Currently, it appears to only use boost .a files.
# * OpenEXR has tools to link to .a files in the cmake/modules/FindOpenEXR.cmake
#   but they are not enabled by LINKSTATIC.
# * Adding logic to always use .a files with externalmodules results in missing
#   symbols for YAML, TinyXML, and a few other libs.


# Excerpted from javacpp-presets/oiio/cppbuild.sh for building OIIO
make clean ; make VERBOSE=1 USE_FREETYPE=0 USE_LIBRAW=0 USE_OPENCV=0 USE_OCIO=0 USE_CPP11=0 USE_PYTHON=0 OIIO_BUILD_TOOLS=0 OIIO_BUILD_TESTS=0 LINKSTATIC=1 OpenEXR_USE_STATIC_LIBS=1 cmakesetup clean
make -j2 USE_FREETYPE=0 USE_LIBRAW=0 USE_OPENCV=0 USE_OCIO=0 USE_CPP11=0 USE_PYTHON=0 OIIO_BUILD_TOOLS=0 OIIO_BUILD_TESTS=0 LINKSTATIC=1 OpenEXR_USE_STATIC_LIBS=1

# Display the resulting library dependencies
otool -L dist/macosx/lib/libOpenImageIO.dylib
