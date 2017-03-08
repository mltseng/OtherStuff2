SHELL:=/bin/bash
init:
	module load cuda/5.0
	module load gcc/4.4.3

stride:
	nvcc stride.cu timer.c -o stride

sequ:
	nvcc sequential.cu timer.c -o sequential

naive:	
	nvcc naive.cu timer.c -o naive

fadd:
	nvcc first_add.cu timer.c -o first_add
