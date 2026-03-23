cmake_minimum_required(VERSION 3.10)
project(p3)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
# uncomment the following section in order to fill in
# further dependencies manually.
# find_package(<dependency> REQUIRED)

set(MEUS_PROGRAMAS
    "n3"
    "n3_copy"
    "n3_copy2" 
    "n3_copy3" 
    "n3_copy4"
)

foreach(programa ${MEUS_PROGRAMAS})
  add_executable(${programa} src/${programa}.cpp)
  target_include_directories(${programa} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include/${PROJECT_NAME}>)
  target_compile_features(${programa} PUBLIC c_std_99 cxx_std_17)  # Require C99 and C++17

  install(TARGETS ${programa}
    DESTINATION lib/${PROJECT_NAME})
  
endforeach()

ament_package()
