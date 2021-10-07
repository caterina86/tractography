

% Open matlab from the terminal with the following line (adapted to the version of matlab you have):
% /Applications/MATLAB_R2020a.app/bin/matlab

clear all;

% Define paths
baseDir = '/Users/cp3488/Documents/tractography/Sample_dMRI/'; % Update with path to clinical data
subIDs = {'0201'}; % change the name of identification number of the subject
hemi = {'lh','rh'};

% path to the rawdata
rawDir = 'rawdata/';
dwiDir = 'dwi/';
t1Dir = 'anat/';

% path to the derivatives:
anat_prep = 'derivatives/anat_prep/';
fsDir = 'derivatives/freesurfer/'; 

% IMPORTANT: Set the path for the freesurfer subjects, in the bash_profile
% fsLicense = '/Applications/freesurfer/license.txt'; %% COMMENT THIS LINE
% (no need to set it up here)

% Add paths
addpath(genpath(fullfile(baseDir, 'code/'))); % code folder location

% Freesurfer
setenv( 'FREESURFER_HOME', '/Applications/freesurfer');
freesurferdir = getenv('FREESURFER_HOME');
freesurferpath = sprintf('%s/matlab',freesurferdir);
path(path, freesurferpath);
setenv ('SUBJECTS_DIR', fsDir); 

% FSL
setenv( 'FSLDIR', '/usr/local/fsl/' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); % added to tell where to save the fsl outputs
fsldir = getenv('FSLDIR');
fsldirmpath = sprintf('%s/etc/matlab',fsldir);
path(path, fsldirmpath);


%% T1 preprocessing

ii = length(subIDs); % number of the subject

% Step 1. 
% T1 FAST only for the T1 acquired in the first session
mkdir(fullfile(baseDir, anat_prep, ['sub-' subIDs{ii}], '/ses-01/'))

% extract the FOV only showing the brain (cutting the neck)
system(['robustfov -i ' baseDir, rawDir, ['sub-' subIDs{ii}], '/ses-01/', t1Dir, ['sub-' subIDs{ii} '_ses-01_T1w.nii.gz'] ' -r ' ...  
    baseDir anat_prep ['sub-' subIDs{ii}] filesep 'ses-01/' ['sub-' subIDs{ii} '_ses-01_t1_crop.nii.gz']]);

system(['fast -B ' baseDir anat_prep ['sub-' subIDs{ii}] filesep 'ses-01/' ['sub-' subIDs{ii} '_ses-01_t1_crop.nii.gz']]);


% Step 2. 
% Freesurfer -> Note: $SUBJECTS_DIR must be set to fsDir defined above
% fsDir = 'derivatives/freesurfer/' -> change it in the bash_profile.
% go to the folder of your user and press command+shift+dot to see the hidden files
% open the bash_profile and set the path of the $SUBJECTS_DIR to the
% derivatives/freesurfer directory

mkdir(fullfile(baseDir, fsDir)) % create the folder for the output of freesurfer
system(['recon-all -i ' baseDir anat_prep ['sub-' subIDs{ii}] filesep 'ses-01/' ['sub-' subIDs{ii} '_ses-01_t1_crop_restore.nii.gz'] ' -subjid ' ['sub-' subIDs{ii}] ' -all'])



% Step 3: subcortical segmentation
% Segment thalamic nuclei (requires that subject has already been processed with recon-all);
system(['segmentThalamicNuclei.sh ' subIDs{ii} ' ' fsDir]);
