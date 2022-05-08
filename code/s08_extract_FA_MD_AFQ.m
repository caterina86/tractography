function s08_extract_FA_MD_AFQ(projectDir, subject, session, hemi)

    measures = {'FA', 'MD'};
    tracts = {'OR', 'OT'};
    
    % define paths
    AFQDir = fullfile(projectDir, 'derivatives/AFQ', subject, session);
    dt6Dir = fullfile(projectDir, 'derivatives/dt6', subject, session);
    fibDir = fullfile(projectDir, '/derivatives/mrtrix3', subject, session);

    weighting = 1; % by default (1) weight each fiber's contribution by its gaussian distance from the core
    clip2rois = 0; % if clip2rois is set to 1 (default) then only the central portion of the fiber group spanning the 2 defining ROIs is analyzed; 0 -> all the fiber is analyzed
    numNodes = 100; % resample 100 points
    dt = dtiLoadDt6(fullfile(dt6Dir, [subject '_' session '_dti394trilin/dt6.mat'])); % file created from the raw data (dMRI and T1)
    direction = 'AP'; % same direction for all subjects

    %% AFQ fibers:
    % Use always the tracts created using the first DTI scan and the dt6.mat of the specific scanning session
    fg_clean = load(fullfile(AFQDir, [subject '_' session '_fg_clean.mat'])); % use always the clean fibers extracted from the 1st diffusion scan

    for k = 1:numel(fg_clean.fg_clean)
         fg_clean_scan1_align(k,:) = dtiAlignFiberDirection(fg_clean.fg_clean(k),direction); % group alignment of the fibers
    end
    [fa_AFQ, md_AFQ] = AFQ_ComputeTractProperties(fg_clean_scan1_align, dt, numNodes, clip2rois, fullfile(dt6Dir, [subject '_' session '_dti394trilin/']), weighting); % dt -> use the dt6.mat of each scan
    
    %% Probabilistic Tractography = from fit tensor script 07    

    i = 1;
    for measure_i = 1:length(measures) % 1 = FA; 2 = MD
        for tract_i = 1:length(tracts) % 1 = OR; 2 = OT
            for hemi_i = 1:length(hemi) % 1 = lh, 2 = rh
                
                temp = importdata(fullfile(fibDir, [hemi{hemi_i} '_' tracts{tract_i} '_' measures{measure_i} '_100sample.txt']));
                measures_results(:,i) = nanmean(temp.data,1);
                i = i+1;
                
            end
        end
    end

    % measures_results:
    % 1 -> FA_OR_LH
    % 2 -> FA_OR_RH
    % 3 -> FA_OT_LH
    % 4 -> FA_OT_RH
    % 5 -> MD_OR_LH
    % 6 -> MD_OR_RH
    % 7 -> MD_OT_LH
    % 8 -> MD_OT_RH

    fa = [fa_AFQ measures_results(:,1:4)];
    md = [md_AFQ 1000.*measures_results(:,5:8)];

    tracts = {'Left Thalamic Radiation', 'Right Thalamic Radiation', 'Left Corticospinal', ...
        'Right Corticospinal','Left Cingulum Cingulate', 'Right Cingulum Cingulate', ...
        'Left Cingulum Hippocampus', 'Right Cingulum Hippocampus', 'Callosum Forceps Major', ...
        'Callosum Forceps Minor', 'Left IFOF', 'Right IFOF', 'Left ILF', 'Right ILF', 'Left SLF', ...
        'Right SLF', 'Left Uncinate', 'Right Uncinate', 'Left Arcuate', 'Right Arcuate', ...
        'Left OR', 'Right OR', 'Left OT', 'Right OT'};
        
    % make table
    labels = [append(tracts, ' FA'), append(tracts, ' MD')];
    results = array2table([fa md], 'VariableNames', labels);
    
    % save the FA/MD values for each subject
    % save(fullfile(AFQDir, [subject '_fa_values']), 'fa_results');
    % save(fullfile(AFQDir, [subject '_md_values']), 'md_results');
    save(fullfile(AFQDir, [subject '_fa_md_values_table']), 'results');
end