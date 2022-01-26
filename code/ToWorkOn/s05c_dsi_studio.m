clearvars;

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

% Specify user
user = 'caterina'; % name of the user
% choose 'server' if you are working on the server
% add your name if you are working on your local PC. In this case you
% should add your files locations in the following 'switch user'

% Specify sequence (NYUAD or CCAD)
sequence = 1; % 1-> NYUAD; 2-> CCAD

% Set the path
switch user
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
    case {'caterina'}
        projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output
    case {'Omnia'}
        projectDir = '~/Documents/GitHub/tractography/code'; % location output
    case {'bas'}
        projectDir = '/Users/rokers/Documents/MRI/Sample_dMRI'; % location output
    case {'Dalia'}
        projectDir = '~/Desktop/Sample_dMRI'; % location output
    case {'hannah'}
        projectDir = '/Users/hannah/Documents/MRI/Sample_dMRI'; %
end
addpath(genpath(fullfile(projectDir, 'code'))); % add user code to path

% Project variables
sub = {'0228'}; % initials of the subject
ses = {'01'}; % ID of the subject
hemi = {'lh', 'rh'};



%% create the SRC and recostruction DTI for dsi studio (deterministic tractography)

sub_i = 1:length(sub); % loop over subjects (eventually)
sub_ses = dir(fullfile(projectDir, 'rawdata', ['sub-' sub{sub_i}], 'ses-*'));


for ses_i = 1:numel(sub_ses) % for each scan session

    eddyDir = fullfile(projectDir, 'derivatives/eddy', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    eddyFile = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data.nii.gz'];
    fibDir_dsi = fullfile(projectDir, '/derivatives/dsi', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    topupDir = fullfile(projectDir, 'derivatives/topup', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    bvec = fullfile(eddyDir, [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data.eddy_rotated_bvecs']);

    if ~exist(fibDir_dsi) % Check if fiber directory exists
        mkdir(fibDir_dsi) % If not, create it
        else
    end

    % SRC
    system(['/Applications/dsi_studio.app/Contents/MacOS/dsi_studio --action=src --source=' ....
        fullfile(eddyDir, eddyFile) ...
      ' --bval=' fullfile(topupDir, 'bval_combined.txt') ...
      ' --bvec=' fullfile(bvec) ...
      ' --output=' fullfile(fibDir_dsi, [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}] '.nii.gz.src'])]);

    % Reconstruction DTI
    system(['/Applications/dsi_studio.app/Contents/MacOS/dsi_studio --action=rec --source=' ...
        fullfile(fibDir_dsi, [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}] '.nii.gz.src']) ' --method=1'],'');

    % Recon GQI -> Generalized Q-sampling Imaging FIB image
    system(['/Applications/dsi_studio.app/Contents/MacOS/dsi_studio --action=rec --source=' ...
        fullfile(fibDir_dsi, [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}] '.nii.gz.src']) ' --method=4 --param0=1.25'],'');


   
    
    %% Deterministic tractography
    numFibers = [1e4; 1e4];
    diffusion_lists = dir(fullfile(fibDir_dsi, '*gqi.1.25.fib.gz'));
    Diffusion_file = fullfile(diffusion_lists.folder, diffusion_lists.name);
    roiDir = fullfile(projectDir, '/derivatives/ROIs', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    tracking_parameter_id_dsi_studio='c9A99193FBB8D243FdbA041b1643Da7cb01b02b01da';% limit angular threshold 50 degrees

    for jj = 1:length(hemi)

        maxLength = 150;
        roi1 = fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']); % FreeSurfer LGN coregistered to diffusion space
        roi2 = fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz']); % FreeSurfer V1 coregistered to diffusion space

        outFile = fullfile(fibDir_dsi, ['dti' ses{ses_i} '_' hemi{jj} '_Deterministic_OR_' num2str(numFibers(1)/1000) 'k.tck']);

        % Run the tractography
        system(['/Applications/dsi_studio.app/Contents/MacOS/dsi_studio --action=trk --source=' Diffusion_file ' --parameter_id=' tracking_parameter_id_dsi_studio ' --output=' outFile ' --seed=' roi2 ' --end=' roi1]);
  
        % Optic Tracts
        maxLength = 50;
        roi1 = fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']); % FreeSurfer LGN
        roi2 = fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_2dilM.nii.gz'); % Freesurfer Optic Chiasm expanded -> 3dil

        outFile = fullfile(fibDir_dsi, ['dti' ses{ses_i} '_' hemi{jj} '_Deterministic_OT_' num2str(numFibers(2)/1000) 'k.tck']);

        % Run the tractography
        system(['/Applications/dsi_studio.app/Contents/MacOS/dsi_studio --action=trk --source=' Diffusion_file ' --parameter_id=' tracking_parameter_id_dsi_studio ' --output=' outFile ' --seed=' roi2 ' --end=' roi1]);


    end


end
