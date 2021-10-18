
clear all;
user = 'caterina'; % name of the user

% Set the path
switch user
    case {'caterina'}
        projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output    
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
end

sub = {'229'}; % initials of the subject
ses = {'01'}; % ID of the subject

% rawdata
rawDir = [projectDir '/rawdata/'];
dwiDir = 'dwi/';
t1Dir = 'anat/';

% derivatives:
eddyDir = [projectDir '/derivatives/eddy/'];
topup = [projectDir '/derivatives/topup/'];

temp = 'temp/';
unprocessed = 'unprocessed/';

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


%% dwi preprocessing

sub_i = length(sub);

for ses_i = 1:numel(dir(fullfile(projectDir, rawDir, sub{ii}, 'ses-*'))) % for each scan session

    mkdir([topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed]); % Make "unprocessed" directory to backup raw dti volumes before processing (susbequent steps will overwrite)

    % copy the original AP and PA dwi image in the folder derivatives/topup
    copyfile(fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], dwiDir, ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz']), ...
        fullfile(topup, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], unprocessed, ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz']));
    copyfile(fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], dwiDir, ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz']), ...
        fullfile(topup, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], unprocessed, ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz']));
   
    
    % Denoise the data - Correct for warping artifacts due to the phase encoding direction
    system(['dwidenoise -force ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz '] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz']])
    system(['dwidenoise -force ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz '] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz']])
     
    
    % Calculate and check the residuals.
    % The lack of anatomy in the residual maps is a marker of accuracy and signal-preservation during denoising
    % denoised dwi - original dwi = residuals
    system(['mrcalc ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz'] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz '] ...
        ' -subtract ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_res_AP.nii.gz ']]) 

    system(['mrcalc ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz'] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz '] ...
        ' -subtract ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_res_PA.nii.gz ']]) 
    
    
    % correct for Gibbs’ Ringing Artifacts
    system(['mrdegibbs -force ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz'] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz']])

    system(['mrdegibbs -force ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz'] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz']])

    
    
    
    
    %% Topup correction
    % extract the b0 from the AP and PA dwi image
    system(['fslroi ' topup sub{ii} filesep ['ses-' ses{ses_i}] filesep [sub{ii} '_ses-' ses{ses_i} '_dwi_AP.nii.gz '] ...
        topup sub{ii} filesep ['ses-' ses{ses_i}] filesep [sub{ii} '_ses-' ses{ses_i} '_dwi_AP_b0.nii.gz 0 1']]);
    system(['fslroi ' topup sub{ii} filesep ['ses-' ses{ses_i}] filesep [sub{ii} '_ses-' ses{ses_i} '_dwi_PA.nii.gz '] ...
        topup sub{ii} filesep ['ses-' ses{ses_i}] filesep [sub{ii} '_ses-' ses{ses_i} '_dwi_PA_b0.nii.gz 0 1']]);
    
    % merge the b0 images with PA and AP phase encoding directions
    system(['fslmerge -t ' topup sub{ii} filesep ['ses-' ses{ses_i}] filesep [sub{ii} '_ses-' ses{ses_i} '_dwi_AP_PA_b0.nii.gz '] ...
        topup sub{ii} filesep ['ses-' ses{ses_i}] filesep [sub{ii} '_ses-' ses{ses_i} '_dwi_AP_b0.nii.gz '] ...
        topup sub{ii} filesep ['ses-' ses{ses_i}] filesep [sub{ii} '_ses-' ses{ses_i} '_dwi_PA_b0.nii.gz ']]);
        
    % run the topup command
    system(['topup --imain='  topup sub{ii} filesep ['ses-' ses{ses_i}] filesep [sub{ii} '_ses-' ses{ses_i} '_dwi_AP_PA_b0.nii.gz '] ...
        ' --datain=acqparams.txt  --config=b02b0.cnf --out=' topup sub{ii} filesep ['ses-' ses{ses_i}] filesep 'my_topup_results  ' ...
        '--iout=' topup sub{ii} filesep ['ses-' ses{ses_i}] filesep 'my_hifi_b0'])

    
    % merge dti_AP and dti_PA in one single image
    system(['fslmerge -t ' topup sub{ii} filesep ['ses-' ses{ses_i}] filesep [sub{ii} '_ses-' ses{ses_i} '_dwi_AP_PA.nii.gz '] ...
        topup sub{ii} filesep ['ses-' ses{ses_i}] filesep [sub{ii} '_ses-' ses{ses_i} '_dwi_AP.nii.gz '] ...
        topup sub{ii} filesep ['ses-' ses{ses_i}] filesep [sub{ii} '_ses-' ses{ses_i} '_dwi_PA.nii.gz ']]);

    
    % Create an index file that specifies the phase encoding direction for each volume in the combined dMRI file. 
    % Combine bval and bvec files from the two dMRI scans
    
end
