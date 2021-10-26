
% Probabilistic tractography (mrtirx3)
clear all;
user = 'caterina'; % name of the user

% Set the path
switch user
    case {'caterina'}
        projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output    
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
end

sub = {'201'}; % initials of the subject
ses = {'01'}; % ID of the subject
hemi = {'lh', 'rh'};

% rawdata
rawDir = [projectDir '/rawdata/'];
dwiDir = 'dwi/';
t1Dir = 'anat/';

% derivatives:
eddyDir = [projectDir '/derivatives/eddy/'];
topup = [projectDir '/derivatives/topup/'];
roiDir = [projectDir '/derivatives/ROIs/'];
fmriprep = [projectDir '/derivatives/fmriprep/'];
fsDir = [projectDir '/derivatives/freesurfer/'];
fibDir = [projectDir '/derivatives/mrtrix3/'];

% Add paths
addpath(genpath('~/Data/GitHub/Prakash/Toolbox/vistasoft')); % vistasoft location
addpath(genpath('~/Data/GitHub/Prakash/Toolbox/AFQ')); % afq location
addpath(genpath(fullfile(projectDir, 'code/'))); % afq location

% FSL
setenv( 'FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); %added to tell where to save the fsl outputs
fsldir = getenv('FSLDIR');
fsldirmpath = sprintf('%s/etc/matlab',fsldir);
path(path, fsldirmpath);

%% Whole Brain Tractography

sub_i = 1;

for ses_i = 1:numel(dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'))) % for each scan session

    if exist([fibDir '/sub-' sub{sub_i} filesep 'ses-' ses{ses_i}]) == 0 % Check if fiber directory exists
        mkdir([fibDir(1:end-1) '/sub-' sub{sub_i} filesep 'ses-' ses{ses_i}]) % If not, create it
    else
    end
    
    % Generate 5tt mask (aligned with T1 volume)
    system(['5ttgen fsl ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['anat/sub-' sub{sub_i} '_ses-' ses{ses_i} '_desc-preproc_T1w_crop_brain_diffspace.nii.gz '] ...
        fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'anat/' ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_5tt.nii.gz -premasked']])        

    
    %% Whole brain tractography
    
    % Define paths (convenience for commands below)
    eddy = [eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data.nii.gz '];
    bvec = [eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data.eddy_rotated_bvecs'];
    bval = [topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/bval_combined.txt'];
    mask = [eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain_mask.nii.gz ']; % brain mask aligned to ACPC

    % Generate normal orientation response function estimates
    system(['dwi2response dhollander ' eddy ' -fslgrad ' bvec ' ' bval ' ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/responseEstimate_sfwm.txt ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/responseEstimate_gm.txt ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/responseEstimate_csf.txt -mask ' mask]) 
        
    % Generate normal fiber orientation distribution estimates (FOD)
    system(['dwi2fod msmt_csd -mask ' mask ' ' eddy ' -fslgrad ' bvec ' ' bval ' ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/responseEstimate_sfwm.txt ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/wmfod.mif ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/responseEstimate_gm.txt ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/gmfod.mif ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/responseEstimate_csf.txt ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/csffod.mif '])

    % Whole brain tractography (mrtrix3)
    act = [fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'anat/' ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_5tt.nii.gz']]; % anatomically-constrain tractography
    wmfod = [fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/wmfod.mif ']; % extracted from eddy_corrected_data.nii.gz aligned to T1-acpc space
    numFibers = 5000000;
    outFile = [fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_wholeBrain_ACT_' num2str(numFibers(1)/1000000) 'M.tck'];       
    
    % Run tractography
    system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' act  ' -select ' num2str(numFibers(1)) ' -seeds 0 ']);

    
end

%% Optic Radiations Tractography

numFibers = [1e4; 1e4];

for ses_i = 1:numel(dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'))) % for each scan session

    for jj = 1:length(hemi)
        % Define paths (convenience for commands below)
        eddy = [eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data.nii.gz '];
        bvec = [eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data.eddy_rotated_bvecs'];
        bval = [topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/bval_combined.txt'];
        mask = [eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain_mask.nii.gz ']; % brain mask aligned to ACPC
        act = [fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'anat/' ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_5tt.nii.gz']]; 
        wmfod = [fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/wmfod.mif ']; % extracted from eddy_corrected_data.nii.gz aligned to T1-acpc space

        maxLength = 150;
        outFile = [fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers(1)/1000) 'k.tck'];
        roi1 = [roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/T1w_fs_' hemi{jj} '_lgn_diffspace.nii.gz']; % FreeSurfer LGN
        roi2 = [roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/T1w_fs_' hemi{jj} '_V1_diffspace.nii.gz']; % FreeSurfer V1
        
        % Run tractography
        system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' roi1 ' -seed_image ' roi2 ' -include ' roi1 ' -include ' roi2 ' -stop ' '-select ' num2str(numFibers(1)) ' -seeds 0 ' '-maxlength ' num2str(maxLength)])
        
        % Convert fibers to DSIStudio format
        outFileImage = [fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers(1)/1000) 'k_DSIStudio.tck'];
        % Convert to DSIStudio format
        system(['tckconvert -scanner2image ' eddy ' ' outFile ' ' outFileImage])

    end
end

% Optic Tract - less number of fibers
numFibers = [1e3; 1e3];

for ses_i = 1:numel(dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*')))

    for jj = 1:length(hemi)
        
        eddy = [eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data.nii.gz '];
        bvec = [eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data.eddy_rotated_bvecs'];
        bval = [topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/bval_combined.txt'];
        mask = [eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain_mask.nii.gz ']; % brain mask aligned to ACPC
        act = [fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'anat/' ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_5tt.nii.gz']]; 
        wmfod = [fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/wmfod.mif ']; % extracted from eddy_corrected_data.nii.gz aligned to T1-acpc space

        maxLength = 150;
        outFile = [fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers(1)/1000) 'k.tck'];
        roi1 = [roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/T1w_fs_' hemi{jj} '_lgn_diffspace.nii.gz']; % FreeSurfer LGN
        roi2 = [roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/T1w_fs_oc_diffspace_3dilM.nii.gz']; % Freesurfer Optic Chiasm expanded -> 3dil
       
        % Run tractography
        system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' roi1 ' -seed_image ' roi2 ' -include ' roi1 ' -include ' roi2 ' -stop ' '-select ' num2str(numFibers(1)) ' -seeds 0 ' '-maxlength ' num2str(maxLength)])
        
        % Convert fibers to DSIStudio format
        outFileImage = [fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers(1)/1000) 'k_acpc_DSIStudio.tck'];
        % Convert to DSIStudio format
        system(['tckconvert -scanner2image ' eddy ' ' outFile ' ' outFileImage])
    
    end
end