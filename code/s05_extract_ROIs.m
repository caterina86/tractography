% extract LGN, V1, Optic Chiasm and Thalamus to perform the OR and OT tractography

clear all;

% Setup the environment
% FSL - remember to update the location of FSL according to the location on your PC
setenv('FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); % added to tell where to save the fsl outputs
setenv('FREESURFER_HOME', '/Applications/freesurfer'); 
% setenv('FREESURFER_HOME', '/Applications/freesurfer/7.2.0');
PATH = getenv('PATH'); setenv('PATH', ['/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/bin:' PATH]);
%PATH = getenv('PATH'); setenv('PATH', ['/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/7.2.0/bin:' PATH]);

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
end
addpath(genpath(fullfile(projectDir, 'code'))); % add user code to path

sub = {'201'}; % initials of the subject
ses = {'01'}; % ID of the session
hemi = {'lh', 'rh'};


%% Extract Regions of Interest

sub_i = 1:length(sub); % loop over subjects (eventually)

sub_ses = dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'));

for ses_i = 1:numel(sub_ses) % for each scan session
    
    roiDir = fullfile(projectDir, '/derivatives/ROIs', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    topupDir = fullfile(projectDir, 'derivatives/topup', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);        
    eddyDir = fullfile(projectDir, 'derivatives/eddy', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);        
    fmriprepDir = fullfile(projectDir, 'derivatives/fmriprep', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);        
    fsDir = fullfile(projectDir, 'derivatives/freesurfer', ['sub-' sub{sub_i}]);
    
    eddyFile = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data'];
    eddyB0File = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data_b0'];
    eddyB0FileBrain = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data_b0_brain'];
    eddyB0FileBrainOpt8 = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data_b0_brain_Opt8'];
    t1File = ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_desc-preproc_T1w.nii.gz'];
    t1FileCrop = ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_desc-preproc_T1w_crop.nii.gz'];
    t1FileCropBrain = ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_desc-preproc_T1w_crop_brain.nii.gz'];
    t1FileCropBrainDiffSpace = ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_desc-preproc_T1w_crop_brain_diffspace.nii.gz'];
    
    % create the folder for the ROIs
    mkdir(roiDir) 
        
    % extract the b0 from the eddy corrected image
    system(['fslroi ' fullfile(eddyDir, eddyFile) ' ' fullfile(eddyDir, eddyB0File) ' 0 1'])
 
    % Skull-strip the resulting b0 volume and generate a brain mask using bet 
    system(['bet ' fullfile(eddyDir, eddyB0File) ' ' fullfile(eddyDir, eddyB0FileBrain) ' -m -f 0.25'])
    
    % Check the resolution of the T1 -> 0.8 isotropic
    system(['fslinfo ' fullfile(fmriprepDir, 'anat/', t1File)])
    
    % Upsample the skull-stripped b0 DWI volume to the T1    
    system(['flirt -in ' fullfile(eddyDir, eddyB0FileBrain) ' -ref ' fullfile(eddyDir, eddyB0FileBrain) ...
       ' -out ' fullfile(eddyDir, eddyB0FileBrainOpt8) ' -applyisoxfm 0.8'])
    
    % Verify the resolution
    system(['fslinfo ' fullfile(eddyDir, eddyB0FileBrainOpt8)])

    % Skip the neck from the T1
    system(['robustfov -i ' fullfile(fmriprepDir, 'anat/', t1File) ' -r ' fullfile(fmriprepDir, 'anat/', t1FileCrop)])

    % Skull-stripped the T1
    system(['bet ' fullfile(fmriprepDir, 'anat/', t1FileCrop) ' ' fullfile(fmriprepDir, 'anat/', t1FileCropBrain) ' -m -f 0.25'])
    
    % Coregistration of the T1 to dwi space and extraction of the coregistration matrix    
    system(['flirt -in ' fullfile(fmriprepDir, 'anat/', t1FileCropBrain) ' -ref ' fullfile(eddyDir, eddyB0FileBrainOpt8) ...
        ' -out ' fullfile(fmriprepDir, 'anat/', t1FileCropBrainDiffSpace) ...
        ' -omat ' fullfile(fmriprepDir, 'anat/t1_2_dwi_xfm.mat') ' -dof 6']);

    
    
    %% extract ROIs
    
    % LGN   
    % Convert segmented atlas to volume
    system(['mri_label2vol --seg ' fsDir '/mri/ThalamicNuclei.v12.T1.mgz --temp ' fsDir '/mri/orig.mgz --o ' fsDir '/mri/ThalSegNativeVol.nii.gz --regheader ' fsDir '/mri/ThalamicNuclei.v12.T1.mgz'])    
    % Extract left and right LGN from volume
    system(['fslmaths ' fsDir '/mri/ThalSegNativeVol.nii.gz -thr 8109 -uthr 8109 ' roiDir '/fs_lh_lgn.nii.gz']);
    system(['fslmaths ' fsDir '/mri/ThalSegNativeVol.nii.gz -thr 8209 -uthr 8209 ' roiDir '/fs_rh_lgn.nii.gz']);
      
    % Process outputs (binarize, reslice, flip)
    for jj = 1:length(hemi)
        
        % Reslice to the T1 
        system(['mri_convert -rt nearest -rl ' fullfile(fmriprepDir, 'anat/', t1FileCropBrain) ' ' ...
            fullfile(roiDir, 'fs_lh_lgn.nii.gz ') ....
            fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice.nii.gz'])])
        
        % Binarize ROI
        system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice.nii.gz']) ' -bin ' ...
            fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice.nii.gz'])]);
        
        % Coregister the LGN to diffusion space
        system(['flirt -in ' fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice.nii.gz']) ...
            ' -ref ' fullfile(eddyDir, eddyB0FileBrainOpt8) ...
            ' -out ' fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']) ...
            ' -init ' fullfile(fmriprepDir, 'anat/t1_2_dwi_xfm.mat') ' -applyxfm']);
        
        % Binarize the ROI
        system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']) ' -bin ' ...
            fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz'])]); 
   
    end

    %% V1
    
    for jj = 1:length(hemi)
        
        % mri_label2vol for xh.V1.label file
        system(['mri_label2vol --label ' fsDir '/label/' hemi{jj} '.V1_exvivo.label --temp ' fsDir '/mri/orig.mgz --o ' fsDir '/label/' hemi{jj} '_V1.nii.gz --identity --fillthresh .3 --proj frac 0 1 .1 --hemi ' hemi{jj} ' --subject ' fsDir])

        % Smooth nifti V1 ROI using -fmedian flag
        system(['fslmaths ' fsDir '/label/' hemi{jj} '_V1.nii.gz -fmedian ' fsDir '/label/' hemi{jj} '_V1.nii.gz'])

        % Reslice to the T1 
        system(['mri_convert -rt nearest -rl ' fullfile(fmriprepDir, 'anat/', t1FileCropBrain) ' ' ...
            fullfile(fsDir, ['label/' hemi{jj} '_V1.nii.gz ']) ....
            fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice.nii.gz'])])

        % Binarize smoothed output
        system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice.nii.gz']) ' -bin ' ...
            fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice.nii.gz'])])

        % Coregister the V1 to diffusion space              
        system(['flirt -in ' fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice.nii.gz']) ...
            ' -ref ' fullfile(eddyDir, eddyB0FileBrainOpt8) ...
            ' -out ' fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz']) ...
            ' -init ' fullfile(fmriprepDir, 'anat/t1_2_dwi_xfm.mat') ' -applyxfm']);
 
        % Binarize
        system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz']) ' -bin ' ...
            fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz'])]); 
    
    end
     
    
    %% Optic Tract
    % Convert aparc+aseg.mgz to nifti
    system(['mri_convert ' fsDir '/mri/aparc+aseg.mgz ' fsDir '/mri/aparc+aseg.nii.gz']) % Reslice aparc+aseg to t1 resolution and save to t1 directory

    % Extract Optic Chiams from freesurfer (85), smooth the ROI and reslice to the T1
    system(['fslmaths ' fsDir '/mri/aparc+aseg.nii.gz ' ...
        '-thr 85 -uthr 85 ' fullfile(roiDir, 'fs_oc.nii.gz')]);    
    
    % Reslice to the T1 
    system(['mri_convert -rt nearest -rl ' fullfile(fmriprepDir, 'anat/', t1FileCropBrain) ' ' ...
        fullfile(roiDir, 'fs_oc.nii.gz ') ....
        fullfile(roiDir, ['fs_' hemi{jj} '_oc_T1Reslice.nii.gz'])]);

        
    % Binarize 
    system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_oc_T1Reslice.nii.gz']) ' -bin ' ...
        fullfile(roiDir, ['fs_' hemi{jj} '_oc_T1Reslice.nii.gz'])]);
        
    % Coregister the OC to diffusion space
    system(['flirt -in ' fullfile(roiDir, 'fs_oc_T1Reslice.nii.gz') ...
        ' -ref ' fullfile(eddyDir, eddyB0FileBrainOpt8) ...
        ' -out ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace.nii.gz') ...
        ' -init ' fullfile(fmriprepDir, 'anat/t1_2_dwi_xfm.mat') ' -applyxfm']);

    % Expand the Optic Chiasm:
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace.nii.gz') ' -dilM ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_dilM.nii.gz')]);        
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_dilM.nii.gz') ' -dilM ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_2dilM.nii.gz')])          
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_2dilM.nii.gz') ' -dilM ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz')])          
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz') ' -bin ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz')]) % binarize the mask
    
    
    
    %% Thalamus
     system(['fslmaths ' fsDir '/mri/aparc+aseg.nii.gz ' ...
        '-thr 10 -uthr 10 ' fullfile(roiDir, 'fs_lh_thalamus.nii.gz')]); 
     system(['fslmaths ' fsDir '/mri/aparc+aseg.nii.gz ' ...
        '-thr 49 -uthr 49 ' fullfile(roiDir, 'fs_l=rh_thalamus.nii.gz')]);
    
    % Merge
    system(['fslmaths ' fullfile(roiDir, 'fs_lh_thalamus.nii.gz') ' -add ' fullfile(roiDir, 'fs_rh_thalamus.nii.gz ') ...
        fullfile(roiDir, 'fs_thalamus.nii.gz')]);

    % Reslice to the T1 
    system(['mri_convert -rt nearest -rl ' fullfile(fmriprepDir, 'anat/', t1FileCropBrain) ' ' ...
        fullfile(roiDir, 'fs_thalamus.nii.gz ') ....
        fullfile(roiDir, ['fs_' hemi{jj} '_thalamus_T1Reslice.nii.gz'])]);
    
    % Binarize
    system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_thalamus_T1Reslice.nii.gz']) ' -bin ' fullfile(roiDir, ['fs_' hemi{jj} '_thalamus_T1Reslice.nii.gz'])]); % save in ROI folder

    % Coregister the OC to diffusion space
    system(['flirt -in ' fullfile(roiDir, 'fs_thalamus_T1Reslice.nii.gz') ...
        ' -ref ' fullfile(eddyDir, eddyB0FileBrainOpt8) ...
        ' -out ' fullfile(roiDir, 'fs_thalamus_T1Reslice_diffspace.nii.gz') ...
        ' -init ' fullfile(fmriprepDir, 'anat/t1_2_dwi_xfm.mat') ' -applyxfm']);

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


end

% IMPORTANT: Check always the FOV, resolution and location of the ROIs over the
% diffusion image and the T1 coregistered to the diffusion.
