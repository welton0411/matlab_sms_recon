function [maps, weights] = ecalib_3d( ksp, ncalib, ksize)

eigThresh_k = 0.02; % threshold of eigenvectors in k-space
eigThresh_im = 0.9; % threshold of eigenvectors in image space

% Generate ESPIRiT Maps (Takes 30 secs to 1 minute)
%[sx,sy,Nc] = size(ksp);
sz_ksp = size(ksp);
Nc=sz_ksp(4);
sz_calib=[ncalib,ncalib,ncalib,Nc];
%calib = crop(ksp,[ncalib,ncalib,Nc]);
if(sum(sz_ksp==sz_calib)<length(sz_ksp))
   str=sprintf('calib=ksp(');
   for i=1:length(sz_calib),
      idx{i} = [floor(sz_ksp(i)/2)+1+ceil(-sz_calib(i)/2) : floor(sz_ksp(i)/2)+ceil(sz_calib(i)/2)];
      str=sprintf('%s idx{%d},',str,i);
   end
   str=sprintf('%s );',str(1:end-1));
	eval(str);
else
   calib = ksp;
end

% Get maps with ESPIRiT
%[kernel,S] = dat2Kernel(calib,ksize);
if(numel(ksize)==1)
   kSize=repmat(ksize,[1 2 3]);
else
   kSize=ksize;
end
tmp = im2row_3d(calib, kSize);
[tsx,tsy,tsz] = size(tmp);
A = reshape(tmp,tsx,tsy*tsz);

[U,S,V] = svd(A,'econ');
    
kernel = reshape(V,kSize(1),kSize(2),Nc,size(V,2));
S = diag(S);S = S(:);

idx = find(S >= S(1)*eigThresh_k, 1, 'last' );
[M,W] = kernelEig(kernel(:,:,:,1:idx), sz_ksp(1:2));
maps = M(:,:,:,end);

% Weight the eigenvectors with soft-sense eigen-values
weights = W(:,:,end) ;
weights = (weights - eigThresh_im)./(1-eigThresh_im).* (W(:,:,end) > eigThresh_im);
weights = -cos(pi*weights)/2 + 1/2;

