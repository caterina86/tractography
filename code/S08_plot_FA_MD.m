
% Representation of FA and MD values
% Import FA values of the Optic Radiations

% Specify user variable
user = 'server'; % name of the user

% Set the path
switch user
    case {'server'}
        projectDir = '/Volumes/Vision/MRI/Sample_dMRI'; % location output
    case {'caterina'}
        projectDir = '~/Documents/tractography/Sample_dMRI'; % location output
    case {'Omnia'}
        projectDir = '~/Documents/GitHub/tractography/code'; % location output
    case {'bas'}
        projectDir = '~/Documents/MRI/Sample_dMRI'; % location output
    case {'Dalia'}
        projectDir = '~/Desktop/Sample_dMRI'; % location output
    case {'hannah'}
        projectDir = '/Users/hannah/Documents/MRI/Sample_dMRI'; % location output
end


sub_i = 1:length(sub); % loop over subjects (eventually)

for ses_i = 1:numel(dir(fullfile(projectDir, 'rawdata', ['sub-' sub{sub_i}], 'ses-*'))) % for each scan session

  fibDir = fullfile(projectDir, '/derivatives/mrtrix3', ['sub-' sub{sub_i}], ['ses-' ses{ses_i}]);

  lh_FA_OR = importdata(fullfile(fibDir, 'lh_OR_FA_100sample.txt'));
  rh_FA_OR = importdata(fullfile(fibDir, 'rh_OR_FA_100sample.txt'));
  lh_MD_OR = importdata(fullfile(fibDir, 'lh_OR_MD_100sample.txt'));
  rh_MD_OR = importdata(fullfile(fibDir, 'rh_OR_MD_100sample.txt'));
  lh_FA_OT = importdata(fullfile(fibDir, 'lh_OT_FA_100sample.txt'));
  rh_FA_OT = importdata(fullfile(fibDir, 'rh_OT_FA_100sample.txt'));
  lh_MD_OT = importdata(fullfile(fibDir, 'lh_OT_MD_100sample.txt'));
  rh_MD_OT = importdata(fullfile(fibDir, 'rh_OT_MD_100sample.txt'));

end


% Plot the data
plot(lh_FA_OR.data(1:200,10:90)');
xlabel('position along tract'); ylabel('FA');
title('FA Left OR');

plot(rh_FA_OR.data(1:200,10:90)');
xlabel('position along tract'); ylabel('FA');
title('FA Right OR')

plot(lh_FA_OT.data(:,10:90)');
xlabel('position along tract'); ylabel('FA');
title('FA Left OT');

plot(rh_FA_OT.data(1:200,10:90)');
xlabel('position along tract'); ylabel('FA');
title('FA Right OT')
