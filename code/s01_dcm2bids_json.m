% Step 1 -> From dicoms to nifti
% Step 2 -> Fix fmap/ .json files
% Step 3 -> Run fmriprep

clear all;

% Specify the user 
user = 'server';

switch user
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI';
    case {'caterina'}
        projectDir = '/Volumes/NYUAD/Projects/pRF_Cate/AnalyzePRF/fMRIPrep';
end

sub = {'0258'}; % ID of the subject
ses = {'01'}; % session
num_runs = 9;


%% Step 1. Run dcm2bids in the shell wrapped in matlab and modify the .json in the fmap folder

for ii = 1:length(sub)
    
    dcmDir = [projectDir '/sourcedata/sub-' sub{ii} '_ses-' ses{ii} '_Br_Prf/']; % load the directory of the dicoms
    config = [projectDir '/code/bids_convert.json'];

    tic
    % from dicoms to nifti
    system(['dcm2bids -d ' dcmDir ...
        ' -o ' projectDir '/rawdata/' ...
        ' -p ' sub{ii} ' -s ' ses{ii} ...
        ' -c ' config ' --forceDcm2niix --clobber']);
    toc
end


%% Step 2. Fix fmap json files by adding run information
% dcm2bids will not set the correct intendedFor field in fmap json files
% See https://docs.google.com/document/d/19oWXHbcYH55vZZ6wickjPrLElfaEl4SelRcAHxJwgZU/edit\

% sometimes in the folder fmap/ there is a file called
% .sub-201_ses-01_dir-AP_epi.json (hidden file ls -a). To delete move to
% the folder and write the command: 
% system(['find . -name ".*" -exec rm -rf {} \;'])

for ii = 1:length(sub)

    jsons = dir(fullfile(projectDir, 'rawdata', ['sub-' sub{ii}], ['ses-' ses{ii}], 'fmap', '*.json'));
    for ff = 1:length(jsons) % for each json file
        fname = fullfile(jsons(ff).folder, jsons(ff).name);
        str = fileread(fname);
        val = jsondecode(str);

        kk = 1;
        for zz = 1:length(val.IntendedFor)
           for jj = 1:num_runs % for each run
                % Get task info
                to_add{kk} = insertAfter(val.IntendedFor{zz}, '_task-prf', ['_run-' num2str(jj,'%02.f')]);
                kk = kk+1;
            end
        end
        val.IntendedFor = to_add;
        str = jsonencode(val);
        % Make the json output file more human readable
        str = strrep(str, ',"', sprintf(',\n"'));
        str = strrep(str, '[{', sprintf('[\n{\n'));
        str = strrep(str, '}]', sprintf('\n}\n]'));

        fid = fopen(fname,'w');
        fwrite(fid,str);
        fclose(fid);

    end
    
end



%% Step 3. Run fmri_prep - Run fmriprep on Dalma
% create a scratch folder outside the project directory, where you can save
% all the outputs of fmriprep while it is running it, so that you can start
% from there if a process stop and the working directory is constructed outside the Docker image, 
% which may have more constraints than disk space
% https://github.com/nipreps/fmriprep/issues/1291

% for ii = 1:length(subID)
% 
%     mkdir('/Volumes/NYUAD/Projects/scratch')
%     
%     system(['fmriprep-docker -w /Volumes/NYUAD/Projects/scratch' ...
%         ' ' projectDir ...
%         ' ' projectDir '/derivatives' ...
%         ' participant --participant-label ' sub{ii} ...
%         ' --fs-license-file /Applications/freesurfer/license.txt' ...
%         ' --output-spaces T1w fsaverage MNI152NLin2009cAsym']);
%     
% end
