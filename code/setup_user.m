% setup_user script
%
% for dMRI analysis
% TODO: Change to projectDir = setup_user(username)

%% user specific data and toolbox locations
user = 'caterina'; % name of the user

switch user
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
        toolboxDir = '/Volumes/Vision/Matlab/Toolbox'; % location output
    case {'caterina'}
        projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output
        toolboxDir = '/Users/cp3488/Documents/MATLAB/toolbox';
    case {'Omnia'}
        projectDir = '~/Documents/GitHub/tractography/code'; % location output
    case {'bas'}
        projectDir = '/Users/rokers/Dropbox/MRI/Sample_dMRI'; % location output
        toolboxDir = '~/Documents/MATLAB/toolbox';
    case {'Dalia'}
        projectDir = '~/Desktop/Sample_dMRI'; % location output
    case {'hannah'}
        projectDir = '/Users/hannah/Documents/MRI';
    case {'class'}
        projectDir = '/Users/rokers/Documents/dMRI_Tractography_sub-0201'; % location output
        toolboxDir = '/Users/rokers/Documents/GitHub';
end

%% fsl and freesurfer paths
setenv('FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); % define fsl output
if isfolder('/Applications/freesurfer/bin')
    setenv('FREESURFER_HOME', '/Applications/freesurfer');
    PATH = getenv('PATH'); setenv('PATH', ['/opt/anaconda3/bin:/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/bin:' PATH]);
elseif isfolder('/Applications/freesurfer/7.2.0/bin')
    setenv('FREESURFER_HOME', '/Applications/freesurfer/7.2.0');
    PATH = getenv('PATH'); setenv('PATH', ['/opt/anaconda3/bin:/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/7.2.0/bin:' PATH]);
else
    error('Cannot find freesurfer binary in or near /Applications/freesurfer')
end
setenv('SUBJECTS_DIR', [projectDir '/derivatives/freesurfer']); % subject directory for freesurfer

%% toolbox paths
% make sure toolboxes are in toolboxDir
if isfolder(fullfile(toolboxDir, 'vistasoft'))
    addpath(genpath(fullfile(toolboxDir, 'vistasoft'))); % add vistasoft toolbox -> for AFQ cleaning
else
    error(['No vistasoft folder found in ' toolboxDir]) % download at https://github.com/vistalab/vistasoft
end

if isfolder(fullfile(toolboxDir, 'spm12'))
    addpath(genpath(fullfile(toolboxDir, 'spm12'))); % add vistasoft toolbox -> for AFQ cleaning
else
    error(['No spm12 folder found in ' toolboxDir]) % download at https://github.com/vistalab/vistasoft
end

if isfolder(fullfile(toolboxDir, 'AFQ'))
    addpath(genpath(fullfile(toolboxDir, 'AFQ'))); % add AFQ toolbox -> for AFQ cleaning
else
    error(['No AFQ in ' toolboxDir]) % download at https://github.com/yeatmanlab/AFQ
end

%% add user code path
addpath(genpath(fullfile(projectDir, 'code')));
