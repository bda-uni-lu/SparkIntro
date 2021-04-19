#!/bin/bash -l
#SBATCH -J bda-job
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=01:30:00
#SBATCH -p batch
#SBATCH -o %x-%j.log

### Load latest available Spark
module load devel/Spark

### If you do not wish tmp dirs to be cleaned
### at the job end, set below to 0
export SPARK_CLEAN_TEMP=1

### START INTERNAL CONFIGURATION

## CPU and Memory settings
export SPARK_WORKER_CORES=${SLURM_CPUS_PER_TASK}
export DAEMON_MEM=4096
export NODE_MEM=$((4096*${SLURM_CPUS_PER_TASK}-${DAEMON_MEM}))
export SPARK_DAEMON_MEMORY=${DAEMON_MEM}m
export SPARK_NODE_MEM=${NODE_MEM}m

## Set up job directories and environment variables
export BDA_HOME_DIR="$HOME/BDA2021"
export SPARK_JOB_DIR="$BDA_HOME_DIR/spark-jobs"
export SPARK_JOB="$BDA_HOME_DIR/spark-jobs/${SLURM_JOBID}"
mkdir -p "${SPARK_JOB}"

export SPARK_HOME=$EBROOTSPARK
export SPARK_WORKER_DIR=${SPARK_JOB}
export SPARK_LOCAL_DIRS=${SPARK_JOB}
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=9080
export SPARK_SLAVE_WEBUI_PORT=9081
export SPARK_INNER_LAUNCHER=${SPARK_JOB}/spark-start-all.sh
export SPARK_MASTER_FILE=${SPARK_JOB}/spark_master

export HADOOP_HOME_WARN_SUPPRESS=1
export HADOOP_ROOT_LOGGER="WARN,DRFA"

export SPARK_SUBMIT_OPTIONS="--conf spark.executor.memory=${SPARK_NODE_MEM} --conf spark.worker.memory=${SPARK_NODE_MEM}"


## Generate spark starter-script
cat << 'EOF' > ${SPARK_INNER_LAUNCHER}
#!/bin/bash
## Load configuration and environment
source "$SPARK_HOME/sbin/spark-config.sh"
source "$SPARK_HOME/bin/load-spark-env.sh"
if [[ ${SLURM_PROCID} -eq 0 ]]; then
    ## Start master in background
    export SPARK_MASTER_HOST=$(hostname)
    MASTER_NODE=$(scontrol show hostname ${SLURM_NODELIST} | head -n 1)

    echo "spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}" > "${SPARK_MASTER_FILE}"

    "${SPARK_HOME}/bin/spark-class" org.apache.spark.deploy.master.Master \
        --ip $SPARK_MASTER_HOST                                           \
        --port $SPARK_MASTER_PORT                                         \
        --webui-port $SPARK_MASTER_WEBUI_PORT &

    ## Start one slave with one less core than the others on this node
    export SPARK_WORKER_CORES=$((${SLURM_CPUS_PER_TASK}-1))
    "${SPARK_HOME}/bin/spark-class" org.apache.spark.deploy.worker.Worker \
       --webui-port ${SPARK_SLAVE_WEBUI_PORT}                             \
       spark://${MASTER_NODE}:${SPARK_MASTER_PORT} &

    ## Wait for background tasks to complete
    wait
else
    ## Start (pure) slave
    MASTER_NODE=spark://$(scontrol show hostname $SLURM_NODELIST | head -n 1):${SPARK_MASTER_PORT}
    "${SPARK_HOME}/bin/spark-class" org.apache.spark.deploy.worker.Worker \
       --webui-port ${SPARK_SLAVE_WEBUI_PORT}                             \
       ${MASTER_NODE}
fi
EOF
chmod +x ${SPARK_INNER_LAUNCHER}

## Launch SPARK and wait for it to start
srun ${SPARK_INNER_LAUNCHER} &
while [ -z "$MASTER" ]; do
	sleep 5
	MASTER=$(cat "${SPARK_MASTER_FILE}")
done
### END OF INTERNAL CONFIGURATION


### ACTUAL USER CODE EXECUTION STARTS HERE
OUTPUTFILE=${SLURM_JOB_NAME}-${SLURM_JOB_ID}.out
INPUTDIR="${BDA_HOME_DIR}/enwiki-articles/AA"
OUTPUTDIR="${BDA_HOME_DIR}/job-results-"${SLURM_JOB_ID}
spark-submit ${SPARK_SUBMIT_OPTIONS} \
  --class SparkWordCount \
  --master $MASTER \
  SparkWordCount.jar ${INPUTDIR} ${OUTPUTDIR} 


### FINAL CLEANUP
if [[ -n "${SPARK_CLEAN_TEMP}" && ${SPARK_CLEAN_TEMP} -eq 1 ]]; then
    echo "====== Cleaning up: SPARK_CLEAN_TEMP=${SPARK_CLEAN_TEMP}"
    rm -rf ${SPARK_JOB_DIR}
else
    echo "====== Not cleaning up: SPARK_CLEAN_TEMP=${SPARK_CLEAN_TEMP}"
fi