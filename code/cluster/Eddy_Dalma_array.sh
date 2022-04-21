#!/bin/bash
#SBATCH -n 1
#SBATCH -c 14
#SBATCH -t 12:00:00
#SBATCH -a 1-2
#SBATCH --gres=gpu:1
#SBATCH -p nvidia

# *** load modules ***
module load NYUAD/4.0 singularity braimcore
# braimcore -e hcp_cuda10.0 shell

export BRAIMCORE_ENGINE=hcp_cuda10.0

# *** Grab a particular subject
subject=`sed "${SLURM_ARRAY_TASK_ID}q;d" subjs.txt`

#sub=$1
#ses=$2
export SUBJECT_ID=${subject}
ses=ses-01

if [ ! -e /scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy ]; then
	mkdir /scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy
fi

if [ ! -e /scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy/${SUBJECT_ID} ]; then
	mkdir /scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy/${SUBJECT_ID}/
fi

if [ ! -e /scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy/${SUBJECT_ID}/${ses} ]; then
	mkdir /scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy/${SUBJECT_ID}/${ses}
fi

PROJECTDIR=/scratch/cp3488/MRI/Sample_dMRI
TOPUPDIR=/scratch/cp3488/MRI/Sample_dMRI/derivatives/topup/${SUBJECT_ID}/${ses}
EDDYDIR=/scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy/${SUBJECT_ID}/${ses}

echo ${SUBJECT_ID} ${ses}

braimcore eddy_cuda --imain=${TOPUPDIR}/${SUBJECT_ID}_${ses}_AP_PA_dwi.nii.gz --mask=${TOPUPDIR}/my_hifi_b0_mean_brain_mask.nii.gz --acqp=${PROJECTDIR}/acqparams.txt --index=${TOPUPDIR}/index.txt --bvecs=${TOPUPDIR}/bvec_combined.txt --bvals=${TOPUPDIR}/bval_combined.txt --topup=${TOPUPDIR}/my_topup_results --out=${EDDYDIR}/${SUBJECT_ID}_${ses}_eddy_corrected_data --repol --verbose

echo "Eddy correction finished"
