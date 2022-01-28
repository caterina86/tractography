#!/bin/bash/
# copy files from your local PC or server to Dalma

# Before running the bash code:
# enter in Dalma and create the folder for the data
# ssh $netID@dalma.abudhabi.nyu.edu
# mkdir /scratch/$netID/MRI/retinotopy/rawdata/sub-${subj}/
# exit

netID=cp3488

# indicate the files locations
# DATAROOT=/Volumes/NYUAD/Projects/pRF_Cate/AnalyzePRF/fMRIPrep
#DATAROOT=/Volumes/Vision/MRI/Sample_dMRI
DATAROOT=/Users/cp3488/Documents/tractography/Sample_dMRI

for subj in "0228"; do
  for ses in 01; do

  echo subject sub-${subj} ses-${ses}

  # Copy rawdata from the local PC/server to Dalma
  rsync -av $DATAROOT/derivatives/topup/sub-${subj}/ses-${ses} $netID@dalma.abudhabi.nyu.edu:/scratch/$netID/MRI/Sample_dMRI/derivatives/topup/sub-${subj}/
  # rsync -av $DATAROOT/acqparams.txt $netID@dalma.abudhabi.nyu.edu:/scratch/$netID/MRI/Sample_dMRI/acqparams.txt

  done
done
