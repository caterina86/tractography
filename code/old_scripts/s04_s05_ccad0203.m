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

sub = {'ccad0203'}; % initials of the subject
ses = {'01'}; % ID of the session
hemi = {'lh', 'rh'};


%% Extract Regions of Interest

sub_i = 1:length(sub); % loop over subjects (eventually)

sub_ses = dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'));
if isempty(sub_ses)
    error(['No files found in ' projectDir]);
end

for ses_i = 1:numel(sub_ses) % for each scan session

    roiDir = fullfile(projectDir, '/derivatives/ROIs', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    topupDir = fullfile(projectDir, 'derivatives/topup', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    eddyDir = fullfile(projectDir, 'derivatives/eddy', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    fsDir = fullfile(projectDir, 'derivatives/freesurfer', ['sub-' sub{sub_i}]);
    anatPrepDir = fullfile(projectDir, 'derivatives/anat_prep', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);        
    anatDir = fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'anat');

    eddyFile = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data'];
    eddyB0File = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data_b0'];
    eddyB0FileBrain = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data_b0_brain'];
    eddyB0FileBrainOpt8 = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data_b0_brain_Opt8'];
    
    t1File = fullfile(anatDir, 't1_acpc.nii.gz');
    t1FileCrop = fullfile(anatPrepDir, 't1_crop.nii.gz');
    t1FileCropBrain = fullfile(anatPrepDir, 't1_crop_brain.nii.gz');
    t1FileCropBrainDiffSpace = fullfile(anatPrepDir, 't1_crop_brain_diffspace.nii.gz');
    t12dwi = fullfile(anatPrepDir, 't1_2_dwi_xfm.mat');
    
    
    
%     system(['robustfov -i ' t1File ' -r ' t1FileCrop])
    system(['bet ' t1File ' ' t1FileCropBrain ' -m -f 0.1'])
    system(['fslroi ' fullfile(eddyDir, eddyFile) ' ' fullfile(eddyDir, eddyB0File) ' 0 1'])
    system(['bet ' fullfile(eddyDir, eddyB0File) ' ' fullfile(eddyDir, eddyB0FileBrain) ' -m -f 0.25'])

    system(['flirt -in ' t1FileCropBrain ' -ref ' fullfile(eddyDir, eddyB0FileBrain) ...
    ' -out ' t1FileCropBrainDiffSpace ...
    ' -omat ' t12dwi ' -dof 6']);





    % LGN
%     % Convert segmented atlas to volume
%     system(['mri_label2vol --seg ' fsDir '/mri/ThalamicNuclei.v12.T1.mgz --temp ' fsDir '/mri/orig.mgz --o ' fsDir '/mri/ThalSegNativeVol.nii.gz --regheader ' fsDir '/mri/ThalamicNuclei.v12.T1.mgz'])
%     % Extract left and right LGN from volume
%     system(['fslmaths ' fsDir '/mri/ThalSegNativeVol.nii.gz -thr 8109 -uthr 8109 ' roiDir '/fs_lh_lgn.nii.gz']);
%     system(['fslmaths ' fsDir '/mri/ThalSegNativeVol.nii.gz -thr 8209 -uthr 8209 ' roiDir '/fs_rh_lgn.nii.gz']);

    % Process outputs (binarize, reslice, flip)
    for jj = 1:length(hemi)

        % Reslice to the T1
%         system(['mri_convert -rt nearest -rl ' t1FileCropBrain ' ' ...
%             fullfile(roiDir, ['fs_' hemi{jj} '_lgn.nii.gz ']) ....
%             fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice.nii.gz'])])

        % Binarize ROI
%         system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice.nii.gz']) ' -bin ' ...
%             fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice.nii.gz'])]);

        % Coregister the LGN to diffusion space
        system(['flirt -in ' fullfile(roiDir, ['osama/T1w_fs_' hemi{jj} '_lgn.nii.gz']) ...
            ' -ref ' fullfile(eddyDir, eddyB0FileBrain) ...
            ' -out ' fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']) ...
            ' -init ' t12dwi ' -applyxfm']);

        % Binarize the ROI
        system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']) ' -bin ' ...
            fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz'])]);

    end

    %% V1

    for jj = 1:length(hemi)

%         % mri_label2vol for xh.V1.label file
%         system(['mri_label2vol --label ' fsDir '/label/' hemi{jj} '.V1_exvivo.label --temp ' fsDir '/mri/orig.mgz --o ' fsDir '/label/' hemi{jj} '_V1.nii.gz --identity --fillthresh .3 --proj frac 0 1 .1 --hemi ' hemi{jj} ' --subject ' fsDir])
% 
%         % Smooth nifti V1 ROI using -fmedian flag
%         system(['fslmaths ' fsDir '/label/' hemi{jj} '_V1.nii.gz -fmedian ' fsDir '/label/' hemi{jj} '_V1.nii.gz'])
% 
%         % Reslice to the T1
%         system(['mri_convert -rt nearest -rl ' t1FileCropBrain ' ' ...
%             fullfile(fsDir, ['label/' hemi{jj} '_V1.nii.gz ']) ....
%             fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice.nii.gz'])])
% 
%         % Binarize smoothed output
%         system(['fslmaths ' fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice.nii.gz']) ' -bin ' ...
%             fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice.nii.gz'])])

        % Coregister the V1 to diffusion space
        system(['flirt -in ' fullfile(roiDir, ['osama/T1w_fs_' hemi{jj} '_V1.nii.gz']) ...
            ' -ref ' fullfile(eddyDir, eddyB0FileBrain) ...
            ' -out ' fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz']) ...
            ' -init ' t12dwi ' -applyxfm']);

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
    system(['mri_convert -rt nearest -rl ' t1FileCropBrain ' ' ...
        fullfile(roiDir, 'fs_oc.nii.gz ') ....
        fullfile(roiDir, 'fs_oc_T1Reslice.nii.gz')]);


    % Binarize
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice.nii.gz') ' -bin ' ...
        fullfile(roiDir, 'fs_oc_T1Reslice.nii.gz')]);

    % Coregister the OC to diffusion space
    system(['flirt -in ' fullfile(roiDir, 'fs_oc_T1Reslice.nii.gz') ...
        ' -ref ' fullfile(eddyDir, eddyB0FileBrain) ...
        ' -out ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace.nii.gz') ...
        ' -init ' t12dwi ' -applyxfm']);

    % Expand the Optic Chiasm:
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace.nii.gz') ' -dilM ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_dilM.nii.gz')]);
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_dilM.nii.gz') ' -dilM ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_2dilM.nii.gz')])
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_2dilM.nii.gz') ' -dilM ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz')])
    system(['fslmaths ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz') ' -bin ' fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz')]) % binarize the mask

    
    % Whole brain tractography
    ttFile = fullfile(anatPrepDir, ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_5tt.nii.gz']);
    fibDir = fullfile(projectDir, '/derivatives/mrtrix3', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);

    act = ttFile; % anatomically-constrain tractography
    wmfod = fullfile(fibDir, 'wmfod.mif'); % extracted from eddy_corrected_data.nii.gz aligned to T1-acpc space
    numFibers_WB = 5000000;
    outFile = fullfile(fibDir, ['dti' ses{ses_i} '_wholeBrain_ACT_' num2str(numFibers_WB/1000000) 'M.tck']);       
    
    % Run tractography
    system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' act  ' -select ' num2str(numFibers_WB) ' -seeds 0']);

    
    
    % Optic Radiations
    numFibers_OR = [1e4; 1e4];
    
    for jj = 1:length(hemi)

        maxLength = 150;
        outFile = fullfile(fibDir, ['dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR(1)/1000) 'k.tck']);
        roi1 = fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']); % FreeSurfer LGN
        roi2 = fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz']); % FreeSurfer V1
        
        % Run tractography
        system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' roi1 ' -seed_image ' roi2 ' -include ' ...
            roi1 ' -include ' roi2 ' -stop ' '-select ' num2str(numFibers_OR(1)) ' -seeds 0 ' '-maxlength ' num2str(maxLength)])
        
        % Convert fibers to DSIStudio format
        outFileImage = fullfile(fibDir, ['dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR(1)/1000) 'k_DSIStudio.tck']);
        % Convert to DSIStudio format
        system(['tckconvert -scanner2image ' eddy ' ' outFile ' ' outFileImage])

    end

    
    
    % Optic Tract - less number of fibers for a matter of time
    numFibers_OT = [1e4; 1e4];

    for jj = 1:length(hemi)
        
        maxLength = 50; % to avoid having long fibers
        outFile = fullfile(fibDir, ['dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT(1)/1000) 'k.tck']);
        roi1 = fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']); % FreeSurfer LGN
        roi2 = fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz'); % Freesurfer Optic Chiasm expanded -> 3dil
       
        % Run tractography
        system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' roi1 ' -seed_image ' roi2 ' -include ' roi1 ' -include ' roi2 ' -stop ' '-select ' num2str(numFibers_OT(1)) ' -seeds 0 ' '-maxlength ' num2str(maxLength)])
        
        % Convert fibers to DSIStudio format
        outFileImage = fullfile(fibDir, ['dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT(1)/1000) 'k_DSIStudio.tck']);
        % Convert to DSIStudio format
        system(['tckconvert -scanner2image ' eddy ' ' outFile ' ' outFileImage])
    
    end

    
end

    
            