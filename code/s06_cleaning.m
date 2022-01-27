% Cleaning Probabilistic tracts (mrtirx3)
clearvars;

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
user = 'bas'; % name of the user
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
        projectDir = '/Users/rokers/Dropbox/MRI/Sample_dMRI'; % location output
    case {'Dalia'}
        projectDir = '~/Desktop/Sample_dMRI'; % location output
    case {'hannah'}
        projectDir = '/Users/hannah/Documents/MRI/Sample_dMRI'; % location output
end
addpath(genpath(fullfile(projectDir, 'code'))); % add user code to path
addpath(genpath('/Volumes/Vision/Matlab/Toolbox/vistasoft')); % add vistasoft toolbox -> for AFQ cleaning

sub = {'0228'}; % initials of the subject
ses = {'01'}; % ID of the session
hemi = {'lh', 'rh'};


%% Cleaning the Tracts with tckedit -> exclude the fibers reaching the talamus and not LGN

sub_i = 1:length(sub); % loop over subjects (eventually)

sub_ses = dir(fullfile(projectDir, 'rawdata', ['sub-' sub{sub_i}], 'ses-*'));

for ses_i = 1:numel(sub_ses) % for each scan session

    roiDir = fullfile(projectDir, '/derivatives/ROIs', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);
    fibDir = fullfile(projectDir, '/derivatives/mrtrix3', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);

    % parametes for the AFQ cleaning
    maxDist = 4; maxLen = 4; numNodes = 25; M = 'mean'; count = 1; show = 1;
    
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

       
        tckedit_out_file = [fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered.tck'];
        afq_cleaned_out_file = [fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.tck'];
        fgdump = read_mrtrix_tracks(tckedit_out_file);  
        fg = fgRead(tckedit_out_file);
        [~, keep]=AFQ_removeFiberOutliers(fg,maxDist,maxLen,numNodes,M,count,show);
        ind = find(keep==0); %find removed fibers
        fgdump.data(ind)=[]; % delete removed fibers
        numel(ind); % removed fibers
        fgdump.total_count=numel(fgdump.data);
        fgdump.count=numel(fgdump.data);
        write_mrtrix_tracks(fgdump, afq_cleaned_out_file); % save the output as .tck 


        % Optic Tract:
        numFibers_OT = (1e4); % indicate the correct number of fibers created
        roi4 = fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_3dilM.nii.gz');

        system(['tckedit -exclude ' roi3 ' -include ' roi1 ' -include ' roi4 ' -ends_only ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k.tck -maxlength 50 '...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_thalFiltered.tck'])

        system(['tckedit -exclude ' roi3 ' -include ' roi1 ' -include ' roi4 ' ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_thalFiltered.tck ' ...
           fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered.tck'])


        tckedit_out_file = [fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered.tck'];
        afq_cleaned_out_file = [fibDir '/dti' ses{ses_i} '_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.tck'];
        fgdump = read_mrtrix_tracks(tckedit_out_file);  
        fg = fgRead(tckedit_out_file);
        [~, keep]=AFQ_removeFiberOutliers(fg,maxDist,maxLen,numNodes,M,count,show);
        ind = find(keep==0); %find removed fibers
        fgdump.data(ind)=[]; % delete removed fibers
        numel(ind); % removed fibers
        fgdump.total_count=numel(fgdump.data);
        fgdump.count=numel(fgdump.data);
        write_mrtrix_tracks(fgdump, afq_cleaned_out_file); 

    end


end

          