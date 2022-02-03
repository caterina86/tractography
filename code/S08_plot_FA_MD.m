
% Representation of FA and MD values
% Import FA values of the Optic Radiations

clearvars;
setup_parameters;


%% Plot the FA/MD values extracted from the tract

for sub_i = 1:length(sub) % loop over subjects
    
    sub_ses = dir(fullfile(projectDir, 'rawdata', sub{sub_i}, 'ses-*'));

    for ses_i = 1:numel(sub_ses) % for each scan session

        fibDir = fullfile(projectDir, '/derivatives/mrtrix3', sub{sub_i}, ses{ses_i});

        % extract FA/MD values from OR and OT for all participants
        lh_FA_OR(sub_i) = importdata(fullfile(fibDir, 'lh_OR_FA_100sample.txt'));
        rh_FA_OR(sub_i) = importdata(fullfile(fibDir, 'rh_OR_FA_100sample.txt'));
        lh_MD_OR(sub_i) = importdata(fullfile(fibDir, 'lh_OR_MD_100sample.txt'));
        rh_MD_OR(sub_i) = importdata(fullfile(fibDir, 'rh_OR_MD_100sample.txt'));
        lh_FA_OT(sub_i) = importdata(fullfile(fibDir, 'lh_OT_FA_100sample.txt'));
        rh_FA_OT(sub_i) = importdata(fullfile(fibDir, 'rh_OT_FA_100sample.txt'));
        lh_MD_OT(sub_i) = importdata(fullfile(fibDir, 'lh_OT_MD_100sample.txt'));
        rh_MD_OT(sub_i) = importdata(fullfile(fibDir, 'rh_OT_MD_100sample.txt'));    
    
    end
end


% Plot the data - left OR - FA values
figure;
FA_OR_left = [mean(lh_FA_OR(1).data,1); mean(lh_FA_OR(2).data,1); mean(lh_FA_OR(3).data,1)];
plot(FA_OR_left(1,:), 'linewidth',2); hold on;
plot(FA_OR_left(2,:), 'linewidth',2); hold on;
plot(FA_OR_left(3,:), 'linewidth',2); hold on;
plot(FA_OR_left(4,:), 'linewidth',2);
xlabel('Location'); ylabel('Fractional Anisotropy'); 
ylim([0 1]); xticklabels({'', '10', '', '', '', '', '', '', '', '90'});  
set(gca,'FontSize',24); %set(gca,'xtick',[])
xline(11,'k--'); xline(90,'k--'); 
title('Left OR - FA values','FontSize', 28);
fgNames={'sub-0201', 'sub-0152', 'sub-0228'};
legend(fgNames,'Location','EastOutside','FontSize',14);

   
% Plot the data - right OR - FA values
figure;
FA_OR_right = [mean(rh_FA_OR(1).data,1); mean(rh_FA_OR(2).data,1); mean(rh_FA_OR(3).data,1)];
plot(FA_OR_right(1,:), 'linewidth',2); hold on;
plot(FA_OR_right(2,:), 'linewidth',2); hold on;
plot(FA_OR_right(3,:), 'linewidth',2); hold on;
plot(FA_OR_right(4,:), 'linewidth',2);
xlabel('Location'); ylabel('Fractional Anisotropy'); 
ylim([0 1]); xticklabels({'', '10', '', '', '', '', '', '', '', '90'});  
set(gca,'FontSize',24); %set(gca,'xtick',[])
xline(11,'k--'); xline(90,'k--'); 
title('Right OR - FA values','FontSize', 28);
fgNames={'sub-0201', 'sub-0152', 'sub-0228'};
legend(fgNames,'Location','EastOutside','FontSize',14);
    
    
    
% Plot the data - left OT - FA values
figure;
FA_OT_left = [mean(lh_FA_OT(1).data,1); mean(lh_FA_OT(2).data,1); mean(lh_FA_OT(3).data,1)];
plot(FA_OT_left(1,:), 'linewidth',2); hold on;
plot(FA_OT_left(2,:), 'linewidth',2); hold on;
plot(FA_OT_left(3,:), 'linewidth',2); hold on;
plot(FA_OT_left(4,:), 'linewidth',2);
xlabel('Location'); ylabel('Fractional Anisotropy'); 
ylim([0 1]); xticklabels({'', '10', '', '', '', '', '', '', '', '90'});  
set(gca,'FontSize',24); %set(gca,'xtick',[])
xline(11,'k--'); xline(90,'k--'); 
title('Left OT - FA values','FontSize', 28);
fgNames={'sub-0201', 'sub-0152', 'sub-0228'};
legend(fgNames,'Location','EastOutside','FontSize',14);

   
% Plot the data - right OT - FA values
figure;
FA_OT_right = [mean(rh_FA_OT(1).data,1); mean(rh_FA_OT(2).data,1); mean(rh_FA_OT(3).data,1)];
plot(FA_OT_right(1,:), 'linewidth',2); hold on;
plot(FA_OT_right(2,:), 'linewidth',2); hold on;
plot(FA_OT_right(3,:), 'linewidth',2); hod on;
plot(FA_OT_right(4,:), 'linewidth',2);
xlabel('Location'); ylabel('Fractional Anisotropy'); 
ylim([0 1]); xticklabels({'', '10', '', '', '', '', '', '', '', '90'});  
set(gca,'FontSize',24); %set(gca,'xtick',[])
xline(11,'k--'); xline(90,'k--'); 
title('Right OT - FA values','FontSize', 28);
fgNames={'sub-0201', 'sub-0152', 'sub-0228'};
legend(fgNames,'Location','EastOutside','FontSize',14);
    
    

%% LME 
% calculate mean FA/MD for OR and OT
a = mean(lh_FA_OT(2).data,1);
b = mean(a);
c = mean(rh_FA_OT(2).data,1);
d = mean(c);

(b+d)/2





f = readtable('/Users/cp3488/Documents/tractography/Sample_dMRI/derivatives/Measures.xlsx');

% LME with Age and group as fixed-effects / Subject as random effect
for ii = 4:7 % Pulling pathway names from VariableNames
    
    disp(f.Properties.VariableNames{ii});

    % lmeResults{ii} = fitlme(d, [d.Properties.VariableNames{ii} ' ~ AgeAtMeasurementDays + LogDaysSinceSurgery + AgeAtSurgeryDays : LogDaysSinceSurgery + (1|Manuscript_NEW)']);
    lmeResults{ii} = fitlme(f, [f.Properties.VariableNames{ii} ' ~ Age + Group + (1|SubjectID)']);

    % lmeResults{ii} = fitlme(d, [d.Properties.VariableNames{ii} ' ~ AgeAtSurgeryDays * LogDaysSinceSurgery + (1|Manuscript_NEW)']);
    anova(lmeResults{ii})
end

