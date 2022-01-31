% dMRI processing pipeline - step 2
% this step needs to be run only when we have more than 1 file with the
% same phase encoding directions but a different number of diffusion
% directions - NYUAD sequence

function s02_merge_dwi(projectDir, subject, session, num_dir)

    % folders:
    dwiDir = fullfile(projectDir, 'rawdata', subject, session, 'dwi');

    % partial filename
    subses = [subject '_' session];

    % files:
    apFile =  [subses '_dir-ap_dwi'];
    paFile =  [subses '_dir-pa_dwi'];
    rawapFile97 = [subses '_dir-APacq' num2str(num_dir{1}) 'vols_dwi'];
    rawapFile98 = [subses '_dir-APacq' num2str(num_dir{2}) 'vols_dwi'];
    rawpaFile97 = [subses '_dir-PAacq' num2str(num_dir{1}) 'vols_dwi'];
    rawpaFile98 = [subses '_dir-PAacq' num2str(num_dir{2}) 'vols_dwi'];

    if exist(fullfile(dwiDir, [apFile '.nii.gz']),'file') && exist(fullfile(dwiDir, [paFile '.nii.gz']),'file')
        disp('skip merging')

    else

        % nifti image
        system(['fslmerge -t ' fullfile(dwiDir, [apFile '.nii.gz ']) fullfile(dwiDir, [rawapFile97 '.nii.gz ']) ...
            fullfile(dwiDir, [rawapFile98 '.nii.gz '])]);

        system(['fslmerge -t ' fullfile(dwiDir, [paFile '.nii.gz ']) fullfile(dwiDir, [rawpaFile97 '.nii.gz ']) ...
            fullfile(dwiDir, [rawpaFile98 '.nii.gz '])]);


        % bvec
        if exist(fullfile(dwiDir, [apFile '.bvec']), 'file') % if it exists
            system(['rm -r ' fullfile(dwiDir, [apFile '.bvec'])]); % remove it
        end
        system(['paste ' fullfile(dwiDir, [rawapFile97 '.bvec ']) fullfile(dwiDir, [rawapFile98 '.bvec ']) ...
            ' >> ' fullfile(dwiDir, [apFile '.bvec'])]);

        if exist(fullfile(dwiDir, [paFile '.bvec']), 'file') % if it exists
            system(['rm -r ' fullfile(dwiDir, [paFile '.bvec '])]); % remove it
        end
        system(['paste ' fullfile(dwiDir, [rawpaFile97 '.bvec ']) fullfile(dwiDir, [rawpaFile98 '.bvec ']) ...
             ' >> ' fullfile(dwiDir, [paFile '.bvec'])]);


        % bval
        if exist(fullfile(dwiDir, [apFile '.bval']), 'file')  % if it exists
          system(['rm -r ' fullfile(dwiDir, [apFile '.bval '])]); % remove it
        end
        system(['paste ' fullfile(dwiDir, [rawapFile97 '.bval ']) fullfile(dwiDir, [rawapFile98 '.bval ']) ...
            ' >> ' fullfile(dwiDir, [apFile '.bval '])]);

        if exist(fullfile(dwiDir, [paFile '.bval']), 'file')  % if it exists
            system(['rm -r ' fullfile(dwiDir, [paFile '.bval '])]); % remove it
        end
        system(['paste ' fullfile(dwiDir, [rawpaFile97 '.bval ']) fullfile(dwiDir, [rawpaFile98 '.bval ']) ...
            ' >> ' fullfile(dwiDir, [paFile '.bval '])]);

    end

    disp('Merging done!')

end
