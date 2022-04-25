function s02_merge_dwi(projectDir, subject, session, num_dir_AP, num_dir_PA)

    % dMRI processing pipeline - step 2
    % this step needs to be run only when we have more than 1 file with the
    % same phase encoding directions but a different number of diffusion
    % directions - NYUAD sequence

    % folders:
    dwiDir = fullfile(projectDir, 'rawdata', subject, session, 'dwi');

    % partial filename
    subses = [subject '_' session];

    % files:
    apFile =  [subses '_dir-ap_dwi'];
    paFile =  [subses '_dir-pa_dwi'];
    
    if length(num_dir_AP) == 1 % if there is only 1 file with XX number directions

        rawapFile1 = [subses '_dir-APacq' num2str(num_dir_AP{1}) 'vols_dwi'];
        rawpaFile1 = [subses '_dir-PAacq' num2str(num_dir_PA{1}) 'vols_dwi'];
    else
        rawapFile1 = [subses '_dir-APacq' num2str(num_dir_AP{1}) 'vols_dwi'];
        rawpaFile1 = [subses '_dir-PAacq' num2str(num_dir_PA{1}) 'vols_dwi'];
        rawapFile2 = [subses '_dir-APacq' num2str(num_dir_AP{2}) 'vols_dwi'];
        rawpaFile2 = [subses '_dir-PAacq' num2str(num_dir_PA{2}) 'vols_dwi'];
    end

    if exist(fullfile(dwiDir, [apFile '.nii.gz']),'file') && exist(fullfile(dwiDir, [paFile '.nii.gz']),'file')
        disp('skip merging')

    else
        
        if length(num_dir_AP) == 1 % if there is only 1 file with XX number directions
            system(['cp ' fullfile(dwiDir, [rawapFile1 '.nii.gz ']) ' ' fullfile(dwiDir, [apFile '.nii.gz '])])
        else   
            % nifti image
            system(['fslmerge -t ' fullfile(dwiDir, [apFile '.nii.gz ']) fullfile(dwiDir, [rawapFile1 '.nii.gz ']) ...
                fullfile(dwiDir, [rawapFile2 '.nii.gz '])]);
        end
        
        if length(num_dir_PA) == 1
            system(['cp ' fullfile(dwiDir, [rawpaFile1 '.nii.gz ']) ' ' fullfile(dwiDir, [paFile '.nii.gz '])])
        else               
            system(['fslmerge -t ' fullfile(dwiDir, [paFile '.nii.gz ']) fullfile(dwiDir, [rawpaFile1 '.nii.gz ']) ...
                fullfile(dwiDir, [rawpaFile2 '.nii.gz '])]);
        end
        
    end

    % bvec
    if exist(fullfile(dwiDir, [apFile '.bvec']), 'file') % if it exists
        system(['rm -r ' fullfile(dwiDir, [apFile '.bvec'])]); % remove it
    end

    if length(num_dir_AP) == 1
        system(['cp ' fullfile(dwiDir, [rawapFile1 '.bvec ']) fullfile(dwiDir, [apFile '.bvec '])])
    else    
        system(['paste ' fullfile(dwiDir, [rawapFile1 '.bvec ']) fullfile(dwiDir, [rawapFile2 '.bvec ']) ...
            ' >> ' fullfile(dwiDir, [apFile '.bvec'])]);
    end

    if exist(fullfile(dwiDir, [paFile '.bvec']), 'file') % if it exists
        system(['rm -r ' fullfile(dwiDir, [paFile '.bvec '])]); % remove it
    end
    if length(num_dir_PA) == 1
        system(['cp ' fullfile(dwiDir, [rawpaFile1 '.bvec ']) fullfile(dwiDir, [paFile '.bvec '])])
    else    
        system(['paste ' fullfile(dwiDir, [rawpaFile1 '.bvec ']) fullfile(dwiDir, [rawpaFile2 '.bvec ']) ...
         ' >> ' fullfile(dwiDir, [paFile '.bvec'])]);
    end

    % bval
    if exist(fullfile(dwiDir, [apFile '.bval']), 'file')  % if it exists
      system(['rm -r ' fullfile(dwiDir, [apFile '.bval '])]); % remove it
    end

    if length(num_dir_AP) == 1
        system(['cp ' fullfile(dwiDir, [rawapFile1 '.bval ']) fullfile(dwiDir, [apFile '.bval '])])
    else

        system(['paste ' fullfile(dwiDir, [rawapFile1 '.bval ']) fullfile(dwiDir, [rawapFile2 '.bval ']) ...
        ' >> ' fullfile(dwiDir, [apFile '.bval '])]);
    end


    if exist(fullfile(dwiDir, [paFile '.bval']), 'file')  % if it exists
        system(['rm -r ' fullfile(dwiDir, [paFile '.bval '])]); % remove it
    end
    if length(num_dir_PA) == 1
        system(['cp ' fullfile(dwiDir, [rawpaFile1 '.bval ']) fullfile(dwiDir, [paFile '.bval '])])
    else

        system(['paste ' fullfile(dwiDir, [rawpaFile1 '.bval ']) fullfile(dwiDir, [rawpaFile2 '.bval ']) ...
        ' >> ' fullfile(dwiDir, [paFile '.bval '])]);
    end
    
    disp('Merging done!')

end



