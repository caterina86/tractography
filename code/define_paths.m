function define_paths(projectDir, toolboxDir)

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
% make sure toolboxes are in ~/Documents/matlab/toolbox
if isfolder(fullfile(toolboxDir, 'vistasoft'))
    addpath(genpath(fullfile(toolboxDir, 'vistasoft'))); % add vistasoft toolbox -> for AFQ cleaning
else
    error(['No vistasoft in ' toolboxDir])
end

if isfolder(fullfile(toolboxDir, 'AFQ'))
    addpath(genpath(fullfile(toolboxDir, 'AFQ'))); % add AFQ toolbox -> for AFQ cleaning
else
    error(['No AFQ in ' toolboxDir])
end

%% user code path
addpath(genpath(fullfile(projectDir, 'code'))); 