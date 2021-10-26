
% Set the paths
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
ses = {'01'}; % ID of the subject

%% Merge the 97 and 98 directions with the same phase encoding direction in one single diffusion image

kk = 1; % number of subject
num_directions = {'97' '98'};

% nifti image
system(['fslmerge -t ' projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_AP_dwi.nii.gz '...
    projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_AP_acq-' num2str(num_directions{1}) 'vols_dwi.nii.gz ' ...
    projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_AP_acq-' num2str(num_directions{2}) 'vols_dwi.nii.gz']);

system(['fslmerge -t ' projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_PA_dwi.nii.gz '...
    projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_PA_acq-' num2str(num_directions{1}) 'vols_dwi.nii.gz ' ...
    projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_PA_acq-' num2str(num_directions{2}) 'vols_dwi.nii.gz']);


% AP - bvec/bval
system(['paste ' projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_AP_acq-' num2str(num_directions{1}) 'vols_dwi.bvec ' ...
   projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_AP_acq-' num2str(num_directions{2}) 'vols_dwi.bvec ' ...
   ' >> ' projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_AP_dwi.bvec '])

system(['paste ' projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_AP_acq-' num2str(num_directions{1}) 'vols_dwi.bval ' ...
   projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_AP_acq-' num2str(num_directions{2}) 'vols_dwi.bval ' ...
   ' >> ' projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_AP_dwi.bval ']);


% PA - bvec/bval
system(['paste ' projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_PA_acq-' num2str(num_directions{1}) 'vols_dwi.bvec ' ...
   projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_PA_acq-' num2str(num_directions{2}) 'vols_dwi.bvec ' ...
   ' >> ' projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_PA_dwi.bvec '])

system(['paste ' projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_PA_acq-' num2str(num_directions{1}) 'vols_dwi.bval ' ...
   projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_PA_acq-' num2str(num_directions{2}) 'vols_dwi.bval ' ...
   ' >> ' projectDir '/sub-' sub{kk} '/ses-' ses{kk} '/dwi/sub-' sub{kk} '_ses-' ses{kk} '_PA_dwi.bval ']);
