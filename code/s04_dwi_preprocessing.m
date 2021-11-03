
clear all;
user = 'caterina'; % name of the user
% choose 'server' if you are working on the server
% add your name if you are working on your local PC. In this case you
% should add your files locations in the following 'switch user'

% Set the path
switch user
    case {'caterina'}
        projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output    
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
end

sub = {'201'}; % initials of the subject
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

% Add paths - update the location of vistasoft and AFQ according to your PC
addpath(genpath('~/Data/GitHub/Prakash/Toolbox/vistasoft')); % vistasoft location
addpath(genpath('~/Data/GitHub/Prakash/Toolbox/AFQ')); % afq location

% add the path of the code
addpath(genpath(fullfile(projectDir, 'code/'))); % afq location

% FSL - remember to update the location of freesurfer according to
% the location on your PC
setenv('FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); %added to tell where to save the fsl outputs
PATH = getenv('PATH'); setenv('PATH', ['/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/bin:' PATH]);


%% dwi preprocessing

sub_i = 1:length(sub);

for ses_i = 1:numel(dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'))) % for each scan session

    mkdir([topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed]); % Make "unprocessed" directory to backup raw dti volumes before processing (susbequent steps will overwrite)

    % copy the original AP and PA dwi image in the folder derivatives/topup
    copyfile(fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], dwiDir, ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz']), ...
        fullfile(topup, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], unprocessed, ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz']));
    copyfile(fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], dwiDir, ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz']), ...
        fullfile(topup, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], unprocessed, ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz']));
   
    
    % Denoise the data - Correct for warping artifacts due to the phase encoding direction
    % input -> topup/unprocesses/sub-_ses-_AP_dwi.nii.gz
    % output -> topup/sub-_ses-_AP_dwi.nii.gz
    
    system(['dwidenoise -force ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz '] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz']])
    
    system(['dwidenoise -force ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz '] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz']])
     
    
    % Calculate and check the residuals.
    % The lack of anatomy in the residual maps is a marker of accuracy and signal-preservation during denoising
    % original dwi - denoised dwi = residuals
    
    system(['mrcalc ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz '] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz '] ...
        ' -subtract ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_res_AP.nii.gz ']]) 

    system(['mrcalc ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep unprocessed ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz '] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz '] ...
        ' -subtract ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_res_PA.nii.gz ']]) 
    
    
    % correct for Gibbs’ Ringing Artifacts
    system(['mrdegibbs -force ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz '] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz']])

    system(['mrdegibbs -force ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz '] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz']])

    
    
    %% Topup correction
    % extract the b0 from the AP and PA dwi image
    system(['fslroi ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz '] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi_b0.nii.gz 0 1']]);
    
    system(['fslroi ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz '] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi_b0.nii.gz 0 1']]);
    
    % merge the b0 images with PA and AP phase encoding directions
    system(['fslmerge -t ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_PA_dwi_b0.nii.gz '] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi_b0.nii.gz '] ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi_b0.nii.gz ']]);
        
    % merge raw dwi_AP and dwi_PA in one single image
    system(['fslmerge -t ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_PA_dwi.nii.gz '] ...
        projectDir filesep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['dwi/sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz '] ...
        projectDir filesep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['dwi/sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz']]);   
    
    % run topup
    system(['topup --imain='  topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_PA_dwi_b0.nii.gz '] ...
        ' --datain=acqparams.txt  --config=b02b0.cnf --out=' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'my_topup_results  ' ...
        '--iout=' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'my_hifi_b0'])

    
    %% Prepare data for the eddy correction
   
    % Create an index file that specifies the phase encoding direction for each volume in the combined dMRI file. 
    % Combine bval and bvec files from the two dMRI scans
    nDirs = (197);
    index = [ones(nDirs,1); 2*ones(nDirs,1)];
    writematrix(index, fullfile(topup, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'index.txt'), 'Delimiter', 'space');
        
    % Combine bvac and bvec files from the two dMRI scans
    bvals = horzcat(load(fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], ['dwi/sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.bval'])), ...
        load(fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], ['dwi/sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.bval'])));
    writematrix(bvals, fullfile(topup, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'bval_combined.txt'), 'Delimiter', 'space');

    bvecs = horzcat(load(fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], ['dwi/sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.bvec'])), ...
        load(fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], ['dwi/sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.bvec'])));
    writematrix(bvecs, fullfile(topup, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'bvec_combined.txt'), 'Delimiter', 'space');
    

    % Generate a brain mask using the corrected b0 image
    system(['fslmaths ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'my_hifi_b0.nii.gz ' ...
        '-Tmean ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'my_hifi_b0_mean.nii.gz '])
    
    % BET the averaged b0 image
    system(['bet ' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'my_hifi_b0_mean.nii.gz ' ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'my_hifi_b0_mean_brain.nii.gz -m -f 0.2'])


    
    %% eddy correction:
    system(['eddy --imain=' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_PA_dwi.nii.gz '] ...
        '--mask=' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'my_hifi_b0_mean_brain_mask.nii.gz ' ...
        '--acqp=acqparams.txt --index=' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'index.txt ' ...
        '--bvecs=' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'bvec_combined.txt ' ...
        '--bvals=' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'bval_combined.txt ' ...
        '--topup=' topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'my_topup_results ' ...
        '--out=' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data --repol --verbose'])



end
