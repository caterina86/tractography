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

for subj in "sub-0201"; do
  for ses in "ses-01"; do

  echo subject ${subj} ${ses}

  # Copy rawdata from the local PC/server to Dalma
  rsync -av $netID@dalma.abudhabi.nyu.edu:/scratch/$netID/MRI/Sample_dMRI/derivatives/eddy/${subj}/ $DATAROOT/derivatives/eddy/${subj}/

  done
done
