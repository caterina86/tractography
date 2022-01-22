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

sub = {'ccad0204'}; % initials of the subject
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
    dwiDir = fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'dwi');

    eddyFile = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data'];
    eddyB0File = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data_b0'];
    eddyB0FileBrain = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data_b0_brain'];
    eddyB0FileBrainOpt8 = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data_b0_brain_Opt8'];
    
    t1File = fullfile(anatDir, 't1_acpc.nii.gz');
    t1FileCrop = fullfile(anatPrepDir, 't1_crop.nii.gz');
    t1FileCropBrain = fullfile(anatPrepDir, 't1_crop_brain.nii.gz');
    t1FileCropBrainDiffSpace = fullfile(anatPrepDir, 't1_crop_brain_diffspace.nii.gz');
    t12dwi = fullfile(anatPrepDir, 't1_2_dwi_xfm.mat');
    
    
    % extract b0
    system(['fslroi ' fullfile(eddyDir, eddyFile) ' ' fullfile(eddyDir, eddyB0File) ' 0 1'])
    % bet of the eddy_b0
    system(['bet ' fullfile(eddyDir, eddyB0File) ' ' fullfile(eddyDir, eddyB0FileBrain) ' -m -f 0.25'])
    % bet of the T1
    system(['bet ' t1File ' ' t1FileCropBrain ' -m -f 0.1'])

    % coregistration t1 -> diffusion
    system(['flirt -in ' t1FileCropBrain ' -ref ' fullfile(eddyDir, eddyB0FileBrain) ...
    ' -out ' t1FileCropBrainDiffSpace ...
    ' -omat ' t12dwi ' -dof 6']);


    %% Regions of interest

    % LGN
    for jj = 1:length(hemi)

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

          
    %% Tractography with wmfod.mif already created with HCP pipeline
    
    % Whole brain tractography
    ttFile = fullfile(anatPrepDir, ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_5tt.nii.gz']);
    fibDir = fullfile(projectDir, '/derivatives/mrtrix3', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);

    act = ttFile; % anatomically-constrain tractography
    wmfod = fullfile(fibDir, 'wmfod.mif'); % extracted from eddy_corrected_data.nii.gz aligned to T1-acpc space
    numFibers_WB = 5000000;
    outFile = fullfile(fibDir, ['dti' ses{ses_i} '_wholeBrain_ACT_' num2str(numFibers_WB/1000000) 'M.tck']);       
    
    % Run whole brain tractography
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

    end

    
    % Optic Tract - less number of fibers for a matter of time
    numFibers_OT = [1e4; 1e4];

    for jj = 1:length(hemi)
        
        maxLength = 150; % to avoid having long fibers
        outFile = fullfile(fibDir, ['dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT(1)/1000) 'k.tck']);
        roi1 = fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']); % FreeSurfer LGN
        roi2 = fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz'); % Freesurfer Optic Chiasm expanded -> 3dil
       
        % Run tractography
        system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' roi1 ' -seed_image ' roi2 ' -include ' roi1 ' -include ' roi2 ' -stop ' '-select ' num2str(numFibers_OT(1)) ' -seeds 0 ' '-maxlength ' num2str(maxLength)])
        
        % Convert fibers to DSIStudio format
        outFileImage = fullfile(fibDir, ['dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT(1)/1000) 'k_DSIStudio.tck']);
    
    end

    % Cleaning the fibers
    for jj = 1:length(hemi)
       
       % Run tckedit, excluding fibers terminating in thalamus outside of LGNs
       % Optic Radiations:
       numFibers_OR = (1e4);
       roi1 = fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']);
       roi2 = fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz']);
       roi3 = fullfile(roiDir, 'fs_thalamus_sub_LGNs_diffspace.nii.gz');
       
       system(['tckedit -exclude ' roi3 ' -include ' roi1 ' -include ' roi2 ' -ends_only ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k.tck ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_thalFiltered.tck'])

       system(['tckedit -exclude ' roi3 ' -include ' roi1 ' -include ' roi2 ' ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_thalFiltered.tck ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered.tck'])
       

       % Optic Tract:
       numFibers_OT = (1e4);
       roi4 = fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz');
       
       system(['tckedit -exclude ' roi3 ' -include ' roi1 ' -include ' roi4 ' -ends_only ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k.tck ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_thalFiltered.tck'])

       system(['tckedit -exclude ' roi3 ' -include ' roi1 ' -include ' roi4 ' ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_thalFiltered.tck ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered.tck'])

       
    end

    
    
end

    

            