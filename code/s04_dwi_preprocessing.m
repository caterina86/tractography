
clear all;

% Define paths
baseDir = '//Users/cp3488/Documents/tractography/Sample_dMRI/'; % Update with path to clinical data
subIDs = {'0201'}; % change the name of identification number of the subject
hemi = {'lh','rh'};

% rawdata
rawDir = 'rawdata/';
dwiDir = 'dwi/';
t1Dir = 'anat/';

% derivatives:
eddyDir = 'derivatives/eddy/';
topup = 'derivatives/topup/';
temp = 'temp/';
unprocessed = 'unprocessed/';

% Add paths
addpath(genpath('~/Data/GitHub/Prakash/Toolbox/vistasoft')); % vistasoft location
addpath(genpath('~/Data/GitHub/Prakash/Toolbox/AFQ')); % afq location
addpath(genpath(fullfile(baseDir, 'code/'))); % afq location

% FSL
setenv( 'FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); %added to tell where to save the fsl outputs
fsldir = getenv('FSLDIR');
fsldirmpath = sprintf('%s/etc/matlab',fsldir);
path(path, fsldirmpath);

%% dwi preprocessing

ii = length(subIDs);

for ee = 1:numel(dir(fullfile(baseDir, rawDir, ['sub-' subIDs{ii}], 'ses-*'))) % for each scan session

    mkdir([baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep unprocessed]); % Make "unprocessed" directory to backup raw dti volumes before processing (susbequent steps will overwrite)

    % copy the original AP and PA dwi image in the folder derivatives/topup
    copyfile(fullfile(baseDir, rawDir, ['sub-' subIDs{ii}], ['ses-0' num2str(ee)], dwiDir, ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP.nii.gz']), ...
        fullfile(baseDir, topup, ['sub-' subIDs{ii}], ['ses-0' num2str(ee)], unprocessed, ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP.nii.gz']));
    copyfile(fullfile(baseDir, rawDir, ['sub-' subIDs{ii}], ['ses-0' num2str(ee)], dwiDir, ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_PA.nii.gz']), ...
        fullfile(baseDir, topup, ['sub-' subIDs{ii}], ['ses-0' num2str(ee)], unprocessed, ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_PA.nii.gz']));

    % denoise the data - Correct for warping artifacts due to the phase encoding direction
    system(['dwidenoise -force ' baseDir rawDir ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep dwiDir ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP.nii.gz '] ...
        baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP.nii.gz ']])
    system(['dwidenoise -force ' baseDir rawDir ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep dwiDir ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_PA.nii.gz '] ...
        baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_PA.nii.gz ']])

    % calculate and check the residuals.
    % The lack of anatomy in the residual maps is a marker of accuracy and signal-preservation during denoising
    % denoised dwi - original dwi = residuals
    system(['mrcalc ' baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP.nii.gz '] ...
        baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep unprocessed ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP.nii.gz '] ...
        ' -subtract ' baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_res_AP.nii.gz ']])            
    system(['mrcalc ' baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_PA.nii.gz '] ...
        baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep unprocessed ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_PA.nii.gz '] ...
        ' -subtract ' baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_res_PA.nii.gz ']])            

    % correct for Gibbs’ Ringing Artifacts
    system(['mrdegibbs -force ' baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP.nii.gz '] ...
        baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP.nii.gz ']])
    system(['mrdegibbs -force ' baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_PA.nii.gz '] ...
        baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_PA.nii.gz ']])
    
    
    
    %% Topup correction
    % extract the b0 from the AP and PA dwi image
    system(['fslroi ' baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP.nii.gz '] ...
        baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP_b0.nii.gz 0 1']]);
    system(['fslroi ' baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_PA.nii.gz '] ...
        baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_PA_b0.nii.gz 0 1']]);
    
    % merge the b0 images with PA and AP phase encoding directions
    system(['fslmerge -t ' baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP_PA_b0.nii.gz '] ...
        baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP_b0.nii.gz '] ...
        baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_PA_b0.nii.gz']]);
        
    % run the topup command
    system(['topup --imain='  baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP_PA_b0.nii.gz '] ...
        ' --datain=acqparams.txt  --config=b02b0.cnf --out=' baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep 'my_topup_results  ' ...
        '--iout=' baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep 'my_hifi_b0'])

    % merge dti_AP and dti_PA in one single image
    system(['fslmerge -t ' baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP_PA.nii.gz '] ...
        baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_AP.nii.gz '] ...
        baseDir topup ['sub-' subIDs{ii}] filesep 'ses-0' num2str(ee) filesep ['sub-' subIDs{ii} '_ses-0' num2str(ee) '_dti_PA.nii.gz']]);

    
    % Create an index file that specifies the phase encoding direction for each volume in the combined dMRI file. 
    % Combine bval and bvec files from the two dMRI scans
    
end
