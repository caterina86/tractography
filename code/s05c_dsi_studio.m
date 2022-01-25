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

%% create the SRC and recostruction DTI for dsi studio (deterministic tractography)

sub_i = 1:length(sub); % loop over subjects (eventually)
sub_ses = dir(fullfile(projectDir, 'rawdata', ['sub-' sub{sub_i}], 'ses-*'));


for ses_i = 1:numel(sub_ses) % for each scan session
    
    eddyDir = fullfile(projectDir, 'derivatives/eddy', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    eddyFile = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data.nii.gz'];
    fibDir_dsi = fullfile(projectDir, '/derivatives/dsi', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);

    if ~exist(fibDir_dsi) % Check if fiber directory exists
        mkdir(fibDir_dsi) % If not, create it
        else
    end
    
    % SRC
    system(['/Applications/dsi_studio.app/Contents/MacOS/dsi_studio --action=src --source=' ....
        fullfile(eddyDir, eddyFile) ...
      ' --bval=/Users/cp3488/Documents/tractography/Sample_dMRI/derivatives/topup/sub-0228/ses-01/bval_combined.bval ' ...
      ' --bvec=/Users/cp3488/Documents/tractography/Sample_dMRI/derivatives/eddy/sub-0228/ses-01/sub-0228_ses-01_dti01_eddy_corrected_data.eddy_rotated_bvecs' ...
      ' --output=' fullfile(fibDir_dsi, [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}] '.nii.gz.src'])]);
    

    % Reconstruction DTI
    system(['/Applications/dsi_studio.app/Contents/MacOS/dsi_studio --action=rec --source=' ...
        fullfile(fibDir_dsi, [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}] '.nii.gz.src']) ' --method=1'],'');

    % Recon GQI -> Generalized Q-sampling Imaging FIB image
    system(['/Applications/dsi_studio.app/Contents/MacOS/dsi_studio --action=rec --source=' ...
        fullfile(fibDir_dsi, [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}] '.nii.gz.src']) ' --method=4 --param0=1.25'],'');
    
end


