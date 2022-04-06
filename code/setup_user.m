% setup_user script
%
% for dMRI analysis
% TODO: Change to projectDir = setup_user(username)

%% data and toolbox locations
user = 'class'; % name of the user

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
        % toolboxDir = '~/Documents/MATLAB/toolbox';
        toolboxDir = '/Users/rokers/Documents/GitHub';
end
% projectDir = char(py.os.path.realpath(py.os.path.expanduser(projectDir))); % convert relative to absolute path
define_paths(projectDir, toolboxDir); % Add all relevant paths
