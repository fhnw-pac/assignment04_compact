#include <iostream>
#include <sstream>
#include <stdlib.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

using namespace std;


/* This is our CUDA call wrapper, we will use in PAC.
*
*  Almost all CUDA calls should be wrapped with this makro.
*  Errors from these calls will be catched and printed on the console.
*  If an error appears, the program will terminate.
*
* Example: gpuErrCheck(cudaMalloc(&deviceA, N * sizeof(int)));
*          gpuErrCheck(cudaMemcpy(deviceA, hostA, N * sizeof(int), cudaMemcpyHostToDevice));
*/
#define gpuErrCheck(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char* file, int line, bool abort = true)
{
	if (code != cudaSuccess)
	{
		std::cout << "GPUassert: " << cudaGetErrorString(code) << " " << file << " " << line << std::endl;
		if (abort)
		{
			exit(code);
		}
	}
}


// Compare result vectors
int compareResultVec(int* vectorCPU, int* vectorGPU, int size)
{
	int error = 0;
	for (int i = 0; i < size; i++)
	{
		error += abs(vectorCPU[i] - vectorGPU[i]);
	}
	if (error == 0)
	{
		cout << "No errors. All good!" << endl;
		return 0;
	}
	else
	{
		cout << "Accumulated error: " << error << endl;
		return -1;
	}
}


// Very inefficient way to check if a number is prime
// Use Baillie–PSW primality test or ECPP if you want to do it right :)
bool isPrime(int n)
{
	if (n == 2 || n == 3)
		return true;

	if (n <= 1 || n % 2 == 0 || n % 3 == 0)
		return false;

	for (int i = 5; i * i <= n; i += 6)
	{
		if (n % i == 0 || n % (i + 2) == 0)
			return false;
	}

	return true;
}


//CPU implementation of compact pattern, returns number of found prime values.
int compact_prime(int* input, int* output, int size)
{
	int current_pos = 0;
	for (int i = 0; i < size; ++i)
	{
		int foo = input[i];
		if (isPrime(foo)) {
			output[current_pos] = input[i];
			current_pos += 1;
		}
	}
	return current_pos;
}


int main(void)
{
	// Define the size of the vector
	const int size = 1 << 22;
	// This gives you 2048 * 2048 items,
	// sounds like a perfect 2 stage fit for the sum scan implementation

	// Allocate and prepare input vector
	int* hostVector = new int[size];
	srand(1337);  // We have the same pseudo-random numbers each time
	for (int index = 0; index < size; ++index) {
		hostVector[index] = rand();
	}

	// Make things easy, so use a same sized output buffer
	int* hostOutput_CPU = new int[size];
	int found_primes = compact_prime(hostVector, hostOutput_CPU, size);
	cout << "Found " << found_primes << "prime numbers." << endl;

	// ToDo: Implement compact pattern on GPU, you can use var found_primes
	// to allocate the right size or to only loop/check what is needed in 
	// comparing the results (in case of an in-place implementation).

	// Free memory on device & host
	delete[] hostVector;
	delete[] hostOutput_CPU;

	return 0;
}