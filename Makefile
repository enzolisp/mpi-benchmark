# Makefile for MPI Matrix Multiplication

SRC_DIR=src
BUILD_DIR=build
RESULTS_DIR=results

all: #mpi_coletiva mpi_p2p_bloqueante mpi_p2p_naobloqueante
	mkdir -p $(BUILD_DIR)
	mpicc $(SRC_DIR)/mpi_coletiva.c -o $(BUILD_DIR)/mpi_coletiva
	mpicc $(SRC_DIR)/mpi_p2p_bloqueante.c -o $(BUILD_DIR)/mpi_p2p_bloqueante
	mpicc $(SRC_DIR)/mpi_p2p_naobloqueante.c -o $(BUILD_DIR)/mpi_p2p_naobloqueante

clean:
	rm -rf $(BUILD_DIR)

clean-results:
	rm -rf $(RESULTS_DIR)
