#include <stdlib.h>
#include <stdio.h>

#include "cuda_utils.h"
#include "timer.c"

typedef float dtype;


__global__ 
void matTrans(dtype* AT, dtype* A, int N)  {
	/* Fill your code here */	
//	AT[N*blockIdx.x + threadIdx.x] = A[N*threadIdx.x + blockIdx.x];
	AT[N*blockIdx.x + threadIdx.x] = 1.0;	
}

void
parseArg (int argc, char** argv, int* N)
{
	if(argc == 2) {
		*N = atoi (argv[1]);
		assert (*N > 0);
	} else {
		fprintf (stderr, "usage: %s <N>\n", argv[0]);
		exit (EXIT_FAILURE);
	}
}


void
initArr (dtype* in, int N)
{
	int i;

	for(i = 0; i < N; i++) {
//		in[i] = (dtype) rand () / RAND_MAX;
		in[i] = (dtype) i*1.0;
	}
}

void
cpuTranspose (dtype* A, dtype* AT, int N)
{
	int i, j;

	for(i = 0; i < N; i++) {
		for(j = 0; j < N; j++) {
			AT[j * N + i] = A[i * N + j];
		}
	}
}

int
cmpArr (dtype* a, dtype* b, int N)
{
	int cnt, i;

	cnt = 0;
	for(i = 0; i < N; i++) {
		if(abs(a[i] - b[i]) > 1e-6) cnt++;
	}

	return cnt;
}



void
gpuTranspose (dtype* A, dtype* AT, int N)
{
	printf("HELLLOEO\n\n\n\n");
	printf("test = %f\n", A[1]);
	/* Timer */
 	struct stopwatch_t* timer = NULL;
	long double t_gpu;

	/* data structure */
	dtype *d_idata, *d_odata;
	dtype *h_odata;

	/* Host allocation */
	h_odata = (dtype*) malloc(N*N*sizeof(dtype));
	
 	/* Setup timers */
 	stopwatch_init ();
 	timer = stopwatch_create ();

	/* allocate memory */
	CUDA_CHECK_ERROR(cudaMalloc(&d_idata, N*N*sizeof(dtype)));
	CUDA_CHECK_ERROR(cudaMalloc(&d_odata, N*N*sizeof(dtype)));


	/* Copy array */
	CUDA_CHECK_ERROR(cudaMemcpy(d_idata, A, N*N*sizeof(dtype), cudaMemcpyHostToDevice));

	/* Warm up */
	matTrans<<<N, N>>>(d_odata, d_idata, N);  	
	cudaThreadSynchronize();
	
 	stopwatch_start (timer);
	/* run your kernel here */
	matTrans<<<N, N>>>(d_odata, d_idata, N);

 	cudaThreadSynchronize ();
 	t_gpu = stopwatch_stop (timer);
 	fprintf (stderr, "GPU transpose: %Lg secs ==> %Lg billion elements/second\n", t_gpu, (N * N) / t_gpu * 1e-9 );

	/* Copy Result back from GPU */
	CUDA_CHECK_ERROR(cudaMemcpy(&h_odata, d_odata, N*N*sizeof(dtype), cudaMemcpyDeviceToHost));
	printf("\ntest2 = %f \n", h_odata[0]);	
}

int 
main(int argc, char** argv)
{
  /* variables */
	dtype *A, *ATgpu, *ATcpu;
  int err;

	int N;

  struct stopwatch_t* timer = NULL;
  long double t_cpu;


	N = -1;
	parseArg (argc, argv, &N);

  /* input and output matrices on host */
  /* output */
  ATcpu = (dtype*) malloc (N * N * sizeof (dtype));
  ATgpu = (dtype*) malloc (N * N * sizeof (dtype));

  /* input */
  A = (dtype*) malloc (N * N * sizeof (dtype));

	initArr (A, N * N);

	/* GPU transpose kernel */
	gpuTranspose (A, ATgpu, N);

  /* Setup timers */
  stopwatch_init ();
  timer = stopwatch_create ();

	stopwatch_start (timer);
  /* compute reference array */
	cpuTranspose (A, ATcpu, N);
  t_cpu = stopwatch_stop (timer);
  fprintf (stderr, "Time to execute CPU transpose kernel: %Lg secs\n",
           t_cpu);

  /* check correctness */
	err = cmpArr (ATgpu, ATcpu, N * N);
	if(err) {
		fprintf (stderr, "Transpose failed: %d\n", err);
	} else {
		fprintf (stderr, "Transpose successful\n");
	}

	printf("\nOriginal\n");
	for(unsigned int i=0;i<N*N;i++){
		printf(" %f ", A[i]);
		if((i+1) % N == 0){
			printf("\n");
		}
	}	
	printf("\nGPU\n");
	for(unsigned int i=0;i<N*N;i++){
		printf(" %f ", ATgpu[i]);
		if((i+1) % N == 0){
			printf("\n");
		}
	}
	printf("\nCPU\n");
	for(unsigned int i=0;i<N*N;i++){
		printf(" %f ", ATcpu[i]);
		if((i+1) % N == 0){
			printf("\n");
		}
	}
	


	free (A);
	free (ATgpu);
	free (ATcpu);

  return 0;
}
