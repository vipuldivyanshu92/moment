#include "neuron.cuh"

/* Establishes a random value of synaptic current on the input
 * neurons. */
void input_random_current(Neuron *neurons) 
{
  int i, r;

  for (i=0; i < INNEURON; i++) {
    r = rand() % 10; // Assumes seeding has been done

    neurons[i].current = (r > 5) ? 5 : 0.0;
  }
}

/* Go through each neuron and update the membrane potential based on
 * the Izhikewich model. 

 * This is for a single iteration. */
__global__ void update_potential(Neuron *neurons, 
    Connection *connections, int number)
{
  float del_v, del_u, v, u, I;
              
  int offset = blockIdx.x * blockDim.x * blockDim.y + threadIdx.x;
  int cIdx;

  if (offset >= number) { 
    // There are no such neurons
    return;
  }

  v = neurons[offset].potential;
  u = neurons[offset].recovery;
  I = neurons[offset].current;

  if (v > IzTHRESHOLD) {
    neurons[offset].potential = IzC;
    neurons[offset].recovery = u + IzD;

    // Update the thalamic input on the next neuron.
    cIdx = neurons[offset].connection; 
    if (connections != NULL) {
      do {
        neurons[connections[cIdx].neuron].potential += \
                         v * connections[cIdx].weight;
        cIdx = connections[cIdx].next;
      } while (cIdx != 0);
    }
  } else {
    del_v = 0.04f*v*v + 5.0f*v + 140.0f - u + I;
    del_u = IzA * ( IzB*v - u);

    // Multiply by IzINCREMENT in this case is equivalent to
    // multipying with dx in a Taylor series expansion
    neurons[offset].potential = v + del_v * IzINCREMENT;
    neurons[offset].recovery  = u + del_u * IzINCREMENT;
  }
}
