%function [im2 CombW]= coilCombine_wt2( im1, seltidx )
function im2= coilCombine_wt2( im1, sel_tidx )
% Function: coilCombine
%
% Description: combine multi-coil image sequences
%
% Based on: Walsh DO, Gmitro AF, Marcellin MW. Adaptive reconstruction of
% phased array MR imagery. Magn Reson Med 2000;43:682-690
% 
% Parameters:
% im1: the multi-coil images (size [nx,ny,nz,ncoils])
%
% Returns: 
% im2: the coil-combined images (size [nx,ny,nz])
%
% Author: Diego Hernando
% Date created: August 13, 2011
% Date last modified: December 8, 2011

% Let's make the coil dimension the fourth one and the TE the third
%im1 = permute(im1,[1 2 4 3]);

% Get image dimensions and set filter size
[sx,sy,sz,C,st] = size(im1);
filtsize = 7;
%im1_avg=mean(im1,5);
im1_avg=mean(im1(:,:,:,:,sel_tidx),5);
% Initialize
im2 = zeros(sx,sy,sz,st,'like',im1);
%CombW = zeros(sx,sy,sz,C,'like',im1);

for kz=1:sz,
   Rs = zeros(sx,sy,C,C);

   % Get correlation matrices
   for kc1=1:C,
     for kc2=1:C,
         %Rs(:,:,kc1,kc2) = filter2(ones(filtsize),im1(:,:,kz,kc1).*conj(im1(:,:,kz,kc2)),'same');
         Rs(:,:,kc1,kc2) = filter2(ones(filtsize),im1_avg(:,:,kz,kc1).*conj(im1_avg(:,:,kz,kc2)),'same');
     end
   end
   % Compute and apply filter at each voxel
   for kx=1:sx
     for ky=1:sy
   % $$$     [U,S] = eig(squeeze(Rs(kx,ky,:,:)));
   % $$$     s = diag(S);
   % $$$     [maxval,maxind] = max(abs(s));
   % $$$     myfilt = U(:,maxind);    
   % $$$     im2(kx,ky,:) = myfilt'*reshape(squeeze(im1(kx,ky,:,:)).',[C N]);
   
       % Change suggested by Mark Bydder
       %[U,S] = svd(squeeze(Rs(kx,ky,:,:)));
       %myfilt = U(:,1); 
       [U,S] = eig(squeeze(Rs(kx,ky,:,:)));
       [dummy maxidx]=max(diag(S));
       myfilt = U(:,maxidx);
       im2(kx,ky,kz,:) = reshape(myfilt'*reshape(im1(kx,ky,kz,:,:),C,[]),[1 1 1 st]);
       %CombW(kx,ky,kz,:) = myfilt';
     end
   end
end

%% In case the input data are single
%if strcmp(class(im1),'single')
%  im2 = single(im2);
%end

