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
setup_parameters;

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

        if fmriprep == 1 % NYUAD setup
            disp([sub{sub_i} ' ' ses{ses_i} ' script02'])
            s02_merge_dwi(projectDir, sub{sub_i}, ses{ses_i}, num_dir)
        end

        disp([sub{sub_i} ' ' ses{ses_i} ' script03'])
        s03_dwi_preprocessing(projectDir, sub{sub_i}, ses{ses_i}, fmriprep)
 
        if fmriprep == 0 % CCAD setup
            disp([sub{sub_i} ' ' ses{ses_i} ' script03b'])
            s03b_t1_preprocessing(projectDir, sub{sub_i}, ses{ses_i})
        end

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

