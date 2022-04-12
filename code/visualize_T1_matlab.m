nifti = load_nifti('t1_crop_brain_diffspace.nii.gz');

imagesc(makeimagestack(nifti.vol(:,:,:)));
colormap(gray);
axis equal tight off;
colorbar;



% Visualize the volume of the T1
mriVolume = squeeze(nifti.vol(:,:,1:20));
B = imrotate3(mriVolume,90,[0 0 1],'nearest','loose','FillValues',0);
volshow(B);
