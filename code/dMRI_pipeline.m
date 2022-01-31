% Run diffusion pipeline
%
% dMRI analysis script that calls:
% s02_merge_dwi.m -> merge diffusion files
% s03_dwi_preprocessing.m -> denoise, de-ring, topup, eddy correction
% s04_extract_ROIs.ms -> extract ROIs for the tractography
% s05_tractography.m -> whole brain tractography, OR and OT tractography
% s06_cleaning.m -> tckedit and AFQ cleaning
% s07_fit_tensor.m -> fit the tensor and extract FA and MD values

clearvars;

% TODO: All parameters need to go to a separate function: pa =
% setup_parameters();
% This script will then remain static

% Specify user
user = 'caterina'; % name of the user
projectDir = define_paths(user);
% edit define_paths to check the location of your projectDir

% Parameters to be setup:
sub = {'sub-0201'}; % initials of the subject
%sub = {'sub-0201' 'sub-0152' 'sub-0228'}; % initials of the subject
ses = {'ses-01'}; % ID of the session
hemi = {'lh', 'rh'};

num_dir = {'97' '98'}; % number of diffusion gradient directions (should get from bval/bvecs file)
fmriprep = 1; % 1 -> we performed fmriprep (NYUAD); 0 -> we did not perform fmriprep (CCAD)
numFibers_WB = 5000000; % number of fibers whole brain
numFibers_OR = 10000; % number of fibers for optic radiation
numFibers_OT = 1000; % number of fibers for optic tract

% AFQ cleaning parameters
maxDist =   4; 
maxLen =    4; 
numNodes =  25; 
M =         'mean'; 
count =     1; 
show =      1;

% copy these folders from MRI/Sample_dMRI on the server to your local PC (projectDir):
% rawdata/sub-XX/ses-YY
% derivatives/fmriprep/sub-XX/ses-YY
% derivatives/freesurfer/sub-XX


%% Run full dMRI preprocessing pipeline

for sub_i = 1:length(sub) % loop over subjects

    sub_ses = dir(fullfile(projectDir, 'rawdata', sub{sub_i}, 'ses-*'));
    if isempty(sub_ses)
        error(['No files found in ' projectDir]);
    end
    
    for ses_i = 1:numel(sub_ses) % for each scan session

        disp([sub{sub_i} ' ' ses{ses_i} ' script02'])
        s02_merge_dwi(projectDir, sub{sub_i}, ses{ses_i}, num_dir)
        
        disp([sub{sub_i} ' ' ses{ses_i} ' script03'])
        s03_dwi_preprocessing(projectDir, sub{sub_i}, ses{ses_i}, fmriprep)  
        
        disp([sub{sub_i} ' ' ses{ses_i} ' script04'])
        s04_extract_ROIs(projectDir, sub{sub_i}, ses{ses_i}, fmriprep, hemi)
        
        disp([sub{sub_i} ' ' ses{ses_i} ' script05'])
        s05_tractography(projectDir, sub{sub_i}, ses{ses_i}, fmriprep, numFibers_WB, numFibers_OR, numFibers_OT, hemi)
        
        disp([sub{sub_i} ' ' ses{ses_i} ' script06'])
        s06_cleaning(projectDir, sub{sub_i}, ses{ses_i}, numFibers_OR, numFibers_OT, hemi, maxDist, maxLen, numNodes, M, count, show)
        
        disp([sub{sub_i} ' ' ses{ses_i} ' script07'])
        s07_fit_tensor(projectDir, sub{sub_i}, ses{ses_i}, numFibers_OR, numFibers_OT)

    end
end