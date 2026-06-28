#!/bin/bash

MATRIX_SIZES="512 1024 2048 4096"
PROC_COUNTS="1 2 4 8"
PROGRAMS="mpi_coletiva mpi_p2p_bloqueante mpi_p2p_naobloqueante"
BUILD_DIR="build"

mkdir -p "results"
RESULTS="results/results.csv"
REPETICOES=3

echo "programa,n,num_processos,execucao,tempo_segundos" > $RESULTS
for prog in $PROGRAMS; do
  for n in $MATRIX_SIZES; do
    for np in $PROC_COUNTS; do
      for rep in $(seq 1 $REPETICOES); do
        echo ">> Executando $prog n=$n np=$np rep=$rep"
        OUT=$(mpirun -np $np \
               --mca btl self,sm,tcp \
               --bind-to none \
               --use-hwthread-cpus \
               ./$BUILD_DIR/$prog $n)
        TEMPO=$(echo "$OUT" | grep "Execution time" | awk '{print $3}')
        echo "$prog,$n,$np,$rep,$TEMPO" >> $RESULTS
      done
    done
  done
done

echo "Resultados salvos em $RESULTS"
