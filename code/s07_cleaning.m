% Cleaning Probabilistic tracts (mrtirx3)
clear all;
user = 'caterina'; % name of the user

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
roiDir = [projectDir '/derivatives/ROIs/'];
fibDir = [projectDir '/derivatives/mrtrix3/'];

% Add paths
addpath(genpath('~/Data/GitHub/Prakash/Toolbox/vistasoft')); % vistasoft location
addpath(genpath('~/Data/GitHub/Prakash/Toolbox/AFQ')); % afq location
addpath(genpath(fullfile(projectDir, 'code/'))); % afq location

% FSL
setenv( 'FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); %added to tell where to save the fsl outputs
fsldir = getenv('FSLDIR');
fsldirmpath = sprintf('%s/etc/matlab',fsldir);
path(path, fsldirmpath);


%% Cleaning the Tracts with tckedit -> exclude the fibers reaching the talamus and not LGN

sub_i = 1;

for ses_i = 1:numel(dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'))) % for each scan session
    
    for jj = 1:length(hemi)
       
       % Run tckedit, excluding fibers terminating in thalamus outside of LGNs
       % Optic Radiations:
       numFibers = (1e4);
       system(['tckedit -exclude ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_sub_LGNs_diffspace.nii.gz -include ' ...
           roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz -include ' ...
           roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz -ends_only ' ...
           fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers(1)/1000) 'k.tck ' ...
           fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers(1)/1000) 'k_thalFiltered.tck'])

       system(['tckedit -exclude ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_sub_LGNs_diffspace.nii.gz -include ' ...
           roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz -include ' ...
           roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz ' ...
           fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers(1)/1000) 'k_thalFiltered.tck ' ...
           fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers(1)/1000) 'k_2thalFiltered.tck'])
       

       % Optic Tract:
       numFibers = (1e2);
       
       system(['tckedit -exclude ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_sub_LGNs_diffspace.nii.gz -include ' ...
           roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz -include ' ...
           roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice_diffspace_3DilM.nii.gz -ends_only ' ...
           fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers(1)/1000) 'k.tck ' ...
           fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers(1)/1000) 'k_thalFiltered.tck'])

       system(['tckedit -exclude ' roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_thalamus_sub_LGNs_diffspace.nii.gz -include ' ...
           roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz -include ' ...
           roiDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/fs_oc_T1Reslice_diffspace_3DilM.nii.gz ' ...
           fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers(1)/1000) 'k_thalFiltered.tck ' ...
           fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers(1)/1000) 'k_2thalFiltered.tck'])

       
    end


end




