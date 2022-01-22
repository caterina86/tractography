%% 2021 Prakash Processing Pipeline
% Written by: Nathaniel Miller (NYUAD, April 2020) and Caterina Pedersini (NYUAD, January 2021)
%
% This script perform different steps:

% 1. Preprocessing of raw T1 and dMRI data.
% FLAG -> t1_preprocessing 
% FLAG -> freesurfer
% FLAG -> dmri_dndg
% FLAG -> synb0_correction
% FLAG -> eddy_correction

% 2. dtiInit -> align the diffusion to the T1 (ACPC) and extract the dt6.mat
% AFQ for whole brain tractography and extraction of late-visual and non-visual pathways
% FLAG -> create_dt6
% FLAG -> AFQ_tractography

% 3.MRTrix 3 -> whole brain tractography
% FLAG -> mrtrix3_wholeBrain

% 4. MRTrix3 -> extraction of ROIs from Freesurfer and OR tractography
% FLAG -> freesurfer_ROIs
% FLAG -> mrtrix3_OR

% 5. MRTrix3 -> OT tractography
% FLAG -> mrtrix3_OT

% 6. Clean the fibers (cleaning the OR and OT):
% FLAG -> cleaning_tracts

% % TO DO before running the script:
% For each subject create two folders:
% 1. raw/ with the raw diffusion data (dti.nii/dti.bvec/dti.bval/dti.json)
% 2. t1/ with the raw t1.nii.gz

% dependences in this script

% Freesurfer, fsl, mrtrix3, docker (for  Synb0-DISCO - topup)


%% Setup
clear all; close all;

% Processing flags
t1_preprocessing = 0;
freesurfer = 0;
dmri_dndg = 0;
synb0_correction = 0;
eddy_correction = 0;

% dtiInit
create_dt6 = 1;
AFQ_tractography = 1;

% mrtix3 Whole Brain
mrtrix3_wholeBrain = 1;

% mrtix3 Optic Radiations
freesurfer_ROIs = 0;
mrtrix3_OR = 1;

% mrtix3 Optic Tracts
mrtrix3_OT = 1;

% cleaning the fibers:
cleaning_tracts = 1;

% Define paths
baseDir = '/Users/cp3488/Documents/tractography_16092021/'; % Update with path to clinical data
subIDs = {'sub-P01'}; % change the name of identification number of the subject
hemi = {'lh','rh'};

rawDir = 'rawdata/';
dwiDir = 'dwi/';
t1Dir = 'anat/';
% derivatives:
eddyDir = 'derivatives/eddy/';
roiDir = 'derivatives/ROIs/';
AFQDir = 'derivatives/AFQ/';
fibDir = 'derivatives/mrtrix3/';
fsDir = 'derivatives/freesurfer/';
anat_prep = 'derivatives/anat_prep/';
dt6 = 'derivatives/dt6/';
topup = 'derivatives/topup/';

temp = 'temp/';
unprocessed = 'unprocessed/';

% IMPORTANT: Set the path for the freesurfer subjects, in the bash_profile
fsLicense = [baseDir fsDir 'license.txt'];

% Add paths
addpath(genpath('~/Data/GitHub/Prakash/Toolbox/vistasoft')); % vistasoft location
addpath(genpath('~/Data/GitHub/Prakash/Toolbox/AFQ')); % afq location

% Freesurfer
setenv( 'FREESURFER_HOME', '/Applications/freesurfer');
freesurferdir = getenv('FREESURFER_HOME');
freesurferpath = sprintf('%s/matlab',freesurferdir);
path(path, freesurferpath);
setenv ('SUBJECTS_DIR', fsDir); 

% MRTrix3
addpath(genpath('/usr/local/mrtrix3/matlab')); % mrtrix3 location

% FSL
setenv( 'FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); %added to tell where to save the fsl outputs
fsldir = getenv('FSLDIR');
fsldirmpath = sprintf('%s/etc/matlab',fsldir);
path(path, fsldirmpath);




%% Preprocessing:

% 1. Dicom to nifti (in the terminal) -> outputs created for each subject and session: dti.nii.gz, dti.bvec, dti.bval, dti.json

% /Users/cp3488/dcm2niix-1.0.20200331/build/bin/dcm2niix -z y -f 'name_output' -o 'path_to_output' 'path_to_dicoms'

% dcm2niix -z y -f test Documents/tractography_class_16092021 Documents/tractography_class_16092021/sourcedata/sub-p01_ses-01/DTI
% -------------------------------------------------------------------------------------------------------------------------------------------

% 2. T1 Preprocessing

% T1 FAST only for the T1 acquired in the first session
if t1_preprocessing == 1
    for ii = 1:numel(subIDs)
        mkdir(fullfile(baseDir, anat_prep, subIDs{ii}, '/ses-1/'))
        
        % extract the FOV only showing the brain (cutting the neck)
        system(['robustfov -i ' baseDir, rawDir, subIDs{ii}, '/ses-1/', t1Dir, [subIDs{ii} '_ses-1_t1.nii.gz'] ' -r ' ...  
            baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop.nii.gz']]);
        
        system(['fast -B ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop.nii.gz']]);
    end
end

% Freesurfer only for the first session -> Note: $SUBJECTS_DIR must be set to fsDir defined above
if freesurfer == 1
    for ii = 1:numel(subIDs) % FreeSurfer recon-all runs on a single thread, use parfor to run multiple patients in parallel
       system(['recon-all -i ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop_restore.nii.gz'] ' -subjid ' subIDs{ii} ' -all'])
    end
end

% ---------------------------------------------------------------------------------------------------------------------------------------------

% 3. dMRI preprocessing

% Denoise and Remove Gibbs Ringing Artifacts from dMRI Data
% https://andysbrainbook.readthedocs.io/en/latest/MRtrix/MRtrix_Course/MRtrix_04_Preprocessing.html
% 1. denoise dMRI data
% 2. mrcalc to extract the residuals -> visualize the result in fsleyes -> the lack of anatomy in the residual maps is a marker of accuracy and signal-preservation during denoising
% 3. mrdegibbs to removes Gibbs’ ringing artifacts from the data

if dmri_dndg == 1
    for ii = 1:numel(subIDs)
        for ee = 1:numel(dir(fullfile(baseDir, rawDir, subIDs{ii}, 'ses-*'))) % for each scan session
            
            mkdir([baseDir topup subIDs{ii} filesep 'ses-' num2str(ee) filesep unprocessed]); % Make "unprocessed" directory to backup raw dti volumes before processing (susbequent steps will overwrite)
            
            copyfile(fullfile(baseDir, rawDir, subIDs{ii}, ['ses-' num2str(ee)], dwiDir, [subIDs{ii} '_ses-' num2str(ee) '_dti.nii.gz']), ...
                fullfile(baseDir, topup, subIDs{ii}, ['ses-' num2str(ee)], unprocessed, [subIDs{ii} '_ses-' num2str(ee) '_dti.nii.gz']));

            system(['dwidenoise -force ' baseDir rawDir subIDs{ii} filesep 'ses-' num2str(ee) filesep dwiDir [subIDs{ii} '_ses-' num2str(ee) '_dti.nii.gz '] ...
                baseDir topup subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti.nii.gz ']])
            
            system(['mrcalc ' baseDir topup subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti.nii.gz '] ...
                baseDir topup subIDs{ii} filesep 'ses-' num2str(ee) filesep unprocessed [subIDs{ii} '_ses-' num2str(ee) '_dti.nii.gz '] ...
                ' -subtract ' baseDir topup subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_res.nii.gz ']])            
            
            system(['mrdegibbs -force ' baseDir topup subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti.nii.gz '] ...
                baseDir topup subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti.nii.gz ']])
        
        end
    end
end

% Topup Correction - to conclude
if topup_correction == 1
    for ii = 1:numel(subIDs)
        for ee = 1:numel(dir(fullfile(baseDir, rawDir, subIDs{ii}, 'ses-*'))) % for each scan session

        fslroi dwi_AP AP_b0 0 1
        fslroi dwi_PA PA_b0 0 1
        fslmerge -t AP_PA_b0 AP_b0 PA_b0 
        system(['topup --imain= ' AP_PA_b0 ' --datain=' acqparams.txt ' --config=' b02b0.cnf ' --out=' my_topup_results  ' --iout=' my_hifi_b0])
        fslmerge -t dwi_AP_PA_merge dwi_AP dwi_PA
        
        end
    end
end


% 4. Eddy Correction
% Preparation of files in the folder:

if eddy_correction == 1
    for ii = 1:numel(subIDs)
        if exist([baseDir rawDir subIDs{ii} filesep 'acqparams.txt']) == 0 % Check if acqparams.txt file exists
            copyfile([baseDir 'acqparams.txt'],[baseDir rawDir subIDs{ii} filesep 'acqparams.txt']) % If not, copy from root directory to subject dwiDir
        else
        end
        for ee = numel(dir(fullfile(baseDir, rawDir, subIDs{ii}, 'ses-*'))) % for each scan session
            if exist([baseDir topup subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_index.txt']]) == 0 % Check if index file exists
                writematrix(ones(numel(dlmread([baseDir rawDir subIDs{ii} filesep 'ses-' num2str(ee) filesep dwiDir [subIDs{ii} '_ses-' num2str(ee) '_dti.bval']])),1), ...
                    [baseDir topup subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_index.txt']],'FileType','text') % If not, create it -- create list of ones (first line of acqparams.txt) the length of the number of shells (read from bval) and save as dti*_index.txt
            else
            end
            %system(['eddy_cuda --imain=' baseDir subIDs{ii} dwiDir 'dti' num2str(ee) '.nii.gz --mask=' baseDir subIDs{ii} dwiDir 'dti' num2str(ee) '_b0_u_brain_mask.nii.gz --acqp=' baseDir subIDs{ii} dwiDir 'acqparams.txt --index=' baseDir subIDs{ii} dwiDir 'dti' num2str(ee) '_index.txt --bvecs=' baseDir subIDs{ii} dwiDir 'dti' num2str(ee) '.bvec --bvals=' baseDir subIDs{ii} dwiDir 'dti' num2str(ee) '.bval --topup=' baseDir subIDs{ii} dwiDir 'dti' num2str(ee) '_topup --out=' baseDir subIDs{ii} dwiDir 'dti' num2str(ee) '_eddy_corrected_data --repol --mporder=18 --json=' baseDir subIDs{ii} dwiDir 'dti' num2str(ee) '.json --s2v_niter=10 --s2v_lambda=1 --s2v_interp=trilinear --estimate_move_by_susceptibility --mbs_niter=10 --mbs_lambda=10 --mbs_ksp=10'])        
            mkdir ([baseDir eddyDir subIDs{ii} filesep 'ses-' num2str(ee)])
        end
    end
end

% Run eddy correction in the cluster -> INSTRUCTIONS:

% 1. Enter the cluster: ssh cp3488@hpc.abudhabi.nyu.edu -p 4410
% 2. Enter Dalma: ssh cp3488@dalma.abudhabi.nyu.edu
% 3. In the CLUSTER: go to /scratch/cp3488/MRI/
% 4. Create the folders:
% - subj/
% - subj/raw
% - subj/raw/eddy/

% 5. From the LOCAL PC: 
% Copy the files in the cluster to run the eddy_correction -> rsync -av

% 6. In the CLUSTER: 
% Start an interactive session and load the Braimcore shell
% srun --pty -n 10 --gres=gpu:1 -p nvidia -t 12:00:00 bash
% module load NYUAD/4.0 singularity braimcore
% braimcore shell

% 7. Go in the folder containing the dmri images to be corrected with eddy
% (/scratch/cp3488/MRI/subj/raw/)

% 8. Run eddy_cuda: 
%% TODO -> CHANGE this command according to the output:

% sh eddy.sh that contains the following command line:
% eddy_cuda --imain=dti1.nii.gz --mask=dti1_b0_u_brain_mask.nii.gz --acqp=acqparams.txt 
% --index=dti1_index.txt --bvecs=dti1.bvec --bvals=dti1.bval --topup=dti1_topup --out=eddy/dti1_eddy_corrected_data 
% --repol --mporder=18 --json=dti1.json --s2v_niter=10 --s2v_lambda=1 --s2v_interp=trilinear --estimate_move_by_susceptibility 
% --mbs_niter=10 --mbs_lambda=10 --mbs_ksp=10 --verbose

% 9. Copy the results of eddy correction in the local PC -> 
% rsync -av cp3488@dalma.abudhabi.nyu.edu:/scratch/cp3488/MRI/subj/raw/eddy/ /Users/cp3488/Documents/Prakash/data/subj/raw/eddy/

% -----------------------------------------------------------------------------------------------------------------------------------------------

%% dtiInit 

% https://web.stanford.edu/group/vista/cgi-bin/wiki/index.php/DTI_Preprocessing

% Alignement of the diffusion preprocessed data to the T1 (ACPC)
% dt6.mat -> to perform the AFQ Whole Brain Tractography on the diffusion data aligned to the T1 (ACPC)
% Extract the FA/MD values from the whole brain
% Output -> folder called ['dti40trilin_'num2str(curScan)]

if create_dt6 == 1   
    runDtiInit = 'true';
    encodingOrientation = {'AP'}; % Find this information in the .json file
    
    for curSub = 1:numel(subIDs) % for each subject
        try
        close all;
        
        for curScan = 1:numel(dir(fullfile(baseDir, rawDir, subIDs{ii}, 'ses-*'))) % for each scan session
            
            cd(fullfile(baseDir,filesep, rawDir, subIDs{curSub}, ['ses-' num2str(curScan)], dwiDir));
            dti_dir = fullfile(baseDir,filesep, rawDir, subIDs{curSub}, ['ses-' num2str(curScan)], dwiDir); % Define the base dti directory
            eddy_dir = fullfile(baseDir, eddyDir, subIDs{ii}, filesep, ['ses-' num2str(curScan)]); % Define the base eddy directory
            t1_dir = fullfile(baseDir, rawDir, subIDs{ii}, '/ses-1/', t1Dir); % Define the base dti directory
 
            % RENAME BVAL & BVEC FILES in the raw folder  
            bvalFile = load([subIDs{ii} '_ses-' num2str(curScan) '_dti.bval']);
            bvecFile = load([subIDs{ii} '_ses-' num2str(curScan) '_dti.bvec']);
            dlmwrite(['bval' num2str(curScan) '.txt'], bvalFile,'delimiter',' '); % save as a space-delimited text file called "bval.txt"
            dlmwrite(['bvec' num2str(curScan) '.txt'], bvecFile,'delimiter',' '); % save as a space-delimited text file called "bvec.txt"
            
            % Back to the baseDir
            cd(baseDir)            
            
            % copy eddy corrected image
            copyfile([eddy_dir filesep 'dti' num2str(curScan) '_eddy_corrected_data.nii.gz'],[eddy_dir filesep subIDs{curSub} '_ses-' num2str(curScan) '_dti_eddy_corrected_data.nii.gz']);
            
            % Define file names 
            dtiFileName = ([subIDs{curSub} '_ses-' num2str(curScan) '_dti.nii.gz']); % load the dMRI file       
            dtiTopCor = niftiRead(fullfile(eddy_dir, [subIDs{curSub} '_ses-' num2str(curScan) '_dti_eddy_corrected_data.nii.gz'])); % load the eddy 
            t1Raw = niftiRead(fullfile(t1_dir, [subIDs{curSub} '_ses-' num2str(curScan) '_t1.nii.gz'])); % load the dMRI file
            
            
            %% ACPC-ALIGN T1 IMAGE 
            % Detect if the t1_acpc exists
            if exist([baseDir, anat_prep, subIDs{ii}, filesep, 'ses-1/' [subIDs{ii} '_ses-1_t1_acpc.nii.gz']],'file') % If a t1_acpc.nii.gz file exists already
                warning('Skipping ACPC alignment. Using the existing ACPC-aligned T1...');
                t1ACPCFileName = [subIDs{ii} '_ses-1_t1_acpc.nii.gz'];
                t1ACPC = niftiRead(fullfile(baseDir, anat_prep, subIDs{ii}, filesep, 'ses-1/' ,filesep,t1ACPCFileName));
                pause(3);
                
            else % If no acpc-corrected T1 exits 
                mrAnatAverageAcpcNifti(t1Raw.fname, [baseDir, anat_prep, subIDs{ii}, filesep, 'ses-1/', [subIDs{ii} '_ses-1_t1_acpc.nii.gz']]);
                t1ACPCFileName = [subIDs{ii} '_ses-1_t1_acpc.nii.gz'];
                t1ACPC = niftiRead(fullfile(baseDir, anat_prep, subIDs{ii}, filesep, 'ses-1/' ,filesep,t1ACPCFileName));
            end
        
            %% dtiInit            
            % Define the parameters (dwParams)
            dwParams = struct; 
            if strcmp(encodingOrientation{1},'AP')
                dwParams.phaseEncodeDir = 2;
            elseif strcmp(encodingOrientation{1},'LR')
                dwParams.phaseEncodeDir = 1;
            else
                error('Unrecognized phase encode direction for dtiInit. Please specify either "AP" or "LR".');
            end

            dwParams.bvalue                  = [];
            dwParams.gradDirsCode            = [];
            dwParams.dt6BaseName             = [baseDir dt6 subIDs{ii} filesep 'ses-' num2str(curScan) '/dti40trilin_',num2str(curScan)]; 
            dwParams.clobber                 = 0;
            dwParams.flipLrApFlag            = false;
            dwParams.numBootStrapSamples     = 500;
            dwParams.fitMethod               = 'ls';
            dwParams.nStep                   = 50;
            dwParams.eddyCorrect             = -1; % not do the eddy correction
            dwParams.excludeVols             = [];
            dwParams.bsplineInterpFlag       = false;
            dwParams.dwOutMm                 = dtiTopCor.pixdim(1:3);
            dwParams.rotateBvecsWithRx       = false;
            dwParams.rotateBvecsWithCanXform = 1;

            dwParams.bvecsFile = fullfile(dti_dir,['bvec' num2str(curScan) '.txt']);  
            dwParams.bvalsFile = fullfile(dti_dir,['bval' num2str(curScan) '.txt']); 

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
        catch me
            disp(['Error in subject ' subIDs{curSub} ' create dt6.mat']);
        end
    end
end
        
            
%% AFQ - Automated Fiber Quantification - Deterministic tractography
% To see an example: http://yeatmanlab.github.io/AFQ/tutorials/AFQ_example
% Output -> folder called [AFQ]

if AFQ_tractography == 1
tic;

    for ii = 1:numel(subIDs)
        try
        close all;
        
        for curScan = 1:numel(dir(fullfile(baseDir, rawDir, subIDs{ii}, 'ses-*')))
          
            % load the dt6.mat file -> ACPC space
            dt = dtiLoadDt6(fullfile([baseDir, dt6, subIDs{ii}, filesep, ['ses-' num2str(curScan)] ['/dti40trilin_' num2str(curScan)] '/dt6.mat'])); % file created from the raw data (dMRI and T1)
            % load the T1 mage aligned to AVPC space    
            t1ACPCFileName = [subIDs{ii} '_ses-1_t1_acpc.nii.gz'];
            t1ACPC = niftiRead(fullfile(baseDir, anat_prep, subIDs{ii}, filesep, 'ses-1/' ,filesep,t1ACPCFileName));
            % Create folder AFQ for the outputs:
            mkdir([baseDir AFQDir]);
            mkdir([baseDir AFQDir subIDs{ii} filesep 'scan_' num2str(curScan)]);

            %% Whole brain tractography with AFQ:
            if exist([baseDir, AFQDir, subIDs{ii}, filesep, 'scan_' num2str(curScan), filesep, subIDs{ii} '_WholeBrainTractography_', num2str(curScan), '_AFQ.mat'],'file')
                load([baseDir, AFQDir, subIDs{ii}, filesep, 'scan_' num2str(curScan), filesep, subIDs{ii} '_WholeBrainTractography_', num2str(curScan), '_AFQ.mat'])
            else
                wholebrainFG = AFQ_WholebrainTractography(dt); 
                save([baseDir, AFQDir, subIDs{ii}, filesep, 'scan_' num2str(curScan), filesep, subIDs{ii} '_WholeBrainTractography_', num2str(curScan), '_AFQ'], 'wholebrainFG', '-v7.3');            
            end    
            
            %% Segment the whole-brain fiber group into 20 fiber tracts
            if exist([baseDir, AFQDir, subIDs{ii}, filesep, 'scan_' num2str(curScan), filesep, subIDs{ii} '_fg_classified_', num2str(curScan) '.mat'],'file')
                load([baseDir, AFQDir, subIDs{ii}, filesep, 'scan_' num2str(curScan), filesep, subIDs{ii} '_fg_classified_', num2str(curScan) '.mat']);
            else
                fg_classified = AFQ_SegmentFiberGroups(dt, wholebrainFG);
                save([baseDir, AFQDir, subIDs{ii}, filesep, 'scan_' num2str(curScan), filesep, subIDs{ii} '_fg_classified_', num2str(curScan)], 'fg_classified');
            end
            
            % fg_classified.subgroup defines the fascicle that each fiber belongs to.
            % We can convert fg_classified to a 1x20 structured array of fiber groups where each entry in the array is a segmented fiber tract. 
            fg_classified = fg2Array(fg_classified);
            
            % Visualization of fibres:
            % Whole brain
            b0 = readFileNifti([baseDir, dt6, subIDs{ii}, filesep, ['ses-' num2str(curScan)] ['/dti40trilin_' num2str(curScan)], '/bin/b0.nii.gz']);
            AFQ_RenderFibers(wholebrainFG, 'numfibers',1000, 'color', [1 .6 .2]); % Whole brain tractography
            AFQ_AddImageTo3dPlot(b0,[-2, 0, 0]);
            saveas(figure(1),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'WB_classified.fig']);
            saveas(figure(1),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'WB_classified.bmp']);

            % Late-visual pathways left hemisphere       
            AFQ_RenderFibers(fg_classified(9),'numfibers',400,'color',[0 0 1]);  % Render 400 CFMajor fibers 
            % To add this tract to the same plotting window set the 'newfig' input to false.
            AFQ_RenderFibers(fg_classified(11),'numfibers',400,'color',[0 1 0],'newfig',false); % Render 400 IFOF fibers 
            % % Render 400 uncinate fibers in yellow
            AFQ_RenderFibers(fg_classified(15),'numfibers',400,'color',[1 1 0],'newfig',false); % Render 400 SLF fibers
            % % Render 400 arcuate fibers in green.
            AFQ_RenderFibers(fg_classified(13),'numfibers',400,'color',[1 0 0],'newfig',false); % Render 400 ILF fibers
            % % Then add the slice X = -2 to the 3d rendering.
            %AFQ_AddImageTo3dPlot(b0,[-2, 0, 0]);
            AFQ_AddImageTo3dPlot(t1ACPC,[-2, 0, 0]);
            saveas(figure(2),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Late_visual_left_classified.fig']);
            saveas(figure(2),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Late_visual_left_classified.bmp']);
            
            % Non-visual pathways left hemisphere       
            AFQ_RenderFibers(fg_classified(3),'numfibers',400,'color',[0 0 1]); % Render 400 CST fibers.
            % To add this tract to the same plotting window set the 'newfig' input to false.
            AFQ_RenderFibers(fg_classified(17),'numfibers',400,'color',[0 1 0],'newfig',false); % Render 400 UF fibers 
            % % Render 400 uncinate fibers in yellow
            AFQ_RenderFibers(fg_classified(5),'numfibers',400,'color',[1 1 0],'newfig',false); % Render 400 CC fibers 
            % % Render 400 arcuate fibers in green.
            AFQ_RenderFibers(fg_classified(10),'numfibers',400,'color',[1 0 0],'newfig',false); % Render 400 CFMinor fibers 
            % % Then add the slice X = -2 to the 3d rendering.
            %AFQ_AddImageTo3dPlot(b0,[-2, 0, 0]);
            AFQ_AddImageTo3dPlot(t1ACPC,[-2, 0, 0]);
            saveas(figure(3),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Non_visual_left_classified.fig']);            
            saveas(figure(3),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Non_visual_left_classified.bmp']);
            
            % Late-visual pathways right hemisphere       
            AFQ_RenderFibers(fg_classified(9),'numfibers',400,'color',[0 0 1]); % Render 400 CFMajor fibers
            % To add this tract to the same plotting window set the 'newfig' input to false.
            AFQ_RenderFibers(fg_classified(12),'numfibers',400,'color',[0 1 0],'newfig',false); % Render 400 IFOF fibers 
            % % Render 400 uncinate fibers in yellow
            AFQ_RenderFibers(fg_classified(16),'numfibers',400,'color',[1 1 0],'newfig',false); % Render 400 SLF fibers
            % % Render 400 arcuate fibers in green.
            AFQ_RenderFibers(fg_classified(14),'numfibers',400,'color',[1 0 0],'newfig',false); % Render 400 ILF fibers
            % % Then add the slice X = -2 to the 3d rendering.
            %AFQ_AddImageTo3dPlot(b0,[2, 0, 0]);
            AFQ_AddImageTo3dPlot(t1ACPC,[2, 0, 0]);
            saveas(figure(4),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Late_visual_right_classified.fig']);
            saveas(figure(4),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Late_visual_right_classified.bmp']);
            
            % Non-visual pathways right hemisphere       
            AFQ_RenderFibers(fg_classified(4),'numfibers',400,'color',[0 0 1]); % Render 400 CST fibers.
            % To add this tract to the same plotting window set the 'newfig' input to false.
            AFQ_RenderFibers(fg_classified(18),'numfibers',400,'color',[0 1 0],'newfig',false); % Render 400 UF fibers  
            % % Render 400 uncinate fibers in yellow
            AFQ_RenderFibers(fg_classified(6),'numfibers',400,'color',[1 1 0],'newfig',false); % Render 400 CC fibers 
            % % Render 400 arcuate fibers in green.
            AFQ_RenderFibers(fg_classified(10),'numfibers',400,'color',[1 0 0],'newfig',false); % Render 400 CFMinor fibers 
            % % Then add the slice X = -2 to the 3d rendering.
            %AFQ_AddImageTo3dPlot(b0,[2, 0, 0]);
            AFQ_AddImageTo3dPlot(t1ACPC,[2, 0, 0]);
            saveas(figure(5),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Non_visual_right_classified.fig']);
            saveas(figure(5),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Non_visual_right_classified.bmp']);
            
            %% Clean all tracts - Updated on the 02/11/2020 with parameters used in AFQ_WholeBrain_fibers_loopTesting4.m
            
            % Remove fibers more than maxDist standard deviations from the tract core
            maxDist = 5;
            % Remove fibers more than maxLen standard deviations above the mean length
            maxLen = 4;
            % Sample each fiber to numNodes points
            numNodes = 100;
            % Compute the tract core with the function M
            M = 'mean';
            % Maximum number of iterations
            maxIter = 1;
            % Display the number of fibers removed in each iteration
            count = true;
            % Maximum number of iteration of the cleaning algorithm
            cleanIter = 5;
            % Loop over all 20 fiber groups and clean each one
               for kk = 1:20 % 
                   if length(fg_classified(kk).fibers) > 20
                        fg_clean(kk) = AFQ_removeFiberOutliers(fg_classified(kk),maxDist,maxLen,numNodes,M,0,cleanIter);
                   end
               end
 
            save([baseDir, AFQDir,subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, subIDs{ii} '_fg_clean_', num2str(curScan)], 'fg_clean');
            
            % If some fibers have been deleted during the cleaning, create a .txt file to indicate the maintained fibers
            if length(fg_clean) < 20
                a = sprintf(['Fibers maintained: ' fg_clean.name]) ;      
                dlmwrite([baseDir, AFQDir,subIDs{ii}, filesep,'scan_' num2str(curScan), filesep,'Fibers.txt'],a,'delimiter','');
            end           
                                        
            % Visualization of cleaned fibres:
            % Late-visual pathways left hemisphere       
            AFQ_RenderFibers(fg_clean(9),'numfibers',400,'color',[0 0 1]); % Render 400 CFMajor fibers.
            % To add this tract to the same plotting window set the 'newfig' input to false.
            AFQ_RenderFibers(fg_clean(11),'numfibers',400,'color',[0 1 0],'newfig',false); % Render 400 IFOF fibers 
            % % Render 400 uncinate fibers in yellow
            AFQ_RenderFibers(fg_clean(15),'numfibers',400,'color',[1 1 0],'newfig',false); % Render 400 SLF fibers
            % % Render 400 arcuate fibers in green.
            AFQ_RenderFibers(fg_clean(13),'numfibers',400,'color',[1 0 0],'newfig',false); % Render 400 ILF fibers
            AFQ_AddImageTo3dPlot(t1ACPC,[-2, 0, 0]);
            saveas(figure(6),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Late_visual_left_clean.fig']);
            saveas(figure(6),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Late_visual_left_clean.bmp']);
            
            % Non-visual pathways left hemisphere       
            AFQ_RenderFibers(fg_clean(3),'numfibers',400,'color',[0 0 1]); % Render 400 CST fibers
            % To add this tract to the same plotting window set the 'newfig' input to false.
            AFQ_RenderFibers(fg_clean(17),'numfibers',400,'color',[0 1 0],'newfig',false); % Render 400 UF fibers 
            % % Render 400 uncinate fibers in yellow
            AFQ_RenderFibers(fg_clean(5),'numfibers',400,'color',[1 1 0],'newfig',false); % Render 400 CC fibers 
            % % Render 400 arcuate fibers in green.
            AFQ_RenderFibers(fg_clean(10),'numfibers',400,'color',[1 0 0],'newfig',false); % Render 400 CFMinor fibers 
            AFQ_AddImageTo3dPlot(t1ACPC,[-2, 0, 0]);
            saveas(figure(7),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Non_visual_left_clean.fig']);
            saveas(figure(7),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Non_visual_left_clean.bmp']);

            % Late-visual pathways right hemisphere       
            AFQ_RenderFibers(fg_clean(9),'numfibers',400,'color',[0 0 1]); % Render 400 CFMajor fibers.
            % To add this tract to the same plotting window set the 'newfig' input to false.
            AFQ_RenderFibers(fg_clean(12),'numfibers',400,'color',[0 1 0],'newfig',false); % Render 400 IFOF fibers  
            % % Render 400 uncinate fibers in yellow
             AFQ_RenderFibers(fg_clean(16),'numfibers',400,'color',[1 1 0],'newfig',false); % Render 400 SLF fibers
            % % Render 400 arcuate fibers in green.
             AFQ_RenderFibers(fg_clean(14),'numfibers',400,'color',[1 0 0],'newfig',false); % Render 400 ILF fibers
            % % Then add the slice X = -2 to the 3d rendering.
            %AFQ_AddImageTo3dPlot(b0,[2, 0, 0]);
            AFQ_AddImageTo3dPlot(t1ACPC,[2, 0, 0]);
            saveas(figure(8),[baseDir, AFQDir,subIDs{ii}, filesep, 'scan_' num2str(curScan), filesep, 'Late_visual_right_clean.fig']);
            saveas(figure(8),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Late_visual_right_clean.bmp']);
            
            % Non-visual pathways right hemisphere       
            AFQ_RenderFibers(fg_clean(4),'numfibers',400,'color',[0 0 1]); % Render 400 CST fibers
            % To add this tract to the same plotting window set the 'newfig' input to false.
            AFQ_RenderFibers(fg_clean(18),'numfibers',400,'color',[0 1 0],'newfig',false); % Render 400 UF fibers 
            % % Render 400 uncinate fibers in yellow
            AFQ_RenderFibers(fg_clean(6),'numfibers',400,'color',[1 1 0],'newfig',false); % Render 400 CC fibers 
            % % Render 400 arcuate fibers in green.
            AFQ_RenderFibers(fg_clean(10),'numfibers',400,'color',[1 0 0],'newfig',false); % Render 400 CFMinor fibers 
            % % Then add the slice X = -2 to the 3d rendering.
            %AFQ_AddImageTo3dPlot(b0,[2, 0, 0]);
            AFQ_AddImageTo3dPlot(t1ACPC,[2, 0, 0]);
            saveas(figure(9),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Non_visual_right_clean.fig']);
            saveas(figure(9),[baseDir, AFQDir, subIDs{ii}, filesep,'scan_' num2str(curScan), filesep, 'Non_visual_right_clean.bmp']);
                       
            sprintf(['Elapsted time: ', num2str(toc/60), ' minutes'])

        end
         catch me
             disp(['Error in subject ' subIDs{ii}]);
        end
    end
    close all;
end

% ---------------------------------------------------------------------------------------------------------------------------------------------

%% Mrtrix3 whole brain tractography: 

% 1. FOD generation and estimation -> wmfod.mif

% This section generates fiber orientation direction (FOD) estimates for tractography:
% 1. Reslice the aparc+aseg output of freesurfer to the T1 resolution
% 2. Coregister the aparc+aseg resliced to diffusion volume (dMRI) applying the matrix created coregistering te T1 to the diffusion volume
% 3. Segmentation (5 tissue types) of the T1 coregisted to the diffusion volume -> 5ttgen
% 4. Generate normal orientation response function estimates (FOD) -> dwi2response dhollander


if mrtrix3_wholeBrain == 1

    for ii =  1:length(subIDs)
        if exist([baseDir fibDir subIDs{ii}]) == 0 % Check if fiber directory exists
            mkdir([baseDir fibDir(1:end-1) filesep subIDs{ii}]) % If not, create it
        else
        end
        for ee = 1 
            
            % Generate 5tt mask (aligned with T1-ACPC volume)
            system(['5ttgen fsl ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop_restore_acpc.nii.gz '] ...
                baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_5tt_acpc.nii.gz']]) % Run 5ttgen command with T1-registered to the diffusion image       

            % Problem with dtiInit -> bvecs flipped on the x-axes
            % (https://community.mrtrix.org/t/afq-tract-segmentation-using-mrtrix3-wb-tractography/1832/4)
            % To solve this, rotate the x-axis of bvecs, and save the new file
            % adding the flag _corrected.bvecs
            bvec = load([baseDir dt6 filesep subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC.bvecs']]);
            bvec = [bvec(1,:)*-1; bvec(2,:)*1; bvec(3,:)*1]; 
            writematrix(bvec, [baseDir dt6 filesep subIDs{ii} filesep 'ses-' num2str(ee) filesep ...
                [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC_corrected.txt']], 'Delimiter', ' ')
            copyfile([baseDir dt6 filesep subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC_corrected.txt']], ...
                [baseDir dt6 filesep subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC_corrected.bvecs']])

            % Define paths (convenience for commands below)
            eddy = [baseDir dt6 subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC.nii.gz']];
            bvec = [baseDir dt6 subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC_corrected.bvecs']]; % Use the output of dtiInit.m
            bval = [baseDir dt6 subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC.bvals']];
            mask = [baseDir dt6 subIDs{ii} filesep 'ses-' num2str(ee) filesep ['dti40trilin_' num2str(ee)] filesep 'bin/brainMask.nii.gz']; % brain mask aligned to ACPC

            % Generate normal orientation response function estimates
            system(['dwi2response dhollander ' eddy ' -fslgrad ' bvec ' ' bval ' ' ...
                baseDir fibDir subIDs{ii} filesep 'responseEstimate_sfwm.txt ' ...
                baseDir fibDir subIDs{ii} filesep 'responseEstimate_gm.txt ' ...
                baseDir fibDir subIDs{ii} filesep 'responseEstimate_csf.txt -mask ' mask]) % Generate white matter and csf response estimates
            % Generate normal fiber orientation distribution estimates (FOD)
            system(['dwi2fod msmt_csd -mask ' mask ' ' eddy ' -fslgrad ' bvec ' ' bval ' ' ...
                baseDir fibDir subIDs{ii} filesep 'responseEstimate_sfwm.txt ' baseDir fibDir subIDs{ii} filesep 'wmfod.mif ' ...
                baseDir fibDir subIDs{ii} filesep 'responseEstimate_gm.txt ' baseDir fibDir subIDs{ii} filesep 'gmfod.mif ' ...
                baseDir fibDir subIDs{ii} filesep 'responseEstimate_csf.txt ' baseDir fibDir subIDs{ii} filesep 'csffod.mif '])

            % 3. Whole brain tractography (mrtrix3)
            act = [baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_5tt_acpc.nii.gz']]; % aligned to ACPC
            wmfod = [baseDir fibDir subIDs{ii} '/wmfod.mif']; % extracted from eddy_corrected_data.nii.gz aligned to T1-acpc space
            numFibers = 5000000;
            outFile = [baseDir fibDir subIDs{ii} '/dti_wholeBrain_ACT_' num2str(numFibers(1)/1000000) 'M_acpc.tck'];       
            % Run tractography
            system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' act  ' -select ' num2str(numFibers(1)) ' -seeds 0 ']);
        
        end
            
    end
end

% Read the output of the Whole Brain Tractography in matlab:
% wholeBrain_mrtrix = read_mrtrix_tracks('tractography/dti1_wholeBrain_ACT_5M_acpc.tck'); 


%% Extract the ROIs from Freesurfer and coregister them to the ACPC T1 space
% LGN, V1 and Optic Chiasm

if freesurfer_ROIs == 1
    
    for ii = 1:numel(subIDs)
        mkdir([baseDir roiDir subIDs{ii} '/ses-1/']) 
        
        % extract the b0 from the eddy corrected image
        system(['fslroi ' baseDir dt6 subIDs{ii} filesep 'ses-1' filesep [subIDs{ii} '_ses-1_dti_eddy_corrected_data_aligned_trilin_noMEC.nii.gz '] ...
            baseDir dt6 subIDs{ii} filesep 'ses-1' filesep [subIDs{ii} '_ses-1_dti_eddy_corrected_data_aligned_trilin_noMEC_b0.nii.gz 0 1' ]]);
        
        % Coregistration preprocessed T1 to the ACPC space to extract the coregistration matrix
        system(['flirt -in ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop_restore.nii.gz'] ...
            ' -ref ' baseDir dt6 subIDs{ii} filesep 'ses-1' filesep [subIDs{ii} '_ses-1_dti_eddy_corrected_data_aligned_trilin_noMEC_b0.nii.gz '] ...
            ' -out ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop_restore_acpc.nii.gz'] ...
            ' -omat ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop_restore_flirt_acpc_xfm.mat']]);

        % LGNs
        % Segment thalamic nuclei (requires that subject has already been processed with recon-all);
        % system(['segmentThalamicNuclei.sh ' subIDs{ii} ' ' fsDir])
        % Convert segmented atlas to volume
        system(['mri_label2vol --seg ' fsDir subIDs{ii} '/mri/ThalamicNuclei.v12.T1.mgz --temp ' fsDir subIDs{ii} '/mri/orig.mgz --o ' fsDir subIDs{ii} '/mri/ThalSegNativeVol.nii.gz --regheader ' fsDir subIDs{ii} '/mri/ThalamicNuclei.v12.T1.mgz'])
        % Extract left LGN from volume
        system(['fslmaths ' fsDir subIDs{ii} '/mri/ThalSegNativeVol.nii.gz -thr 8109 -uthr 8109 ' baseDir roiDir subIDs{ii} filesep '/ses-1/fs_lh_lgn.nii.gz']);
        % Extract right LGN from volume
        system(['fslmaths ' fsDir subIDs{ii} '/mri/ThalSegNativeVol.nii.gz -thr 8209 -uthr 8209 ' baseDir roiDir subIDs{ii} filesep '/ses-1/fs_rh_lgn.nii.gz']);
        
        % Process outputs (binarize, reslice, flip)
        for jj = 1:length(hemi)
            % Binarize ROI
            system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/fs_' hemi{jj} '_lgn.nii.gz -bin ' baseDir roiDir subIDs{ii} '/ses-1/fs_' hemi{jj} '_lgn.nii.gz']);
            % Reslice ROI to T1 resolution
            system(['mri_convert -rt nearest -rl ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop_restore.nii.gz '] ...
                baseDir roiDir subIDs{ii} '/ses-1/fs_' hemi{jj} '_lgn.nii.gz ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_lgn.nii.gz']);
            % Coregister the LGN to ACPC space
            system(['flirt -in ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_lgn.nii.gz -ref ' ...
                baseDir dt6 subIDs{ii} filesep 'ses-1' filesep [subIDs{ii} '_ses-1_dti_eddy_corrected_data_aligned_trilin_noMEC_b0.nii.gz '] ' -out ' ...
                baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_lgn_acpc_coreg.nii.gz -init ' ...
                baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop_restore_flirt_acpc_xfm.mat -applyxfm']])
            system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_lgn_acpc_coreg.nii.gz -bin ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_lgn_acpc_coreg.nii.gz']); % binarize the mask
        end
        % V1s
        for jj = 1:length(hemi)
            % mri_label2vol for xh.V1.label file
            system(['mri_label2vol --label ' fsDir subIDs{ii} '/label/' hemi{jj} '.V1_exvivo.label --temp ' fsDir subIDs{ii} '/mri/orig.mgz --o ' fsDir subIDs{ii} '/label/' hemi{jj} '_V1.nii.gz --identity --fillthresh .3 --proj frac 0 1 .1 --hemi ' hemi{jj} ' --subject ' subIDs{ii}])
            % Smooth nifti V1 ROI using -fmedian flag
            system(['fslmaths ' fsDir subIDs{ii} '/label/' hemi{jj} '_V1.nii.gz -fmedian ' fsDir subIDs{ii} '/label/' hemi{jj} '_V1.nii.gz'])
            % Binarize smoothed output
            system(['fslmaths ' fsDir subIDs{ii} '/label/' hemi{jj} '_V1.nii.gz -bin ' fsDir subIDs{ii} '/label/' hemi{jj} '_V1.nii.gz'])
            % Reslice to T1w resolution and save to ROI folder
            system(['mri_convert -rt nearest -rl ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop_restore.nii.gz '] ...
                fsDir subIDs{ii} '/label/' hemi{jj} '_V1.nii.gz ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_V1.nii.gz']);
            % Coregister the V1 to ACPC space            
            system(['flirt -in ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_V1.nii.gz -ref ' ...
                baseDir dt6 subIDs{ii} filesep 'ses-1' filesep [subIDs{ii} '_ses-1_dti_eddy_corrected_data_aligned_trilin_noMEC_b0.nii.gz '] ' -out ' ...
                baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_V1_acpc_coreg.nii.gz -init ' ...
                baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop_restore_flirt_acpc_xfm.mat -applyxfm']]);
            
            system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_V1_acpc_coreg.nii.gz -bin ' ...
                baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_V1_acpc_coreg.nii.gz']); % binarize the mask
        end
        
        % Convert aparc+aseg.mgz to nifti
        system(['mri_convert -rt nearest -rl ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop_restore.nii.gz '] ...
            fsDir subIDs{ii} '/mri/aparc+aseg.mgz ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_aparc+aseg_t1Reslice.nii.gz']]) % Reslice aparc+aseg to t1 resolution and save to t1 directory
        
        % Extract Optic Chiams from freesurfer (85), smooth the ROI and reslice to the T1
        system(['fslmaths ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_aparc+aseg_t1Reslice.nii.gz '] '-thr 85 -uthr 85 ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc.nii.gz']);    
        system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc.nii.gz -fmedian ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc.nii.gz'])
        % Binarize smoothed output
        system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc.nii.gz -bin ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc.nii.gz'])
        % coregister the OC to ACPC space
        system(['flirt -in ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc.nii.gz -ref ' ...
            baseDir dt6 subIDs{ii} filesep 'ses-1' filesep [subIDs{ii} '_ses-1_dti_eddy_corrected_data_aligned_trilin_noMEC_b0.nii.gz '] '-out ' ...
            baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc_acpc_coreg.nii.gz -init ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop_restore_flirt_acpc_xfm.mat -applyxfm']])
        
        % Expand the Optic Chiasm:
        system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc_acpc_coreg.nii.gz -dilM ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc_acpc_coreg_dilM.nii.gz'])          
        system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc_acpc_coreg_dilM.nii.gz -dilM ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc_acpc_coreg_2dilM.nii.gz'])          
        system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc_acpc_coreg_2dilM.nii.gz -dilM ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc_acpc_coreg_3dilM.nii.gz'])          
        system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc_acpc_coreg_3dilM.nii.gz -bin ' baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc_acpc_coreg_3dilM.nii.gz']) % binarize the mask
      
    end
end


%% Optic Radiations Tractography with MRTrix3 using the output of dtiInit
% Input -> wmfod.mif created with function dwi2fod -> dMRI scan session 1

if mrtrix3_OR == 1
    
    numFibers = [1e4; 1e4];
    for ii = 1:length(subIDs)
        
        ee = 1; % only for the first run
        for jj = 1:length(hemi)
            % Setup paths & filenames
            eddy = [baseDir dt6 subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC.nii.gz']];
            bvec = [baseDir dt6 subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC_corrected.bvecs']]; % Use the output of dtiInit.m
            bval = [baseDir dt6 subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC.bvals']];
            act = [baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_5tt_acpc.nii.gz']]; % aligned to ACPC
            wmfod = [baseDir fibDir subIDs{ii} '/wmfod.mif']; % extracted from eddy_corrected_data.nii.gz aligned to T1-acpc space

            maxLength = 150;
            outFile = [baseDir fibDir subIDs{ii} '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers(1)/1000) 'k_acpc.tck'];
            roi1 = [baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_lgn_acpc_coreg.nii.gz']; % FreeSurfer LGN
            roi2 = [baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_V1_acpc_coreg.nii.gz']; % FreeSurfer V1
            % Run tractography
            system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' roi1 ' -seed_image ' roi2 ' -include ' roi1 ' -include ' roi2 ' -stop ' '-select ' num2str(numFibers(1)) ' -seeds 0 ' '-maxlength ' num2str(maxLength)])
            % Convert fibers to DSIStudio format
            outFileImage = [baseDir fibDir subIDs{ii} '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers(1)/1000) 'k_acpc_DSIStudio.tck'];
            % Convert to DSIStudio format
            system(['tckconvert -scanner2image ' eddy ' ' outFile ' ' outFileImage])

        end
    end
end



%% Optic Tract Tractography with MRTrix3 using the output of dtiInit
% Input -> wmfod.mif created with functin dwi2fod -> dMRI scan session 1

if mrtrix3_OT == 1
    
    numFibers = [1e4; 1e4];
    for ii = 1:length(subIDs)
        ee = 1; % only for the first scan
        for jj = 1:length(hemi)
           % Setup paths & filenames
            eddy = [baseDir dt6 subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC.nii.gz']];
            bvec = [baseDir dt6 subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC_corrected.bvecs']]; % Use the output of dtiInit.m
            bval = [baseDir dt6 subIDs{ii} filesep 'ses-' num2str(ee) filesep [subIDs{ii} '_ses-' num2str(ee) '_dti_eddy_corrected_data_aligned_trilin_noMEC.bvals']];
            act = [baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_5tt_acpc.nii.gz']]; % aligned to ACPC
            wmfod = [baseDir fibDir subIDs{ii} '/wmfod.mif']; % extracted from eddy_corrected_data.nii.gz aligned to T1-acpc space

           maxLength = 150;
           outFile = [baseDir fibDir subIDs{ii} '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers(1)/1000) 'k_acpc.tck'];
           roi1 = [baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_lgn_acpc_coreg.nii.gz']; % FreeSurfer LGN
           roi2 = [baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc_acpc_coreg_3dilM.nii.gz']; % Freesurfer Optic Chiasm expanded -> 3dil
           % Run tractography
           system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' roi1 ' -seed_image ' roi2 ' -include ' roi1 ' -include ' roi2 ' -stop ' '-select ' num2str(numFibers(1)) ' -seeds 0 ' '-maxlength ' num2str(maxLength)])
           % Convert fibers to DSIStudio format
           outFileImage = [baseDir fibDir subIDs{ii} '/dti' num2str(ee) '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers(1)/1000) 'k_acpc_DSIStudio.tck'];
           % Convert to DSIStudio format
           system(['tckconvert -scanner2image ' eddy ' ' outFile ' ' outFileImage])
        end
    end
end


%% Cleaning the Tracts with tckedit -> exclude the fibers reaching the talamus and not LGN

if cleaning_tracts == 1
    numFibers = (1e4);

    for ii = 1:length(subIDs)
        % Extract left thalamus from aparc+aseg_t1Reslice
        system(['fslmaths ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_aparc+aseg_t1Reslice.nii.gz'] ' -thr 10 -uthr 10 ' ...
            baseDir roiDir subIDs{ii} '/ses-1/fs_lh_thalamus.nii.gz']);
        % Extract right thalamus from aparc+aseg
        system(['fslmaths ' baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_aparc+aseg_t1Reslice.nii.gz'] ' -thr 49 -uthr 49 ' ...
            baseDir roiDir subIDs{ii} '/ses-1/fs_rh_thalamus.nii.gz']);
        
        % Merge and binarize
        system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/fs_lh_thalamus.nii.gz -add ' baseDir roiDir subIDs{ii} '/ses-1/fs_rh_thalamus.nii.gz ' ...
            baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus.nii.gz']);
        system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus.nii.gz -bin ' baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus.nii.gz']); % save in ROI folder
        
        % Coregister ACPC
        system(['flirt -in ' baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus.nii.gz -ref ' ...
            baseDir dt6 subIDs{ii} filesep 'ses-1' filesep [subIDs{ii} '_ses-1_dti_eddy_corrected_data_aligned_trilin_noMEC_b0.nii.gz '] '-out ' ...
            baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus_acpc_coreg.nii.gz -init ' ...
            baseDir anat_prep subIDs{ii} filesep 'ses-1/' [subIDs{ii} '_ses-1_t1_crop_restore_flirt_acpc_xfm.mat -applyxfm']]);
        
        % Subtract LGNs from thalamus volume & binarize
        system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus_acpc_coreg.nii.gz -sub ' ...
            baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{1} '_lgn_acpc_coreg.nii.gz -sub ' ...
            baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{2} '_lgn_acpc_coreg.nii.gz ' ...
            baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus_acpc_coreg_sub_fs_LGNs.nii.gz']);
        
        system(['fslmaths ' baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus_acpc_coreg_sub_fs_LGNs.nii.gz -bin ' ...
            baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus_acpc_coreg_sub_fs_LGNs.nii.gz']);

        ee = 1;
        for jj = 1:length(hemi)
           % Run tckedit, excluding fibers terminating in thalamus outside of LGNs
           % Optic Radiations:
           system(['tckedit -exclude ' baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus_acpc_coreg_sub_fs_LGNs.nii.gz -include ' ...
               baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_lgn_acpc_coreg.nii.gz -include ' ...
               baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_V1_acpc_coreg.nii.gz -ends_only ' ...
               baseDir fibDir subIDs{ii} '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers/1000) 'k_acpc.tck ' ...
               baseDir fibDir subIDs{ii} '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers/1000) 'k_acpc_thalFiltered.tck'])

           system(['tckedit -exclude ' baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus_acpc_coreg_sub_fs_LGNs.nii.gz -include ' ...
               baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_lgn_acpc_coreg.nii.gz -include '  ...
               baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_V1_acpc_coreg.nii.gz '...
               baseDir fibDir subIDs{ii} '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers/1000) 'k_acpc_thalFiltered.tck ' ...
               baseDir fibDir subIDs{ii} '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers/1000) 'k_acpc_2thalFiltered.tck'])

           % Optic Tract:
           % Maxlength = 50 to avoid longer fibers projecting to the posterior brain
           system(['tckedit -exclude ' baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus_acpc_coreg_sub_fs_LGNs.nii.gz -include ' ...
               baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_lgn_acpc_coreg.nii.gz -include '  ...
               baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc_acpc_coreg.nii.gz -ends_only ' ...
               baseDir fibDir subIDs{ii} '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers/1000) 'k_acpc.tck ' ...
               '-maxlength 50 ' baseDir fibDir subIDs{ii} '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers/1000) 'k_acpc_thalFiltered.tck'])

           % Second cleaning of OT:
           system(['tckedit -exclude ' baseDir roiDir subIDs{ii} '/ses-1/fs_thalamus_acpc_coreg_sub_fs_LGNs.nii.gz -include ' ...
               baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_' hemi{jj} '_lgn_acpc_coreg.nii.gz -include '  ...
               baseDir roiDir subIDs{ii} '/ses-1/T1w_fs_oc_acpc_coreg.nii.gz ' ...
               baseDir fibDir subIDs{ii} '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers/1000) 'k_acpc_thalFiltered.tck ' baseDir fibDir subIDs{ii} '/dti_' 'dti' num2str(ee) '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers/1000) 'k_acpc_2thalFiltered.tck'])  


        end

    end
end



