from launch import LaunchDescription
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument

def generate_launch_description():


    b_node = Node (
        package='p7', 
        namespace='/',
        name='n7_no_gdb',
        output='screen',
        executable='n7',
    )

    a_node = Node (
        executable='n7',
        package='p7',
        namespace='/',
        output='screen',
        name='n7_with_gdb',
    )

    c_node = Node (
        executable='n5',
        package='p5',
        namespace='/',
        output='screen',
        name='n5_de_fora',
    )

    c_node1 = Node (
        executable='n5',
        package='p5',
        namespace='/',
        output='screen',
        name='n5_mais_poderoso',
    )

    c_node2 = Node (
        executable='n5',
        package='p5',
        namespace='/',
        output='screen',
        name='n5_de_fora2',
    )

    c_node3 = Node (
        executable='n5',
        package='p5',
        namespace='/',
        output='screen',
        name='n5_de_fora3',
    )




    d_node = Node (
        executable='n7_copy',
        package='p7',
        namespace='/',
        output='screen',
        name='n7_copy1',
    )

    e_node = Node (
        executable='n7_copy2',
        package='p7',
        namespace='/',
        output='screen',
        name='n7_copy2',
    )

    f_node = Node (
        executable='n3',
        package='p3',
        namespace='/',
        output='screen',
        name='n3',
    )

    f_node1 = Node (
        executable='n3',
        package='p3',
        namespace='/',
        output='screen',
        name='n3_de_fora',
    )

    f_node2 = Node (
        executable='n3_copy',
        package='p3',
        namespace='/',
        output='screen',
        name='n3_copy',
    )

    f_node3 = Node (
        executable='n3_copy2',
        package='p3',
        namespace='/',
        output='screen',
        name='n3_copy2',
    )

    # grep -iroPh '(?<=<name>).*?(?=</name>)' './src' --include="package.xml" --exclude-dir={"micro_ros_setup","uros","examples"}


    b_launch_description = LaunchDescription()
    b_launch_description.add_action(b_node)
    b_launch_description.add_action(a_node)
    b_launch_description.add_action(c_node)
    b_launch_description.add_action(c_node1)
    b_launch_description.add_action(c_node2)
    b_launch_description.add_action(c_node3)
    b_launch_description.add_action(d_node)
    b_launch_description.add_action(e_node)
    b_launch_description.add_action(f_node)
    b_launch_description.add_action(f_node1)
    b_launch_description.add_action(f_node2)
    b_launch_description.add_action(f_node3)

    
    

    return b_launch_description