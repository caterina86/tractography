
% Representation of FA and MD values 
% Import FA values of the Optic Radiations
projectDir = '/Users/cp3488/Documents/tractography/Sample_dMRI'; % location output
lh_OR = importdata(fullfile(projectDir, 'derivatives/mrtrix3/sub-ccad0202/ses-01/lh_OR_FA_100sample.txt'));


% Plot the data
plot(lh_OR.data(1:200,:)');
xlabel('position along tract'); ylabel('FA');


lh_OR = importdata(fullfile(projectDir, 'derivatives/mrtrix3/sub-ccad0202/ses-01/lh_OR_MD_100sample.txt'));


% Plot the data
plot(lh_OR.data(1:200,:)');
xlabel('position along tract'); ylabel('MD');