% dMRI processing pipeline - step 2
%
% As we are running fmriprep, we are not going to run the t1_preprocessing
% as it is performed by fmriprep

% Open matlab from the terminal with the following line (adapted to the version of matlab you have):
% /Applications/MATLAB_R2020a.app/bin/matlab

clear all; clc
user = 'omnia'; % name of the user
% choose 'server' if you are working on the server
% add your name if you are working on your local PC. In this case you
% should add your files locations in the following 'switch user'

% Set the path
switch user
    case {'caterina'}
        projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output    
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
        
   case {'omnia'}
        projectDir = '/Users/omniahassanin/Documents/GitHub/tractography/code'; % location output
end

sub = {'201'}; % ID of the subject
ses = {'01'}; % ID of the session
hemi = {'lh','rh'};

% Add paths
addpath(genpath(fullfile(projectDir, 'code/'))); % code folder location

% Freesurfer - remember to update the location of freesurfer according to
% the location on your PC
setenv('FREESURFER_HOME', '/Applications/freesurfer/7.2.0');
freesurferdir = getenv('FREESURFER_HOME');
freesurferpath = sprintf('%s/matlab',freesurferdir);
path(path, freesurferpath);
fsDir = [projectDir '/derivatives/freesurfer']; % define the location of the output of freesurfer
setenv ('SUBJECTS_DIR', fsDir); 

PATH = getenv('PATH'); setenv('PATH', ['/opt/anaconda3/bin:/usr/local/bin:/Applications/freesurfer/7.2.0/bin:' PATH]); % 
% PATH = getenv('PATH'); setenv('PATH', ['/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/7.2.0/bin:' PATH]);



%% Subcortical segmentation

% Segment thalamic nuclei (requires that subject has already been processed with recon-all);
% fs_install_mcr R2014b
% download the runtime for FS version 7: fs_install_mcr R2014b
% If the fs_install_mcr script is not available in your freesurfer distribution, it can be downloaded by running the following command:
% cd $FREESURFER_HOME/bin && curl https://raw.githubusercontent.com/freesurfer/freesurfer/dev/scripts/fs_install_mcr -o fs_install_mcr && chmod +x fs_install_mcrsystem(['segmentThalamicNuclei.sh ' sub{ii} ' ' fsDir]);
% Run without any problem on Mac Catalina (problems with BigSur)

for sub_i = 1:length(sub) % for each subject

    system(['segmentThalamicNuclei.sh sub-' sub{sub_i} ' ' fsDir]);
    
end
