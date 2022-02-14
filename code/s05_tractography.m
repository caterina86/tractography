function s05_tractography(projectDir, subject, session, fmriprep, numFibers_WB, numFibers_OR, numFibers_OT, hemi)

    % Probabilistic tractography (mrtrix3)

    fibDir = fullfile(projectDir, '/derivatives/mrtrix3', subject, session);
    fmriprepDir = fullfile(projectDir, 'derivatives/fmriprep', subject, session);
    eddyDir = fullfile(projectDir, 'derivatives/eddy', subject, session);
    topupDir = fullfile(projectDir, 'derivatives/topup', subject, session);
    roiDir = fullfile(projectDir, '/derivatives/ROIs', subject, session);
    anatPrepDir = fullfile(projectDir, 'derivatives/anat_prep', subject, session);

    eddyFile = [subject '_' session '_eddy_corrected_data'];
    eddyB0FileBrain = [subject '_' session '_eddy_corrected_data_b0_brain'];

    if fmriprep == 1
        t1FileCropBrainDiffSpace = fullfile(fmriprepDir, 'anat/', [subject '_' session '_desc-preproc_T1w_crop_brain_diffspace.nii.gz']);
        ttFile = fullfile(fmriprepDir, 'anat/', [subject '_' session '_5tt.nii.gz']); 
    else
        t1FileCropBrainDiffSpace = fullfile(anatPrepDir, 't1_crop_brain_diffspace.nii.gz');
        ttFile = fullfile(anatPrepDir, [subject '_' session '_5tt.nii.gz']);
    end

    eddy = fullfile(eddyDir, eddyFile);
    bvec = fullfile(eddyDir, [subject, '_', session, '_eddy_corrected_data.eddy_rotated_bvecs']);
    bval = fullfile(topupDir, 'bval_combined.txt');
    mask = fullfile(eddyDir, [eddyB0FileBrain '_mask.nii.gz ']); % brain mask
    
    act = ttFile; % anatomically-constrain tractography
    wmfod = fullfile(fibDir, 'wmfod.mif'); % extracted from eddy_corrected_data.nii.gz aligned to T1-acpc space
 
    if ~ exist(fibDir, 'dir')
        mkdir(fibDir);
    end
    
    
    % Generate 5tt mask (aligned with T1 volume) -> ACT
    system(['5ttgen fsl ' t1FileCropBrainDiffSpace ' ' ttFile ' -premasked']);
    
    % 
    wmfod_file=dir(fullfile(fibDir, 'wmfod.mif'));

    if exist(wmfod, 'file') &&  wmfod_file.bytes >0 % assume the wmfod.mif exists and it's not empty
        disp('skipping fod')
    else
        % Generate normal orientation response function estimates - dhollander algorithm
        system(['dwi2response dhollander ' eddy '.nii.gz -fslgrad ' bvec ' ' bval ' ' ...
            fibDir '/responseEstimate_sfwm.txt ' ...
            fibDir '/responseEstimate_gm.txt ' ...
            fibDir '/responseEstimate_csf.txt -mask ' mask])

        % Generate normal fiber orientation distribution estimates (FOD) - mdmt_csd algorithm
        system(['dwi2fod msmt_csd -mask ' mask ' ' eddy '.nii.gz -fslgrad ' bvec ' ' bval ' ' ...
            fibDir '/responseEstimate_sfwm.txt ' fibDir '/wmfod.mif ' ...
            fibDir '/responseEstimate_gm.txt ' fibDir '/gmfod.mif ' ...
            fibDir  '/responseEstimate_csf.txt ' fibDir '/csffod.mif '])
        
    end


    %% Whole brain tractography
    
    outFile = fullfile(fibDir, ['dti_wholeBrain_ACT_' num2str(numFibers_WB/1000000) 'M.tck']);
    outFile_name = dir(fullfile(fibDir, ['dti_wholeBrain_ACT_' num2str(numFibers_WB/1000000) 'M.tck']));

    if exist(outFile, 'file') &&  outFile_name.bytes > 0 % assume the wmfod.mif exists and it's not empty
        disp('skipping whole brain tractography')
    else        
        % Run tractography
        system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' act  ' -select ' num2str(numFibers_WB) ' -seeds 0']);
    end
    
    
    %% Optic Radiations Tractography

    for jj = 1:length(hemi)

        maxLength = 150;
        outFile = fullfile(fibDir, ['dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k.tck']);
        outFile_name = dir(fullfile(fibDir, ['dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k.tck']));
        roi1 = fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']); % FreeSurfer LGN
        roi2 = fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz']); % FreeSurfer V1

        if exist(outFile, 'file') &&  outFile_name.bytes >0 % assume the wmfod.mif exists and it's not empty
            disp('skipping OR tractography')
        else 
        
            % Run tractography
            system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' roi1 ' -seed_image ' roi2 ' -include ' ...
                roi1 ' -include ' roi2 ' -stop ' '-select ' num2str(numFibers_OR) ' -seeds 0 ' '-maxlength ' num2str(maxLength)])
        end
    end

    
    % Optic Tract - larger number of fibers take more time
    for jj = 1:length(hemi)

        maxLength = 150; % to avoid having long fibers
        outFile = fullfile(fibDir, ['dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k.tck']);
        outFile_name = dir(fullfile(fibDir, ['dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k.tck']));
        roi1 = fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']); % FreeSurfer LGN
        roi2 = fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_2dilM.nii.gz'); % Freesurfer Optic Chiasm expanded 

        if exist(outFile, 'file') &&  outFile_name.bytes >0 % assume the wmfod.mif exists and it's not empty
            disp('skipping OT tractography')
        else     
            % Run tractography
            system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' roi1 ' -seed_image ' roi2 ' -include ' ...
                roi1 ' -include ' roi2 ' -stop ' '-select ' num2str(numFibers_OT) ' -seeds 0 ' '-maxlength ' num2str(maxLength)])
        end
    end
    
    disp('Tractography done!')
    
end
