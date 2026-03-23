# !/bin/bash

. ./debug_init_variables_and_constants.bash # Initializes all the constants and variables.
. ./debug_define_functions.bash # Defines the functions to be used.
# Captures these signals to exit the program in a proper manner.
trap cleanup_and_exit SIGINT SIGTERM SIGTSTP EXIT 



update_menu_option(){
    menu_option=$1
}


menu_option=$MENU_FIRST_WINDOW
return_to_previous_menu=$NO
states=()
while true;
do
    if [[ $return_to_previous_menu -eq $YES ]]; then
        unset states[-1]
        menu_option=${states[@]:(-1)}
        # echo "I am on the return"
        # echo "${print_menu[$menu_option]})"
        # echo "=================="
    else 
        states+=($menu_option)
        # echo "${print_menu[$menu_option]})"
        # echo "=================="
    fi
    return_to_previous_menu=$NO
    case $menu_option in

        $MENU_FIRST_WINDOW) 
            is_first_menu=$YES
            create_menu "$BUILD_OR_DEBUG_MENU" "Attach Debbuger to running process." "Go to build menu."
            is_first_menu=$NO
            was_attach_used=$NO
            case $choosen_item in
                $BUILD) update_menu_option $MENU_BUILD;;
                $ATTACH) 
                    . "$ROS2_PROJECT_PATH/install/local_setup.bash"
                    find_package_names
                    update_menu_option $MENU_WAS_BUILD_MADE_WITH_DEBUG_FLAGS
                    was_attach_used=$YES;;
                *) exit 0;;
            esac  
        ;;
        $MENU_BUILD)
            create_menu $BUILD_OR_DEBUG_MENU "${BUILD_OR_DEBUG_MENU_OPTIONS[@]}"
            [[ $return_to_previous_menu -eq $YES ]] && continue
            choosen_build_type="${TYPE_OF_BUILD[$choosen_item]}"
            case $choosen_item in
                    0|1|2) build_project_command && [[ $choosen_item -eq 0 ]] && update_menu_option $MENU_RUN_PROJECT || update_menu_option $MENU_BUILD_WITH_DEBUG_FLAGS ;;
                    3) update_menu_option $MENU_WAS_BUILD_MADE_WITH_DEBUG_FLAGS;;
                    *) exit 0 ;;
            esac
            . "$ROS2_PROJECT_PATH/install/local_setup.bash"
            find_package_names
        ;;
        $MENU_WAS_BUILD_MADE_WITH_DEBUG_FLAGS)
            create_yes_no_menu $DEBUG_BUILD_MADE_WITH_CORRECT_FLAGS
            [[ $return_to_previous_menu -eq $YES ]] && continue
            build_made_with_debug_flags=$choosen_item
            case $was_attach_used in
                $YES)
                    if [[ $build_made_with_debug_flags -eq $NO ]]; then
                            message_box "For the debugger to work, you need to rebuild with debug flags. Such as: colcon build --cmake-args \"-DCMAKE_BUILD_TYPE=Debug\".\nClick ok to exit. "
                            exit 0;
                    fi
                    filter_packages_for_attach
                    update_menu_option $MENU_CHOOSE_PACKAGE_FOR_ATTACH ;;
                $NO) [[ $build_made_with_debug_flags -eq $NO ]] && update_menu_option $MENU_RUN_PROJECT || update_menu_option $MENU_BUILD_WITH_DEBUG_FLAGS;;
                *)exit 0;;
            esac
        ;;
        $MENU_RUN_PROJECT)
            create_yes_no_menu $RUN_PROJECT_MENU
            [[ $return_to_previous_menu -eq $YES ]] && continue
            [[ $choosen_item -eq $NO ]] && exit 0
            case $STANDARD_RUN in
                $YES)update_menu_option $MENU_USE_LAUNCH_FILE;;    
                $NO) user_defined_run_project_command    ;;
                *) exit 0;;
            esac
        ;;

        $MENU_USE_LAUNCH_FILE)
            create_yes_no_menu $USE_LAUNCH_MENU
            [[ $return_to_previous_menu -eq $YES ]] && continue
            if [[ $choosen_item -eq $YES ]]; then
                filter_packages_without_launch_file 
                update_menu_option $MENU_CHOOSE_PACKAGE_WITH_LAUNCH_FILE
                execute_launch=$YES
            else
                filter_packages_without_executables
                update_menu_option $MENU_CHOOSE_PACKAGE
            fi
        ;;

        $MENU_CHOOSE_PACKAGE_WITH_LAUNCH_FILE)
            create_menu $CHOOSE_ROS2_PACKAGE_WITH_LAUNCH_FILE "${list_of_packages_that_have_launch_files[@]}"
            [[ $return_to_previous_menu -eq $YES ]] && continue
            launch_package="${list_of_packages_that_have_launch_files[$choosen_item]}"
            choosen_package_with_launch_files=(${list_of_packages_with_launch_files[$choosen_item]})
            update_menu_option $MENU_CHOOSE_LAUNCH_FILE
        ;;

        $MENU_CHOOSE_LAUNCH_FILE)
            create_menu $CHOOSE_ROS2_LAUNCH_FILE "${choosen_package_with_launch_files[@]}"
            [[ $return_to_previous_menu -eq $YES ]] && continue
            set_ros2_launch_vars 
            case $execute_launch in
                $YES) run_ros2_with_launch_file && exit 0;;
                $NO)  update_menu_option $MENU_CHOOSE_NODE;;
                *)exit 0;;
            esac 
        ;;

        $MENU_CHOOSE_NODE)
            mapfile -t nodes < <(grep -oP '^\s*\K\w+(?=\s*=\s*Node\s*\()' $launch_folder_path)
            create_menu $DEBUG_NODE_MENU "${nodes[@]}"
            [[ $return_to_previous_menu -eq $YES ]] && continue
            edit_ros2_launch_file_for_debugger
            update_menu_option $MENU_CONFIG_DEBUGGER
        ;;

        $MENU_RUN_DEBUGGER)
            if [[ $use_gdb_debugger -eq $YES ]]; then            
                [[ $was_attach_used -eq $YES ]] && { 
                    [[ -z "$choosen_pid" ]] && sudo gdb -tui --pid="$choosen_pid" "$program_path" 
                } || gdb -tui "$program_path" 
                exit 0
            fi
            [[ $was_ros2_launch_used -eq $NO ]] && { ros2 run --prefix "gdbserver localhost:3000" $pkg_name $executable_name; exit 0; }
            case $STANDARD_RUN in
                $YES) update_menu_option $MENU_USE_PREVIOUS_LAUNCH_FILE;;
                $NO) user_defined_run_project_command ;;
                *) exit 0;;
            esac
        ;;

        $MENU_USE_PREVIOUS_LAUNCH_FILE)
            WHIPTAIL_MESSAGE[$DEBUG_LAUNCH_FILES_MENU]="Run project with the previous launch file?:$launch_folder_path" 
            create_yes_no_menu $DEBUG_LAUNCH_FILES_MENU
            [[ $return_to_previous_menu -eq $YES ]] && continue
            if [[ $choosen_item -eq $NO ]]; then 
                update_menu_option $MENU_CHOOSE_PACKAGE_WITH_LAUNCH_FILE
                execute_launch=$YES
            else  
                run_ros2_with_launch_file 
                exit 0
            fi
            
        ;;

        $MENU_CHOOSE_PACKAGE)
            create_menu $DEBUG_PACKAGE_MENU "${list_of_packages_that_have_executables[@]}"
            [[ $return_to_previous_menu -eq $YES ]] && continue
            update_package_info "${list_of_packages_that_have_executables[$choosen_item]}"
            choosen_package=(${list_of_packages_with_executables[$choosen_item]})
            update_menu_option $MENU_RUN_ROS2_WITH_EXECUTABLE
        ;;
        $MENU_RUN_ROS2_WITH_EXECUTABLE)
            create_menu $DEBUG_EXECUTABLE_MENU "${choosen_package[@]}"
            [[ $return_to_previous_menu -eq $YES ]] && continue
            executable_name=${choosen_package[$choosen_item]}
            if [[ $was_debug_used -eq $YES ]]; then 
                update_menu_option $MENU_CONFIG_DEBUGGER
            else
                ros2 run $pkg_name $executable_name
                 exit 0
            fi
        ;;

        $MENU_BUILD_WITH_DEBUG_FLAGS)
            was_debug_used=$NO
            use_gdb_debugger=$NO
            use_vscode_debugger=$NO
            was_ros2_launch_used=$NO
            #===================== Run or debug project menu =====================
            # Create menu in which the user chooses to run the project with or without the debugger
            # Without de debbuger, the project is just run.
            # With the debbuger, the user chooses a node from a launch file or a ros2 executable to debug
            create_menu $BUILD_OR_DEBUG_MENU "Run project without debugger" "Run project with debugger"
             [[ $return_to_previous_menu -eq $YES ]] && continue
            case $choosen_item in
                $RUN_WITHOUT_DEBUGGER) 
                update_menu_option $MENU_USE_LAUNCH_FILE ;;
                $RUN_WITH_DEBUGGER)
                    update_menu_option $MENU_DEBUG_FROM_LAUNCH_OR_NODE 
                    was_debug_used=$YES;;
                *) exit 0;;
            esac

        ;;

        $MENU_DEBUG_FROM_LAUNCH_OR_NODE)
            create_menu $BUILD_OR_DEBUG_MENU "Debug node from launch file" "Debug ros2 executable"
            [[ $return_to_previous_menu -eq $YES ]] && continue
            ros2_launch_or_exec_option=$choosen_item
            case $ros2_launch_or_exec_option in
                $USE_LAUNCH_FILE)
                    filter_packages_without_launch_file 
                    update_menu_option $MENU_CHOOSE_PACKAGE_WITH_LAUNCH_FILE
                    execute_launch=$NO
                    ;;
                $RUN_SINGLE_EXECUTABLE) 
                    filter_packages_without_executables
                    update_menu_option $MENU_CHOOSE_PACKAGE;;
                *) exit 0 ;;
            esac
        ;;
        $MENU_CHOOSE_PACKAGE_FOR_ATTACH)
            create_menu $DEBUG_PACKAGE_MENU "${filtered_packages[@]}"
            [[ $return_to_previous_menu -eq $YES ]] && continue
            choosen_package_index=$choosen_item
            temp_pkg_name="${filtered_packages[$choosen_package_index]}"
            update_package_info "$temp_pkg_name"
            create_package_executable_list
            update_menu_option $MENU_CHOOSE_EXECUTABLE_FOR_ATTACH
        ;;
        $MENU_CHOOSE_EXECUTABLE_FOR_ATTACH)
            create_menu $DEBUG_EXECUTABLE_MENU "${choosen_package_executable_list[@]}"
            [[ $return_to_previous_menu -eq $YES ]] && continue
            set_an_executable_for_attach
            find_nodes
            update_menu_option $MENU_CHOOSE_PROCESS_FOR_ATTACH
        ;;

        $MENU_CHOOSE_PROCESS_FOR_ATTACH)
            create_menu $CHOOSE_A_PROCESS_MENU "${nodes_or_executables[@]}"
            [[ $return_to_previous_menu -eq $YES ]] && continue
            choosen_pid="${pids[$choosen_item]}"
            update_menu_option $MENU_CONFIG_DEBUGGER

        ;;

        $MENU_CONFIG_DEBUGGER)
            program_path="$pkg_dir/lib/$pkg_name/$executable_name"
            use_vscode_debugger=$NO #reset value if user returns the page
            use_gdb_debugger=$NO
            create_menu "$DEBUG_VSCODE_OR_GDB_MENU" "${DEBUGGERS[@]}"
            [[ $return_to_previous_menu -eq $YES ]] && continue
            case $choosen_item in
                $GDB_DEBUGGER) 
                    use_gdb_debugger=$YES
                    update_menu_option $MENU_RUN_DEBUGGER;;
                $VSCODE_DEBUGGER)
                    update_menu_option $MENU_VSCODE_DEBUGGER;;
                *) exit 0 ;;
            esac
        ;;
        $MENU_VSCODE_DEBUGGER)
            use_vscode_debugger=$YES
            choose_a_vscode_debugger_file # This might will only create a window if it finds more than one debugger file
            [[ $return_to_previous_menu -eq $YES ]] && continue
            # Creates the .vscode folder if it does not exist and then copy the launch.json file used by the debugger to the .vscode folder.
            # If a launch.json already exists, it creates a backup called "launch.json~".
            mkdir -p $REPO_ORIGIN_PATH/.vscode && cp -b $ORIGINAL_DEBUGGER_LAUNCH_PATH $VSCODE_LAUNCH_PATH
            #edit the .vscode/launch.json with the correct path of the choosen node and then starts the debugger
            sed -i.$LAUNCH_FILE_NAME_TERMINATION 's|"processId": .*$|"processId": "'"$choosen_pid"'",|; s|"program": .*$|"program": "'"$program_path"'",|' $VSCODE_LAUNCH_PATH
            [[ $was_attach_used -eq $YES ]] && exit 0 || update_menu_option $MENU_RUN_DEBUGGER
        ;;
        *) exit 0;;
    esac
done








