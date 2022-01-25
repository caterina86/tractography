
% Probabilistic tractography (mrtirx3)
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
fmriprep = 1; % 1 -> we performed fmriprep; 0 -> we did not perform fmriprep

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
        projectDir = '/Users/hannah/Documents/MRI/Sample_dMRI'; % location output
end
addpath(genpath(fullfile(projectDir, 'code'))); % add user code to path

sub = {'0228'}; % initials of the subject
ses = {'01'}; % ID of the session
hemi = {'lh', 'rh'};


%% Probabilistic Tractography

sub_i = 1:length(sub); % loop over subjects (eventually)

sub_ses = dir(fullfile(projectDir, 'rawdata',  ['sub-' sub{sub_i}], 'ses-*'));

for ses_i = 1:numel(sub_ses) % for each scan session

    fibDir = fullfile(projectDir, '/derivatives/mrtrix3', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    fmriprepDir = fullfile(projectDir, 'derivatives/fmriprep', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    eddyDir = fullfile(projectDir, 'derivatives/eddy', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    topupDir = fullfile(projectDir, 'derivatives/topup', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    roiDir = fullfile(projectDir, '/derivatives/ROIs', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    anatPrepDir = fullfile(projectDir, 'derivatives/anat_prep', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    fsDir = fullfile(projectDir, 'derivatives/freesurfer', ['sub-' sub{sub_i}]);
    anatDir = fullfile(projectDir, 'rawdata', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'anat');

    eddyFile = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data.nii.gz'];
    eddyB0FileBrain = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data_b0_brain'];
    eddyB0FileBrainOpt8 = [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data_b0_brain_Opt8'];

    if fmriprep == 1
        t1FileCropBrain = fullfile(fmriprepDir,'anat/',['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_desc-preproc_T1w_crop_brain.nii.gz']);
        t1FileCropBrainDiffSpace = fullfile(fmriprepDir, 'anat/', ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_desc-preproc_T1w_crop_brain_diffspace.nii.gz']);
        ttFile = fullfile(fmriprepDir, 'anat/', ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_5tt.nii.gz']);
        t12dwi = fullfile(fmriprepDir, 'anat/t1_2_dwi_xfm.mat');
    else
        t1FileCropBrainDiffSpace = fullfile(anatPrepDir, 't1_crop_brain_diffspace.nii.gz');
        ttFile = fullfile(anatPrepDir, ['sub-' sub{sub_i} '_' 'ses-' ses{ses_i} '_5tt.nii.gz']);
        t1FileCropBrain = fullfile(anatPrepDir, 't1_crop_brain.nii.gz');
        t12dwi = fullfile(anatPrepDir, 't1_2_dwi_xfm.mat');

    end


    if ~exist(fibDir) % Check if fiber directory exists
        mkdir(fibDir) % If not, create it
    else
    end

    % Generate 5tt mask (aligned with T1 volume) -> ACT
    system(['5ttgen fsl ' t1FileCropBrainDiffSpace ' ' ttFile ' -premasked']);


    %% Whole brain tractography
    % Define paths (convenience for commands below)
    eddy = fullfile(eddyDir, eddyFile);
    bvec = fullfile(eddyDir, [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data.eddy_rotated_bvecs']);
    bval = fullfile(topupDir, 'bval_combined.txt');
    mask = fullfile(eddyDir, [eddyB0FileBrain '_mask.nii.gz ']); % brain mask

    % Generate normal orientation response function estimates
    system(['dwi2response dhollander ' eddy ' -fslgrad ' bvec ' ' bval ' ' ...
        fibDir '/responseEstimate_sfwm.txt ' ...
        fibDir '/responseEstimate_gm.txt ' ...
        fibDir '/responseEstimate_csf.txt -mask ' mask])

    % Generate normal fiber orientation distribution estimates (FOD)
    system(['dwi2fod msmt_csd -mask ' mask ' ' eddy ' -fslgrad ' bvec ' ' bval ' ' ...
        fibDir '/responseEstimate_sfwm.txt ' fibDir '/wmfod.mif ' ...
        fibDir '/responseEstimate_gm.txt ' fibDir '/gmfod.mif ' ...
        fibDir  '/responseEstimate_csf.txt ' fibDir '/csffod.mif '])


    % Whole brain tractography (mrtrix3)
    act = ttFile; % anatomically-constrain tractography
    wmfod = fullfile(fibDir, 'wmfod.mif'); % extracted from eddy_corrected_data.nii.gz aligned to T1-acpc space
    numFibers_WB = 5000000;
    outFile = fullfile(fibDir, ['dti' ses{ses_i} '_wholeBrain_ACT_' num2str(numFibers_WB/1000000) 'M.tck']);

    % Run tractography
    system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' act  ' -select ' num2str(numFibers_WB) ' -seeds 0']);

end


%% Optic Radiations Tractography
for ses_i = 1:numel(sub_ses) % for each scan session

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
    numFibers_OT = [1e2; 1e2];

    for jj = 1:length(hemi)

        maxLength = 150; % to avoid having long fibers
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



    %% Left and Right Optic Nerve
    % 1. load the t1 image of the subject in fsleyes
    % 2. extract the voxel coordinates from the start and end point of the
    % Optic Nerve
    % i.e.: start point -> 72 87 181 / end point -> 87 165 181

    % Create a point for the beginning and end of the optic nerve, in the T1 native space
    system(['fslmaths ' fullfile(anatDir, 't1.nii.gz' ) ' -mul 0 -add 1 -roi 116 1 195 1 181 1 0 1 ' ...
        fullfile(roiDir, 'rhEyePointUp')])
    system(['fslmaths ' fullfile(anatDir, 't1.nii.gz' ) ' -mul 0 -add 1 -roi 102 1 166 1 181 1 0 1 ' ...
        fullfile(roiDir, 'rhEyePointDown')])

    system(['fslmaths ' fullfile(anatDir, 't1.nii.gz' ) ' -mul 0 -add 1 -roi 72 1 187 1 181 1 0 1 ' ...
        fullfile(roiDir, 'lhEyePointUp')])
    system(['fslmaths ' fullfile(anatDir, 't1.nii.gz' ) ' -mul 0 -add 1 -roi 87 1 165 1 181 1 0 1 ' ...
        fullfile(roiDir, 'lhEyePointDown')])

    for jj = 1:length(hemi)

        % From point to sphere
        system(['fslmaths ' fullfile(roiDir, [hemi{jj} 'EyePointUp']) ' -kernel sphere 5 -fmean ' ...
            fullfile(roiDir, [hemi{jj} 'EyeSphereUp5'])])
        system(['fslmaths ' fullfile(roiDir, [hemi{jj} 'EyePointDown']) ' -kernel sphere 5 -fmean ' ...
            fullfile(roiDir, [hemi{jj} 'EyeSphereDown5'])])

        % Remove the noise and binarize the mask
        system(['fslmaths ' fullfile(roiDir, [hemi{jj} 'EyeSphereUp5']) ' -thr 1e-8 -bin ' ...
            fullfile(roiDir, [hemi{jj} 'EyeSphere5Up_bin'])])
        system(['fslmaths ' fullfile(roiDir, [hemi{jj} 'EyeSphereDown5']) ' -thr 1e-8 -bin ' ...
            fullfile(roiDir, [hemi{jj} 'EyeSphere5Down_bin'])])

        % Reslice to the T1
        system(['mri_convert -rt nearest -rl ' t1FileCropBrain ' ' ...
            fullfile(roiDir, [hemi{jj} 'EyeSphere5Up_bin.nii.gz ']) ....
            fullfile(roiDir, [hemi{jj} 'EyeSphere5Up_bin_T1Reslice.nii.gz'])]);
        system(['mri_convert -rt nearest -rl ' t1FileCropBrain ' ' ...
            fullfile(roiDir, [hemi{jj} 'EyeSphere5Down_bin.nii.gz ']) ....
            fullfile(roiDir, [hemi{jj} 'EyeSphere5Down_bin_T1Reslice.nii.gz'])]);

        % Coregister the OC to diffusion space
        system(['flirt -in ' fullfile(roiDir, [hemi{jj} 'EyeSphere5Up_bin_T1Reslice']) ...
            ' -ref ' fullfile(eddyDir, eddyB0FileBrainOpt8) ...
            ' -out ' fullfile(roiDir, [hemi{jj} 'EyeSphere5Up_bin_T1Reslice_diffspace']) ...
            ' -init ' t12dwi ' -applyxfm']);
        system(['flirt -in ' fullfile(roiDir, [hemi{jj} 'EyeSphere5Down_bin_T1Reslice']) ...
            ' -ref ' fullfile(eddyDir, eddyB0FileBrainOpt8) ...
            ' -out ' fullfile(roiDir, [hemi{jj} 'EyeSphere5Down_bin_T1Reslice_diffspace']) ...
            ' -init ' t12dwi ' -applyxfm']);

        % Binarize
        system(['fslmaths ' fullfile(roiDir, [hemi{jj} 'EyeSphere5Up_bin_T1Reslice_diffspace']) ' -bin ' ...
            fullfile(roiDir, [hemi{jj} 'EyeSphere5Up_bin_T1Reslice_diffspace'])]); % save in ROI folder
        system(['fslmaths ' fullfile(roiDir, [hemi{jj} 'EyeSphere5Down_bin_T1Reslice_diffspace']) ' -bin ' ...
            fullfile(roiDir, [hemi{jj} 'EyeSphere5Down_bin_T1Reslice_diffspace'])]); % save in ROI folder


    end

    % Which mask for the dwi2fod?
    % white matter mask extacted from Freesurfer
    system(['mri_convert ' fsDir '/mri/wm.seg.mgz ' fsDir '/mri/wm.seg.nii.gz'])
    system(['flirt -in ' fsDir '/mri/wm.seg.nii.gz -ref ' fullfile(eddyDir, eddyB0FileBrain) ...
        ' -out ' fsDir '/mri/wm_seg_diffspace.nii.gz -dof 6']);
    system(['fslmaths ' fsDir '/mri/wm_seg_diffspace.nii.gz -bin ' fsDir '/mri/wm_seg_diffspace.nii.gz'])

    % Define paths (convenience for commands below)
    eddy = fullfile(eddyDir, eddyFile);
    bvec = fullfile(eddyDir, [['sub-' sub{sub_i}], ['_ses-' ses{ses_i}], '_dti' ses{ses_i} '_eddy_corrected_data.eddy_rotated_bvecs']);
    bval = fullfile(topupDir, 'bval_combined.txt');
    mask = fullfile(fsDir, 'mri/wm_seg_diffspace.nii.gz'); % mask of white matter

    % Generate normal fiber orientation distribution estimates (FOD) -
    % white matter mask
    system(['dwi2fod msmt_csd -mask ' mask ' ' eddy ' -fslgrad ' bvec ' ' bval ' ' ...
        fibDir '/responseEstimate_sfwm.txt ' fibDir '/wmfod_wmmask.mif ' ...
        fibDir '/responseEstimate_gm.txt ' fibDir '/gmfod_wmmask.mif ' ...
        fibDir  '/responseEstimate_csf.txt ' fibDir '/csffod_wmmask.mif '])

    % Generate normal fiber orientation distribution estimates (FOD) - no
    % mask
    system(['dwi2fod msmt_csd ' eddy ' -fslgrad ' bvec ' ' bval ' ' ...
        fibDir '/responseEstimate_sfwm.txt ' fibDir '/wmfod_nomask.mif ' ...
        fibDir '/responseEstimate_gm.txt ' fibDir '/gmfod_nomask.mif ' ...
        fibDir  '/responseEstimate_csf.txt ' fibDir '/csffod_nomask.mif '])

    % Optic Nerve - less number of fibers for a matter of time
    numFibers_ON = [1e2; 1e2];

    wmfod = fullfile(fibDir, 'wmfod_nomask.mif'); % extracted from eddy_corrected_data.nii.gz aligned to T1-acpc space

    for jj = 1:length(hemi)

        maxLength = 150; % to avoid having long fibers
        outFile = fullfile(fibDir, ['dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_ON_' num2str(numFibers_ON(1)/1000) 'k.tck']);
        roi1 = fullfile(roiDir, [hemi{jj} 'EyeSphere5Up_bin_T1Reslice_diffspace.nii.gz']); % Eye
        roi2 = fullfile(roiDir, [hemi{jj} 'EyeSphere5Down_bin_T1Reslice_diffspace.nii.gz']); % Freesurfer Optic Chiasm expanded -> 3dil

        % Run tractography
        system(['tckgen '  wmfod ' '  outFile ' -act ' act ' -seed_image ' roi1 ' -seed_image ' roi2 ' -include ' roi1 ' -include ' roi2 ' -stop ' '-select ' num2str(numFibers_ON(1)) ' -seeds 0 ' '-maxlength ' num2str(maxLength)])

        % Convert fibers to DSIStudio format
        outFileImage = fullfile(fibDir, ['dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_ON_' num2str(numFibers_ON(1)/1000) 'k_DSIStudio.tck']);
        % Convert to DSIStudio format
        system(['tckconvert -scanner2image ' eddy ' ' outFile ' ' outFileImage])

    end
