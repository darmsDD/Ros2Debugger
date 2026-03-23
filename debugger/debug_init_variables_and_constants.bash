# !/bin/bash

#=========================================Constants definition=========================================

PATTERN_TO_FIND_NODE_IN_LAUNCH_FILE="[[:space:]]*=[[:space:]]*Node" # this pattern is used by awk/sed/grep to find nodes in a launch file.
prefix_pattern="[[:space:]]*=[[:space:]]*'gdbserver localhost:3000'" # this pattern is used by awk/sed/grep to find the prefix with gdb server
DEBUGGERS=("Use Vscode extension" "Use the terminal") # list of debugger options.
LAUNCH_FILE_NAME_TERMINATION="debugger"
ONLY_BUILD=1
TYPE_OF_BUILD=("Release" "Debug" "RelWithDebInfo")
#PATH_OF_CONSTANTS_AND_VARIABLES_FILE=$(realpath "${BASH_SOURCE[0]}")
BUILD_OR_DEBUG_MENU_OPTIONS=("Build without debug (colcon build --symlink-install  --cmake-args \"-DCMAKE_BUILD_TYPE=Release\")" \
            "Build with all debug options (colcon build --symlink-install  --cmake-args \"-DCMAKE_BUILD_TYPE=Debug\")" \
            "Build with some debug options (colcon build --symlink-install  --cmake-args \"-DCMAKE_BUILD_TYPE=RelWithDebInfo\")" \
            "Skip build (I have already built the ROS2 project)")

# ============== Menu options ============================================
YES=0   # option for yes in the yes or no menu.
NO=1    # option for no in the yes or no menu.
VSCODE_DEBUGGER=0 # option to choose vscode as the debugger.
GDB_DEBUGGER=1 # option to choose gdb in the terminal as the debugger.
USE_LAUNCH_FILE=0 # option to use a launch file in the debugger launch mode.
RUN_SINGLE_EXECUTABLE=1 # option to run a single executable in the debugger launch mode.
RUN_WITHOUT_DEBUGGER=0 # option to run project without the debugger
RUN_WITH_DEBUGGER=1 # option to run the project with the debugger
BUILD=1
ATTACH=0
#=========== Title and message options for the menus ======================
whiptail_title="Ros2 menu"
declare -A WHIPTAIL_MESSAGE
BUILD_OR_DEBUG_MENU=0
DEBUG_PACKAGE_MENU=1
DEBUG_EXECUTABLE_MENU=2
DEBUG_VSCODE_OR_GDB_MENU=3
DEBUG_BUILD_MADE_WITH_CORRECT_FLAGS=4
DEBUG_NODE_MENU=5
DEBUG_LAUNCH_FILES_MENU=6
RUN_PROJECT_MENU=7
CHOOSE_ROS2_PACKAGE_WITH_LAUNCH_FILE=8
CHOOSE_ROS2_LAUNCH_FILE=9
CHOOSE_A_PROCESS_MENU=10
RUN_COMMAND_MENU=11 # this message is edited for different commands, that is why it is not declared here as WHIPTAIL_MESSAGE[$RUN_COMMAND_MENU]="..."
USE_LAUNCH_MENU=12
WHIPTAIL_MESSAGE[$BUILD_OR_DEBUG_MENU]="Choose an option:"
WHIPTAIL_MESSAGE[$DEBUG_PACKAGE_MENU]="Choose a package"
WHIPTAIL_MESSAGE[$DEBUG_EXECUTABLE_MENU]="Choose an executable:"
WHIPTAIL_MESSAGE[$DEBUG_NODE_MENU]="Choose a node to debug:"
WHIPTAIL_MESSAGE[$DEBUG_VSCODE_OR_GDB_MENU]="Choose a debugger to use:"
WHIPTAIL_MESSAGE[$DEBUG_BUILD_MADE_WITH_CORRECT_FLAGS]="Was the running build made with one of the debug flags? Example: colcon build --cmake-args \"-DCMAKE_BUILD_TYPE=Debug\""
WHIPTAIL_MESSAGE[$DEBUG_LAUNCH_FILES_MENU]="Run project with the previous launch file?"
WHIPTAIL_MESSAGE[$RUN_PROJECT_MENU]="Run project?"
WHIPTAIL_MESSAGE[$CHOOSE_ROS2_PACKAGE_WITH_LAUNCH_FILE]="Choose a package with the correct launch file:"
WHIPTAIL_MESSAGE[$CHOOSE_ROS2_LAUNCH_FILE]="Choose the ros2 launch file:"
WHIPTAIL_MESSAGE[$CHOOSE_A_PROCESS_MENU]="Choose a process:"
WHIPTAIL_MESSAGE[$USE_LAUNCH_MENU]="Use launch file"

#======================CHANGE THESE 4 CONSTANTS TO YOUR CORRECT VALUES ============================
REPO_ORIGIN_PATH="/home/ivan/Documents/MestradoComBacurau/Robo/EstudoRos/debug" # place where you opened the vscode program. Pass the full path.
ROS2_PROJECT_PATH="/home/ivan/Documents/MestradoComBacurau/Robo/EstudoRos/debug" # ROS2 project path
STANDARD_BUILD=$YES # YES: use the standard ros2 build | NO: use your own build method (remember to rewrite the function user_defined_build_command)
STANDARD_RUN=$YES # YES: use the standard ros2 run | NO: use your own run method (remember to rewrite the function user_defined_run_project_command)
#===================================================================================================

VSCODE_LAUNCH_PATH="$REPO_ORIGIN_PATH/.vscode/launch.json" # path for the launch.json file used by the debugger.
# using path and a different name for the launch file to reduce the chances of finding another file
ORIGINAL_DEBUGGER_LAUNCH_PATH=$(find $REPO_ORIGIN_PATH/ -type f -path "*/debugger/*" -name "launch_file_to_be_used_by_debugger.json")
NUMBER_OF_DEBUGGER_LAUNCH_FILES=$(wc -l <<< $ORIGINAL_DEBUGGER_LAUNCH_PATH)


#=========================================Variables definition=========================================
was_debug_used=$NO
use_gdb_debugger=$NO
use_vscode_debugger=$NO
was_ros2_launch_used=$NO


#=========================================STATE MACHINE OPTION ====================


MENU_FIRST_WINDOW=0
MENU_WAS_BUILD_MADE_WITH_DEBUG_FLAGS=1
MENU_BUILD=2
MENU_CONFIG_DEBUGGER=3
MENU_VSCODE_DEBUGGER=4
MENU_CHOOSE_PACKAGE_FOR_ATTACH=5
MENU_CHOOSE_EXECUTABLE_FOR_ATTACH=6
MENU_CHOOSE_PROCESS_FOR_ATTACH=7
MENU_RUN_PROJECT=8
MENU_USE_LAUNCH_FILE=9
MENU_CHOOSE_PACKAGE_WITH_LAUNCH_FILE=10
MENU_CHOOSE_PACKAGE=11
MENU_RUN_ROS2_WITH_EXECUTABLE=12
MENU_CHOOSE_LAUNCH_FILE=13
MENU_CHOOSE_NODE=14
MENU_RUN_DEBUGGER=15
MENU_BUILD_WITH_DEBUG_FLAGS=16
MENU_USE_PREVIOUS_LAUNCH_FILE=17
MENU_DEBUG_FROM_LAUNCH_OR_NODE=18


print_menu=()
print_menu[$MENU_FIRST_WINDOW]="MENU_FIRST_WINDOW"
print_menu[$MENU_WAS_BUILD_MADE_WITH_DEBUG_FLAGS]="MENU_WAS_BUILD_MADE_WITH_DEBUG_FLAGS"
print_menu[$MENU_BUILD]="MENU_BUILD"
print_menu[$MENU_CONFIG_DEBUGGER]="MENU_CONFIG_DEBUGGER"
print_menu[$MENU_VSCODE_DEBUGGER]="MENU_VSCODE_DEBUGGER"
print_menu[$MENU_CHOOSE_PACKAGE_FOR_ATTACH]="MENU_CHOOSE_PACKAGE_FOR_ATTACH"
print_menu[$MENU_CHOOSE_EXECUTABLE_FOR_ATTACH]="MENU_CHOOSE_EXECUTABLE_FOR_ATTACH"
print_menu[$MENU_CHOOSE_PROCESS_FOR_ATTACH]="MENU_CHOOSE_PROCESS_FOR_ATTACH"
print_menu[$MENU_RUN_PROJECT]="MENU_RUN_PROJECT"
print_menu[$MENU_USE_LAUNCH_FILE]="MENU_USE_LAUNCH_FILE"
print_menu[$MENU_CHOOSE_PACKAGE_WITH_LAUNCH_FILE]="MENU_CHOOSE_PACKAGE_WITH_LAUNCH_FILE"
print_menu[$MENU_CHOOSE_PACKAGE]="MENU_CHOOSE_PACKAGE"
print_menu[$MENU_RUN_ROS2_WITH_EXECUTABLE]="MENU_RUN_ROS2_WITH_EXECUTABLE"
print_menu[$MENU_CHOOSE_LAUNCH_FILE]="MENU_CHOOSE_LAUNCH_FILE"
print_menu[$MENU_CHOOSE_NODE]="MENU_CHOOSE_NODE"
print_menu[$MENU_RUN_DEBUGGER]="MENU_RUN_DEBUGGER"
print_menu[$MENU_BUILD_WITH_DEBUG_FLAGS]="MENU_BUILD_WITH_DEBUG_FLAGS"
print_menu[$MENU_USE_PREVIOUS_LAUNCH_FILE]="MENU_USE_PREVIOUS_LAUNCH_FILE"
print_menu[$MENU_DEBUG_FROM_LAUNCH_OR_NODE]="MENU_DEBUG_FROM_LAUNCH_OR_NODE"