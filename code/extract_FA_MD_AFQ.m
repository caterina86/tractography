% Parameters:

clearvars;
setup_user;

% copy these folders from MRI/Sample_dMRI on the server to your local PC (projectDir):
% rawdata/sub-XX/ses-YY
% derivatives/fmriprep/sub-XX/ses-YY
% derivatives/freesurfer/sub-XX

%% Setup parameters

% sub{sub_i}/ses{ses_i}/etc:
sub = {'sub-0258'}; % initials of the sub{sub_i}
ses = {'ses-01'}; % ID of the ses{ses_i}
hemi = {'lh', 'rh'};

num_dir = {'97' '98'}; % number of diffusion gradient directions (should get from bval/bvecs file)
fmriprep = 1; % 1 -> we performed fmriprep (NYUAD); 0 -> we did not perform fmriprep (CCAD)
numFibers_WB = 5000000; % number of fibers whole brain
numFibers_OR = 10000; % number of fibers for optic radiation
numFibers_OT = 1000; % number of fibers for optic tract

% AFQ cleaning
maxDist =   4;
maxLen =    4;
numNodes =  25;
M =         'mean';
count =     1;
show =      1;


%%
for sub_i = 1:length(sub) % loop over sub{sub_i}s

    disp(['Subject ' sub{sub_i}])
    
    sub_ses = dir(fullfile(projectDir, 'rawdata', sub{sub_i}, 'ses-*'));

    for ses_i = 1:numel(sub_ses) % for each scan ses{ses_i}

    % define paths
    rawDir = fullfile(projectDir, 'rawdata', sub{sub_i}, ses{ses_i});
    AFQDir = fullfile(projectDir, 'derivatives/AFQ', sub{sub_i}, ses{ses_i});
    dt6Dir = fullfile(projectDir, 'derivatives/dt6', sub{sub_i}, ses{ses_i});
    fmriprepDir = fullfile(projectDir, 'derivatives/fmriprep', sub{sub_i}, ses{ses_i});
    fibDir = fullfile(projectDir, '/derivatives/mrtrix3', sub{sub_i}, ses{ses_i});

    weighting = 1; % by default (1) weight each fiber's contribution by its gaussian distance from the core
    clip2rois = 0; % if clip2rois is set to 1 (default) then only the central portion of the fiber group spanning the 2 defining ROIs is analyzed; 0 -> all the fiber is analyzed
    numNodes = 100; % resample 100 points
    dt = dtiLoadDt6(fullfile(dt6Dir, [sub{sub_i} '_' ses{ses_i} '_dti394trilin/dt6.mat'])); % file created from the raw data (dMRI and T1)
    dtiInit = load(fullfile(dt6Dir, 'dtiInitLog.mat')); % file created from the raw data (dMRI and T1)
    direction = 'AP'; % same direction for all sub{sub_i}s
    sub_dir = dt6Dir;

    % AFQ fibers:
    % Use always the tracts created using the first DTI scan and the dt6.mat of the specific scanning ses{ses_i}
    fg_clean = load(fullfile(AFQDir, [sub{sub_i} '_' ses{ses_i} '_fg_clean.mat'])); % use always the clean fibers extracted from the 1st diffusion scan

    for k = 1:numel(fg_clean.fg_clean)
         fg_clean_scan1_align(k,:) = dtiAlignFiberDirection(fg_clean.fg_clean(k),direction); % group alignement of the fibers
    end
    [fa_AFQ, md_AFQ] = AFQ_ComputeTractProperties(fg_clean_scan1_align, dt, numNodes, clip2rois, fullfile(dt6Dir, [sub{sub_i} '_' ses{ses_i} '_dti394trilin/']), weighting); % dt -> use the dt6.mat of each scan
    fa_AFQ = fa_AFQ';
    md_AFQ = md_AFQ';

    % Probabilistic Tractography - from AFQ
    % from .tck to .pdb
%     mrtrix_tck2pdb([fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.tck'])], ...
%         [fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.pdb'])]);
%     mrtrix_tck2pdb([fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.tck'])], ...
%         [fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.pdb'])]);
%
%     mrtrix_tck2pdb([fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.tck'])], ...
%         [fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.pdb'])]);
%     mrtrix_tck2pdb([fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.tck'])], ...
%         [fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.pdb'])]);
%
%     fiberName = {['dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.pdb'], ...
%         ['dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.pdb'], ...
%         ['dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.pdb'], ...
%         ['dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.pdb']};
%
%     for fgNumber=1:numel(fiberName)
%         fiberGroup = fullfile(fibDir, fiberName{fgNumber});
%         % Align fibers across sub{sub_i}s
%         fg_clean_mrtrix = dtiAlignFiberDirection((dtiLoadFiberGroup(fiberGroup)),direction);
%         % extract fiber properties
%         [fa_mrtrix, md_mrtrix] = AFQ_ComputeTractProperties(fg_clean_mrtrix, dt, numNodes, clip2rois, sub_dir, weighting);
%         fa_mrtrix_all(:,fgNumber) = fa_mrtrix;
%         md_mrtrix_all(:,fgNumber) = md_mrtrix;
%     end

    % Probabilistic Tractography = from fit tensor script 07
    lh_FA_OR(sub_i) = importdata(fullfile(fibDir, 'lh_OR_FA_100sample.txt'));
    lh_FA_OR_mean = nanmean(lh_FA_OR(sub_i).data,1);

    rh_FA_OR(sub_i) = importdata(fullfile(fibDir, 'rh_OR_FA_100sample.txt'));
    rh_FA_OR_mean = nanmean(rh_FA_OR(sub_i).data,1);

    lh_MD_OR(sub_i) = importdata(fullfile(fibDir, 'lh_OR_MD_100sample.txt'));
    lh_MD_OR_mean = nanmean(lh_MD_OR(sub_i).data,1);

    rh_MD_OR(sub_i) = importdata(fullfile(fibDir, 'rh_OR_MD_100sample.txt'));
    rh_MD_OR_mean = nanmean(rh_MD_OR(sub_i).data,1);

    lh_FA_OT(sub_i) = importdata(fullfile(fibDir, 'lh_OT_FA_100sample.txt'));
    lh_FA_OT_mean = nanmean(lh_FA_OT(sub_i).data,1);

    rh_FA_OT(sub_i) = importdata(fullfile(fibDir, 'rh_OT_FA_100sample.txt'));
    rh_FA_OT_mean = nanmean(rh_FA_OT(sub_i).data,1);

    lh_MD_OT(sub_i) = importdata(fullfile(fibDir, 'lh_OT_MD_100sample.txt'));
    lh_MD_OT_mean = nanmean(lh_MD_OT(sub_i).data,1);

    rh_MD_OT(sub_i) = importdata(fullfile(fibDir, 'rh_OT_MD_100sample.txt'));
    rh_MD_OT_mean = nanmean(rh_MD_OT(sub_i).data,1);


    fa = [fa_AFQ; lh_FA_OR_mean; rh_FA_OR_mean; lh_FA_OT_mean; rh_FA_OT_mean];
    md = [md_AFQ; (lh_MD_OR_mean*1000); (rh_MD_OR_mean*1000); (lh_MD_OT_mean*1000); (rh_MD_OT_mean*1000)];

    results = {'Left Thalamic Radiation'; 'Right Thalamic Radiation';'Left Corticospinal';...
        'Right Corticospinal';'Left Cingulum Cingulate';'Right Cingulum Cingulate';...
        'Left Cingulum Hippocampus';'Right Cingulum Hippocampus';'Callosum Forceps Major';...
        'Callosum Forceps Minor';'Left IFOF';'Right IFOF';'Left ILF';'Right ILF';'Left SLF';...
        'Right SLF';'Left Uncinate';'Right Uncinate';'Left Arcuate';'Right Arcuate'; ...
        'Left OR'; 'Right OR'; 'Left OT'; 'Right OT'};
    
    FA = {'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; ...
        'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'; 'FA'};
    
    MD = {'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; ...
        'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'; 'MD'};

    fa_results = [results FA num2cell(fa)];
    md_results = [results MD num2cell(md)];
    results = [fa_results; md_results];

    % save the FA/MD values for each sub{sub_i}
    save(fullfile(AFQDir, [sub{sub_i} '_fa_values']), 'fa_results');
    save(fullfile(AFQDir, [sub{sub_i} '_md_values']), 'md_results');
    save(fullfile(AFQDir, [sub{sub_i} '_fa_md_values']), 'results');


    end

end


%% To plot the results:

%plot(cell2mat(results(1,3:end)))
