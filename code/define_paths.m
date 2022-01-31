function [projectDir] = define_paths(user)

%% define the location of projectDir for each user
% TODO: Add toolboxPath for users
    switch user
        case {'server'}
            projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
            toolboxPath = '/Volumes/Vision/Matlab/Toolbox'; % location toolboxes
        case {'caterina'}
            projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output
            toolboxPath = '~/Data/Github/Prakash/Toolbox'; % location toolboxes
        case {'Omnia'}
            projectDir = '~/Documents/GitHub/tractography/code'; % location output
            toolboxPath = '/Volumes/Vision/Matlab/Toolbox'; % location toolboxes
        case {'bas'}
            projectDir = '/Users/rokers/Dropbox/MRI/Sample_dMRI'; % location output
            toolboxPath = '~/Documents/MATLAB/toolbox'; % location toolboxes
        case {'Dalia'}
            projectDir = '~/Desktop/Sample_dMRI'; % location output
            toolboxPath = '/Volumes/Vision/Matlab/Toolbox'; % location toolboxes
        case {'hannah'}
            projectDir = '/Users/hannah/Documents/MRI'; % location output
            toolboxPath = '/Volumes/Vision/Matlab/Toolbox'; % location toolboxes
        case {'class'}
            projectDir = '~/Documents/MRI/Sample_dMRI'; % location output
            toolboxPath = '~/Documents/MATLAB/toolbox'; % location toolboxes
    end
    addpath(genpath(fullfile(projectDir, 'code'))); % add user code to path

    
    %% setup fsl and freesurfer paths
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

    
    %% setup toolboxes 
    % make sure toolboxes are in ~/Documents/matlab/toolbox
    if isfolder(fullfile(toolboxPath, 'vistasoft'))
        addpath(genpath(fullfile(toolboxPath, 'vistasoft'))); % add vistasoft toolbox -> for AFQ cleaning
    else 
        error(['No vistasoft in ' toolboxPath])
    end

    if isfolder(fullfile(toolboxPath, 'AFQ'))
        addpath(genpath(fullfile(toolboxPath, 'AFQ'))); % add AFQ toolbox -> for AFQ cleaning
    else 
        error(['No AFQ in ' toolboxPath])
    end
end
