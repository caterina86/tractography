function s05a_AFQ(projectDir, subject, session)

    % Run deterministic tractography 

    %% dtiInit 

    % https://web.stanford.edu/group/vista/cgi-bin/wiki/index.php/DTI_Preprocessing

    % Alignement of the diffusion preprocessed data to the T1 (ACPC)
    % dt6.mat -> to perform the AFQ Whole Brain Tractography on the diffusion data aligned to the T1 (ACPC)
    % Extract the fa values from the whole brain
    % Output -> folder called ['dti40trilin_'num2str(curScan)]

    runDtiInit = 'true';
    encodingOrientation = {'AP'}; % Phase encoding direction for each participant

    % load the paths
    rawDir = fullfile(projectDir, 'rawdata', subject, session);
    eddyDir = fullfile(projectDir, 'derivatives/eddy', subject, session);
    t1Dir = fullfile(rawDir, 'anat');
    dt6Dir = fullfile(projectDir, 'derivatives/dt6', subject, session);
    topupDir = fullfile(projectDir, 'derivatives/topup', subject, session);
    AFQDir = fullfile(projectDir, 'derivatives/AFQ', subject, session);

    % Define file names 
    eddyFile = [subject '_' session '_eddy_corrected_data.nii.gz'];
    t1RawFileName = [subject '_' session '_T1w.nii.gz']; % load the t1 image

    % read nifti of the inputs
    dtiTopCor = niftiRead(fullfile(eddyDir,filesep, eddyFile)); 
    t1Raw = niftiRead(fullfile(t1Dir, t1RawFileName));


    %% ACPC-ALIGN T1 IMAGE 
    % Detect if the t1_acpc exists or create it (if not)
    if exist([t1Dir,filesep,'t1_acpc.nii.gz'],'file') % If a t1_acpc.nii.gz file exists already
        warning('Skipping ACPC alignment. Using the existing ACPC-aligned T1...');
        t1ACPCFileName = 't1_acpc.nii.gz';
        t1ACPC = niftiRead(fullfile(t1Dir,filesep,t1ACPCFileName));
        pause(3);

    else % If no acpc-corrected T1 exits 
        mrAnatAverageAcpcNifti(t1Raw.fname,[t1Dir,filesep,'t1_acpc.nii.gz']);
        t1ACPCFileName = 't1_acpc.nii.gz';
        t1ACPC = niftiRead(fullfile(t1Dir,filesep,t1ACPCFileName));    
    end

    close all;

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

    % create the directory in the derivatives
    mkdir(dt6Dir)

    % load the bvals to extract the number of directions used
    bvals = load(fullfile(topupDir, 'bval_combined.txt'));

    for ii = 1:size(bvals,2)
        if bvals(1,ii) == 5
            bvals(1,ii) = 0;
        end  
    end

    writematrix(bvals, fullfile(topupDir, 'bval_combined_modified.txt'), 'Delimiter', 'space');


    % define options
    dwParams.bvalue                  = [];
    dwParams.gradDirsCode            = [];
    dwParams.dt6BaseName             = fullfile(dt6Dir, [subject '_' session '_dti' num2str(size(bvals,2)) 'trilin']); 
    dwParams.clobber                 = 0; % ask to overwrite existing files
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

    dwParams.bvecsFile = fullfile(topupDir, 'bvec_combined.txt'); % path name
    dwParams.bvalsFile = fullfile(topupDir, 'bval_combined_modified.txt'); % path name

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




    %% AFQ
    % To see an example: http://yeatmanlab.github.io/AFQ/tutorials/AFQ_example
    % Tract Profiles of White Matter Properties: AutomatingFiber-Tract Quantification, 2012, Plos One
    % Output -> folder called [AFQ] in derivatives

    dt6 = fullfile(dt6Dir, [subject '_' session '_dti' num2str(size(bvals,2)) 'trilin']);

    % load the dt6.mat file -> ACPC space
    dt = dtiLoadDt6(fullfile(dt6, 'dt6.mat')); % file created from the raw data (dMRI and T1)

    % Create folder AFQ for the outputs:
    mkdir(AFQDir);

    %% Whole brain tractography with AFQ:

    if exist(fullfile(AFQDir, [subject '_' session '_WholeBrainTractography_AFQ.mat']),'file')
        load(fullfile(AFQDir, [subject '_' session '_WholeBrainTractography_AFQ.mat']));
    else
        wholebrainFG = AFQ_WholebrainTractography(dt); 
        save(fullfile(AFQDir, [subject '_' session '_WholeBrainTractography_AFQ.mat']), 'wholebrainFG', '-v7.3');            
    end    


    %% Segment the whole-brain fiber group into 20 fiber tracts

    if exist(fullfile(AFQDir, [subject '_' session '_fg_classified.mat']),'file')
        load(fullfile(AFQDir, [subject '_' session '_fg_classified.mat']));
    else
        fg_classified = AFQ_SegmentFiberGroups(dt, wholebrainFG);
        save(fullfile(AFQDir, [subject '_' session '_fg_classified.mat']), 'fg_classified');
    end

    % fg_classified.subgroup defines the fascicle that each fiber belongs to.
    % We can convert fg_classified to a 1x20 structured array of fiber groups 
    % where each entry in the array is a segmented fiber tract. 
    fg_classified = fg2Array(fg_classified);

    % Visualization of fibres and save the image:
    % Whole brain
    b0 = readFileNifti(fullfile(dt6Dir, [subject '_' session '_dti' num2str(size(bvals,2)) 'trilin/bin/b0.nii.gz']));
    AFQ_RenderFibers(wholebrainFG, 'numfibers',1000, 'color', [1 .6 .2]); % Whole brain
    AFQ_AddImageTo3dPlot(b0,[-2, 0, 0]);
    saveas(figure(1),[AFQDir, '/WB_classified.fig']);
    saveas(figure(1),[AFQDir, '/WB_classified.bmp']);

    close all;


    %% Clean all tracts - check if these parameters are OK for this protocol

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
    for ii = 1:20
       if length(fg_classified(ii).fibers) > 20
            fg_clean(ii) = AFQ_removeFiberOutliers(fg_classified(ii),maxDist,maxLen,numNodes,M,0,cleanIter);
       end
    end

    save(fullfile(AFQDir, [subject '_' session '_fg_clean.mat']), 'fg_clean');

    % If some fibers have been deleted during the cleaning, create a .txt file to indicate the maintained fibers
    if length(fg_clean) < 20
        a = sprintf(['Fibers maintained: ' fg_clean.name]) ;      
        dlmwrite(fullfile(AFQDir,'Fibers.txt'),a,'delimiter','');
    end           

    % If you want to visualize the tracts use the same script as in line 210 

    sprintf(['Elapsted time: ', num2str(toc/60), ' minutes'])

end


