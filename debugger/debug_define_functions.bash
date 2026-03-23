# !/bin/bash


#========================================Functions================================================================

#===================== Rewrite this functions to your own needs ================================
# called to build the ros2 project
user_defined_build_command() {
    cd "$ROS2_PROJECT_PATH/scripts" && ./main.sh "${TYPE_OF_BUILD[$choosen_item]}" $ONLY_BUILD
}
# called to run the ros2 project
user_defined_run_project_command() {
    cd "$ROS2_PROJECT_PATH/scripts" && ./run_project.sh
}

#==================================================================================================


# Description:  Creates a menu using whiptail.
#
# Args: 1- the index of the WHIPTAIL_MESSAGE to be shown in the modal. All the messages can be checked in the debug_variables.bash file.
#       2- List of options to be shown in the menu.
create_menu(){
    # get array and option from the arguments passed
    local menu_list=()
    local which_menu="$1"    # take the first argument
    shift               # remove the first argument from the list of arguments
    local list=("$@") # take the rest of the arguments. In this case, the list of options to be used in the menu.
    # create a list in the format that whiptail expects that is [id] [name], example "1 my_package"
    for i in "${!list[@]}"; do
        menu_list+=( "$((i+1))" "${list[$i]}" )
    done
    if [[ ${#menu_list[@]} -eq 0 ]]; then
        return_to_previous_menu=$YES
        message_box "No option was found for \"${WHIPTAIL_MESSAGE[$which_menu]}\". Returning to previous menu."
        return
    fi
    
    # create whiptail menu
    # whiptail outputs to descriptor 2 (which is stderr normally), so we create a third descriptor and chance things
    # 0: stdin, 1: stdout, 2: stderr
    # 1- Create a third descriptor and make it point to stdout. 1: stdout, 2: stderr ,3:stdout
    # 2- Now make the descriptor 1 (stdout) point to descriptor 2 (stderr).1: stderr, 2: stderr ,3:stdout 
    # 3- Finally point the descriptor 2 (stderr) to descriptor 3(now stdout). 1: stderr, 2: stdout ,3:stdout
    
    [[ $is_first_menu -eq $NO ]] && extra_button=(--extra-button --extra-label "Return")
    item=$(dialog --keep-tite --title "$whiptail_title" ${extra_button[@]} \
       --menu "${WHIPTAIL_MESSAGE[$which_menu]}" 0 0 0 "${menu_list[@]}" 3>&1 1>&2 2>&3)
    status=$?
    # item=$(whiptail --title "$whiptail_title" --menu "${WHIPTAIL_MESSAGE[$which_menu]}" 0 0 0 \
    # "${menu_list[@]}" \
    # 3>&1 1>&2 2>&3)
    # if cancel button is pressed, terminate the program.
    [[ $status -eq 1 ]] && exit 0
    [[ $status -eq 3 ]] && {
        return_to_previous_menu=$YES
        return
    }
    choosen_item=$((item - 1))
}

# Description: create a yes or no menu using whiptail.
# Args: 1- the index of the WHIPTAIL_MESSAGE to be shown in the modal. All the messages can be checked in the debug_variables.bash file.
#
create_yes_no_menu(){
    # create whiptail yes or no menu
    local which_menu="$1"
    dialog --keep-tite --title "$whiptail_title" --extra-button --extra-label "Return" \
       --yesno "${WHIPTAIL_MESSAGE[$which_menu]}" 0 0
    choosen_item=$?
    [[ $choosen_item -eq 3 ]] && {
        return_to_previous_menu=$YES
    }
}


filter_packages_for_attach(){
    list_of_packages_with_executables=()
    list_of_executables_with_running_processes=()
    index_for_package_executables=() # used to know where is the starting index of 
    filtered_packages=()
    filtered_executables=()
    previous_package=""
    # Removes packages which don't have executables and running processes.
    for i in "${!packages[@]}"
    do
        mapfile -t executables < <(ros2 pkg executables ${packages[$i]} | awk '{print$2}')
        if [[ ${#executables[@]} -gt 0 ]]; then
         
            single_package_filtered_executable_list=()
            for j in "${!executables[@]}"
            do
                
                pid_and_nodes_or_executables_names=$(ps -ef | awk -v pkg_name="${packages[$i]}" -v ex=${executables[$j]} -v was_ros2_launch_used=$was_ros2_launch_used '
                    $0 ~ pkg_name "/" ex "([[:space:]]|$)" {
                        pid = $2
                        if( pid == "" ){
                            exit;
                        }
                        else if ( was_ros2_launch_used == 0 ){
                            split($11, node_name, ":=");
                            print node_name[2], pid ;
                        } else {
                            print ex, pid;  
                        }
                    }')
                
                if [[ ! -z "$pid_and_nodes_or_executables_names" ]]; then
                    if [[ "${packages[$i]}" != "$previous_package" ]]; then
                        number_of_packages=${#filtered_packages[@]}
                        index_for_package_executables[$number_of_packages]=${#list_of_executables_with_running_processes[@]}
                        filtered_packages+=(${packages[$i]})
                        previous_package=${packages[$i]}
                    fi
                    single_package_filtered_executable_list+=(${executables[$j]})
                    list_of_executables_with_running_processes+=("${pid_and_nodes_or_executables_names[*]}")
                fi
                
                if [[ ${#executables[@]} -eq $((j+1)) && ${#single_package_filtered_executable_list[@]} -gt 0 ]]; then
                        filtered_executables+=("${single_package_filtered_executable_list[*]}")
                fi
               
            done
        fi
    done
}

update_package_info(){
    pkg_name=$1 
    pkg_dir="$(ros2 pkg prefix $pkg_name)" 
}

create_package_executable_list(){
    choosen_package_executable_list=(${filtered_executables[$choosen_package_index]})
    package_index=${index_for_package_executables[$choosen_package_index]}
}
set_an_executable_for_attach(){  
    # #===========Choose an Executable=======================
    set -x
    executable_name=${choosen_package_executable_list[$choosen_item]}
    current_index=$((package_index+choosen_item))
    pid_list="${list_of_executables_with_running_processes[$current_index]}"
    set +x
}

# Description: Every package can have 0 or more executables. This function allows the user to
#              select a package and then choose an executable from that package.
# Args: none.
# Details: Sets the global variables pkg_name, pkg_dir and executable_name.
filter_packages_without_executables(){
    #declare -A list_of_packages_with_executables
    list_of_packages_with_executables=()
    list_of_packages_that_have_executables=()
    # Removes packages which don't have executables.
    for i in "${!packages[@]}"
    do
        mapfile -t executables < <(ros2 pkg executables ${packages[$i]} | awk '{print$2}')
        if [[ ${#executables[@]} -gt 0 ]]; then
            list_of_packages_that_have_executables+=(${packages[$i]})
            list_of_packages_with_executables+=("${executables[*]}")
        fi
    done
}

edit_ros2_launch_file_for_debugger(){
    # remove the prefix if it already exists
    # add the prefix for the debugger in the node in the launch file.
    sed -i.$LAUNCH_FILE_NAME_TERMINATION \
    -e "/$PATTERN_TO_FIND_NODE_IN_LAUNCH_FILE/,/$prefix_pattern/ { /$prefix_pattern/d; }" \
    -e "/${nodes[$choosen_item]}$PATTERN_TO_FIND_NODE_IN_LAUNCH_FILE/a\prefix='gdbserver localhost:3000'," \
    "$launch_folder_path"
    # look for package and executable values of the choosen node
    # Basically we have to find the node and then after "Node(", find the first intances of executable and package
    # $0 ~ node_pattern {f=1}: if the whole line $0 matches the node_pattern, f=1
    # if f = 1 then search for executable and saves the name
    # same logic applies after
    # only when pkg and executable are not empty, we save the output (prints) and then exit
    package_and_executable=$(awk -F "['\"]" -v node_pattern="${nodes[$choosen_item]}$PATTERN_TO_FIND_NODE_IN_LAUNCH_FILE" '
                $0 ~ node_pattern {f=1}
                f && /package/ { pkg = $2 }
                f && /executable/ { exe = $2}
                f && pkg !="" && exe !="" {
                    print pkg;
                    print exe;
                    exit;
                }' $launch_folder_path)
    read -d ' ' temp_pkg_name executable_name <<< $package_and_executable
    update_package_info "$temp_pkg_name"    
    was_ros2_launch_used=$YES
}

# Description: Chooses a pid to attach the debbuger to. The list of pids is bases on the package_name
#              choosen previsouly and the executable name. If a launch file was used, the list contains the
#              nodes names instead of the executable name. 
# Args: none.
# Details: If a node in a launch file does not have the "name" field, this function will fail.
find_nodes(){
    nodes_or_executables=()
    pids=()
    while read -r node_or_exec pid; do
        nodes_or_executables+=("$node_or_exec")
        pids+=("$pid")
    done <<< $pid_list
}


# Description: Asks the user if they want to execute the command.
# Args: The command to be executed.
run_cmd(){
    WHIPTAIL_MESSAGE[$RUN_COMMAND_MENU]="Running the command [$*]. Do you want to continue?"
    create_yes_no_menu $RUN_COMMAND_MENU
    #read -p "${red}Running the command [$*]. Do you want to continue? [y/n]:${nocolor}" input
    if [[ $choosen_item -eq $YES ]]; then
        "$@"
    fi
}

# Description: Creates a modal with a simple message passed as an argument by the user.
# Args: 1- message to be displayed.
message_box(){
    dialog --keep-tite --title "$whiptail_title" --msgbox "$1" 0 0
}

# Description: Executes the necessary steps to finish the code in a clean manner.
# Args: None
cleanup_and_exit(){
    
    trap - SIGINT SIGTERM SIGTSTP EXIT
    # if [[ $was_debug_used -eq $YES ]] && [[ -f "$launch_folder_path.$LAUNCH_FILE_NAME_TERMINATION" ]]; then
    #     run_cmd cp "$launch_folder_path.$LAUNCH_FILE_NAME_TERMINATION" "$launch_folder_path"
    # fi
    message_box "Terminating the program."
    exit 0
}



filter_packages_without_launch_file(){
    list_of_packages_with_launch_files=()
    list_of_packages_that_have_launch_files=()
    # Removes packages which don't have launch files.
    for i in "${!packages[@]}"
    do
        mapfile -t pkg_launch_files < <(find "$ROS2_PROJECT_PATH/install/${packages[$i]}/share/${packages[$i]}/launch/" -type f -regex '.*launch.\(py\|xml\|yaml\)' 2>/dev/null)
        if [[ ${#pkg_launch_files[@]} -gt 0 ]]; then
            list_of_packages_that_have_launch_files+=(${packages[$i]})
            list_of_packages_with_launch_files+=("${pkg_launch_files[*]}")
        fi
    done
}

set_ros2_launch_vars(){
    launch_folder_path="${choosen_package_with_launch_files[$choosen_item]}"
    launch_file_name=$(basename $launch_folder_path)
}

run_ros2_with_launch_file(){
    ros2 launch $launch_package $launch_file_name 
}


## Rewrite this function with your correct build method
build_project_command(){
    case $STANDARD_BUILD in
        $YES) cd $ROS2_PROJECT_PATH && colcon build --cmake-args "-DCMAKE_BUILD_TYPE=$choosen_build_type";;
        $NO) user_defined_build_command;;
        *) exit 0;; 
    esac
    
}

choose_a_vscode_debugger_file(){
     # These conditions check if there are more than one file called "launch_file_to_be_used_by_debugger.json".
            # If there are, allows the user to choose one.
    if [[ $NUMBER_OF_DEBUGGER_LAUNCH_FILES -gt 1 ]]; then
        mapfile -t debugger_launch_files < <(echo "$ORIGINAL_DEBUGGER_LAUNCH_PATH")
        create_menu $BUILD_OR_DEBUG_MENU "${debugger_launch_files[@]}"
        ORIGINAL_DEBUGGER_LAUNCH_PATH="${debugger_launch_files[$choosen_item]}"
    elif [[ $NUMBER_OF_DEBUGGER_LAUNCH_FILES -lt 1 ]]; then
        message_box "The launch file for the vscode debugger was not found.\nClick ok to exit. "
        exit 0;
    fi
}

find_package_names(){
    mapfile -t packages < <(grep -iroPh '(?<=<name>).*?(?=</name>)' "$ROS2_PROJECT_PATH/src" --include="package.xml" --exclude-dir={"micro_ros_setup","uros","examples"} | sort)
}