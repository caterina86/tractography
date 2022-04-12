function s05c_optic_nerve(projectDir, subject, session, numFibers_ON, hemi)

    % Probabilistic tractography (mrtrix3)

    fibDir = fullfile(projectDir, '/derivatives/mrtrix3', subject, session);
    fmriprepDir = fullfile(projectDir, 'derivatives/fmriprep', subject, session);
    eddyDir = fullfile(projectDir, 'derivatives/eddy', subject, session);
    topupDir = fullfile(projectDir, 'derivatives/topup', subject, session);
    roiDir = fullfile(projectDir, '/derivatives/ROIs', subject, session);
    anatPrepDir = fullfile(fullfile(fmriprepDir, 'anat/'));
    
    eddyFile = [subject '_' session '_eddy_corrected_data'];
    eddyB0File = [subject '_' session '_eddy_corrected_data_b0'];

    t1FileCrop = fullfile(fmriprepDir,'anat/',[subject '_' session '_desc-preproc_T1w_crop.nii.gz']);
    t1FileCropDiffSpace = fullfile(fmriprepDir, 'anat/', [subject '_' session '_desc-preproc_T1w_crop_diffspace.nii.gz']);
    ttFile = fullfile(fmriprepDir, 'anat/', [subject '_' session '_5tt.nii.gz']); 

    eddy = fullfile(eddyDir, eddyFile);
    bvec = fullfile(eddyDir, [subject, '_', session, '_eddy_corrected_data.eddy_rotated_bvecs']);
    bval = fullfile(topupDir, 'bval_combined.txt');
    mask = fullfile(topupDir, [subject, '_', session, '_AP_PA_dwi_b0_bin.nii.gz']);
    mask_response = fullfile(topupDir, [subject, '_', session, '_AP_PA_dwi_b0_bin_3D.nii.gz']);

    act = ttFile; % anatomically-constrain tractography
    wmfod = fullfile(fibDir, 'wmfod_on.mif'); 
 
    if ~ exist(fibDir, 'dir')
        mkdir(fibDir);
    end
    
    
    % Generate 5tt mask (aligned with T1 volume) -> ACT
    % system(['5ttgen fsl ' t1FileCropBrainDiffSpace ' ' ttFile ' -premasked']);
    
    % 
    
    % Mask for the Optic Nerve Tractography
    system(['fslmaths ' fullfile(topupDir, [subject '_' session '_AP_PA_dwi_b0.nii.gz ']) ...
    ' -bin ' mask]);

    cd(topupDir)
    % Split the 4D in 3D images and rename the first of them
    system(['fslsplit ' mask ' -t'])
    system(['mv vol0000.nii.gz ' mask_response]);
    system(['rm vol0001.nii.gz']);
    
    wmfod_file=dir(fullfile(fibDir, 'wmfod_on.mif'));

    if exist(wmfod, 'file') &&  wmfod_file.bytes >0 % assume the wmfod.mif exists and it's not empty
        disp('skipping fod')
    else
        % Generate normal orientation response function estimates - dhollander algorithm
        system(['dwi2response dhollander ' eddy '.nii.gz -fslgrad ' bvec ' ' bval ' ' ...
            fibDir '/responseEstimate_sfwm_on.txt ' ...
            fibDir '/responseEstimate_gm_on.txt ' ...
            fibDir '/responseEstimate_csf_on.txt -mask ' mask_response])

        % Generate normal fiber orientation distribution estimates (FOD) - mdmt_csd algorithm
        system(['dwi2fod msmt_csd -mask ' mask ' ' eddy '.nii.gz -fslgrad ' bvec ' ' bval ' ' ...
            fibDir '/responseEstimate_sfwm_on.txt ' fibDir '/wmfod_on.mif ' ...
            fibDir '/responseEstimate_gm_on.txt ' fibDir '/gmfod_on.mif ' ...
            fibDir  '/responseEstimate_csf_on.txt ' fibDir '/csffod_on.mif '])
        
    end
 
    % matrix of coregistration without the bet
    t12dwi = fullfile(fmriprepDir, 'anat/t1_2_dwi_xfm_noBet.mat');

    % Coregistration of the T1 to dwi space (dwi spatial resolution) 
    % and extraction of the coregistration matrix
    system(['flirt -in ' t1FileCrop ' -ref ' fullfile(eddyDir, eddyB0File) ...
        ' -out ' t1FileCropDiffSpace ...
        ' -omat ' t12dwi ' -dof 6']);
    
    
    %% Optic Nerve Tractography
    
    % Create a point for the beginning and end of the optic nerve, in the
    % T1 native space (t1FileCrop)
    % I can't use the T1w_crop_brain image as the optic nerve is removed
    % during the bet.
    system(['fslmaths ' fullfile(anatPrepDir, [subject '_' session '_desc-preproc_T1w_crop.nii.gz']) ' -mul 0 -add 1 -roi 70 1 217 1 93 1 0 1 ' ...
       fullfile(roiDir, 'lhEyePoint')]);
    system(['fslmaths ' fullfile(anatPrepDir, [subject '_' session '_desc-preproc_T1w_crop.nii.gz']) ' -mul 0 -add 1 -roi 143 1 217 1 91 1 0 1 ' ...
       fullfile(roiDir, 'rhEyePoint')]);
   
    % extract sphere from the point
    for jj = 1:length(hemi)

        % From point to sphere - 5mm
        system(['fslmaths ' fullfile(roiDir, [hemi{jj} 'EyePoint']) ' -kernel sphere 5 -fmean ' ...
            fullfile(roiDir, [hemi{jj} 'EyeSphere5'])])
        
        % Remove the noise and binarize the mask
        system(['fslmaths ' fullfile(roiDir, [hemi{jj} 'EyeSphere5']) ' -thr 1e-8 -bin ' ...
            fullfile(roiDir, [hemi{jj} 'EyeSphere5_bin'])])
        
        % Reslice to the T1
        system(['mri_convert -rt nearest -rl ' t1FileCrop ' ' ...
            fullfile(roiDir, [hemi{jj} 'EyeSphere5_bin.nii.gz ']) ....
            fullfile(roiDir, [hemi{jj} 'EyeSphere5_bin_T1Reslice.nii.gz'])]);
        
        % Coregister the OC to diffusion space
        system(['flirt -in ' fullfile(roiDir, [hemi{jj} 'EyeSphere5_bin_T1Reslice']) ...
            ' -ref ' fullfile(eddyDir, eddyB0File) ...
            ' -out ' fullfile(roiDir, [hemi{jj} 'EyeSphere5_bin_T1Reslice_diffspace']) ...
            ' -init ' t12dwi ' -applyxfm']);
        
        % Binarize
        system(['fslmaths ' fullfile(roiDir, [hemi{jj} 'EyeSphere5_bin_T1Reslice_diffspace']) ' -bin ' ...
            fullfile(roiDir, [hemi{jj} 'EyeSphere5_bin_T1Reslice_diffspace'])]); % save in ROI folder

    end
    

    % Optic Nerve - less number of fibers for a matter of time
    
    for jj = 1:length(hemi)

        maxLength = 150; % to avoid having long fibers
        outFile = fullfile(fibDir, ['dti_' hemi{jj} '_fsAnatomical_ACT_ON_' num2str(numFibers_ON/1000) 'k.tck']);
        outFile_name = dir(fullfile(fibDir, ['dti_' hemi{jj} '_fsAnatomical_ACT_ON_' num2str(numFibers_ON/1000) 'k.tck']));
        roi1 = fullfile(roiDir, [hemi{jj} 'EyeSphere5_bin_T1Reslice_diffspace.nii.gz']); % ROI for the Eye
        roi2 = fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_2dilM.nii.gz'); % Freesurfer Optic Chiasm expanded 

        if exist(outFile, 'file') &&  outFile_name.bytes >0 % assume the wmfod.mif exists and it's not empty
            disp('skipping ON tractography')
        else     
            % Run tractography
            system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' roi1 ' -seed_image ' roi2 ' -include ' ...
                roi1 ' -include ' roi2 ' -stop -select ' num2str(numFibers_ON) ' -seeds 0 -maxlength ' num2str(maxLength)])
        end
    end
    
    
    
    disp('Tractography done!')
    
end
