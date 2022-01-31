% extract LGN, V1, Optic Chiasm and Thalamus to perform the OR and OT tractography

function s04_extract_ROIs(projectDir, subject, session, fmriprep, hemi)

    roiDir = fullfile(projectDir, '/derivatives/ROIs', subject, session);
    eddyDir = fullfile(projectDir, 'derivatives/eddy', subject, session);
    fsDir = fullfile(projectDir, 'derivatives/freesurfer', subject);
    anatPrepDir = fullfile(projectDir, 'derivatives/anat_prep', subject, session);
    anatDir = fullfile(projectDir, 'rawdata', subject, session, 'anat');

    eddyFile = [subject '_' session '_eddy_corrected_data.nii.gz'];
    eddyB0File = [subject '_' session '_eddy_corrected_data_b0'];
    eddyB0FileBrain = [subject '_' session '_eddy_corrected_data_b0_brain'];

    if fmriprep == 1 % if fmriprep was performed
        fmriprepDir = fullfile(projectDir, 'derivatives/fmriprep', subject,session);
        t1File = fullfile(fmriprepDir, 'anat/',[subject '_' session '_desc-preproc_T1w.nii.gz']);
        t1FileCrop = fullfile(fmriprepDir,'anat/',[subject '_' session '_desc-preproc_T1w_crop.nii.gz']);
        t1FileCropBrain = fullfile(fmriprepDir,'anat/',[subject '_' session '_desc-preproc_T1w_crop_brain.nii.gz']);
        t1FileCropBrainDiffSpace = fullfile(fmriprepDir,'anat/',[subject '_' session '_desc-preproc_T1w_crop_brain_diffspace.nii.gz']);
        t12dwi = fullfile(fmriprepDir, 'anat/t1_2_dwi_xfm.mat');
    else % if fmriprep was not performed
        t1File = fullfile(anatDir, 't1.nii.gz');
        t1FileCrop = fullfile(anatPrepDir, 't1_crop.nii.gz');
        t1FileCropBrain = fullfile(anatPrepDir, 't1_crop_brain.nii.gz');
        t1FileCropBrainDiffSpace = fullfile(anatPrepDir, 't1_crop_brain_diffspace.nii.gz');
        t12dwi = fullfile(anatPrepDir, 't1_2_dwi_xfm.mat');
    end

    % create the folder for the ROIs
    mkdir(roiDir)

    % extract the b0 from the eddy corrected image
    system(['fslroi ' fullfile(eddyDir, eddyFile) ' ' fullfile(eddyDir, eddyB0File) ' 0 1']);

    % Skull-strip the resulting b0 volume and generate a brain mask using bet
    system(['bet ' fullfile(eddyDir, eddyB0File) ' ' fullfile(eddyDir, eddyB0FileBrain) ' -m -f 0.25']);

    if fmriprep == 1
        % Skip the neck from the T1
        system(['robustfov -i ' t1File ' -r ' t1FileCrop]);
    else
    end

    % Skull-stripped the T1:
    system(['bet ' t1FileCrop ' ' t1FileCropBrain ' -m -f 0.25']);

    % Coregistration of the T1 to dwi space (dwi spatial resolution) 
    % and extraction of the coregistration matrix
    system(['flirt -in ' t1FileCropBrain ' -ref ' fullfile(eddyDir, eddyB0FileBrain) ...
        ' -out ' t1FileCropBrainDiffSpace ...
        ' -omat ' t12dwi ' -dof 6']);

      
    %% extract ROIs

    % Subcortical segmentation
    % Segment thalamic nuclei (requires that subject has already been processed with recon-all);
    % fs_install_mcr R2014b
    % download the runtime for FS version 7: fs_install_mcr R2014b
    % If the fs_install_mcr script is not available in your freesurfer distribution, it can be downloaded by running the following command:
    % cd $FREESURFER_HOME/bin && curl https://raw.githubusercontent.com/freesurfer/freesurfer/dev/scripts/fs_install_mcr -o fs_install_mcr && chmod +x fs_install_mcrsystem(['segmentThalamicNuclei.sh ' sub{ii} ' ' fsDir]);
    % Run without any problem on Mac Catalina (problems with BigSur)
    % system(['segmentThalamicNuclei.sh sub-' sub{sub_i} ' ' fullfile(projectDir, 'derivatives/freesurfer')]);

    % LGN
    % Convert segmented atlas to volume
    system(['mri_label2vol --seg ' fsDir '/mri/ThalamicNuclei.v12.T1.mgz --temp ' fsDir '/mri/orig.mgz --o ' fsDir '/mri/ThalSegNativeVol.nii.gz --regheader ' fsDir '/mri/ThalamicNuclei.v12.T1.mgz'])
    % Extract left and right LGN from volume
    system(['fslmaths ' fsDir '/mri/ThalSegNativeVol.nii.gz -thr 8109 -uthr 8109 ' roiDir '/fs_lh_lgn.nii.gz']);
    system(['fslmaths ' fsDir '/mri/ThalSegNativeVol.nii.gz -thr 8209 -uthr 8209 ' roiDir '/fs_rh_lgn.nii.gz']);

    % Process outputs (binarize, reslice, flip)
    for jj = 1:length(hemi)

        % Reslice to the T1
        system(['mri_convert -rt nearest -rl ' t1FileCropBrain ' ' ...
            fullfile(roiDir, ['fs_' hemi{jj} '_lgn.nii.gz ']) ....
            fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice.nii.gz'])]);

        % Binarize ROI
        system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice.nii.gz']) ' -bin ' ...
            fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice.nii.gz'])]);

        % Coregister the LGN to diffusion space
        system(['flirt -in ' fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice.nii.gz']) ...
            ' -ref ' fullfile(eddyDir, eddyB0FileBrain) ...
            ' -out ' fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']) ...
            ' -init ' t12dwi ' -applyxfm']);
        
        % Binarize the ROI
        system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']) ' -bin ' ...
            fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz'])]);

    end

    %% V1

    for jj = 1:length(hemi)

        % mri_label2vol for xh.V1.label file
        system(['mri_label2vol --label ' fsDir '/label/' hemi{jj} '.V1_exvivo.label --temp ' fsDir '/mri/orig.mgz --o ' fsDir '/label/' hemi{jj} '_V1.nii.gz --identity --fillthresh .3 --proj frac 0 1 .1 --hemi ' hemi{jj} ' --subject ' subject]);

        % Smooth nifti V1 ROI using -fmedian flag
        system(['fslmaths ' fsDir '/label/' hemi{jj} '_V1.nii.gz -fmedian ' fsDir '/label/' hemi{jj} '_V1.nii.gz']);

        % Reslice to the T1
        system(['mri_convert -rt nearest -rl ' t1FileCropBrain ' ' ...
            fullfile(fsDir, ['label/' hemi{jj} '_V1.nii.gz ']) ....
            fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice.nii.gz'])]);

        % Binarize smoothed output
        system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice.nii.gz']) ' -bin ' ...
            fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice.nii.gz'])]);

        % Coregister the V1 to diffusion space
        system(['flirt -in ' fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice.nii.gz']) ...
            ' -ref ' fullfile(eddyDir, eddyB0FileBrain) ...
            ' -out ' fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz']) ...
            ' -init ' t12dwi ' -applyxfm']);
        
        % Binarize
        system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz']) ' -bin ' ...
            fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz'])]);

    end


    %% Optic Tract
    % Convert aparc+aseg.mgz to nifti
    system(['mri_convert ' fsDir '/mri/aparc+aseg.mgz ' fsDir '/mri/aparc+aseg.nii.gz']); % Reslice aparc+aseg to t1 resolution and save to t1 directory

    % Extract Optic Chiams from freesurfer (85), smooth the ROI and reslice to the T1
    system(['fslmaths ' fsDir '/mri/aparc+aseg.nii.gz ' ...
        '-thr 85 -uthr 85 ' fullfile(roiDir, 'fs_oc.nii.gz')]);

    % Reslice to the T1
    system(['mri_convert -rt nearest -rl ' t1FileCropBrain ' ' ...
        fullfile(roiDir, 'fs_oc.nii.gz ') ....
        fullfile(roiDir, 'fs_oc_T1Reslice.nii.gz')]);

    % Binarize the mask
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice.nii.gz') ' -bin ' ...
        fullfile(roiDir, 'fs_oc_T1Reslice.nii.gz')]);

    % Coregister the OC to diffusion space
    system(['flirt -in ' fullfile(roiDir, 'fs_oc_T1Reslice.nii.gz') ...
        ' -ref ' fullfile(eddyDir, eddyB0FileBrain) ...
        ' -out ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace.nii.gz') ...
        ' -init ' t12dwi ' -applyxfm']);

    % Expand the Optic Chiasm:
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace.nii.gz') ' -dilM ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_dilM.nii.gz')]);
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_dilM.nii.gz') ' -dilM ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_2dilM.nii.gz')]);
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_2dilM.nii.gz') ' -dilM ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz')]);
    % Binarize all the masks
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz') ' -bin ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz')]); % binarize the mask
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_2dilM.nii.gz') ' -bin ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_2dilM.nii.gz')]); % binarize the mask
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_dilM.nii.gz') ' -bin ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_dilM.nii.gz')]); % binarize the mask



    %% Thalamus
     system(['fslmaths ' fsDir '/mri/aparc+aseg.nii.gz ' ...
        '-thr 10 -uthr 10 ' fullfile(roiDir, 'fs_lh_thalamus.nii.gz')]);
     system(['fslmaths ' fsDir '/mri/aparc+aseg.nii.gz ' ...
        '-thr 49 -uthr 49 ' fullfile(roiDir, 'fs_rh_thalamus.nii.gz')]);

    % Merge
    system(['fslmaths ' fullfile(roiDir, 'fs_lh_thalamus.nii.gz') ' -add ' fullfile(roiDir, 'fs_rh_thalamus.nii.gz ') ...
        fullfile(roiDir, 'fs_thalamus.nii.gz')]);

    % Reslice to the T1
    system(['mri_convert -rt nearest -rl ' t1FileCropBrain ' ' ...
        fullfile(roiDir, 'fs_thalamus.nii.gz ') ....
        fullfile(roiDir, 'fs_thalamus_T1Reslice.nii.gz')]);

    % Binarize
    system(['fslmaths ' fullfile(roiDir, 'fs_thalamus_T1Reslice.nii.gz') ' -bin ' fullfile(roiDir, ['fs_thalamus_T1Reslice.nii.gz'])]); % save in ROI folder

    % Coregister the OC to diffusion space
    system(['flirt -in ' fullfile(roiDir, 'fs_thalamus_T1Reslice.nii.gz') ...
        ' -ref ' fullfile(eddyDir, eddyB0FileBrain) ...
        ' -out ' fullfile(roiDir, 'fs_thalamus_T1Reslice_diffspace.nii.gz') ...
        ' -init ' t12dwi ' -applyxfm']);
    
    % Binarize
    system(['fslmaths ' fullfile(roiDir, 'fs_thalamus_T1Reslice_diffspace.nii.gz') ' -bin ' ...
        fullfile(roiDir, 'fs_thalamus_T1Reslice_diffspace.nii.gz')]); % save in ROI folder


    %% Subtract LGNs from thalamus volume & binarize
    system(['fslmaths ' fullfile(roiDir, 'fs_thalamus_T1Reslice_diffspace.nii.gz') ' -sub ' ...
        fullfile(roiDir, ['fs_' hemi{1} '_lgn_T1Reslice_diffspace.nii.gz']) ' -sub ' ...
        fullfile(roiDir, ['fs_' hemi{2} '_lgn_T1Reslice_diffspace.nii.gz']) ' ' ...
        fullfile(roiDir, 'fs_thalamus_sub_LGNs_diffspace.nii.gz')]);

    system(['fslmaths '  fullfile(roiDir, 'fs_thalamus_sub_LGNs_diffspace.nii.gz') ' -bin ' ...
         fullfile(roiDir, 'fs_thalamus_sub_LGNs_diffspace.nii.gz')]);


     disp('ROIs extraction!')

end

% IMPORTANT: Check always the FOV, resolution and location of the ROIs over the
% diffusion image and the T1 coregistered to the diffusion.

