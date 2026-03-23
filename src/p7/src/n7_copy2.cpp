#include <cstdio>
#include <unistd.h>
int main(int argc, char ** argv)
{
  (void) argc;
  (void) argv;

 printf("hello world n7 copy2 package\n");
  for (int i=0;i<1000;i++){
    printf("i=%d\n",i);
    sleep(1);
  }
  return 0;
}
