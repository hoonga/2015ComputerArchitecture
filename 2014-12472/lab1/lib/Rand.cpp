#include <cstdlib>

extern "C" {
  
  void setSeed(unsigned int seed) {
    srand(seed);
  }
  unsigned int getRandom() {
    int sign = rand()%2;
    int val = rand();
    return (unsigned int) (val | sign << 31);
  }
}
