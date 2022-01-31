function s06_cleaning(projectDir, subject, session, numFibers_OR, numFibers_OT, hemi, maxDist, maxLen, numNodes, M, count, show)
% Cleaning Probabilistic tracts (mrtirx3)

roiDir = fullfile(projectDir, '/derivatives/ROIs', subject, session);
fibDir = fullfile(projectDir, '/derivatives/mrtrix3', subject, session);

for jj = 1:length(hemi)

    % Run tckedit, excluding fibers terminating in thalamus outside of LGNs
    % Optic Radiations:
    roi1 = fullfile(roiDir, ['fs_' hemi{jj} '_lgn_T1Reslice_diffspace.nii.gz']);
    roi2 = fullfile(roiDir, ['fs_' hemi{jj} '_V1_T1Reslice_diffspace.nii.gz']);
    roi3 = fullfile(roiDir, 'fs_thalamus_sub_LGNs_diffspace.nii.gz');

    system(['tckedit -exclude ' roi3 ' -include ' roi1 ' -include ' roi2 ' -ends_only ' ...
        fibDir '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k.tck ' ...
        fibDir '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_thalFiltered.tck'])

    system(['tckedit -exclude ' roi3 ' -include ' roi1 ' -include ' roi2 ' ' ...
        fibDir '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_thalFiltered.tck ' ...
        fibDir '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered.tck'])


    tckedit_out_file = [fibDir '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered.tck'];
    afq_cleaned_out_file = [fibDir '/dti_' hemi{jj} '_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.tck'];
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
    roi4 = fullfile(roiDir, 'fs_oc_T1Reslice_diffspace_2dilM.nii.gz');

    system(['tckedit -exclude ' roi3 ' -include ' roi1 ' -include ' roi4 ' -ends_only ' ...
        fibDir '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k.tck -maxlength 50 '...
        fibDir '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_thalFiltered.tck'])

    system(['tckedit -exclude ' roi3 ' -include ' roi1 ' -include ' roi4 ' ' ...
        fibDir '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_thalFiltered.tck ' ...
        fibDir '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered.tck'])


    tckedit_out_file = [fibDir '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered.tck'];
    afq_cleaned_out_file = [fibDir '/dti_' hemi{jj} '_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.tck'];
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

disp('All done!')

end


