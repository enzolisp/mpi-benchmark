#!/bin/bash
#SBATCH --job-name=mpi-benchmark
#SBATCH --partition=hype
#SBATCH --nodes=2
#SBATCH --ntasks=32
#SBATCH --time=2:00:00
#SBATCH --output=output/%x_%j.out
#SBATCH --error=output/%x_%j.err

PROJECT_ROOT="$SLURM_SUBMIT_DIR"
RESULTS_DIR="$PROJECT_ROOT/results"
BUILD_DIR="$PROJECT_ROOT/build"
NODES_DIR="$PROJECT_ROOT/nodes"
mkdir -p $RESULTS_DIR

export LD_PRELOAD=$HOME/.local/share/akypuera/build/libaky.so
export LD_LIBRARY_PATH=$HOME/.local/share/akypuera/build:$LD_LIBRARY_PATH

mkdir -p $NODES_DIR
MACHINEFILE="$NODES_DIR/nodes.$SLURM_JOB_ID"
srun -l hostname | sort -n | awk '{print $2}' > $MACHINEFILE

MATRIX_SIZES="512 1024 2048 4096"
PROC_COUNTS="1 2 4 8 16 32"
PROGRAMS="mpi_coletiva mpi_p2p_bloqueante mpi_p2p_naobloqueante"

RESULTS="$RESULTS_DIR/$SLURM_JOB_ID.csv"
echo "programa,n,num_processos,execucao,tempo_segundos" > $RESULTS

REPETICOES=3

RASTRO_OUT_DIR="$PROJECT_ROOT/rastro"
mkdir -p $RASTRO_OUT_DIR
cd $RASTRO_OUT_DIR

for prog in $PROGRAMS; do
  for n in $MATRIX_SIZES; do
    for np in $PROC_COUNTS; do
      for rep in $(seq 1 $REPETICOES); do
        echo ">> Executando $prog n=$n np=$np rep=$rep"
        OUT=$(LD_PRELOAD=$HOME/.local/share/akypuera/build/libaky.so:/usr/lib/x86_64-linux-gnu/libmpi.so \
		mpirun \
	       -np $np \
               -machinefile $MACHINEFILE \
               --mca btl ^openib \
               --mca btl_tcp_if_include eno2 \
               --bind-to none \
               /$BUILD_DIR/$prog $n)
        TEMPO=$(echo "$OUT" | grep "Execution time" | awk '{print $3}')
        echo "$prog,$n,$np,$rep,$TEMPO" >> $RESULTS
      done
    done
  done
done

echo "Resultados salvos em $RESULTS"
