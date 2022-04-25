% Plot AFQ and OT/OR profiles

clear variables
setup_user; % initialize

% %% Convert cell array to table
% load(fullfile(projectDir, 'derivatives', 'afq', 'sub-0201_fa_md_values.mat'));
% temp = results(:,1:2);
% for ii = 1:size(results,1)
%     temp{ii,3} = cell2mat(results(ii,3:end));
% end
% 
% tract_profiles = cell2table(temp,...
%     "VariableNames",["Tract" "Measure" "Values"])
% 
% cd(fullfile(projectDir, 'derivatives', 'afq'))
% save('sub-0201_fa_md_values_table.mat', 'tract_profiles')


%% load data
load(fullfile(projectDir, 'derivatives', 'afq', 'sub-0201_fa_md_values_table.mat'));

%% set figure formatting defaults
line_width = 2;
set(0, 'DefaultLineLineWidth', line_width);
font_size = 14;
set(0, 'DefaultAxesFontSize', font_size);

%% plot sample data
myrows_lh = startsWith(tract_profiles.Tract, 'Left OR') & startsWith(tract_profiles.Measure, 'FA');
myrows_rh = startsWith(tract_profiles.Tract, 'Right OR') & startsWith(tract_profiles.Measure, 'FA');

toplot_lh = tract_profiles.Values(myrows_lh,:);
toplot_rh = tract_profiles.Values(myrows_rh,:);

figure, hold on
plot(toplot_lh)
plot(toplot_rh)

legend({'Left hemisphere', 'Right hemisphere'})
xlabel('Location along tract')
ylabel('Diffusivity (MD)')


%% compare across hemispheres
myrows_lh = startsWith(tract_profiles.Tract, 'Left') & startsWith(tract_profiles.Measure, 'MD');
myrows_rh = startsWith(tract_profiles.Tract, 'Right') & startsWith(tract_profiles.Measure, 'MD');

toplot_lh = tract_profiles.Values(myrows_lh,:);
toplot_rh = tract_profiles.Values(myrows_rh,:);

figure, hold on
plot(toplot_lh', 'Color', 'b')
plot(toplot_rh', 'Color', 'r')

% legend({'Left hemisphere', 'Right hemisphere'})
xlabel('Location along tract')
ylabel('Diffusivity (MD)')

%% do statistics

% since you are testing the same tract in both hemispheres, will this be a
% paired or unpaired t-test?

% we have 100 numbers for each tract, so what should we test?

mean(toplot_lh)

% gives you the mean across tracts, not locations

means_lh = mean(toplot_lh, 2); % take the mean along the second dimension
means_rh = mean(toplot_rh, 2);

ttest(means_lh, means_rh);
% ans = 1, what does that mean?

[h,p,ci,stats] = ttest(means_lh, means_rh)
% provides more detail

% which hemisphere gives you larger values?
grandmean_lh = mean(toplot_lh(:)) % grand mean
grandmean_rh = mean(toplot_rh(:)) % grand mean


%% Optional: let's look back at the tract profile figure, any concerns?

% There are some funky values at the beginning and ends of the tracts
% You can cut them out and redo the analysis

range_to_include = 10:90;
toplot_lh_cut = toplot_lh(:,range_to_include);
toplot_rh_cut = toplot_rh(:,range_to_include);

% redo statistics
means_lh_cut = mean(toplot_lh_cut, 2); % take the mean along the second dimension
means_rh_cut = mean(toplot_rh_cut, 2);

[h,p,ci,stats] = ttest(means_lh_cut, means_rh_cut)


%% Class Assignment 
% It is generally suspected that lateralization
% increases as you move from posterior to anterior parts of the brain. 

% Divide the tracts up in three groups based on their overall 
% location in the brain (posterior, anterior , and neither) 
% based on the information provided in this paper - 
% https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0049790 

% Report your results of your analyses

% Optionally, classify tracts based on other criteria instead, such
% as function (motor, sensoryO or modality (visual, auditory) and perform similar analyses 
