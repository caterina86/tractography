
% Fit tensors to the diffusion volume and quantify (mean diffusivity and fractional anisotropy)

function s07_fit_tensor(projectDir, subject, session, numFibers_OR, numFibers_OT)

    eddyDir = fullfile(projectDir, 'derivatives/eddy', subject, session);
    fibDir = fullfile(projectDir, '/derivatives/mrtrix3', subject, session);
    topupDir = fullfile(projectDir, 'derivatives/topup', subject, session);

    eddyFile = [subject '_' session '_eddy_corrected_data'];
    bvec = fullfile(eddyDir, [eddyFile '.eddy_rotated_bvecs']);
    bval = fullfile(topupDir, 'bval_combined.txt');

    % Fit tensors to the diffusion volume
    system(['dwi2tensor ' fullfile(eddyDir, [eddyFile '.nii.gz'])  ' -fslgrad ' bvec ' ' bval ' ' fullfile(fibDir, 'tensor.mif')]);

    % Extract MD and FA values from tensors
    system(['tensor2metric ' fullfile(fibDir, 'tensor.mif') ' -fa ' fullfile(fibDir, 'tensor_fa.mif')]);
    system(['tensor2metric ' fullfile(fibDir, 'tensor.mif') ' -adc ' fullfile(fibDir, 'tensor_md.mif')]);

    % Resample the Optic Radiations
    % resample the tract so that diffusion measures can be extracted from 100 evenly spaced points for all fibers
    % TODO: if we will add the AFQ cleaning, change the name of the tracts (2thalFiltered_AFQ.tck)
    system(['tckresample ' fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.tck ']) ...
        fullfile(fibDir,['dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_100sample.tck']) ' -num_points 100'])
    system(['tckresample ' fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_AFQ.tck ']) ...
        fullfile(fibDir,['dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_100sample.tck']) ' -num_points 100'])


    % Resample the Optic Tracts
    system(['tckresample ' fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.tck ']) ...
        fullfile(fibDir,['dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_100sample.tck']) ' -num_points 100'])
    system(['tckresample ' fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_AFQ.tck ']) ...
        fullfile(fibDir,['dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_100sample.tck']) ' -num_points 100'])


    % Sample FA measures from the optic radiations - add force to overwrite them
    system(['tcksample ' fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_fa.mif') ' ' fullfile(fibDir, 'lh_OR_FA_100sample.txt')]);
    system(['tcksample ' fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_fa.mif') ' ' fullfile(fibDir, 'rh_OR_FA_100sample.txt')]);

    % Sample FA measures from the optic tracts
    system(['tcksample ' fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_fa.mif') ' ' fullfile(fibDir, 'lh_OT_FA_100sample.txt')]);
    system(['tcksample ' fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_fa.mif') ' ' fullfile(fibDir, 'rh_OT_FA_100sample.txt')]);



    % Sample MD measures from the optic radiations
    system(['tcksample ' fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_md.mif') ' ' fullfile(fibDir, 'lh_OR_MD_100sample.txt')]);
    system(['tcksample ' fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OR_' num2str(numFibers_OR/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_md.mif') ' ' fullfile(fibDir, 'rh_OR_MD_100sample.txt')]);


    % Sample MD measures from the optic tracts
    system(['tcksample ' fullfile(fibDir, ['dti_lh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_md.mif') ' ' fullfile(fibDir, 'lh_OT_MD_100sample.txt')]);
    system(['tcksample ' fullfile(fibDir, ['dti_rh_fsAnatomical_ACT_OT_' num2str(numFibers_OT/1000) 'k_2thalFiltered_100sample.tck ']) ...
        fullfile(fibDir, 'tensor_md.mif') ' ' fullfile(fibDir, 'rh_OT_MD_100sample.txt')]);


    disp('All done!')

end

