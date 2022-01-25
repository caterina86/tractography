
% Fit tensors to the diffusion volume and quantify (mean diffusivity and fractional anisotropy)

% Probabilistic tractography (mrtrix3)
clearvars

% Setup the environment
% FSL - remember to update the location of FSL according to the location on your PC
setenv('FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); % added to tell where to save the fsl outputs
if isfolder('/Applications/freesurfer/bin')
    setenv('FREESURFER_HOME', '/Applications/freesurfer');
    PATH = getenv('PATH'); setenv('PATH', ['/opt/anaconda3/bin:/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/bin:' PATH]);
elseif isfolder('/Applications/freesurfer/7.2.0/bin')
    setenv('FREESURFER_HOME', '/Applications/freesurfer/7.2.0');
    PATH = getenv('PATH'); setenv('PATH', ['/opt/anaconda3/bin:/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/7.2.0/bin:' PATH]);
else
    error('Cannot find freesurfer binary in or near /Applications/freesurfer')
end

% Specify user variable
user = 'server'; % name of the user

% Set the path
switch user
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
    case {'caterina'}
        projectDir = '~/Documents/tractography/Sample_dMRI'; % location output
    case {'Omnia'}
        projectDir = '~/Documents/GitHub/tractography/code'; % location output
    case {'bas'}
        projectDir = '~/Documents/MRI/Sample_dMRI'; % location output
    case {'Dalia'}
        projectDir = '~/Desktop/Sample_dMRI'; % location output
    case {'hannah'}
        projectDir = '/Users/hannah/Documents/MRI/Sample_dMRI'; % location output
end
addpath(genpath(fullfile(projectDir, 'code'))); % add user code to path

sub = {'0228'}; % initials of the subject
ses = {'01'}; % ID of the session
hemi = {'lh', 'rh'};


%% Fit the Tensor
% Change the number of fibers extracted
numFibers_OR = (1e4);
numFibers_OT = (1e3); 

sub_i = 1:length(sub); % loop over subjects (eventually)

for ses_i = 1:numel(dir(fullfile(projectDir, 'rawdata', ['sub-' sub{sub_i}], 'ses-*'))) % for each scan session

    eddyDir = fullfile(projectDir, 'derivatives/eddy', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    fibDir = fullfile(projectDir, '/derivatives/mrtrix3', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    topupDir = fullfile(projectDir, 'derivatives/topup', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);

    eddyFile = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data'];
    bvec = fullfile(eddyDir, [eddyFile '.eddy_rotated_bvecs']);
    bval = fullfile(topupDir, 'bval_combined.txt');

    % Fit tensors to the diffusion volume
    system(['dwi2tensor ' fullfile(eddyDir, [eddyFile '.nii.gz'])  ' -fslgrad ' bvec ' ' bval ' ' fullfile(fibDir, 'tensor.mif')])

    % Extract MD and FA values from tensors
    system(['tensor2metric ' fullfile(fibDir, 'tensor.mif') ' -fa ' fullfile(fibDir, 'tensor_fa.mif')]);
    system(['tensor2metric ' fullfile(fibDir, 'tensor.mif') ' -adc ' fullfile(fibDir, 'tensor_md.mif')]);

    % Resample the Optic Radiations
    % resample the tract so that diffusion measures can be extracted from 100 evenly spaced points for all fibers
    system(['tckresample ' fullfile(fibDir, ['dti' ses{ses_i} '_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered.tck ']) ...
        fullfile(fibDir,['dti' ses{ses_i} '_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_100sample.tck']) ' -num_points 100'])
    system(['tckresample ' fullfile(fibDir, ['dti' ses{ses_i} '_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered.tck ']) ...
        fullfile(fibDir,['dti' ses{ses_i} '_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_100sample.tck']) ' -num_points 100'])


    % Resample the Optic Tracts
    system(['tckresample ' fullfile(fibDir, ['dti' ses{ses_i} '_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered.tck ']) ...
        fullfile(fibDir,['dti' ses{ses_i} '_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_100sample.tck']) ' -num_points 100'])
    system(['tckresample ' fullfile(fibDir, ['dti' ses{ses_i} '_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered.tck ']) ...
        fullfile(fibDir,['dti' ses{ses_i} '_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_100sample.tck']) ' -num_points 100'])


    % Sample FA measures from the optic radiations
    system(['tcksample ' fullfile(fibDir, ['dti' ses{ses_i} '_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_fa.mif') ' ' fullfile(fibDir, 'lh_OR_FA_100sample.txt')]);
    system(['tcksample ' fullfile(fibDir, ['dti' ses{ses_i} '_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_fa.mif') ' ' fullfile(fibDir, 'rh_OR_FA_100sample.txt')]);

    % Sample FA measures from the optic tracts
    system(['tcksample ' fullfile(fibDir, ['dti' ses{ses_i} '_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_fa.mif') ' ' fullfile(fibDir, 'lh_OT_FA_100sample.txt')]);
    system(['tcksample ' fullfile(fibDir, ['dti' ses{ses_i} '_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_fa.mif') ' ' fullfile(fibDir, 'rh_OT_FA_100sample.txt')]);



    % Sample MD measures from the optic radiations
    system(['tcksample ' fullfile(fibDir, ['dti' ses{ses_i} '_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_md.mif') ' ' fullfile(fibDir, 'lh_OR_MD_100sample.txt')]);
    system(['tcksample ' fullfile(fibDir, ['dti' ses{ses_i} '_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_md.mif') ' ' fullfile(fibDir, 'rh_OR_MD_100sample.txt')]);


    % Sample MD measures from the optic tracts
    system(['tcksample ' fullfile(fibDir, ['dti' ses{ses_i} '_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_md.mif') ' ' fullfile(fibDir, 'lh_OT_MD_100sample.txt')]);
    system(['tcksample ' fullfile(fibDir, ['dti' ses{ses_i} '_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_md.mif') ' ' fullfile(fibDir, 'rh_OT_MD_100sample.txt')]);


end
