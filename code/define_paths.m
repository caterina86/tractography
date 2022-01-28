
% define paths

function [projectDir] = define_paths(user)

    % setup fsl and freesurfer paths
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

    % define the location of the projectDir for each user
    switch user
        case {'server'}
            projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
        case {'caterina'}
            projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output
        case {'Omnia'}
            projectDir = '~/Documents/GitHub/tractography/code'; % location output
        case {'bas'}
            projectDir = '/Users/rokers/Dropbox/MRI/Sample_dMRI'; % location output
        case {'Dalia'}
            projectDir = '~/Desktop/Sample_dMRI'; % location output
        case {'hannah'}
            projectDir = '/Users/hannah/Documents/MRI';
    end
    
    setenv('SUBJECTS_DIR', [projectDir '/derivatives/freesurfer']); % subject directory for freesurfer
    addpath(genpath(fullfile(projectDir, 'code'))); % add user code to path

    % addpath(genpath('/Volumes/Vision/Matlab/Toolbox/vistasoft')); % add vistasoft toolbox -> for AFQ cleaning
    % addpath(genpath('/Volumes/Vision/Matlab/Toolbox/AFQ')); % add AFQ toolbox -> for AFQ cleaning
    addpath(genpath('/Users/cp3488/Data/GitHub/Prakash/Toolbox/vistasoft')); % add vistasoft toolbox -> for AFQ cleaning
    addpath(genpath('/Users/cp3488/Data/GitHub/Prakash/Toolbox/AFQ')); % add AFQ toolbox -> for AFQ cleaning

end