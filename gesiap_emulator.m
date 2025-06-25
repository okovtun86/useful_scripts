clear all;clc
%% parameter definition
filename = 'dLight.tif';           % Input tif file
psfSigma = 1;                      % gaussian PSF sigma for deconvolution
numIter = 20;                      % Landweber iterations
gaussianSigma = 1;                 % sigma for Gaussian denoising
bgDiskRadius = 50;                 % radius for morphological background sub
dffBaselineFrames = 1:25;          % frames used for F0 calculation

%% load the tif stack
info = imfinfo(filename);
nFrames = numel(info);
imgSize = [info(1).Height, info(1).Width];
rawStack = zeros([imgSize, nFrames]);

for k = 1:nFrames
    rawStack(:,:,k) = double(imread(filename, k)) / 65535;
end

%% drift correction
optimizer = registration.optimizer.RegularStepGradientDescent;
metric = registration.metric.MeanSquares;
aligned = zeros(size(rawStack));
ref = rawStack(:,:,1);
aligned(:,:,1) = ref;

for k = 2:nFrames
    mov = rawStack(:,:,k);
    tform = imregtform(mov, ref, 'translation', optimizer, metric);
    aligned(:,:,k) = imwarp(mov, tform, 'OutputView', imref2d(size(ref)));
end


%% landweber decon
PSF = fspecial('gaussian', 15, psfSigma);
decon = zeros(size(aligned));

for k = 1:nFrames
    f = aligned(:,:,k);
    u = f;
    for iter = 1:numIter
        r = f - conv2(u, PSF, 'same');
        u = u + conv2(r, rot90(PSF,2), 'same');
        u(u<0) = 0;
    end
    decon(:,:,k) = u;
end

%% Gaussian filter denoising
denoised = zeros(size(decon));
for k = 1:nFrames
    denoised(:,:,k) = imgaussfilt(decon(:,:,k), gaussianSigma);
end


%% background subtraction
bgSubtracted = zeros(size(denoised));
se = strel('disk', bgDiskRadius);
for k = 1:nFrames
    b = imopen(denoised(:,:,k), se);
    bgSubtracted(:,:,k) = denoised(:,:,k) - b;
end


%% ΔF/F₀ calculation
F0 = median(bgSubtracted(:,:,dffBaselineFrames), 3);
dFF = zeros(size(bgSubtracted));
for k = 1:nFrames
    dFF(:,:,k) = (bgSubtracted(:,:,k) - F0) ./ F0;
end

%% visualize a single frame
figure; 
imagesc(dFF(:,:,27), [0.5 5]); 
axis image off;
colorbar;
title('\DeltaF/F_0 Heatmap');
caxis([0.5 5]);


%% save as the new tif stack

outputFile = 'processed_dFF_float32.tif';
t = Tiff(outputFile, 'w');

tagstruct.ImageLength = size(dFF,1);
tagstruct.ImageWidth = size(dFF,2);
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample = 32;
tagstruct.SamplesPerPixel = 1;
tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
tagstruct.RowsPerStrip = size(dFF,1);
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Compression = Tiff.Compression.None;

for k = 1:nFrames
    setTag(t, tagstruct);
    write(t, single(dFF(:,:,k)));
    if k < nFrames
        writeDirectory(t);
    end
end

close(t);

