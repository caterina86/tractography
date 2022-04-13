  
% extract FA, MD and RD values from the tracts (AFQ)
% Script created by Caterina Pedersini - NYUAD February 2022

clearvars;

% Add paths
addpath(genpath('/Users/cp3488/Documents/MATLAB/toolbox/vistasoft')); % vistasoft location
addpath(genpath('/Users/cp3488/Documents/MATLAB/toolbox/AFQ')); % afq location
addpath(genpath('/Volumes/Vision/MRI/Covid_dMRI/code'))

user = 'caterina'; % name of the user

% Set the path
switch user
    case {'caterina'}
        baseDir = '/Users/cp3488/Data/Projects/Covid_dMRI/'; % location sourcedata
    case {'server'}
        baseDir = '/Volumes/Vision/MRI/Covid_dMRI/Covid'; % location sourcedata
end

sub = {'01'}; % ID of the subject

ses = {'01'}; % number of the session

rawDir = 'rawdata/';
dwiDir = 'dwi/';
t1Dir = 'anat/';

% derivatives: folders fot the outputs
eddyDir = 'derivatives/eddy/';
topup = 'derivatives/topup/';
temp = 'temp/';
unprocessed = 'unprocessed/';


for sub_i = 1:numel(sub)

    sub_dir = fullfile(baseDir,sub{sub_i});

    for ses_i = 1:numel(ses) % for each scan session

        % load the paths        
        dt6Dir = fullfile(baseDir, 'derivatives/dt6', ['S' sub{sub_i}], ['ses-' ses{ses_i}]);
        AFQDir = fullfile(baseDir, 'derivatives/AFQ', ['S' sub{sub_i}], ['ses-' ses{ses_i}]);
        
        dt = dtiLoadDt6(fullfile(dt6Dir, ['S' sub{sub_i} '_dti40trilin_' num2str(ses_i)], '/dt6.mat')); % file created from the raw data (dMRI and T1)
        dtiInit = load(fullfile(dt6Dir, 'dtiInitLog.mat')); % file created from the raw data (dMRI and T1)

        % Parameters:
        weighting = 1; % by default (1) weight each fiber's contribution by its gaussian distance from the core
        clip2rois = 0; % if clip2rois is set to 1 (default) then only the central portion of the fiber group spanning the 2 defining ROIs is analyzed; 0 -> all the fiber is analyzed
        numNodes = 100; % resample 100 points
        direction = 'AP'; % TODO: check if this is the correct phase encoding direction - same direction for all subjects

        % AFQ fibers:
        % Use always the tracts created using the first DTI scan and the dt6.mat of the specific scanning session
        fg_clean_scan = load(fullfile(AFQDir, ['S' sub{sub_i} '_fg_clean.mat'])); % use always the clean fibers extracted from the 1st diffusion scan    
        
        for k = 1:numel(fg_clean_scan.fg_clean)
             fg_clean_scan_align(k,:) = dtiAlignFiberDirection(fg_clean_scan.fg_clean(k),direction); % group alignement of the fibers
        end 
        
        [fa, md, rd] = AFQ_ComputeTractProperties(fg_clean_scan_align, dt, numNodes, clip2rois, sub_dir, weighting); % dt -> use the dt6.mat of each scan

        for i=1:numel(fg_clean_scan_align) 
            theFAs{sub_i}{ses_i}{i} = fa(:,i);
            theMDs{sub_i}{ses_i}{i} = md(:,i);
            theRDs{sub_i}{ses_i}{i} = rd(:,i);
        end
    
        % save the FA/MD values for each subject
        save(fullfile(AFQDir, ['S' sub{sub_i} '_fa_AP']), 'fa');
        save(fullfile(AFQDir, ['S' sub{sub_i} '_md_AP']), 'md');
        save(fullfile(AFQDir, ['S' sub{sub_i} '_rd_AP']), 'md');

        % extract FA/MD/RD values 
        sampleRange = 11:90; % take only the 80 central points              
        
        % Extract the mean value for each tract - look at fg_clean for the order of the tracts
        % OR
        MD_means_OR_left{sub_i}(ses_i) = nanmean(theMDs{sub_i}{ses_i}{1}(sampleRange));
        FA_means_OR_left{sub_i}(ses_i) = nanmean(theFAs{sub_i}{ses_i}{1}(sampleRange));
        RD_means_OR_left{sub_i}(ses_i) = nanmean(theFAs{sub_i}{ses_i}{1}(sampleRange));

        MD_means_OR_right{sub_i}(ses_i) = nanmean(theMDs{sub_i}{ses_i}{2}(sampleRange));
        FA_means_OR_right{sub_i}(ses_i) = nanmean(theFAs{sub_i}{ses_i}{2}(sampleRange));
        RD_means_OR_right{sub_i}(ses_i) = nanmean(theFAs{sub_i}{ses_i}{2}(sampleRange));
        
        
        % Complete the code with the list of all tracts and then save the final output
        mkdir(fullfile(baseDir, 'derivatives/measures')); % Create the folder /measures/ where to save the results
        save(fullfile(baseDir, 'derivatives/measures/mean_FA_11_90'), 'FA_means_OR_left', 'FA_means_OR_right', ...);
        save(fullfile(baseDir, 'derivatives/measures/mean_MD_11_90'), 'MD_means_OR_left', 'MD_means_OR_right',...);
        save(fullfile(baseDir, 'derivatives/measures/mean_RD_11_90'), 'RD_means_OR_left', 'RD_means_OR_right',...);
    
    end
    
end

                