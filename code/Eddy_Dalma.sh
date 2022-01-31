#!/bin/bash
#SBATCH -n 1
#SBATCH -c 14
#SBATCH -t 12:00:00
#SBATCH --gres=gpu:1
#SBATCH -p nvidia

# *** load modules ***
module load NYUAD/4.0 singularity braimcore
# braimcore -e hcp_cuda10.0 shell

export BRAIMCORE_ENGINE=hcp_cuda10.0

# *** Set tmp working dir ***
#sub=$1
#ses=$2
sub=sub-0152
ses=ses-01

if [ ! -e /scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy ]; then
	mkdir /scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy
fi

if [ ! -e /scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy/${sub} ]; then
	mkdir /scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy/${sub}/
fi

if [ ! -e /scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy/${sub}/${ses} ]; then
	mkdir /scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy/${sub}/${ses}
fi

PROJECTDIR=/scratch/cp3488/MRI/Sample_dMRI
TOPUPDIR=/scratch/cp3488/MRI/Sample_dMRI/derivatives/topup/${sub}/${ses}
EDDYDIR=/scratch/cp3488/MRI/Sample_dMRI/derivatives/eddy/${sub}/${ses}

echo ${sub} ${ses}

braimcore eddy_cuda --imain=${TOPUPDIR}/${sub}_${ses}_AP_PA_dwi.nii.gz --mask=${TOPUPDIR}/my_hifi_b0_mean_brain_mask.nii.gz --acqp=${PROJECTDIR}/acqparams.txt --index=${TOPUPDIR}/index.txt --bvecs=${TOPUPDIR}/bvec_combined.txt --bvals=${TOPUPDIR}/bval_combined.txt --topup=${TOPUPDIR}/my_topup_results --out=${EDDYDIR}/${sub}_${ses}_eddy_corrected_data --repol --verbose

echo "Eddy correction finished"
