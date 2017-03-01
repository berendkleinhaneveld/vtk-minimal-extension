# Minimal project for extending VTK with custom classes
# that should serve as an example of how to build it the
# 'right way'.

PROJECT(vtkMinimalExtension)
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

OPTION(WRAP_PYTHON "Build Python wrappers" ON)

SET(LIB_DESTINATION lib)
SET(BIN_DESTINATION bin)
SET(INCLUDE_DESTINATION "include/${PROJECT_NAME}")

MESSAGE( STATUS "CMAKE_INSTALL_PREFIX:    " ${CMAKE_INSTALL_PREFIX} )
MESSAGE( STATUS "LIB_DESTINATION:         " ${LIB_DESTINATION} )

# Find VTK
FIND_PACKAGE(VTK REQUIRED
    vtkCommonCore)
MESSAGE(STATUS "Found VTK libraries: ${VTK_LIBRARIES}")
MESSAGE(STATUS "Found UseVTK.cmake: ${VTK_USE_FILE}")
INCLUDE(${VTK_USE_FILE})
SET(VTK_MODULES_USED vtkCommonCore)

# Find OpenGL
FIND_PACKAGE(OpenGL)
MESSAGE(STATUS "Found OpenGL libraries: ${OPENGL_LIBRARIES}")

# Create vtkMinimalExample shared library
SET(LIBS ${VTK_LIBRARIES})
SET(SRC_FILES vtkMinimal.cxx vtkMinimal.h)
ADD_LIBRARY(${PROJECT_NAME} SHARED ${SRC_FILES})
TARGET_LINK_LIBRARIES(${PROJECT_NAME}
    ${LIBS})
IF(WIN32)
    TARGET_LINK_LIBRARIES(${PROJECT_NAME} 
        winmm)
ENDIF(WIN32)
INSTALL(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION ${BIN_DESTINATION}
    ARCHIVE DESTINATION ${LIB_DESTINATION}
    LIBRARY DESTINATION ${LIB_DESTINATION}
)
INSTALL(DIRECTORY .
    DESTINATION ${INCLUDE_DESTINATION} 
    FILES_MATCHING PATTERN "*.h"
    PATTERN "CMake" EXCLUDE
)
MESSAGE(STATUS "Added library: " "${PROJECT_NAME}")

INCLUDE_DIRECTORIES(${VTK_INCLUDE_DIRS})
INCLUDE_DIRECTORIES(${VTK_PYTHON_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})
INCLUDE_DIRECTORIES(${PROJECT_SOURCE_DIR})

if(WRAP_PYTHON)
    # Find Python
    FIND_PACKAGE(PythonLibs REQUIRED)
    MESSAGE(STATUS "Found Python include dir: " ${PYTHON_INCLUDE_DIRS} )
    MESSAGE(STATUS "Found Python library: " ${PYTHON_LIBRARIES} )
    INCLUDE_DIRECTORIES("${PYTHON_INCLUDE_DIRS}")
    
    # Generate VTK Python wrappers
    INCLUDE(vtkWrapPython)
    # despite the name, this works for any Python version (tested up to 3.5)
    VTK_WRAP_PYTHON3(${PROJECT_NAME}Python PYTHON_SRCS "${SRC_FILES}")
    MESSAGE(STATUS "Generated Python wrappers: " "${PYTHON_SRCS}")
    
    # Create PythonD library (brings everything together)
    ADD_LIBRARY("${PROJECT_NAME}PythonD" "${PYTHON_SRCS}" "${SRC_FILES}")
    SET_TARGET_PROPERTIES("${PROJECT_NAME}PythonD" PROPERTIES POSITION_INDEPENDENT_CODE ON)
    IF(WIN32)
        TARGET_LINK_LIBRARIES("${PROJECT_NAME}PythonD" 
            winmm)
    ENDIF(WIN32)
    TARGET_LINK_LIBRARIES("${PROJECT_NAME}PythonD" 
        ${LIBS} 
        vtkWrappingPythonCore 
        ${VTK_PYTHON_LIBRARIES})
    INSTALL(TARGETS "${PROJECT_NAME}PythonD"
        RUNTIME DESTINATION ${BIN_DESTINATION}
        ARCHIVE DESTINATION ${LIB_DESTINATION}
        LIBRARY DESTINATION ${LIB_DESTINATION}
    )
    
    # Create Python library (exposes to Python through a pyd)
    ADD_LIBRARY("${PROJECT_NAME}Python" MODULE "${PROJECT_NAME}PythonInit.cxx" "${PROJECT_NAME}PythonInitImpl.cxx")
    # collect the used pythonD libs in VTK_PYTHOND_LIBS
    SET(VTK_PYTHOND_LIBS)
    FOREACH(TMP_LIB ${VTK_MODULES_USED})
        SET(VTK_PYTHOND_LIBS ${VTK_PYTHOND_LIBS} ${TMP_LIB}PythonD)
    ENDFOREACH()
    # link 'em up
    TARGET_LINK_LIBRARIES("${PROJECT_NAME}Python" 
        "${PROJECT_NAME}PythonD" 
        ${VTK_PYTHOND_LIBS})
    # prettify the output
    SET_TARGET_PROPERTIES("${PROJECT_NAME}Python" PROPERTIES PREFIX "")
    if(WIN32 AND NOT CYGWIN)
        SET_TARGET_PROPERTIES("${PROJECT_NAME}Python" PROPERTIES SUFFIX ".pyd")
    endif(WIN32 AND NOT CYGWIN)
    # install command for the pyd
    INSTALL(TARGETS "${PROJECT_NAME}Python"
        LIBRARY DESTINATION "${SP_DIR}/${PROJECT_NAME}"
    )
    # install __init__.py to make it importable
    FILE(WRITE __init__.py "\
from __future__ import absolute_import\n\
\n\
try:\n\
    # use relative import for installed modules\n\
    from .${PROJECT_NAME}Python import *\n\
except ImportError:\n\
    # during build and testing, the modules will be elsewhere,\n\
    # e.g. in lib directory or Release/Debug config directories\n\
    from ${PROJECT_NAME}Python import *\n\
")
    INSTALL(FILES __init__.py
        DESTINATION "${SP_DIR}/${PROJECT_NAME}"
    )    
    
endif(WRAP_PYTHON)
