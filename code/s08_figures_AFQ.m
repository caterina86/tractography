function s08_figures_AFQ(projectDir, subject, session, numFibers_OT, numFibers_OR, fmriprep)

% Visualize tracts on the t1

rawDir = fullfile(projectDir, 'rawdata', subject, session);
t1Dir = fullfile(rawDir, 'anat');
t1ACPCFileName = 't1_acpc.nii.gz';
t1ACPC = niftiRead(fullfile(t1Dir,filesep,t1ACPCFileName));
AFQDir = fullfile(projectDir, 'derivatives/AFQ', subject, session);

if fmriprep == 1
    t1FileCropBrainDiffSpace = fullfile(fmriprepDir, 'anat/', [subject '_' session '_desc-preproc_T1w_crop_brain_diffspace.nii.gz']);
else
    t1FileCropBrainDiffSpace = fullfile(anatPrepDir, 't1_crop_brain_diffspace.nii.gz');
end
    
% load the tracts
load(fullfile(AFQDir, [subject '_' session '_fg_clean.mat']));

% choose the colors for the tracts
colorstring = [0.3686    0.0667    0.2549; ...
    0.9961    0.4000    0.2824; ...
    0.9804    0.8392    0.2471; ...
    0.5843    0.0196    0.1137; ...
    0    0.4392    0.5569; ...
    0.7490    0.9216    0.7529; ...
    0.9216    0.5137    0.1255; ...
    0.0510    0.6471    0.7608; ...
    0.6706    0.6745    0.6863; ...
    0.7451    0.7804    0.9451; ...
    0.6000    0.3765    0.5961; ...
    0.4863    0.5686    0.2902; ...
    0.1333    0.5098    0.5020; ...
    0.9804    0.6196    0.5176; ...
    0    0.6353    0.0118; ...
    0.8314    0.8510    0.6667; ...
    0.8941    0.0314    0.6196; ...
    0.4118    0.8471    0.9255; ...
    0    0.1725    0.5608; ...
    0.9255    0.7961    0.7961; ...
    0.7608    0.6824    0.8745; ...
    0    0.9294    0.7490; ...
    1.0000    0.6510    0.7961];

% Late visual pathways
AFQ_RenderFibers(fg_clean(15),'numfibers',600,'color',colorstring(2,:));  % SLF
AFQ_RenderFibers(fg_clean(13),'numfibers',600,'color',colorstring(3,:),'newfig',false);  % ILF 
AFQ_RenderFibers(fg_clean(9),'numfibers',600,'color',colorstring(17,:),'newfig',false);  % CFMajor
AFQ_RenderFibers(fg_clean(11),'numfibers',600,'color',colorstring(8,:),'newfig',false);  % IFOF
% Then add one slice of the T1 as overlay for the 3d rendering.
AFQ_AddImageTo3dPlot(t1ACPC,[-2, 0, 0], [], [], 0.5);

% Non-visual pathways
AFQ_RenderFibers(fg_clean(17),'numfibers',600,'color',colorstring(5,:));  % UF
AFQ_RenderFibers(fg_clean(5),'numfibers',600,'color',colorstring(19,:),'newfig',false);  % CC 
AFQ_RenderFibers(fg_clean(10),'numfibers',600,'color',colorstring(4,:),'newfig',false);  % CFMinor
AFQ_RenderFibers(fg_clean(3),'numfibers',600,'color',colorstring(11,:),'newfig',false);  % CST
% Then add one slice of the T1 as overlay for the 3d rendering.
AFQ_AddImageTo3dPlot(t1ACPC,[-2, 0, 0], [], [], 0.5);


% single tracts
AFQ_RenderFibers(fg_clean(5),'numfibers',600,'color',colorstring(19,:));  % CC 
AFQ_AddImageTo3dPlot(t1ACPC,[-2, 0, 0], [], [], 0.5);

AFQ_RenderFibers(fg_clean(17),'numfibers',600,'color',colorstring(5,:));  % UF
AFQ_AddImageTo3dPlot(t1ACPC,[-2, 0, 0], [], [], 0.5);

AFQ_RenderFibers(fg_clean(10),'numfibers',600,'color',colorstring(4,:));  % CFMinor
AFQ_AddImageTo3dPlot(t1ACPC,[-2, 0, 0], [], [], 0.5);

AFQ_RenderFibers(fg_clean(3),'numfibers',600,'color',colorstring(11,:));  % CST
AFQ_AddImageTo3dPlot(t1ACPC,[-2, 0, 0], [], [], 0.5);

AFQ_RenderFibers(fg_clean(15),'numfibers',600,'color',colorstring(2,:));  % SLF
AFQ_AddImageTo3dPlot(t1ACPC,[-10, 0, 0], [], [], 0.5);

AFQ_RenderFibers(fg_clean(13),'numfibers',600,'color',colorstring(3,:));  % ILF 
AFQ_AddImageTo3dPlot(t1ACPC,[-10, 0, 0], [], [], 0.5);

AFQ_RenderFibers(fg_clean(9),'numfibers',600,'color',colorstring(17,:));  % CFMajor
AFQ_AddImageTo3dPlot(t1ACPC,[-10, 0, 0], [], [], 0.5);

AFQ_RenderFibers(fg_clean(11),'numfibers',600,'color',colorstring(8,:));  % IFOF
AFQ_AddImageTo3dPlot(t1ACPC,[-10, 0, 0], [], [], 0.5);




%% MRTrix3 fibers on the T1 coregistered to diffusion space:
fibDir = fullfile(projectDir, '/derivatives/mrtrix3', subject, session);

% from .tck to .pdb
mrtrix_tck2pdb([fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.tck'])], ...
    [fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.pdb'])]);
mrtrix_tck2pdb([fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.tck'])], ...
    [fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.pdb'])]);

mrtrix_tck2pdb([fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.tck'])], ...
    [fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.pdb'])]);
mrtrix_tck2pdb([fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.tck'])], ...
    [fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.pdb'])]);
    
    
fiberName = {['dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.pdb'], ...
    ['dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.pdb'], ...
    ['dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.pdb'], ...
    ['dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.pdb']};
    
direction = 'AP';

OR_lh = fullfile(fibDir, fiberName{1});
OR_lh = dtiAlignFiberDirection((dtiLoadFiberGroup(OR_lh)),direction);
OR_rh = fullfile(fibDir, fiberName{2});
OR_rh = dtiAlignFiberDirection((dtiLoadFiberGroup(OR_rh)),direction);

OT_lh = fullfile(fibDir, fiberName{3});
OT_lh = dtiAlignFiberDirection((dtiLoadFiberGroup(OT_lh)),direction);
OT_rh = fullfile(fibDir, fiberName{4});
OT_rh = dtiAlignFiberDirection((dtiLoadFiberGroup(OT_rh)),direction);

% Optic Radiations
AFQ_RenderFibers(OR_lh,'numfibers',600,'color',colorstring(13,:));  % left OR
AFQ_RenderFibers(OR_rh,'numfibers',600,'color',colorstring(13,:),'newfig',false);  % right OR
AFQ_RenderFibers(OT_lh,'numfibers',600,'color',colorstring(7,:),'newfig',false);  % left OT
AFQ_RenderFibers(OT_rh,'numfibers',600,'color',colorstring(7,:),'newfig',false);  % right OT
AFQ_AddImageTo3dPlot(t1FileCropBrainDiffSpace,[0, 0, -10], [], [], 0.5);

% Optic Tracts
AFQ_RenderFibers(OT_lh,'numfibers',600,'color',colorstring(7,:));  % left OT
AFQ_RenderFibers(OT_rh,'numfibers',600,'color',colorstring(7,:),'newfig',false);  % right OT
AFQ_AddImageTo3dPlot(t1FileCropBrainDiffSpace,[0, 0, -10], [], [], 0.5);

end