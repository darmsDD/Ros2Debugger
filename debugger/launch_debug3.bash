#!/bin/bash

# Script: launch_debug.bash
# Description: This script automatizates the configuration of a ros2 project in build or debug mode. 
# For the build option, the ros2 project is built and then ran with the correct launch file.
# For the debugger option, the user chooses if it wants to attach the debugger to a running process or
# launch the project and the debugger together. After choosing some options, the user should be able to choose the
# executable or process it wants to debug. The final option is the choice of debugging using vscode debugger extension or the terminal.
# Remember: if you choose the vscode debugger extension, you need to select the correct debugger option
#           before hitting the play. The options are: attach and launch.
# Author: 
# Date: 
# Usage: ./launch_debug.bash

. ./debug_init_variables_and_constants.bash # Initializes all the constants and variables.
. ./debug_define_functions.bash # Defines the functions to be used.
# Captures these signals to exit the program in a proper manner.
trap cleanup_and_exit SIGINT SIGTERM SIGTSTP EXIT 


build4(){
    was_debug_used=$NO
    use_gdb_debugger=$NO
    use_vscode_debugger=$NO
    was_ros2_launch_used=$NO
    #===================== Run or debug project menu =====================
    # Create menu in which the user chooses to run the project with or without the debugger
    # Without de debbuger, the project is just run.
    # With the debbuger, the user chooses a node from a launch file or a ros2 executable to debug
    create_menu $BUILD_OR_DEBUG_MENU "Run project without debugger" "Run project with debugger"
    case $choosen_item in
        $RUN_WITHOUT_DEBUGGER) run_project_without_debugger ;;
        $RUN_WITH_DEBUGGER)
            was_debug_used=$YES
                create_menu $BUILD_OR_DEBUG_MENU "Debug node from launch file" "Debug ros2 executable"
                ros2_launch_or_exec_option=$choosen_item
                    case $ros2_launch_or_exec_option in
                        $USE_LAUNCH_FILE)
                            choose_ros2_launch_file_for_debugger
                           ;; 
                        $RUN_SINGLE_EXECUTABLE) 
                                filter_packages
                                choose_a_package
                                choose_an_executable ;;
                        *) exit 0 ;;
                    esac
                        config_debugger
                        run_project_with_debugger
                        wait # is this wait needed?
    esac
}

build3(){
    # If the build was made with no debug flags, just run the project.
    if [[ $build_made_with_debug_flags -eq $NO ]]; then
        create_yes_no_menu $RUN_PROJECT_MENU
        [[ $go_to_next_menu -ne $YES ]] && return
        [[ $choosen_item -eq $YES ]] && run_project_without_debugger
        exit 0;
    fi
    [[ $build_made_with_debug_flags -ne $YES ]] && exit 0
    create_while_for_menu build4
}


build2(){
    case $choosen_build in
        0|1|2) build_project_command && [[ $choosen_build -eq 0 ]] && build_made_with_debug_flags=$NO || build_made_with_debug_flags=$YES ;;
        3) 
            create_yes_no_menu $DEBUG_BUILD_MADE_WITH_CORRECT_FLAGS
            build_made_with_debug_flags=$choosen_item ;;
        *) exit 0 ;;
    esac
    . "$ROS2_PROJECT_PATH/install/local_setup.bash"
    # save the names of all the packages (this is used by other functions later.)
    find_package_names
    # Builds the ros2 project with the correct flags and sources the project OR skips the build.
    # The procedure 
    create_while_for_menu build3
}



build1(){
    create_menu $BUILD_OR_DEBUG_MENU "${BUILD_OR_DEBUG_MENU_OPTIONS[@]}"
    [[ $go_to_next_menu -ne $YES ]] && return
    choosen_build_type="${TYPE_OF_BUILD[$choosen_item]}"
    choosen_build=$choosen_item
   for all builds are the same, the only thing that changes is the flag passsed to colcon build
    create_while_for_menu build2
}





attach1(){
    #Check if the user has built with the correct debug flags
    create_yes_no_menu $DEBUG_BUILD_MADE_WITH_CORRECT_FLAGS
    if [[ $choosen_item -eq $NO ]]; then
        message_box "For the debugger to work, you need to rebuild with debug flags. Such as: colcon build --cmake-args \"-DCMAKE_BUILD_TYPE=Debug\".\nClick ok to exit. "
        exit 0;
    fi
    find_package_names
    filter_packages_for_attach 
    create_package_executable_list
    choose_an_executable_for_attach
    find_nodes_and_choose_pid
    config_debugger
    [[ $use_gdb_debugger -eq $YES ]] && gdb -tui "$program_path" ${choosen_pid:+"$choosen_pid"}
}



#====================== Attach Debbuger or go to Build Menu================
second_main(){
        is_first_menu=$YES
        create_menu "$BUILD_OR_DEBUG_MENU" "Attach Debbuger to running process." "Go to build menu."
        is_first_menu=$NO
        was_attach_used=$choosen_item
        case $was_attach_used in
            $YES)
                #============= Attach ===============================
                . "$ROS2_PROJECT_PATH/install/local_setup.bash"
                create_while_for_menu attach1;;
            $NO)
                #============ Build menu ===========================
                BUILD_OR_DEBUG_MENU_OPTIONS=("Build without debug (colcon build --symlink-install  --cmake-args \"-DCMAKE_BUILD_TYPE=Release\")" \
                "Build with all debug options (colcon build --symlink-install  --cmake-args \"-DCMAKE_BUILD_TYPE=Debug\")" \
                "Build with some debug options (colcon build --symlink-install  --cmake-args \"-DCMAKE_BUILD_TYPE=RelWithDebInfo\")" \
                "Skip build (I have already built the ROS2 project)")
                create_while_for_menu build1
        esac
}

go_to_next_menu=0
create_while_for_menu second_main


