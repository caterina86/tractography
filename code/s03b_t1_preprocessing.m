
% T1 preprocessing pipeline: robustfov, fast and recon-all
% 
% Written by Caterina Pedersini

function s03b_t1_preprocessing(projectDir, subject, session)

    anatPrepDir = fullfile(projectDir, 'derivatives/anat_prep', subject, session);        
    anatDir = fullfile(projectDir, 'rawdata', subject, session, 'anat');
    fsDir = fullfile(projectDir, 'derivatives/freesurfer/');

    fileName = dir(fullfile(anatDir, '*_MPR1.nii.gz'));
    copyfile(fullfile(anatDir,fileName.name), fullfile(anatDir, 't1.nii.gz'));

    mkdir(anatPrepDir)
        
    % extract the FOV only showing the brain (cutting the neck)
    system(['robustfov -i ' fullfile(anatDir, 't1.nii.gz') ' -r ' ...  
        fullfile(anatPrepDir, 't1_crop.nii.gz')]);
    
    % FAST 
    system(['fast -B ' fullfile(anatPrepDir, 't1_crop.nii.gz')]);
    
    % Recon-all
    if exist(fullfile(projectDir, 'derivatives/freesurfer', subject), 'dir') % if the directory already exists
        system(['recon-all -subjid ' subject ' -all'])
    else % if it's the first time we run recon-all for this subject
        system(['recon-all -i ' fullfile(anatPrepDir, 't1_crop_restore.nii.gz') ' -subjid ' subject ' -all'])
    end
   
end

