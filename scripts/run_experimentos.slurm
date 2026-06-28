#!/bin/bash
#SBATCH --job-name=mpi_experimentos
#SBATCH --partition=hype
#SBATCH --nodes=2
#SBATCH --ntasks=32
#SBATCH --time=2:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

# make all

RESULTS_DIR="../results"

MACHINEFILE="nodes.$SLURM_JOB_ID"
srun -l hostname | sort -n | awk '{print $2}' > $MACHINEFILE

MATRIX_SIZES="512 1024 2048 4096"
PROC_COUNTS="1 2 4 8 16 32"
PROGRAMS="mpi_coletiva mpi_p2p_bloqueante mpi_p2p_naobloqueante"

RESULTS="../results/$SLURM_JOB_ID.csv"
echo "programa,n,num_processos,execucao,tempo_segundos" > $RESULTS

REPETICOES=3

for prog in $PROGRAMS; do
  for n in $MATRIX_SIZES; do
    for np in $PROC_COUNTS; do
      for rep in $(seq 1 $REPETICOES); do
        echo ">> Executando $prog n=$n np=$np rep=$rep"
        OUT=$(mpirun -np $np \
               -machinefile $MACHINEFILE \
               --mca btl ^openib \
               --mca btl_tcp_if_include eno2 \
               --bind-to none \
               ./$(RESULTS_DIR)/$prog $n)
        TEMPO=$(echo "$OUT" | grep "Execution time" | awk '{print $3}')
        echo "$prog,$n,$np,$rep,$TEMPO" >> $RESULTS
      done
    done
  done
done

echo "Resultados salvos em $RESULTS"
