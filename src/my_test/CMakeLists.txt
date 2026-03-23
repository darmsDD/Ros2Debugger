cmake_minimum_required(VERSION 3.8)
project(my_test)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
# uncomment the following section in order to fill in
# further dependencies manually.
# find_package(<dependency> REQUIRED)

set(NODES
  my_node
  t1
)

add_executable(my_node src/my_node.cpp)
add_executable(t1 src/t1.cpp)

foreach(node ${NODES})

  target_include_directories(${node} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include/${PROJECT_NAME}>)

  target_compile_features(${node} PUBLIC c_std_99 cxx_std_17)

endforeach()

install(TARGETS my_node t1
  DESTINATION lib/${PROJECT_NAME})

ament_package()
