#include <cstdio>
#include <stdlib.h>
#include<iostream>
#include<unistd.h>
int main(int argc, char ** argv)
{


    // int* p = nullptr;
   // *p = 42;   // dereferencing null → SIGSEGV
       system("pwd");
  printf("ola\n");
  printf("hello world my_package package\n");
  int b=55;
  int a = 37;
  printf("%d %d\n",a,b);
  for(int i=0;i<10;i++){sleep(1);}
  return 0;
}

/*
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
  
    "configurations": [ 
        {
            "name": "teste Launch",
            "type": "cppdbg",
            "args": ["abacaxi","arroz","${workspaceFolder}"],
            "request": "launch",
            "cwd": "${workspaceFolder}",
            "program": "${workspaceFolder}/prog",
           // "miDebuggerServerAddress": "localhost:3001",
            "MIMode": "gdb",
            "stopAtEntry": true,
        },
    {
        "name": "ros2 debugger",
        "type": "cppdbg",
        "request": "launch",
        "program": "${workspaceFolder}/install/my_package/lib/my_package/my_node",
        "cwd": "${workspaceFolder}",
        "stopAtEntry": true,
        "miDebuggerServerAddress": "localhost:3000",
        "MIMode": "gdb"
       
    }
    ]
}
    */