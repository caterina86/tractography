% dMRI preprocessing pipeline: denoise, de-ring, topup, eddy correction

function s03_dwi_preprocessing(projectDir, subject, session, fmriprep)

    % create names for input and output files:
    % folders:
    topupDir = fullfile(projectDir, 'derivatives/topup', subject, session);
    eddyDir = fullfile(projectDir, 'derivatives/eddy', subject, session);
    unprocessedTopupDir = fullfile(topupDir, 'unprocessed');
    dwiDir = fullfile(projectDir, 'rawdata', subject, session, 'dwi');

    % load name files:
    % TODO: Define these with full pathnames, i.e. fullfile(Dir, file)
    apFile =  [subject '_' session '_dir-ap_dwi.nii.gz'];
    paFile =  [subject '_' session '_dir-pa_dwi.nii.gz'];
    apFileBval =  [subject '_' session '_dir-ap_dwi.bval'];
    paFileBval =  [subject '_' session '_dir-pa_dwi.bval'];
    apFileBvec =  [subject '_' session '_dir-ap_dwi.bvec'];
    paFileBvec =  [subject '_' session '_dir-pa_dwi.bvec'];
    appaFile =  [subject '_' session '_AP_PA_dwi.nii.gz'];
    apResFile = [subject '_' session '_res_AP.nii.gz'];
    paResFile = [subject '_' session '_res_PA.nii.gz'];
    apB0File = [subject '_' session '_AP_dwi_b0.nii.gz'];
    paB0File = [subject '_' session '_PA_dwi_b0.nii.gz'];
    appaB0File = [subject '_' session '_AP_PA_dwi_b0.nii.gz'];
    eddyFile = [subject '_' session '_eddy_corrected_data'];

    %% Start the preprocessing
    % Create 'unprocessed' directory to backup raw dti volumes before processing (susbequent steps will overwrite)
    mkdir(unprocessedTopupDir);
    % Create folder for the results of the eddy correction
    mkdir(eddyDir);

    if fmriprep == 0
        % rename the dwi files
        fileName = dir(fullfile(dwiDir, '*_AP.nii.gz'));
        copyfile(fullfile(dwiDir,fileName.name), fullfile(dwiDir, apFile));
        fileName = dir(fullfile(dwiDir, '*_AP.bvec'));
        copyfile(fullfile(dwiDir,fileName.name), fullfile(dwiDir, apFileBvec));
        fileName = dir(fullfile(dwiDir, '*_AP.bval'));
        copyfile(fullfile(dwiDir,fileName.name), fullfile(dwiDir, apFileBval));
        fileName = dir(fullfile(dwiDir, '*_PA.nii.gz'));
        copyfile(fullfile(dwiDir,fileName.name), fullfile(dwiDir, paFile));
        fileName = dir(fullfile(dwiDir, '*_PA.bvec'));
        copyfile(fullfile(dwiDir,fileName.name), fullfile(dwiDir, paFileBvec));
        fileName = dir(fullfile(dwiDir, '*_PA.bval'));
        copyfile(fullfile(dwiDir,fileName.name), fullfile(dwiDir, paFileBval));
    else
    end

    myFiles = {apFile, paFile};
    myResFiles = {apResFile, paResFile};
    
    % TODO: When s03 is aborted a zero byte file is created, caussing a
    % skip
    if exist(fullfile(topupDir, apFile), 'file')
        disp('skipping denoise')
    else

        for ii = 1:length(myFiles)
            % copy the original AP and PA dwi images to derivatives/topup
            copyfile(fullfile(dwiDir, apFile), fullfile(unprocessedTopupDir, myFiles{ii}));

            % Denoise the data - Correct for warping artifacts due to the phase encoding direction
            % input -> topup/unprocesses/sub-_ses-_AP_dwi.nii.gz
            % output -> topup/sub-_ses-_AP_dwi.nii.gz
            system(['dwidenoise -force ' fullfile(unprocessedTopupDir, apFile) ' ' fullfile(topupDir, myFiles{ii})]);

            % Calculate and check the residuals.
            % The lack of anatomy in the residual maps is a marker of accuracy and signal-preservation during denoising
            % original dwi - denoised dwi = residuals
            system(['mrcalc ' fullfile(unprocessedTopupDir, apFile) ' '  fullfile(topupDir, myFiles{ii}) ' -subtract ' fullfile(topupDir, myResFiles{ii})]);

            % correct for Gibbs Ringing Artifacts
            system(['mrdegibbs -force ' fullfile(topupDir, apFile) ' ' fullfile(topupDir, myFiles{ii})]);

        end
    end


    %% topup correction

    % Check number of slices in the image -> dim3 in the output
    % If the number is odd topup will crash -> https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;67dcb45c.1209
    system(['fslinfo ' fullfile(topupDir, apFile) ' >> ' fullfile(topupDir, 'fslinfo.txt')]);
    info = importdata(fullfile(topupDir, 'fslinfo.txt'));
    dim3 = info.data(3,1);

    if mod(dim3, 2) == 0 % even number
    else % odd number
        % In case of odd number of slices, we have to remove one slice to
        % be able to run topup - we will keep the originals in the rawdata folder
        system(['fslroi ' fullfile(topupDir, apFile) ' ' fullfile(topupDir, apFile) ' 0 -1 0 -1 0 ' num2str((dim3-1))]);
        system(['fslroi ' fullfile(topupDir, paFile) ' ' fullfile(topupDir, paFile) ' 0 -1 0 -1 0 ' num2str((dim3-1))]);
    end

    if exist(fullfile(topupDir, appaFile), 'file')
        disp('skipping merging')
    else

        % extract the b0 from the AP and PA dwi image
        system(['fslroi ' fullfile(topupDir, apFile) ' ' fullfile(topupDir, apB0File) ' 0 1']);
        system(['fslroi ' fullfile(topupDir, paFile) ' ' fullfile(topupDir, paB0File) ' 0 1']);

        % merge the b0 images with PA and AP phase encoding directions
        system(['fslmerge -t ' fullfile(topupDir, appaB0File) ' ' fullfile(topupDir, apB0File) ' ' fullfile(topupDir, paB0File)]);

        % merge raw dwi_AP and dwi_PA in one single image
        system(['fslmerge -t ' fullfile(topupDir, appaFile) ' ' fullfile(topupDir, apFile) ' ' fullfile(topupDir, paFile)]);

    end

    % create the acqparams.txt, if it does not exist
    if exist(fullfile(projectDir, 'rawdata', 'acqparams.txt'), 'file')
        disp('acqparams.txt already exists')
    else
        acqparams = [0 1 0 0.05; 0 -1 0 0.05];
        writematrix(acqparams,fullfile(projectDir, 'rawdata', 'acqparams.txt'),'Delimiter','space');
    end


    % Run the Topup correction
    if exist(fullfile(topupDir, 'my_topup_results_fieldcoef.nii.gz'), 'file')
        disp('skipping topup')
    else
        disp('running topup')
        system(['topup --imain='  fullfile(topupDir, appaB0File) ' --datain=' fullfile(projectDir, 'rawdata', 'acqparams.txt') ' --config=b02b0.cnf --out=' fullfile(topupDir, 'my_topup_results') ...
            ' --iout=' fullfile(topupDir, 'my_hifi_b0')]);
    end


    %% Eddy correction
    % Preliminary steps:
    % Create an index file that specifies the phase encoding direction for each volume in the combined dMRI file.
    % Combine bval and bvec files from the two dMRI scans

    nDir = load(fullfile(dwiDir, apFileBval)); % extract the number of directions
    nDirs = length(nDir); % total # directions

    % create the index
    index = [ones(nDirs,1); 2*ones(nDirs,1)];
    writematrix(index, fullfile(topupDir, 'index.txt'), 'Delimiter', 'space');

   % Combine bval and bvec files from the two dMRI scans
    bvals = horzcat(load(fullfile(dwiDir, apFileBval)), load(fullfile(dwiDir, paFileBval)));
    writematrix(bvals, fullfile(topupDir, 'bval_combined.txt'), 'Delimiter', 'space');

    bvecs = horzcat(load(fullfile(dwiDir, apFileBvec)), load(fullfile(dwiDir, paFileBvec)));
    writematrix(bvecs, fullfile(topupDir, 'bvec_combined.txt'), 'Delimiter', 'space');

    % Generate a brain mask using the corrected b0 image
    system(['fslmaths ' fullfile(topupDir, 'my_hifi_b0.nii.gz') ' -Tmean ' fullfile(topupDir, 'my_hifi_b0_mean.nii.gz')])

    % BET the averaged b0 image
    system(['bet ' fullfile(topupDir, 'my_hifi_b0_mean.nii.gz') ' '  fullfile(topupDir, 'my_hifi_b0_mean_brain.nii.gz') ' -m -f 0.2']);


    if exist(fullfile(eddyDir, [eddyFile '.nii.gz']), 'file') % if EddyFile does exist, skip the eddy correction
        disp('skipping eddy correction')
    else
        disp('running eddy correction')
        % run eddy correction
        system(['eddy --imain=' fullfile(topupDir, appaFile) ' --mask=' fullfile(topupDir, 'my_hifi_b0_mean_brain.nii.gz') ...
            ' --acqp=' fullfile(projectDir, 'rawdata/acqparams.txt') ' --index=' fullfile(topupDir, 'index.txt') ...
            ' --bvecs=' fullfile(topupDir, 'bvec_combined.txt') ...
            ' --bvals=' fullfile(topupDir, 'bval_combined.txt') ...
            ' --topup=' fullfile(topupDir, 'my_topup_results') ...
            ' --out=' fullfile(eddyDir, eddyFile) ' --repol --verbose'])

    end


end
