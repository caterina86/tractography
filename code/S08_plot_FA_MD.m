% Plot (and test) FA and MD values as a function of position along tract

clearvars;
setup_user;

sub = {'sub-0201'}; % 'sub-0152' 'sub-0228' 'sub-ccad0203'}; % initials of the subject
ses = {'ses-01'}; % ID of the session
hemi = {'lh', 'rh'};


%% Plot the FA/MD values extracted from the tract

for sub_i = 1:length(sub) % loop over subjects
    
    sub_ses = dir(fullfile(projectDir, 'rawdata', sub{sub_i}, 'ses-*'));

    for ses_i = 1:numel(sub_ses) % for each scan session

        fibDir = fullfile(projectDir, '/derivatives/mrtrix3', sub{sub_i}, ses{ses_i});

        % extract FA/MD values from OR and OT for participants
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


%% Plot the data - OR - FA values
fontSize = 14;
figure;
FA_OR_left = [nanmean(lh_FA_OR(1).data,1)]; % TODO: do not hardcode #subjects; nanmean(lh_FA_OR(2).data,1); nanmean(lh_FA_OR(3).data,1) ; nanmean(lh_FA_OR(4).data,1)];
FA_OR_right = [nanmean(rh_FA_OR(1).data,1)]; % nanmean(rh_FA_OR(2).data,1); nanmean(rh_FA_OR(3).data,1); nanmean(rh_FA_OR(3).data,1)];
plot(FA_OR_right(1,:), 'linewidth',2); hold on;
plot(FA_OR_left(1,:), 'linewidth',2); hold on;
% plot(FA_OR_left(2,:), 'linewidth',2); hold on;
% plot(FA_OR_left(3,:), 'linewidth',2); hold on;
% plot(FA_OR_left(4,:), 'linewidth',2);
xlabel('Location'); ylabel('Fractional Anisotropy'); 
ylim([0 1]);  
set(gca,'FontSize', fontSize); %set(gca,'xtick',[])
xline(11,'k--'); xline(90,'k--'); 
title('Optic Radiation - FA values','FontSize', fontSize);
legend({'left hemi', 'right hemi'},'Location','northeast','FontSize',fontSize); 
% legend(sub,'Location','northeast','FontSize',fontSize);

    
% Plot the data - OT - FA values
figure;
FA_OT_left = [nanmean(lh_FA_OT(1).data,1)]; % nanmean(lh_FA_OT(2).data,1); nanmean(lh_FA_OT(3).data,1); nanmean(lh_FA_OT(4).data,1)];
FA_OT_right = [nanmean(rh_FA_OT(1).data,1)]; % nanmean(rh_FA_OT(2).data,1); nanmean(rh_FA_OT(3).data,1) ; nanmean(rh_FA_OT(4).data,1)];
plot(FA_OT_left(1,:), 'linewidth',2); hold on;
plot(FA_OT_right(1,:), 'linewidth',2); hold on;

xlabel('Location'); ylabel('Fractional Anisotropy'); 
ylim([0 1]);
set(gca,'FontSize',fontSize); %set(gca,'xtick',[])
xline(11,'k--'); xline(90,'k--'); 
title('Optic Tract - FA values','FontSize', fontSize);
legend({'left hemi', 'right hemi'},'Location','northeast','FontSize',fontSize); 
% legend(sub,'Location','EastInside','FontSize',fontSize);    

%% LME 
% calculate mean FA/MD for OR and OT
% a = nanmean(lh_FA_OR(4).data,1);
% b = nanmean(a);
% c = nanmean(rh_FA_OR(4).data,1);
% d = nanmean(c);
% 
% (b+d)/2


f = readtable(fullfile(projectDir, 'derivatives/Measures.xlsx')); % where is this file?

% LME with Age and group as fixed-effects / Subject as random effect
for ii = 4:5 % Pulling pathway names from VariableNames
    
    disp(f.Properties.VariableNames{ii});
    lmeResults{ii} = fitlme(f, [f.Properties.VariableNames{ii} ' ~ Age + Group + (1|SubjectID)']);
    anova(lmeResults{ii})
end

