% Cleaning Probabilistic tracts (mrtirx3)
clear all;

% Setup the environment
% FSL - remember to update the location of FSL according to the location on your PC
setenv('FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); % added to tell where to save the fsl outputs
setenv('FREESURFER_HOME', '/Applications/freesurfer'); 
% setenv('FREESURFER_HOME', '/Applications/freesurfer/7.2.0');
PATH = getenv('PATH'); setenv('PATH', ['/opt/anaconda3/bin:/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/bin:' PATH]);
%PATH = getenv('PATH'); setenv('PATH', ['/opt/anaconda3/bin:/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/7.2.0/bin:' PATH]);

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


%% Cleaning the Tracts with tckedit -> exclude the fibers reaching the talamus and not LGN

sub_i = 1:length(sub); % loop over subjects (eventually)

sub_ses = dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'));

for ses_i = 1:numel(sub_ses) % for each scan session
    
    roiDir = fullfile(projectDir, '/derivatives/ROIs', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    fibDir = fullfile(projectDir, '/derivatives/mrtrix3', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);

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
       numFibers_OT = (1e2);
       
       system(['tckedit -exclude ' roi3 ' -include ' roi1 ' -include ' roi2 ' -ends_only ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k.tck ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_thalFiltered.tck'])

       system(['tckedit -exclude ' roi3 ' -include ' roi1 ' -include ' roi2 ' ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_thalFiltered.tck ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered.tck'])

       
    end


end




