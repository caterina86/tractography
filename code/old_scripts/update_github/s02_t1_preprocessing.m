% As we are running fmriprep, we are not going to run the t1_preprocessing
% as it is performed by fmriprep

% Open matlab from the terminal with the following line (adapted to the version of matlab you have):
% /Applications/MATLAB_R2020a.app/bin/matlab

clear all;
user = 'caterina'; % name of the user

% Set the path
switch user
    case {'caterina'}
        projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output    
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
end

sub = {'229'}; % ID of the subject
ses = {'01'}; % ID of the session
hemi = {'lh','rh'};

% Add paths
addpath(genpath(fullfile(baseDir, 'code/'))); % code folder location

% Freesurfer
setenv( 'FREESURFER_HOME', '/Applications/freesurfer');
freesurferdir = getenv('FREESURFER_HOME');
freesurferpath = sprintf('%s/matlab',freesurferdir);
path(path, freesurferpath);
setenv ('SUBJECTS_DIR', fsDir); 


%% T1 preprocessing

% Step 1. 
% T1 FAST only for the T1 acquired in the first session
% mkdir(fullfile(baseDir, anat_prep, ['sub-' subIDs{ii}], '/ses-01/'))

% extract the FOV only showing the brain (cutting the neck)
% system(['robustfov -i ' baseDir, rawDir, ['sub-' subIDs{ii}], '/ses-01/', t1Dir, ['sub-' subIDs{ii} '_ses-01_T1w.nii.gz'] ' -r ' ...  
%    baseDir anat_prep ['sub-' subIDs{ii}] filesep 'ses-01/' ['sub-' subIDs{ii} '_ses-01_t1_crop.nii.gz']]);

% system(['fast -B ' baseDir anat_prep ['sub-' subIDs{ii}] filesep 'ses-01/' ['sub-' subIDs{ii} '_ses-01_t1_crop.nii.gz']]);


% Step 2. 
% Freesurfer -> Note: $SUBJECTS_DIR must be set to fsDir defined above
% fsDir = 'derivatives/freesurfer/' -> change it in the bash_profile.
% go to the folder of your user and press command+shift+dot to see the hidden files
% open the bash_profile and set the path of the $SUBJECTS_DIR to the
% derivatives/freesurfer directory

% mkdir(fullfile(baseDir, fsDir)) % create the folder for the output of freesurfer
% system(['recon-all -i ' baseDir anat_prep ['sub-' subIDs{ii}] filesep 'ses-01/' ['sub-' subIDs{ii} '_ses-01_t1_crop_restore.nii.gz'] ' -subjid ' ['sub-' subIDs{ii}] ' -all'])


%% Subcortical segmentation
fsDir = [projectDir '/derivatives/freesurfer']; % define the location of the output of freesurfer

% Segment thalamic nuclei (requires that subject has already been processed with recon-all);
% fs_install_mcr R2014b
% download the runtime for FS version 7: fs_install_mcr R2014b
% If the fs_install_mcr script is not available in your freesurfer distribution, it can be downloaded by running the following command:
% cd $FREESURFER_HOME/bin && curl https://raw.githubusercontent.com/freesurfer/freesurfer/dev/scripts/fs_install_mcr -o fs_install_mcr && chmod +x fs_install_mcrsystem(['segmentThalamicNuclei.sh ' sub{ii} ' ' fsDir]);
% Run without any problem on Mac Catalina (problems with BigSur)

for sub_i = 1:length(sub) % for each subject

    system(['segmentThalamicNuclei.sh sub-' sub{sub_i} ' ' fsDir]);
    
end
