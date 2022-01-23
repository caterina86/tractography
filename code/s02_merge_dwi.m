% dMRI processing pipeline - step 2
% this step needs to be run only when we have more than 1 file with the
% same phase encoding directions but a different number of diffusion
% directions - NYUAD sequence

clearvars;

% FSL
setenv('FSLDIR', '/usr/local/fsl' ); % set according to your system's freesurfer location
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); % added to tell how to save fsl outputs
PATH = getenv('PATH'); setenv('PATH', ['/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/bin:' PATH]);

% Set paths
user = 'caterina'; % name of the user
% choose 'server' if you are working on the server
% add your name if you are working on your local PC. In this case you
% should add your files locations in the following 'switch user'

switch user
    case {'caterina'}
        projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output
    case {'bas'}
        projectDir = '/Users/rokers/Dropbox/MRI/Sample_dMRI/'; % location output
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
end

% Set subject/scan info
sub = {'0228'}; % subject ID
ses = {'01'}; % subject session(s)


%% Merge the 97 and 98 directions with the same phase encoding direction in one single diffusion image

sub_i = 1:length(sub); % loop over subjects (eventually)
num_dir = {'97' '98'}; % number of diffusion gradient directions (should get from bval/bvecs file)

sub_ses = dir(fullfile(projectDir, 'rawdata', ['sub-' sub{sub_i}], 'ses-*'));

for ses_i = 1:numel(sub_ses) % for each scan session

    % folders:
    dwiDir = fullfile(projectDir, 'rawdata', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'dwi');

    % partial filename
    subses = ['sub-' sub{sub_i} '_ses-' ses{ses_i}];

    % files:
    apFile =  [subses '_AP_dwi'];
    paFile =  [subses '_PA_dwi'];
    rawapFile97 = [subses '_dir-APacq' num2str(num_dir{1}) 'vols_dwi'];
    rawapFile98 = [subses '_dir-APacq' num2str(num_dir{2}) 'vols_dwi'];
    rawpaFile97 = [subses '_dir-PAacq' num2str(num_dir{1}) 'vols_dwi'];
    rawpaFile98 = [subses '_dir-PAacq' num2str(num_dir{2}) 'vols_dwi'];

    % nifti image
    if exist(fullfile(dwiDir, [apFile '.nii.gz']), 'file') % if the file already exist
        system(['rm -r ' fullfile(dwiDir, [apFile '.nii.gz'])]); % remove it
    else
    end
    system(['fslmerge -t ' fullfile(dwiDir, [apFile '.nii.gz ']) fullfile(dwiDir, [rawapFile97 '.nii.gz ']) ...
        fullfile(dwiDir, [rawapFile98 '.nii.gz '])]);


    if exist(fullfile(dwiDir, [paFile '.nii.gz']), 'file') % if the file already exists
        system(['rm -r ' fullfile(dwiDir, [paFile '.nii.gz'])]); % remove it 
    else % if the file does not exist
    end
    system(['fslmerge -t ' fullfile(dwiDir, [paFile '.nii.gz ']) fullfile(dwiDir, [rawpaFile97 '.nii.gz ']) ...
        fullfile(dwiDir, [rawpaFile98 '.nii.gz '])]);


    % bvec
    if exist(fullfile(dwiDir, [apFile '.bvec']), 'file') % if it exists
        system(['rm -r ' fullfile(dwiDir, [apFile '.bvec'])]); % remove it
    else
    end
    system(['paste ' fullfile(dwiDir, [rawapFile97 '.bvec ']) fullfile(dwiDir, [rawapFile98 '.bvec ']) ...
        ' >> ' fullfile(dwiDir, [apFile '.bvec'])]);

    if exist(fullfile(dwiDir, [paFile '.bvec']), 'file') % if it exists
        system(['rm -r ' fullfile(dwiDir, [paFile '.bvec '])]); % remove it
    else
    end
    system(['paste ' fullfile(dwiDir, [rawpaFile97 '.bvec ']) fullfile(dwiDir, [rawpaFile98 '.bvec ']) ...
         ' >> ' fullfile(dwiDir, [paFile '.bvec'])]);


    % bval
    if exist(fullfile(dwiDir, [apFile '.bval']), 'file')  % if it exists
      system(['rm -r ' fullfile(dwiDir, [apFile '.bval '])]); % remove it
    else
    end
    system(['paste ' fullfile(dwiDir, [rawapFile97 '.bval ']) fullfile(dwiDir, [rawapFile98 '.bval ']) ...
        ' >> ' fullfile(dwiDir, [apFile '.bval '])]);

    if exist(fullfile(dwiDir, [paFile '.bval']), 'file')  % if it exists
        system(['rm -r ' fullfile(dwiDir, [paFile '.bval '])]); % remove it
    else
    end
    system(['paste ' fullfile(dwiDir, [rawpaFile97 '.bval ']) fullfile(dwiDir, [rawpaFile98 '.bval ']) ...
        ' >> ' fullfile(dwiDir, [paFile '.bval '])]);

    disp('All done!')

end
