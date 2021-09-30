
% from dicoms to nifti
% dependencies: dcm2bids 
setenv('PATH', [getenv('PATH') ':/usr/local/bin:~/opt/anaconda3/bin']);

baseDir = '/Users/cp3488/Documents/tractography/Sample_dMRI/'; % Update with path to clinical data
subIDs = {'0201'}; % change the name of identification number of the subject
% ses = {'01'}; % ID of the session
% num_runs = 1; % of functional scans


%% Run dcm2bids in the shell wrapped in matlab and modify the .json in the code folder

for ii = 1:length(ses) % for each session
    
    dcmDir = [baseDir 'sourcedata/Sub' subIDs{ii} '_Br_Prf_Dicom'];
    config = [baseDir 'code/bids_convert.json'];

    tic
    % from dicoms to nifti
    system(['dcm2bids -d ' dcmDir ...
        ' -o ' [baseDir 'rawdata/'] ...
        ' -p ' subIDs{ii} ' -s ' ses{ii} ...
        ' -c ' config ' --forceDcm2niix --clobber']);
    toc
    
end
