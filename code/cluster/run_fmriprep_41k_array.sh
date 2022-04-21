#!/bin/bash
#SBATCH -n 1
#SBATCH -c 14
#SBATCH -a 1 # indicate number of subjects
#SBATCH -t 48:00:00

#
# *** load modules ***
module load NYUAD/4.0 singularity/3.8.0 braimcore/3.1

CDIR=`pwd`

# *** Set tmp working dir ***
WORKDIR=/tmpdata/${SLURM_JOB_USER}/${SLURM_JOB_ID}/${SLURM_ARRAY_TASK_ID}

# *** Set BRAIMCORE_ENGINE in case not using -e option ***
export BRAIMCORE_ENGINE=fmriprep

#
# *** Grab a particular subject
subject=`sed "${SLURM_ARRAY_TASK_ID}q;d" subjs.txt`

#
# *** DEFINE VARIABLES ***
#
export SUBJECT_ID=${subject}
export STUDY_DIR=`cd ${CDIR}/.. && pwd`

# Needed if u downloaded the templates to a place other than $HOME/.cache/templateflow
export TEMPLATEFLOW_HOME=`cd ${CDIR}/../../templateflow && pwd`

# To avoid fmriprep race condition processing multiple subjects in parallel
sleep 60

braimcore 	run \
		--nprocs 14 --omp-nthreads 14  \
        	${STUDY_DIR}/rawdata \
        	${STUDY_DIR}/derivatives \
        	participant \
        	--fs-license-file ${CDIR}/license.txt \
					--output-space T1w:res-native fsnative:den-41k MNI152NLin2009cAsym:res-native fsaverage:den-41k fsaverage\
        	--participant_label ${SUBJECT_ID} \
        	--skip_bids_validation \
        	-w ${WORKDIR} \
        	--no-submm-recon

# remove workdir
# rm -rf ${WORKDIR}

echo "Braimcore Finished"
