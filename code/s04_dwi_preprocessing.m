% dMRI preprocessing pipeline: denoise, dering, topup, eddy correction
% 
% Written by Caterina Pedersini

clear all;

% Set up our environment
setenv('FSLDIR', '/usr/local/fsl' ); % fsl binary
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); % specify fsl output format
% add fsl and freesurfer to the path
PATH = getenv('PATH'); setenv('PATH', ['/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/bin:' PATH]);

% Specify user variable
user = 'caterina'; % name of the user

% choose 'server' if you are working on the server
% add your name if you are working on your local PC. In this case you
% should add your files locations in the following 'switch user'

% Set the path
switch user
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
    case {'caterina'}
        projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output    
    case {'Omnia'}
        projectDir = '~/Documents/GitHub/tractography/code'; % location output
    case {'bas'}
        projectDir = '~/Documents/MRI/Sample_dMRI'; % location output
    case {'Dalia'}
        projectDir = '~/Desktop/Sample_dMRI'; % location output
    case {'hannah'}
        projectDir = '~/Documents/MRI/Sample_dMRI'; % location output
end
addpath(genpath(fullfile(projectDir, 'code'))); % add user code to path

% Project variables
sub = {'201'}; % initials of the subject
ses = {'01'}; % ID of the subject


%% dwi preprocessing

sub_i = 1:length(sub); % loop over subjects (eventually)

sub_ses = dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'));

for ses_i = 1:numel(sub_ses) % for each scan session
    
    % create names for input and output files:
    % folders:
    topupDir = fullfile(projectDir, 'derivatives/topup', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);        
    eddyDir = fullfile(projectDir, 'derivatives/eddy', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);        
    unprocessedTopupDir = fullfile(topupDir, 'unprocessed');
    dwiDir = fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'dwi');
    % files:
    apFile =  ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.nii.gz'];
    paFile =  ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.nii.gz'];
    apFileBval =  ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.bval'];
    paFileBval =  ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.bval'];
    apFileBvec =  ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi.bvec'];
    paFileBvec =  ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi.bvec'];
    appaFile =  ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_PA_dwi.nii.gz'];
    apResFile = ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_res_AP.nii.gz'];
    paResFile = ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_res_PA.nii.gz'];    
    apB0File = ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi_b0.nii.gz'];
    paB0File = ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi_b0.nii.gz'];
    appaB0File = ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_PA_dwi_b0.nii.gz'];
    eddyFile = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data'];
    
    %% Start the preprocessing
    % Create 'unprocessed' directory to backup raw dti volumes before processing (susbequent steps will overwrite)
    mkdir(unprocessedTopupDir); 
    % Create folder for the results of the eddy correction
    mkdir(eddyDir); 

    % copy the original AP and PA dwi images to derivatives/topup
    copyfile(fullfile(dwiDir, apFile), fullfile(unprocessedTopupDir, apFile));
    copyfile(fullfile(dwiDir, paFile), fullfile(unprocessedTopupDir, paFile));
    
    % Denoise the data - Correct for warping artifacts due to the phase encoding direction
    % input -> topup/unprocesses/sub-_ses-_AP_dwi.nii.gz
    % output -> topup/sub-_ses-_AP_dwi.nii.gz    
    system(['dwidenoise -force ' fullfile(unprocessedTopupDir, apFile) ' ' fullfile(topupDir, apFile)]);
    system(['dwidenoise -force ' fullfile(unprocessedTopupDir, paFile) ' ' fullfile(topupDir, paFile)]);
                
    % Calculate and check the residuals.
    % The lack of anatomy in the residual maps is a marker of accuracy and signal-preservation during denoising
    % original dwi - denoised dwi = residuals  
    system(['mrcalc ' fullfile(unprocessedTopupDir, apFile) ' '  fullfile(topupDir, apFile) ' -subtract ' fullfile(topupDir, apResFile)]);
    system(['mrcalc ' fullfile(unprocessedTopupDir, paFile) ' '  fullfile(topupDir, paFile) ' -subtract ' fullfile(topupDir, paResFile)]);
    
    % correct for Gibbs’ Ringing Artifacts
    system(['mrdegibbs -force ' fullfile(topupDir, apFile) ' ' fullfile(topupDir, apFile)]);
    system(['mrdegibbs -force ' fullfile(topupDir, paFile) ' ' fullfile(topupDir, paFile)]);

    
    %% topup correction
    % extract the b0 from the AP and PA dwi image
    system(['fslroi ' fullfile(topupDir, apFile) ' ' fullfile(topupDir, apB0File) ' 0 1']);
    system(['fslroi ' fullfile(topupDir, paFile) ' ' fullfile(topupDir, paB0File) ' 0 1']);
    
    % merge the b0 images with PA and AP phase encoding directions
    system(['fslmerge -t ' fullfile(topupDir, appaB0File) ' ' fullfile(topupDir, apB0File) ' ' fullfile(topupDir, paB0File)]);
        
    % merge raw dwi_AP and dwi_PA in one single image
    system(['fslmerge -t ' fullfile(topupDir, appaFile) ' ' fullfile(topupDir, apFile) ' ' fullfile(topupDir, paFile)]);
    
    % Topup correction
    system(['topup --imain='  fullfile(topupDir, appaB0File) ' --datain=acqparams.txt --config=b02b0.cnf --out=' fullfile(topupDir, 'my_topup_results') ... 
        ' --iout=' fullfile(topupDir, 'my_hifi_b0')]);

   
    %% Eddy correction
    % Create an index file that specifies the phase encoding direction for each volume in the combined dMRI file. 
    % Combine bval and bvec files from the two dMRI scans
    nDirs = (197);
    index = [ones(nDirs,1); 2*ones(nDirs,1)];
    writematrix(index, fullfile(topupDir, 'index.txt'), 'Delimiter', 'space');
        
    % Combine bvac and bvec files from the two dMRI scans
    bvals = horzcat(load(fullfile(dwiDir, apFileBval)), load(fullfile(dwiDir, paFileBval)));
    writematrix(bvals, fullfile(topupDir, 'bval_combined.txt'), 'Delimiter', 'space');

    bvecs = horzcat(load(fullfile(dwiDir, apFileBvec)), load(fullfile(dwiDir, paFileBvec)));
    writematrix(bvecs, fullfile(topupDir, 'bvec_combined.txt'), 'Delimiter', 'space');

    % Generate a brain mask using the corrected b0 image
    system(['fslmaths ' fullfile(topupDir, 'my_hifi_b0.nii.gz') ' -Tmean ' fullfile(topupDir, 'my_hifi_b0_mean.nii.gz')])
    
    % BET the averaged b0 image
    system(['bet ' fullfile(topupDir, 'my_hifi_b0_mean.nii.gz') ' '  fullfile(topupDir, 'my_hifi_b0_mean_brain.nii.gz') ' -m -f 0.2'])
    
    % run eddy correction
    system(['eddy --imain=' fullfile(topupDir, appaFile) ' --mask=' fullfile(topupDir, 'my_hifi_b0_mean_brain.nii.gz') ...
        ' --acqp=' fullfile(projectDir, 'acqparams.txt') ' --index=' fullfile(topupDir, 'index.txt') ...
        ' --bvecs=' fullfile(topupDir, 'bvec_combined.txt') ...
        ' --bvals=' fullfile(topupDir, 'bval_combined.txt') ...
        ' --topup=' fullfile(topupDir, 'my_topup_results') ...
        ' --out=' fullfile(eddyDir, eddyFile) ' --repol --verbose'])


end
