% setup_parameters script
%
% for dMRI analysis

%% subject/session/etc:
sub = {'sub-0228'}; % sub = {'sub-0201' 'sub-0152' 'sub-0228'}; % initials of the subject
ses = {'ses-01'}; % ID of the session
hemi = {'lh', 'rh'};

num_dir = {'97' '98'}; % number of diffusion gradient directions (should get from bval/bvecs file)
fmriprep = 1; % 1 -> we performed fmriprep (NYUAD); 0 -> we did not perform fmriprep (CCAD)
numFibers_WB = 5000000; % number of fibers whole brain
numFibers_OR = 10000; % number of fibers for optic radiation
numFibers_OT = 1000; % number of fibers for optic tract

%% AFQ cleaning
maxDist =   4;
maxLen =    4;
numNodes =  25;
M =         'mean';
count =     1;
show =      1;

%% data and toolbox locations
user = 'caterina'; % name of the user

switch user
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
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
        projectDir = '~/Documents/MRI/Sample_dMRI'; % location output
        toolboxDir = '~/Documents/MATLAB/toolbox';
end
define_paths(projectDir, toolboxDir); % Add all relevant paths