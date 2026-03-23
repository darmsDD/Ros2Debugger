cmake_minimum_required(VERSION 3.10)
project(p7)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
# uncomment the following section in order to fill in
# further dependencies manually.
# find_package(<dependency> REQUIRED)

set(MEUS_PROGRAMAS
    "n7"
    "n7_copy"
    "n7_copy2" 
)

foreach(programa ${MEUS_PROGRAMAS})
  add_executable(${programa} src/${programa}.cpp)
  ament_target_dependencies(${programa} rclcpp)
  target_include_directories(${programa} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include/${PROJECT_NAME}>)
  target_compile_features(${programa} PUBLIC c_std_99 cxx_std_17)  # Require C99 and C++17

  install(TARGETS ${programa}
    DESTINATION lib/${PROJECT_NAME})
  
endforeach()


install(DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
