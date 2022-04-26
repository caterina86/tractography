% Run full diffusion pipeline
%
% dMRI analysis script that takes bids converted and fmripreped data and calls:
% s02_merge_dwi.m -> merge diffusion files
% s03_dwi_preprocessing.m -> denoise, de-ring, topup, eddy correction
% s04_extract_ROIs.m -> extract ROIs for the tractography
% s05a_AFQ -> Automatic Fiber Quantification
% s05_tractography.m -> whole brain tractography, OR and OT tractography
% s06_cleaning.m -> tckedit and AFQ cleaning
% s07_fit_tensor.m -> fit tensors and extract FA and MD values
% s08_figures_AFQ -> figures to visualize the AFQ fibers

clearvars;
setup_user;

% copy these folders from MRI/Sample_dMRI on the server to your local PC (projectDir):
% rawdata/sub-XX/ses-YY
% derivatives/fmriprep/sub-XX/ses-YY
% derivatives/freesurfer/sub-XX

%% Setup parameters

% subject/session/etc:
sub = {'sub-0201'}; % initials of the subject
ses = {'ses-01'}; % ID of the session
hemi = {'lh', 'rh'};

% Specify the number of diffusion gradients for AP and PA encoding direction
% You need to have both encoding directions to run this pipeline
num_dir_AP = {'97' '98'}; %{'104'}; %{'97' '98'}; % number of diffusion gradient directions (should get from bval/bvecs file)
num_dir_PA = {'97' '98'}; %{'6'}; %{'97' '98'}; % number of diffusion gradient directions (should get from bval/bvecs file)
fmriprep = 1; % 1 -> we performed fmriprep (NYUAD); 0 -> we did not perform fmriprep (CCAD)
numFibers_WB = 5000000; % number of fibers whole brain
numFibers_OR = 10000; % number of fibers for optic radiation
numFibers_OT = 1000; % number of fibers for optic tract
numFibers_ON = 10000; % number of fibers for optic tract

% Parameters for dtiInit.m
runDtiInit = 'true';
encodingOrientation = {'AP'}; % Phase encoding direction for each participant

% AFQ cleaning
maxDist =   4;
maxLen =    4;
numNodes =  25;
M =         'mean';
count =     1;
show =      1;

%% Run full dMRI preprocessing pipeline

for sub_i = 1:length(sub) % loop over subjects

    sub_ses = dir(fullfile(projectDir, 'rawdata', sub{sub_i}, 'ses-*'));
    if isempty(sub_ses)
        error(['No files found in ' projectDir]);
    end

    for ses_i = 1:numel(sub_ses) % for each scan session

        if fmriprep == 1 % NYUAD setup
            disp([sub{sub_i} ' ' ses{ses_i} ' Merge DWI files'])
            s02_merge_dwi(projectDir, sub{sub_i}, ses{ses_i}, num_dir_AP, num_dir_PA)
        end

        disp([sub{sub_i} ' ' ses{ses_i} ' DWI preprocessing'])
        s03_dwi_preprocessing(projectDir, sub{sub_i}, ses{ses_i}, fmriprep)

        if fmriprep == 0 % CCAD setup
            disp([sub{sub_i} ' ' ses{ses_i} ' T1 preprocessing'])
            s03b_t1_preprocessing(projectDir, sub{sub_i}, ses{ses_i})
        end
        
        % extract ROIs
        disp([sub{sub_i} ' ' ses{ses_i} ' extract ROIs'])
        s04_extract_ROIs(projectDir, sub{sub_i}, ses{ses_i}, fmriprep, hemi)

        % AFQ - deterministic tractography - ACPC space - needs SPM12 (loaded in setup_user)
        disp([sub{sub_i} ' ' ses{ses_i} ' extract AFQ fibers'])
        s05a_AFQ(projectDir, sub{sub_i}, ses{ses_i}, runDtiInit, encodingOrientation)

        % probabilistic tractography
        disp([sub{sub_i} ' ' ses{ses_i} ' Run Probabilistic Tractography'])
        s05b_tractography(projectDir, sub{sub_i}, ses{ses_i}, fmriprep, numFibers_WB, numFibers_OR, numFibers_OT, hemi)

%         disp([sub{sub_i} ' ' ses{ses_i} ' script05'])
%         s05c_optic_nerve(projectDir, sub{sub_i}, ses{ses_i}, numFibers_ON, hemi, maxDist, maxLen, numNodes, M, count, show)

        disp([sub{sub_i} ' ' ses{ses_i} ' Clean Probabilistic Tracts'])
        s06_cleaning(projectDir, sub{sub_i}, ses{ses_i}, numFibers_OR, numFibers_OT, hemi, maxDist, maxLen, numNodes, M, count, show)

        disp([sub{sub_i} ' ' ses{ses_i} ' Fit Tensor Probabilistic Tractography'])
        s07_fit_tensor(projectDir, sub{sub_i}, ses{ses_i}, numFibers_OR, numFibers_OT)

        disp(['Extract AFQ measures subject ' sub{sub_i} ' ' ses{ses_i}])
        s08_extract_FA_MD_AFQ(projectDir, sub{sub_i}, ses{ses_i}, hemi)
        
        % figures plotting the deterministic and probabilistic tracts
        disp('Plot AFQ fibers')
        s09_figures_AFQ(projectDir, sub{sub_i}, ses{ses_i})

        disp(['Extract AFQ measures subject ' sub{sub_i} ' ' ses{ses_i}])
        s10_AFQ_profiles(projectDir, sub{sub_i}, ses{ses_i})

        close all;
        
    end
end
