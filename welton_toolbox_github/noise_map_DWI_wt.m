function [sigma, trace] = noise_map_DWI_wt(img, bvec, threshold, median_kernel, gauss_kernel)
%NOISE_MAP_DWI    Noise map generation using DWIs at a low b-shell.
%   [Y, XT] = noise_map_DWI(X, G, T, mw, gw) generates a noise map Y from
%   DWIs X at a low b-shell in directions G by creating multiple trace
%   images. The trace images are calculated by repeatedly averaing 3 DWIs
%   with almost orthogonal directions. The standard of orthogonality is
%   controled by the threshold T of the sum of absolute values of inner
%   products.
%
%   The preliminary noise map is obtained from the standard deviation of
%   trace images and further smoothed by applying median filter of width mw
%   and Gaussian filter of width gw. The mean trace images is outputed as
%   XT.
%
%   X: Nx, Ny, Nz, Ng
%   G: Nx, 3
%   T, mw, gw: scalars
%
%   Author: Hong-Hsi Lee, HLEE84@mgh.harvard.edu
%   Martinos Center, Charlestown, MA, 2023
 
    zsign = sign(bvec(:,3));
    zsign(zsign==0) = 1;
    bvec(:,1) = bvec(:,1).*zsign;
    bvec(:,2) = bvec(:,2).*zsign;
    bvec(:,3) = bvec(:,3).*zsign;
   
    n  = bvec;
    Nn = size(n,1);
    ip = zeros(Nn,1);   % sum of absolute value of inner product
    It = zeros(Nn,3);   % index
    for i = 1:Nn
        [~,I] = min(abs(n*n(i,:).'));
        x = cross(n(i,:),n(I,:));
        [~,J] = max(abs(n*x.'));
        ip(i) = abs(n(i,:)*n(I,:).') + abs(n(i,:)*n(J,:).') + abs(n(I,:)*n(J,:).');
        It(i,1) = i;
        It(i,2) = I;
        It(i,3) = J;
    end
    C = sort(It, 2);
    C = unique(C, 'rows');
    ip = zeros(size(C,1),1);
    for i = 1:size(C,1)
        ip(i) = abs(n(C(i,1),:)*n(C(i,2),:).') + ...
            abs(n(C(i,1),:)*n(C(i,3),:).') + ...
            abs(n(C(i,2),:)*n(C(i,3),:).');
    end
    I = find(ip<threshold);
    [nx,ny,nz,~] = size(img);
    trace = zeros(nx,ny,nz,numel(I));
    for i = 1:numel(I)
        trace(:,:,:,i) = mean(img(:,:,:,C(I(i),:)),4);
    end
    sigma = std(trace, 0, 4) * sqrt(3);
    sigma = medfilt3(sigma, median_kernel);
    sigma = imgaussfilt3(sigma, gauss_kernel);
end
