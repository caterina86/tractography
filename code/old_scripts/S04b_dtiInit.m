%% dtiInit 

% https://web.stanford.edu/group/vista/cgi-bin/wiki/index.php/DTI_Preprocessing

% Alignement of the diffusion preprocessed data to the T1 (ACPC)
% dt6.mat -> to perform the AFQ Whole Brain Tractography on the diffusion data aligned to the T1 (ACPC)
% Extract the fa values from the whole brain
% Output -> folder called ['dti40trilin_'num2str(curScan)]

% extract LGN, V1, Optic Chiasm and Thalamus to perform the OR and OT tractography

clear all;

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
user = 'caterina'; % name of the user
fmriprep = 0; % 1 -> we performed fmriprep; 0 -> we did not perform fmriprep

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
        projectDir = '/Users/hannah/Documents/MRI/Sample_dMRI';
end
addpath(genpath(fullfile(projectDir, 'code'))); % add user code to path
addpath(genpath('/Users/cp3488/Data/GitHub/Prakash/Toolbox')); % add user code to path
addpath(genpath('/Users/cp3488/matlab/spm12')); % add user code to path

sub = {'ccad0203'}; % initials of the subject
ses = {'01'}; % ID of the session
hemi = {'lh', 'rh'};




%% Extract Regions of Interest

runDtiInit = 'true';
encodingOrientation = {'AP'}; % Phase encoding direction for each participant

sub_i = 1:length(sub); % loop over subjects (eventually)

sub_ses = dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'));
if isempty(sub_ses)
    error(['No files found in ' projectDir]);
end
    

for ses_i = 1:numel(sub_ses) % for each scan session
    
    eddyDir = fullfile(projectDir, 'derivatives/eddy', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);        
    roiDir = fullfile(projectDir, '/derivatives/ROIs', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    anatDir = fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'anat');
    dwiDir = fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'dwi');
    dt6Dir = fullfile(projectDir, 'derivatives/dt6', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    topupDir = fullfile(projectDir, 'derivatives/topup', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);

    if fmriprep == 1 % if fmriprep was performed
        anatPrepDir = fullfile(projectDir, 'derivatives/fmriprep', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
        t1File = fullfile(anatPrepDir, 'anat/',['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_desc-preproc_T1w.nii.gz']);
        
    else % if fmriprep was not performed
        anatPrepDir = fullfile(projectDir, 'derivatives/anat_prep', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);        
        t1File = fullfile(anatDir, 't1.nii.gz');
    end  

    
    % Define file names 
    eddyFileName = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data.nii.gz'];
    t1ACPCFileName = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_T1w_acpc.nii.gz']; 
    t1ACPCFile = fullfile(anatPrepDir,filesep,t1ACPCFileName);

    % read nifti of the inputs
    dtiTopCor = niftiRead(fullfile(eddyDir,filesep, eddyFileName)); 
    t1Raw = niftiRead(t1File);

    
    %% ACPC-ALIGN T1 IMAGE 
    % Detect if the t1_acpc exists or create it (if not)
    if exist(t1ACPCFile,'file') % If a t1_acpc.nii.gz file exists already
        warning('Skipping ACPC alignment. Using the existing ACPC-aligned T1...');
        t1ACPC = niftiRead(t1ACPCFile);
        pause(3);

    else % If no acpc-corrected T1 exits 
        mrAnatAverageAcpcNifti(t1Raw.fname,t1ACPCFile);
        t1ACPC = niftiRead(t1ACPCFile);    
    end

    close all;

    %% dtiInit            
    % Define the parameters (dwParams)
    % Important: Define these parametes according to your study

    dwParams = struct; 
    if strcmp(encodingOrientation{1},'AP')
        dwParams.phaseEncodeDir = 2;
    elseif strcmp(encodingOrientation{1},'LR')
        dwParams.phaseEncodeDir = 1;
    else
        error('Unrecognized phase encode direction for dtiInit. Please specify either "AP" or "LR".');
    end

    mkdir(dt6Dir)

    dwParams.bvalue                  = [];
    dwParams.gradDirsCode            = [];
    dwParams.dt6BaseName             = fullfile(dt6Dir, [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti40trilin_' num2str(ses_i)]); 
    dwParams.clobber                 = 0;
    dwParams.flipLrApFlag            = false;
    dwParams.numBootStrapSamples     = 500;
    dwParams.fitMethod               = 'ls';
    dwParams.nStep                   = 50;
    dwParams.eddyCorrect             = -1; % not do the eddy correction
    dwParams.excludeVols             = [];
    dwParams.bsplineInterpFlag       = false;
    dwParams.dwOutMm                 = dtiTopCor.pixdim(1:3); % pixel resolution
    dwParams.rotateBvecsWithRx       = false; % check if this option is correct
    dwParams.rotateBvecsWithCanXform = 1; % check if this option is correct

    dwParams.bvecsFile = fullfile(topupDir,'bvec_combined.txt');  
    dwParams.bvalsFile = fullfile(topupDir,'bval_combined.txt'); 

    if strcmp(runDtiInit,'true') % If the user indicates they want to run dtiInit
        if ~exist(dwParams.dt6BaseName) % If there isn't an existing dt6 file directory

            dtiInit(dtiTopCor.fname, t1ACPC.fname, dwParams); % run dtiInit

        else
            choiceInit = questdlg('Warning: A dt6 directory already exists for this participant. What would you like to do?',...
                'dt6 directory detected',...
                'Use existing dt6','Generate new dt6','Abort','Abort');
            switch choiceInit
                case 'Use existing dt6'
                    warning('Bypassing dtiInit, using existing dt6...')
                    pause(3);

                case 'Generate new dt6'
                    warning('Generating new dt6. This will overwrite existing dt6 directory...')
                    % run dtiInit
                    dtiInit(dtiTopCor.fname, t1ACPC.fname, dwParams);

                case 'Abort'
                    error('Aborting...');
            end

        end
    end
end



%% Mrtrix3 whole brain tractography: 

% 1. FOD generation and estimation -> wmfod.mif

% This section generates fiber orientation direction (FOD) estimates for tractography:
% 1. Reslice the aparc+aseg output of freesurfer to the T1 resolution
% 2. Coregister the aparc+aseg resliced to diffusion volume (dMRI) applying the matrix created coregistering te T1 to the diffusion volume
% 3. Segmentation (5 tissue types) of the T1 coregisted to the diffusion volume -> 5ttgen
% 4. Generate normal orientation response function estimates (FOD) -> dwi2response dhollander

t1FileCrop = fullfile(anatPrepDir, 't1_crop_restore.nii.gz');
fibDir = fullfile(projectDir, '/derivatives/mrtrix3', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
ses_i = 01;

    % Coregistration preprocessed T1 to the ACPC space to extract the coregistration matrix
    system(['flirt -in ' t1FileCrop ' -ref ' ...
        '/Users/cp3488/Documents/tractography/Sample_dMRI/derivatives/anat_prep/sub-ccad0203/ses-01/sub-ccad0203_ses-01_T1w_acpc.nii.gz -out ' ...
        '/Users/cp3488/Documents/tractography/Sample_dMRI/derivatives/anat_prep/sub-ccad0203/ses-01/sub-ccad0203_ses-01_crop_restore_acpc.nii.gz -omat ' ...
        '/Users/cp3488/Documents/tractography/Sample_dMRI/derivatives/anat_prep/sub-ccad0203/ses-01/t1_crop_restore_flirt_acpc_xfm.mat -dof 6'])
    
    % Generate 5tt mask (aligned with T1-ACPC volume)
    system(['5ttgen fsl /Users/cp3488/Documents/tractography/Sample_dMRI/derivatives/anat_prep/sub-ccad0203/ses-01/sub-ccad0203_ses-01_crop_restore_acpc.nii.gz ' ...
        ' /Users/cp3488/Documents/tractography/Sample_dMRI/derivatives/anat_prep/sub-ccad0203/ses-01/5tt_acpc.nii.gz']) % Run 5ttgen command with T1-registered to the diffusion image       

%     % Problem with dtiInit -> bvecs flipped on the x-axes
%     % (https://community.mrtrix.org/t/afq-tract-segmentation-using-mrtrix3-wb-tractography/1832/4)
%     % To solve this, rotate the x-axis of bvecs, and save the new file
%     % adding the flag _corrected.bvecs
%     bvecs = '/Users/cp3488/Documents/tractography/Sample_dMRI/derivatives/dt6/sub-ccad0203/ses-01/sub-ccad0203_ses-01_dti01_eddy_corrected_data_aligned_trilin_noMEC.bvecs';
%     bvec = load(bvecs);
%     bvec = [bvec(1,:)*-1; bvec(2,:)*1; bvec(3,:)*1]; 
    
%     writematrix(bvec, [baseDir subIDs{ii} filesep subIDs{ii} '_dti' num2str(ee) '_eddy_corrected_data_aligned_trilin_noMEC_corrected.txt'], 'Delimiter', ' ')
%     copyfile([baseDir subIDs{ii} filesep subIDs{ii} '_dti' num2str(ee) '_eddy_corrected_data_aligned_trilin_noMEC_corrected.txt'],[baseDir subIDs{ii} filesep subIDs{ii} '_dti' num2str(ee) '_eddy_corrected_data_aligned_trilin_noMEC_corrected.bvecs'])

    % Define paths (convenience for commands below)
    eddy = fullfile(dt6Dir, ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_dti01_eddy_corrected_data_aligned_trilin_noMEC.nii.gz']);
    bvec = fullfile(dt6Dir, ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_dti01_eddy_corrected_data_aligned_trilin_noMEC.bvecs']); % Use the output of dtiInit.m
    bval = fullfile(dt6Dir, ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_dti01_eddy_corrected_data_aligned_trilin_noMEC.bvals']);
    mask = fullfile(dt6Dir, ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_dti40trilin_' num2str(ses_i)], 'bin/brainMask.nii.gz'); % brain mask aligned to ACPC

    if ~exist(fibDir) % Check if fiber directory exists
        mkdir(fibDir) % If not, create it
    else
    end
    
    % Generate normal orientation response function estimates
    system(['dwi2response dhollander ' eddy ' -fslgrad ' bvec ' ' bval ' ' ...
        fibDir '/responseEstimate_sfwm.txt ' ...
        fibDir '/responseEstimate_gm.txt ' ...
        fibDir '/responseEstimate_csf.txt -mask ' mask]) 
        
    % Generate normal fiber orientation distribution estimates (FOD)
    system(['dwi2fod msmt_csd -mask ' mask ' ' eddy ' -fslgrad ' bvec ' ' bval ' ' ...
        fibDir '/responseEstimate_sfwm.txt ' fibDir '/wmfod.mif ' ...
        fibDir '/responseEstimate_gm.txt ' fibDir '/gmfod.mif ' ...
        fibDir  '/responseEstimate_csf.txt ' fibDir '/csffod.mif '])

    % 3. Whole brain tractography (mrtrix3)
    act = '/Users/cp3488/Documents/tractography/Sample_dMRI/derivatives/anat_prep/sub-ccad0203/ses-01/5tt_acpc.nii.gz'; % aligned to ACPC
    wmfod = fullfile(fibDir, 'wmfod.mif'); % extracted from eddy_corrected_data.nii.gz aligned to T1-acpc space
    numFibers_WB = 5000000;
    outFile = fullfile(fibDir, ['dti' ses{ses_i} '_wholeBrain_ACT_' num2str(numFibers_WB/1000000) 'M.tck']);       
    
    % Run tractography
    system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' act  ' -select ' num2str(numFibers_WB(1)) ' -seeds 0 ']);
  