% extract LGN, V1 and Optic Chiasm, to perform the OR and OT tractography

clear all;
user = 'caterina'; % name of the user
% choose 'server' if you are working on the server
% add your name if you are working on your local PC. In this case you
% should add your files locations in the following 'switch user'

% Set the path
switch user
    case {'caterina'}
        projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output    
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
end

sub = {'201'}; % initials of the subject
ses = {'01'}; % ID of the session
hemi = {'lh', 'rh'};

% derivatives:
eddyDir = [projectDir '/derivatives/eddy/'];
topup = [projectDir '/derivatives/topup/'];
roiDir = [projectDir '/derivatives/ROIs/'];
fmriprep = [projectDir '/derivatives/fmriprep/'];
fsDir = [projectDir '/derivatives/freesurfer/'];

% Add paths - update the location of vistasoft and AFQ according to your PC
addpath(genpath('~/Data/GitHub/Prakash/Toolbox/vistasoft')); % vistasoft location
addpath(genpath('~/Data/GitHub/Prakash/Toolbox/AFQ')); % afq location

% add the path of the code
addpath(genpath(fullfile(projectDir, 'code/'))); % afq location

% FSL - remember to update the location of freesurfer according to
% the location on your PC
setenv('FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); %added to tell where to save the fsl outputs
PATH = getenv('PATH'); setenv('PATH', ['/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/bin:' PATH]);


%% Extract Regions of Interest

sub_i = length(sub);

for ses_i = 1:numel(dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'))) % for each scan session
    
    % create the folder for the ROIs
    mkdir([roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]]) 
        
    % extract the b0 from the eddy corrected image
    system(['fslroi ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data ' ...
        eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0.nii.gz 0 1' ]);
 
    % Skull-strip the resulting b0 volume and generate a brain mask using bet 
    system(['bet ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0.nii.gz ' ...
        eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain.nii.gz -m -f 0.25'])
    
    % Check the resolution of the T1 -> 0.8 isotropic
    system(['fslinfo ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'anat/' ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_desc-preproc_T1w.nii.gz ']])
    
    % Upsample the skull-stripped b0 DWI volume to the T1    
    system(['flirt -in ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain.nii.gz ' ...
       '-ref ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain.nii.gz ' ...
       '-out ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain_Opt8.nii.gz -applyisoxfm 0.8'])
    
    % Verify the resolution
    system(['fslinfo ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain_Opt8.nii.gz'])

    % Skip the neck from the T1
    system(['robustfov -i ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['anat/sub-' sub{sub_i} '_ses-' ses{ses_i} '_desc-preproc_T1w.nii.gz'] ' -r ' ...  
        fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['anat/sub-' sub{sub_i} '_ses-' ses{ses_i} '_desc-preproc_T1w_crop.nii.gz']]);

    % Skull-stripped the T1
    system(['bet ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['anat/sub-' sub{sub_i} '_ses-' ses{ses_i} '_desc-preproc_T1w_crop.nii.gz '] ...
        fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['anat/sub-' sub{sub_i} '_ses-' ses{ses_i} '_desc-preproc_T1w_crop_brain.nii.gz ' ] '-m -f 0.25'])
    
    % Coregistration of the T1 to dwi space and extract the coregistration matrix    
    system(['flirt -in ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['anat/sub-' sub{sub_i} '_ses-' ses{ses_i} '_desc-preproc_T1w_crop_brain.nii.gz '] ...
        '-ref ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain_Opt8.nii.gz ' ...
        '-out ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['anat/sub-' sub{sub_i} '_ses-' ses{ses_i} '_desc-preproc_T1w_crop_brain_diffspace.nii.gz '] ...
        '-omat ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'anat/t1_2_dwi_xfm.mat -dof 6']);

    
    %% extract ROIs
    
    % LGN
    % Convert segmented atlas to volume
    system(['mri_label2vol --seg ' fsDir 'sub-' sub{sub_i} '/mri/ThalamicNuclei.v12.T1.mgz --temp ' fsDir 'sub-' sub{sub_i} '/mri/orig.mgz --o ' fsDir 'sub-' sub{sub_i} '/mri/ThalSegNativeVol.nii.gz --regheader ' fsDir 'sub-' sub{sub_i} '/mri/ThalamicNuclei.v12.T1.mgz'])    
    % Extract left and right LGN from volume
    system(['fslmaths ' fsDir 'sub-' sub{sub_i} '/mri/ThalSegNativeVol.nii.gz -thr 8109 -uthr 8109 ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_lh_lgn.nii.gz']);
    system(['fslmaths ' fsDir 'sub-' sub{sub_i} '/mri/ThalSegNativeVol.nii.gz -thr 8209 -uthr 8209 ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_rh_lgn.nii.gz']);
      
    % Process outputs (binarize, reslice, flip)
    for jj = 1:length(hemi)
        
        % Reslice to the T1 
        system(['mri_convert -rt nearest -rl ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['anat/sub-' sub{sub_i} '_ses-' ses{ses_i} '_desc-preproc_T1w_crop_brain.nii.gz '] ...
            roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_lgn.nii.gz ' ....
            roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_lgn_T1Reslice.nii.gz '])
        
        % Binarize ROI
        system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_lgn_T1Reslice.nii.gz -bin ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_lgn_T1Reslice.nii.gz']);
        
        % Coregister the LGN to diffusion space
        system(['flirt -in ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_lgn_T1Reslice.nii.gz ' ...
            '-ref ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain_Opt8.nii.gz ' ...
            '-out ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz ' ...
            '-init ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'anat/t1_2_dwi_xfm.mat -applyxfm']);
        
        % Binarize the ROI
        system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz -bin ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']); % save in ROI folder
   
    end

    %% V1
    
    for jj = 1:length(hemi)
        
        % mri_label2vol for xh.V1.label file
        system(['mri_label2vol --label ' fsDir 'sub-' sub{sub_i} '/label/' hemi{jj} '.V1_exvivo.label --temp ' fsDir 'sub-' sub{sub_i} '/mri/orig.mgz --o ' fsDir 'sub-' sub{sub_i} '/label/' hemi{jj} '_V1.nii.gz --identity --fillthresh .3 --proj frac 0 1 .1 --hemi ' hemi{jj} ' --subject ' fsDir 'sub-' sub{sub_i}])

        % Smooth nifti V1 ROI using -fmedian flag
        system(['fslmaths ' fsDir 'sub-' sub{sub_i} '/label/' hemi{jj} '_V1.nii.gz -fmedian ' fsDir 'sub-' sub{sub_i} '/label/' hemi{jj} '_V1.nii.gz'])

        % Reslice to the T1 
        system(['mri_convert -rt nearest -rl ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['anat/sub-' sub{sub_i} '_ses-' ses{ses_i} '_desc-preproc_T1w_crop_brain.nii.gz '] ...
            fsDir 'sub-' sub{sub_i} '/label/' hemi{jj} '_V1.nii.gz ' ....
            roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_V1_T1Reslice.nii.gz '])

        % Binarize smoothed output
        system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_V1_T1Reslice.nii.gz -bin ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_V1_T1Reslice.nii.gz'])

        % Coregister the V1 to diffusion space            
        system(['flirt -in ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_V1_T1Reslice.nii.gz ' ...
            '-ref ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain_Opt8.nii.gz ' ...
            '-out ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz ' ...
            '-init ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'anat/t1_2_dwi_xfm.mat -applyxfm']);
  
 
        system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz -bin ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz']); % save in ROI folder

    end
     
    
    %% Optic Tract
    % Convert aparc+aseg.mgz to nifti
    system(['mri_convert ' fsDir 'sub-' sub{sub_i} '/mri/aparc+aseg.mgz ' fsDir 'sub-' sub{sub_i} '/mri/aparc+aseg.nii.gz']) % Reslice aparc+aseg to t1 resolution and save to t1 directory

    % Extract Optic Chiams from freesurfer (85), smooth the ROI and reslice to the T1
    system(['fslmaths ' fsDir 'sub-' sub{sub_i} '/mri/aparc+aseg.nii.gz ' ...
        '-thr 85 -uthr 85 ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc.nii.gz']);    
    
    % Reslice to the T1 
    system(['mri_convert -rt nearest -rl ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['anat/sub-' sub{sub_i} '_ses-' ses{ses_i} '_desc-preproc_T1w_crop_brain.nii.gz '] ...
        roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc.nii.gz ' ....
        roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice.nii.gz '])
        
    % Binarize 
    system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice.nii.gz -bin ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice.nii.gz'])
        
    % Coregister the OC to diffusion space
    system(['flirt -in ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice.nii.gz ' ...
        ' -ref ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain_Opt8.nii.gz ' ...
        ' -out ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice_diffspace.nii.gz ' ...
        ' -init ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'anat/t1_2_dwi_xfm.mat -applyxfm']);

    % Expand the Optic Chiasm:
    system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice_diffspace.nii.gz -dilM ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice_diffspace_dilM.nii.gz'])          
    system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice_diffspace_dilM.nii.gz -dilM ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice_diffspace_2dilM.nii.gz'])          
    system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice_diffspace_2dilM.nii.gz -dilM ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice_diffspace_3dilM.nii.gz'])          
    system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice_diffspace_3dilM.nii.gz -bin ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice_diffspace_3dilM.nii.gz']) % binarize the mask
    
    
    
    %% Thalamus
     system(['fslmaths ' fsDir 'sub-' sub{sub_i} '/mri/aparc+aseg.nii.gz ' ...
        '-thr 10 -uthr 10 ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_lh_thalamus.nii.gz']); 
     system(['fslmaths ' fsDir 'sub-' sub{sub_i} '/mri/aparc+aseg.nii.gz ' ...
        '-thr 49 -uthr 49 ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_rh_thalamus.nii.gz']);
    
    % Merge
    system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_lh_thalamus.nii.gz ' ...
        '-add ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_rh_thalamus.nii.gz ' ...
        roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus.nii.gz']);

    % Reslice to the T1 
    system(['mri_convert -rt nearest -rl ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep ['anat/sub-' sub{sub_i} '_ses-' ses{ses_i} '_desc-preproc_T1w_crop_brain.nii.gz '] ...
        roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus.nii.gz ' ....
        roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_T1Reslice.nii.gz '])

    % Binarize
    system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_T1Reslice.nii.gz -bin ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_T1Reslice.nii.gz']); % save in ROI folder

    % Coregister the OC to diffusion space
    system(['flirt -in ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_T1Reslice.nii.gz ' ...
        ' -ref ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data_b0_brain_Opt8.nii.gz ' ...
        ' -out ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_T1Reslice_diffspace.nii.gz ' ...
        ' -init ' fmriprep ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'anat/t1_2_dwi_xfm.mat -applyxfm']);

    % Binarize
    system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_T1Reslice_diffspace.nii.gz -bin ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_T1Reslice_diffspace.nii.gz']); % save in ROI folder
     
    
    %% Subtract LGNs from thalamus volume & binarize
    system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_T1Reslice_diffspace.nii.gz -sub ' ...
        roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{1} '_lgn_T1Reslice_diffspace.nii.gz -sub ' ...
        roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{2} '_lgn_T1Reslice_diffspace.nii.gz ' ...
        roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_sub_LGNs_diffspace.nii.gz']);

    system(['fslmaths ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_sub_LGNs_diffspace.nii.gz -bin ' ...
        roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_sub_LGNs_diffspace.nii.gz']);

end

% IMPORTANT: Check always the FOV, resolution and location of the ROIs over the
% diffusion image and the T1 coregistered to the diffusion.
