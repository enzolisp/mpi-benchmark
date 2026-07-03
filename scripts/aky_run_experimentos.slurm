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
BUILD_DIR="$PROJECT_ROOT/build"
NODES_DIR="$PROJECT_ROOT/nodes"
RASTRO_OUT_DIR="$PROJECT_ROOT/rastro"

mkdir -p "$NODES_DIR" "$RASTRO_OUT_DIR"

export LD_PRELOAD=$HOME/.local/share/akypuera/build/libaky.so
export LD_LIBRARY_PATH=$HOME/.local/share/akypuera/build:$LD_LIBRARY_PATH

# Machinefile completo: uma linha por task alocada (96 linhas, 32 por nó)
MACHINEFILE="$NODES_DIR/nodes.$SLURM_JOB_ID"
srun -l hostname | sort -n | awk '{print $2}' > "$MACHINEFILE"

# Lista de hostnames únicos (um por nó, na ordem de alocação)
HOSTLIST="$NODES_DIR/hosts.$SLURM_JOB_ID"
awk '!seen[$0]++' "$MACHINEFILE" > "$HOSTLIST"

MATRIX_SIZES="1024 2048 4096"
PROGRAMS="mpi_coletiva mpi_p2p_bloqueante mpi_p2p_naobloqueante"
NODE_COUNTS="1 2 3"
PROCS_PER_NODE="1 2 4 8 16 32"

for num_nodes in $NODE_COUNTS; do
  # Machinefile intercalado: hype1, hype2, hype3, hype1, hype2, hype3, ...
  # Garante que mpirun -np N distribui round-robin entre os nós,
  # colocando exatamente pn processos por nó.
  NODE_MACHINEFILE="$NODES_DIR/nodes.${SLURM_JOB_ID}.n${num_nodes}"
  python3 -c "
hosts = open('$HOSTLIST').read().splitlines()[:$num_nodes]
slots = $SLURM_NTASKS_PER_NODE
print('\n'.join(h for _ in range(slots) for h in hosts))
" > "$NODE_MACHINEFILE"

  MPIRUN_OPTS=(-machinefile "$NODE_MACHINEFILE" --mca btl ^openib --mca btl_tcp_if_include eno2 --bind-to none)

  for prog in $PROGRAMS; do
    for n in $MATRIX_SIZES; do
      for pn in $PROCS_PER_NODE; do
        np=$(( num_nodes * pn ))

        RUN_DIR="$RASTRO_OUT_DIR/${SLURM_JOB_ID}_nodes${num_nodes}_${prog}_size${n}_nproc${np}"
        mkdir -p "$RUN_DIR"

        echo ">> Executando $prog n=$n np=$np (${pn}/no) nodes=$num_nodes"

        (cd "$RUN_DIR" && \
          LD_PRELOAD=$HOME/.local/share/akypuera/build/libaky.so:/usr/lib/x86_64-linux-gnu/libmpi.so \
          mpirun -np "$np" "${MPIRUN_OPTS[@]}" "$BUILD_DIR/$prog" "$n")
      done
    done
  done
done
