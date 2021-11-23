% dMRI processing pipeline - step 3
%
% Set the paths
clear all;
user = 'server'; % name of the user
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
ses = {'01'}; % ID of the subject

% FSL - remember to update the location of freesurfer according to
% the location on your PC
setenv('FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); %added to tell where to save the fsl outputs
PATH = getenv('PATH'); setenv('PATH', ['/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/bin:' PATH]);


%% Merge the 97 and 98 directions with the same phase encoding direction in one single diffusion image

sub_i = 1:length(sub); % loop over subjects (eventually)
num_dir = {'97' '98'}; % number of diffusion gradient directions

sub_ses = dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'));

for ses_i = 1:numel(sub_ses) % for each scan session
    
    % folders:
    dwiDir = fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'dwi');
    % files:
    apFile =  ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_AP_dwi'];
    paFile =  ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_PA_dwi'];
    rawapFile97 = ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_dir-APacq' num2str(num_dir{1}) 'vols_dwi'];
    rawapFile98 = ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_dir-APacq' num2str(num_dir{2}) 'vols_dwi'];
    rawpaFile97 = ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_dir-PAacq' num2str(num_dir{1}) 'vols_dwi'];
    rawpaFile98 = ['sub-' sub{sub_i} '_ses-' ses{ses_i} '_dir-PAacq' num2str(num_dir{2}) 'vols_dwi'];

    % nifti image
    system(['fslmerge -t ' fullfile(dwiDir, [apFile '.nii.gz ']) fullfile(dwiDir, [rawapFile97 '.nii.gz ']) ...
        fullfile(dwiDir, [rawapFile98 '.nii.gz '])]);

    system(['fslmerge -t ' fullfile(dwiDir, [paFile '.nii.gz ']) fullfile(dwiDir, [rawpaFile97 '.nii.gz ']) ...
        fullfile(dwiDir, [rawpaFile98 '.nii.gz '])]);

    % bvec
    system(['paste ' fullfile(dwiDir, [rawapFile97 '.bvec ']) fullfile(dwiDir, [rawapFile98 '.bvec ']) ...
       ' >> ' fullfile(dwiDir, [apFile '.bvec '])]);

    system(['paste ' fullfile(dwiDir, [rawpaFile97 '.bvec ']) fullfile(dwiDir, [rawpaFile98 '.bvec ']) ...
       ' >> ' fullfile(dwiDir, [paFile '.bvec '])]);

    % bval
    system(['paste ' fullfile(dwiDir, [rawapFile97 '.bval ']) fullfile(dwiDir, [rawapFile98 '.bval ']) ...
       ' >> ' fullfile(dwiDir, [apFile '.bval '])]);

    system(['paste ' fullfile(dwiDir, [rawpaFile97 '.bval ']) fullfile(dwiDir, [rawpaFile98 '.bval ']) ...
       ' >> ' fullfile(dwiDir, [paFile '.bval '])]);       


    disp('All done!')
        
end

