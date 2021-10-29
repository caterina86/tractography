
% Set the paths
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
ses = {'01'}; % ID of the subject

%% Merge the 97 and 98 directions with the same phase encoding direction in one single diffusion image

sub_i = 1; % number of subject
num_directions = {'97' '98'};

% nifti image
system(['fslmerge -t ' projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_AP_dwi.nii.gz '...
    projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_AP_acq-' num2str(num_directions{1}) 'vols_dwi.nii.gz ' ...
    projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_AP_acq-' num2str(num_directions{2}) 'vols_dwi.nii.gz']);

system(['fslmerge -t ' projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_PA_dwi.nii.gz '...
    projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_PA_acq-' num2str(num_directions{1}) 'vols_dwi.nii.gz ' ...
    projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_PA_acq-' num2str(num_directions{2}) 'vols_dwi.nii.gz']);


% AP - bvec/bval
system(['paste ' projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_AP_acq-' num2str(num_directions{1}) 'vols_dwi.bvec ' ...
   projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_AP_acq-' num2str(num_directions{2}) 'vols_dwi.bvec ' ...
   ' >> ' projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_AP_dwi.bvec '])

system(['paste ' projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_AP_acq-' num2str(num_directions{1}) 'vols_dwi.bval ' ...
   projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_AP_acq-' num2str(num_directions{2}) 'vols_dwi.bval ' ...
   ' >> ' projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_AP_dwi.bval ']);


% PA - bvec/bval
system(['paste ' projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_PA_acq-' num2str(num_directions{1}) 'vols_dwi.bvec ' ...
   projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_PA_acq-' num2str(num_directions{2}) 'vols_dwi.bvec ' ...
   ' >> ' projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_PA_dwi.bvec '])

system(['paste ' projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_PA_acq-' num2str(num_directions{1}) 'vols_dwi.bval ' ...
   projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_PA_acq-' num2str(num_directions{2}) 'vols_dwi.bval ' ...
   ' >> ' projectDir '/sub-' sub{sub_i} '/ses-' ses{sub_i} '/dwi/sub-' sub{sub_i} '_ses-' ses{sub_i} '_PA_dwi.bval ']);
