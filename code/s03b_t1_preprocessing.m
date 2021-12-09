
% T1 preprocessing pipeline: robustfov, fast and recon-all
% 
% Written by Caterina Pedersini

clear all;

% Setup the environment
% FSL - remember to update the location of FSL according to the location on your PC
setenv('FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); % added to tell where to save the fsl outputs
setenv('FREESURFER_HOME', '/Applications/freesurfer');
%setenv('FREESURFER_HOME', '/Applications/freesurfer/7.2.0');
PATH = getenv('PATH'); setenv('PATH', ['/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/bin:' PATH]);
%PATH = getenv('PATH'); setenv('PATH', ['/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/7.2.0/bin:' PATH]);

% Specify user 
user = 'caterina'; % name of the user

% choose 'server' if you are working on the server
% add your name if you are working on your local PC. In this case you
% should add your files locations in the following 'switch user'

% Set the path
switch user
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
    case {'caterina'}
        projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output    
    case {'Omnia'}
        projectDir = '~/Documents/GitHub/tractography/code'; % location output
    case {'bas'}
        projectDir = '/Users/rokers/Documents/MRI/Sample_dMRI'; % location output
    case {'Dalia'}
        projectDir = '~/Desktop/Sample_dMRI'; % location output
    case {'hannah'}
        projectDir = '/Users/hannah/Documents/MRI/Sample_dMRI'; % 
end
addpath(genpath(fullfile(projectDir, 'code'))); % add user code to path

% Project variables
sub = {'202'}; % initials of the subject
ses = {'01'}; % ID of the subject



%% T1 preprocessing

sub_i = 1:length(sub); % loop over subjects (eventually)
sub_ses = dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'));

for ses_i = 1:numel(sub_ses) % for each scan session

    anatPrepDir = fullfile(projectDir, 'derivatives/anat_prep', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);        
    anatDir = fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'anat');
    fsDir = fullfile(projectDir, 'derivatives/freesurfer/');

    fileName = dir(fullfile(anatDir, '*_MPR1.nii.gz'));
    copyfile(fullfile(anatDir,fileName.name), fullfile(anatDir, 't1.nii.gz'));

    mkdir(anatPrepDir)
        
    % extract the FOV only showing the brain (cutting the neck)
    system(['robustfov -i ' fullfile(anatDir, 't1.nii.gz') ' -r ' ...  
        fullfile(anatPrepDir, 't1_crop.nii.gz')]);
    
    % FAST 
    system(['fast -B ' fullfile(anatPrepDir, 't1_crop.nii.gz')]);

    % RECON-ALL
    % Freesurfer -> Note: $SUBJECTS_DIR must be set to fsDir defined above
    setenv ('SUBJECTS_DIR', fsDir); 
    
    if exist(fullfile(projectDir, 'derivatives/freesurfer', ['sub-' sub{sub_i}]), 'dir') % if the directory already exists
        system(['recon-all -subjid sub-' sub{sub_i} ' -all'])
    else % if it's the first time we run recon-all for this subject
        system(['recon-all -i ' fullfile(anatPrepDir, 't1_crop_restore.nii.gz') ' -subjid sub-' sub{sub_i} ' -all'])
    end
end

