

% Fit tensors to the diffusion volume and quantify (mean diffusivity and fractional anisotropy)

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
eddyDir = [projectDir '/derivatives/eddy/'];
topup = [projectDir '/derivatives/topup/'];
fibDir = [projectDir '/derivatives/mrtrix3/'];

% add the path of the code
addpath(genpath(fullfile(projectDir, 'code/'))); % afq location

% FSL and mrtrix3 - remember to update the location of FSL and mrtrix3 according to the location on your PC
setenv('FSLDIR', '/usr/local/fsl' );
setenv('FSLOUTPUTTYPE','NIFTI_GZ'); %added to tell where to save the fsl outputs
PATH = getenv('PATH'); setenv('PATH', ['/opt/anaconda3/bin:/usr/local/bin:/usr/local/fsl/bin:/Applications/freesurfer/bin:' PATH]);


%% Fit the Tensor

numFibers_OR = (1e4);
numFibers_OT = (1e2);

sub_i = 1;

for ses_i = 1:numel(dir(fullfile(projectDir, ['sub-' sub{sub_i}], 'ses-*'))) % for each scan session

    % Fit tensors to the diffusion volume
    system(['dwi2tensor ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data.nii.gz ' ... 
        ' -fslgrad ' eddyDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] filesep 'dti1_eddy_corrected_data.eddy_rotated_bvecs ' ...
        topup ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}] '/bval_combined.txt ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor.mif'])

    % Extract MD and FA values from tensors
    system(['tensor2metric ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor.mif ' ...
        ' -fa ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor_fa.mif'])
    system(['tensor2metric ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor.mif ' ...
        ' -adc ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor_md.mif'])

    % Resample the Optic Radiations
    system(['tckresample ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR(1)/1000) 'k_2thalFiltered.tck ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR(1)/1000) 'k_2thalFiltered_100sample.tck ' ...
        ' -num_points 100'])
    
    system(['tckresample ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR(1)/1000) 'k_2thalFiltered.tck ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR(1)/1000) 'k_2thalFiltered_100sample.tck ' ...
        ' -num_points 100'])

    % Resample the Optic Tracts
    system(['tckresample ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT(1)/1000) 'k_2thalFiltered.tck ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT(1)/1000) 'k_2thalFiltered_100sample.tck ' ...
        ' -num_points 100'])
    
    system(['tckresample ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT(1)/1000) 'k_2thalFiltered.tck ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT(1)/1000) 'k_2thalFiltered_100sample.tck ' ...
        ' -num_points 100'])
    
    
    
    % Sample FA measures from the optic radiations
    system(['tcksample ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR(1)/1000) 'k_2thalFiltered_100sample.tck ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor_fa.mif ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/lh_OR_FA_100sample.txt'])

    system(['tcksample ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR(1)/1000) 'k_2thalFiltered_100sample.tck ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor_fa.mif ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/rh_OR_FA_100sample.txt'])

    % Sample FA measures from the optic tracts
    system(['tcksample ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT(1)/1000) 'k_2thalFiltered_100sample.tck ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor_fa.mif ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/lh_OT_FA_100sample.txt'])

    system(['tcksample ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT(1)/1000) 'k_2thalFiltered_100sample.tck ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor_fa.mif ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/rh_OT_FA_100sample.txt'])
    
    
    
    % Sample MD measures from the optic radiations
    system(['tcksample ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR(1)/1000) 'k_2thalFiltered_100sample.tck ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor_md.mif ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/lh_OR_MD_100sample.txt'])

    system(['tcksample ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR(1)/1000) 'k_2thalFiltered_100sample.tck ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor_md.mif ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/rh_OR_MD_100sample.txt'])

    % Sample MD measures from the optic tracts
    system(['tcksample ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT(1)/1000) 'k_2thalFiltered_100sample.tck ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor_md.mif ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/lh_OT_MD_100sample.txt'])

    system(['tcksample ' fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT(1)/1000) 'k_2thalFiltered_100sample.tck ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/tensor_md.mif ' ...
        fibDir ['sub-' sub{sub_i}] filesep ['ses-' ses{ses_i}]  '/rh_OT_MD_100sample.txt'])

    
end