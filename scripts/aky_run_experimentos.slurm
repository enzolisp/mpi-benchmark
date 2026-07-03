#!/bin/bash
#SBATCH --job-name=mpi-benchmark
#SBATCH --partition=hype
#SBATCH --nodes=3
#SBATCH --ntasks=96
#SBATCH --ntasks-per-node=32
#SBATCH --time=24:00:00
#SBATCH --output=output/%x_%j.out
#SBATCH --error=output/%x_%j.err

PROJECT_ROOT="$SLURM_SUBMIT_DIR"
RESULTS_DIR="$PROJECT_ROOT/results"
BUILD_DIR="$PROJECT_ROOT/build"
NODES_DIR="$PROJECT_ROOT/nodes"
RASTRO_OUT_DIR="$PROJECT_ROOT/rastro"

mkdir -p "$RESULTS_DIR" "$NODES_DIR" "$RASTRO_OUT_DIR"

export LD_PRELOAD=$HOME/.local/share/akypuera/build/libaky.so
export LD_LIBRARY_PATH=$HOME/.local/share/akypuera/build:$LD_LIBRARY_PATH

MACHINEFILE="$NODES_DIR/nodes.$SLURM_JOB_ID"
srun -l hostname | sort -n | awk '{print $2}' > $MACHINEFILE

MATRIX_SIZES="1024 2048 4096"
PROC_COUNTS="1 2 4 8 16 32"
NODE_COUNTS="1 2 3"
PROGRAMS="mpi_coletiva mpi_p2p_bloqueante mpi_p2p_naobloqueante"

RESULTS="$RESULTS_DIR/$SLURM_JOB_ID.csv"
echo "programa,n,num_processos,num_nos,execucao,tempo_segundos" > "$RESULTS"

#REPETICOES=3

#cd "$RASTRO_OUT_DIR"

for num_nodes in $NODE_COUNTS; do
  # Gera machinefile com apenas os primeiros num_nodes nós da alocação
  NODE_MACHINEFILE="$NODES_DIR/nodes.${SLURM_JOB_ID}.n${num_nodes}"
  head -n $(( num_nodes * SLURM_NTASKS_PER_NODE )) "$MACHINEFILE" > "$NODE_MACHINEFILE"

  MPIRUN_OPTS=(-machinefile "$NODE_MACHINEFILE" --mca btl ^openib --mca btl_tcp_if_include eno2 --bind-to none)

  for prog in $PROGRAMS; do
    for n in $MATRIX_SIZES; do
      for np in $PROC_COUNTS; do
        #for rep in $(seq 1 $REPETICOES); do

	  # cria diretório dos rastros
	  RUN_DIR="$RASTRO_OUT_DIR/${SLURM_JOB_ID}_nodes${num_nodes}_${prog}_size${n}_nproc${np}"
	  mkdir -p $RUN_DIR
	  cd $RUN_DIR

          echo ">> Executando $prog n=$n np=$np nodes=$num_nodes"
          OUT=$(LD_PRELOAD=$HOME/.local/share/akypuera/build/libaky.so:/usr/lib/x86_64-linux-gnu/libmpi.so \
                mpirun -np "$np" "${MPIRUN_OPTS[@]}" "$BUILD_DIR/$prog" "$n")
          TEMPO=$(echo "$OUT" | grep "Execution time" | awk '{print $3}')
          #echo "$prog,$n,$np,$num_nodes,$rep,$TEMPO" >> "$RESULTS"
        #done
      done
    done
  done
done

#echo "Resultados salvos em $RESULTS"
