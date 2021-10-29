% Step 1 -> From dicoms to nifti - anatomical, functional and diffusion
% data in the sourcedata
% Step 2 -> Fix fmap/ .json files for the functional images
% Step 3 -> Run fmriprep
% Step 4 -> Convert diffusion data to nifti with the parameters information saved in the diffusion name (phase encoding direction and number of
% diffusion gradients)

clear all;
user = 'caterina'; % name of the user
% choose 'server' if you are working on the server
% add your name if you are working on your local PC. In this case you
% should add your files locations in the following 'switch user'

% Set the path
switch user
    case {'caterina'}
        baseDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location sourcedata
        projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output  
        work_dir = '/Users/cp3488/Documents/tractography/scratch'; % location of the working directory created by fmriprep
    case {'server'}
        baseDir = '/Volumes/Vision/Raw'; % location sourcedata
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
        work_dir = '/Volumes/Vision/MRI/scratch'; % location of the working directory created by fmriprep
end

sub = {'201'}; % ID of the subject
ses = {'01'}; % ID of the session
num_runs = 2;


%% Step 1. Run dcm2bids in the shell wrapped in matlab and modify the .json in the fmap folder

% Run dcm2bids of the anat, func and fmap

for ses_i = 1:length(ses) % for each session
    
    switch user
        case {'caterina'}
            dcmDir = [baseDir '/sourcedata/sub-' sub{ses_i} '_ses-' ses{ses_i} '_Br_Prf/S' sub{ses_i} '_Br_Prf_Dicom/']; % load the directory of the dicoms
            config = [projectDir '/code/bids_convert.json'];
        case {'server'}
            dcmDir = [baseDir '/sub-' sub{ses_i} '/sub-' sub{ses_i} '_ses-' ses{ses_i} '_Br_Prf/']; % path on the server
            config = [projectDir '/code/update_github/bids_convert.json'];
    end    
    
    tic
    % from dicoms to nifti
    system(['dcm2bids -d ' dcmDir ...
        ' -o ' projectDir ...
        ' -p ' sub{ses_i} ' -s ' ses{ses_i} ...
        ' -c ' config ' --forceDcm2niix --clobber']);
    toc
    
end


%% Step 2. Fix fmap json files by adding run information
% dcm2bids will not set the correct intendedFor field in fmap json files
% See https://docs.google.com/document/d/19oWXHbcYH55vZZ6wickjPrLElfaEl4SelRcAHxJwgZU/edit\

for sub_i = 1:length(sub) % for each subject
    
    for ses_i = 1:length(ses)

        jsons = dir(fullfile(projectDir, ['sub-' sub{sub_i}], ['ses-' ses{ses_i}], 'fmap', '*.json'));
        
        for ff = 1:length(jsons) % for each json file
            fname = fullfile(jsons(ff).folder, jsons(ff).name);
            str = fileread(fname);
            val = jsondecode(str);

            kk = 1;
            for zz = 1:length(val.IntendedFor)
               %val.IntendedFor{zz} = ['ses-' subID{ii} '/' val.IntendedFor{zz}];
               val.IntendedFor{zz} = [val.IntendedFor{zz}];
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
    
end

% sometimes in the folder fmap/ there is a file called
% .sub_br_ses_S201_dir_AP_epi.json (hidden file ls -a). To delete move to
% the folder and write the command: 
% system(['find . -name ".*" -exec rm -rf {} \;'])


%% Step 3. Run fmri_prep - you need docker and fmriprep installed to run this step
% create a scratch folder outside the project directory, where you can save
% all the outputs of fmriprep while it is running it, so that you can start
% from there if a process stop and the working directory is constructed outside the Docker image, 
% which may have more constraints than disk space
% https://github.com/nipreps/fmriprep/issues/1291

for sub_i = 1:length(sub) % for each subject

    mkdir(work_dir)
    
    system(['fmriprep-docker -w ' work_dir ...
        ' ' projectDir ...
        ' ' projectDir '/derivatives' ...
        ' participant --participant-label ' sub{sub_i} ...
        ' --fs-license-file /Applications/freesurfer/license.txt' ...
        ' --output-spaces T1w fsaverage MNI152NLin2009cAsym']);
    
end


%% dwi convertion with acquisition parameters
% Run dcm2bids of the diffusion images

for ses_i = 1:length(ses) % for each session 
    
    switch user
        case {'caterina'}
            dcmDir = [baseDir '/sourcedata/sub-' sub{ses_i} '_ses-' ses{ses_i} '_Br_Prf/S' sub{ses_i} '_Br_Prf_Dicom/']; % load the directory of the dicoms
            config = [projectDir '/code/bids_convert_dwi.json'];
        case {'server'}
            dcmDir = [baseDir '/sub-' sub{ses_i} '/sub-' sub{ses_i} '_ses-' ses{ses_i} '_Br_Prf/']; % path on the server
            config = [projectDir '/code/update_github/bids_convert_dwi.json'];
    end
    
    % remove the dwi folder
    system(['rm -r ' projectDir '/sub-' sub{ses_i} '/ses-' ses{ses_i} '/dwi/' ]);
    
    tic
    system(['dcm2bids -d ' dcmDir ...
        ' -o ' projectDir ...
        ' -p ' sub{ses_i} ' -s ' ses{ses_i} ...
        ' -c ' config ' --forceDcm2niix --clobber']);
    toc
    
end


