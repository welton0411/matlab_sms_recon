function [I_recon header] = mb3d_grappa_wt3(train_img, collapse_img_t, header, varargin)
%function [I_recon header] = mb3d_grappa_wt3(train_img, collapse_img_t, header, varargin)
%	
%	Wei-Tang Chang, UNC-Chapel Hill
%  Feb. 15, 2024
%
% Usage			: slice-GRAPPA with option of SPSG
% Input arguments:
%  train_img: The training data with matrix dimension of [N_pe x N_fe x (N_slc*N_pae) x N_ch]
%             N_pe  is the number of phase encoding
%             N_fe  is the number of frequency encoding
%             N_slc is the number of slice number
%             N_ch is the number of receiving channels
%  collapse_img_t: The collapsed image (SMS data) with dimension of [N_pe x N_fe x N_sg x N_ch x N_pae x N_rep]
%             N_sg  is the number of SMS excitation (= N_slc / N_sms where N_sms is the SMS acceleration rate)
%             N_ch  is the number of receiving channels
%             N_rep is the number of repetition
%  header: the structural variable of imaging protocol
%  (optional)
%     flag_regularization: 0- No GRAPPA regularization; 1- GRAPPA regularization applied (default)
%     sampdata_dtype: 0- use the average image across time as the sampled dataset (default); 1- use the first image; 2- use the last image
%     flag_apply_exist_kernel: 0- do not apply existed GRAPPA kernel; 1- apply existed GRAPPA kernel
%     flag_debug: 0 - do not show figures/messages for debug; 1- show figures/messages for debug
%
% output:
%  I_recon  : the reconstructed image with matrix dimension of [N_pe x N_fe x N_slc x N_ch x N_pae x N_rep]
%
% References:   Blipped-CAIPI for SMS EPI, Kawin Setsompop, Magnetic Resonance in Medicne, 67:1210-1224 (2012)

%if(isempty(gcp))
%   p=parpool('local',12);
%end

collapse_img=[];
%flag_slcdep_kernel = 1;
flag_regularization=1;
reg_ratio=0.001;
sampdata_dtype=0;
parfourier_ratio=1;
flag_apply_exist_kernel=0;
flag_coilcompress=0;
num_coilcompress=16;
flag_whiten=0;
flag_apply1stkernel=0;
flag_debug=0;
recon_space=0; %unit: 0: reconstruct in image space; 1: reconstruct in k-space
flag_parfour_recon=0;
flag_spsg=0;
spsg_weight=1.0;
k_pat_stidx=1;
k_pat_endidx=0;
mb3d_randph=[];
%flag_slc_joint_est=0;
%flag_slc_fft=0;
phscramble_mode=1;

for i=1:floor(length(varargin)/2)
   option=varargin{i*2-1};
   option_value=varargin{i*2};
   switch lower(option)
      %case 'flag_slcdep_kernel'
      %   flag_slcdep_kernel=option_value;
      case 'collapse_img',
         collapse_img=option_value;
      case 'flag_regularization'
         flag_regularization=option_value;
      case 'reg_ratio',
         reg_ratio=option_value;
      case 'sampdata_dtype',
         sampdata_dtype=option_value;
      case 'parfourier_ratio',
         parfourier_ratio=option_value;
      case 'flag_apply_exist_kernel',
         flag_apply_exist_kernel=option_value;
      case 'flag_coilcompress',
         flag_coilcompress=option_value;
      case 'num_coilcompress',
         num_coilcompress=option_value;
      case 'flag_whiten',
         flag_whiten=option_value;
      case 'flag_apply1stkernel',
         flag_apply1stkernel=option_value;
      case 'flag_debug',
         flag_debug=option_value;
      case 'flag_flip_disp',
         flag_flip_disp=option_value;
      case 'recon_space',
         recon_space=option_value;
      case 'flag_parfour_recon',
         flag_parfour_recon=option_value;
      case 'flag_spsg',
         flag_spsg=option_value;
      case 'spsg_weight',
         spsg_weight=option_value;
      case 'k_pat_stidx',
         k_pat_stidx=option_value;
      case 'k_pat_endidx',   
         k_pat_endidx=option_value;
      case 'mb3d_randph',
         mb3d_randph=option_value;
      case 'phscramble_mode',
         phscramble_mode=option_value;
      %case 'flag_slc_joint_est',
      %   flag_slc_joint_est=option_value;
      %case 'flag_slc_fft',
      %   flag_slc_fft=option_value;
      otherwise
          fprintf('unknown option [%s]!\n',option);
          fprintf('error!\n');
          return;
   end
end

if(flag_coilcompress==0)
   I_recon = zeros(header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, header.Nrep,'single');
else
   I_recon = zeros(header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, num_coilcompress, header.Nrep,'single');
end

[N1, N2, Nsep, Nc, Nshot, Nrep] = size(collapse_img_t);
collapse_img_t(find(~isfinite(collapse_img_t(:))))=0;

header.PEshift=k_pat_stidx-1; %round((1-parfourier_ratio)*header.Npe);
header.range_fe = ceil((100 - header.percent) * header.Nfe / 200):header.Nfe - ceil((100 - header.percent) * header.Nfe / 200);
%if( (header.Npe-round(parfourier_ratio*header.Npe)+1) > ceil((100 - header.percent) * header.Npe / 200) )
if(header.PEshift > ceil((100 - header.percent) * header.Npe / 200))
   header.range_pe = (header.PEshift+1):header.Npe - ceil((100 - header.percent) * header.Npe / 200);
else
   header.range_pe = ceil((100 - header.percent) * header.Npe / 200):header.Npe - ceil((100 - header.percent) * header.Npe / 200);
end

if(isempty(collapse_img))
   if(sampdata_dtype==0)
      collapse_img = mean(collapse_img_t,6);
   elseif(sampdata_dtype==1)
      collapse_img = collapse_img_t(:,:,:,:,:,1);
   elseif(sampdata_dtype==2)
      collapse_img = collapse_img_t(:,:,:,:,:,end);
   else
      %do nothing
   end
end

if(flag_apply_exist_kernel==0)
   if(isfield(header,'K_kernel'))
      header=rmfield(header,'K_kernel');
   end
   if(isfield(header,'I_kernel'))
      header=rmfield(header,'I_kernel');
   end
end

minidx_fe=header.range_fe(1);
maxidx_fe=header.range_fe(end);
%if(header.range_fe(1)-header.grappa_width_fe < 1)
%   minidx_fe=header.grappa_width_fe+1;
%end

if(header.range_fe(1)-floor((header.grappa_width_fe-1)/2) < 1)
   minidx_fe=floor((header.grappa_width_fe-1)/2)+1;
end
%if(header.range_fe(end)+header.grappa_width_fe > header.Nfe)
%   maxidx_fe=header.Nfe-header.grappa_width_fe;
%end
if(header.range_fe(end)+ceil((header.grappa_width_fe-1)/2) > header.Nfe)
   maxidx_fe=header.Nfe-ceil((header.grappa_width_fe-1)/2);
end
index2fit_fe=[minidx_fe:1:maxidx_fe];

if(header.pat>1)
   tmp_array=[k_pat_stidx:header.pat:k_pat_endidx];
   tmp_endidx=tmp_array(end);
   %full_L=numel([tmp_endidx:-header.pat:1]);
   %if(mod(tmpL,2)==0) %even
   %   num_samp_deduc=1;
   %else
   %   num_samp_deduc=0;
   %end
   %full_L=tmpL-num_samp_deduc;
   
   full_sampidx_pe=fliplr([tmp_endidx:-header.pat:1]);
   
   %if(header.PEshift>0)
   %   %if(header.pat<6)
   %   %   skip_sampidx_pe=[2:header.pat:header.PEshift];
   %   %   sampidx_pe=setdiff(full_sampidx_pe,skip_sampidx_pe);
   %   %   if((num_samp_deduc>0) && (header.pat~=2))
   %   %      for nidx=1:num_samp_deduc,
   %   %         sampidx_pe=[sampidx_pe,sampidx_pe(end)+header.pat];
   %   %      end
   %   %   end
   %   %else
   %   %   fprintf('ERROR!! Acceleration factor of %d with partial fourier is not supported yet!\n',header.pat);
   %   %   return;
   %   %end
   %   sampidx_pe=[k_pat_stidx:header.pat:k_pat_endidx];
   %   acsidx_pe=[k_pat_stidx:1:k_pat_endidx];
   %else
   %   sampidx_pe=full_sampidx_pe;
   %   acsidx_pe=[k_pat_stidx:1:k_pat_endidx];
   %end
   
   sampidx_pe=[k_pat_stidx:header.pat:k_pat_endidx];
   acsidx_pe=[k_pat_stidx:1:k_pat_endidx];
else
   full_sampidx_pe=[1:1:header.Npe];
   if(header.PEshift>0)
      skip_sampidx_pe=[1:1:header.PEshift];
      sampidx_pe=setdiff(full_sampidx_pe,skip_sampidx_pe);
   else
      sampidx_pe=full_sampidx_pe;
   end
   acsidx_pe=sampidx_pe;
end
header.range_pe=intersect(header.range_pe,sampidx_pe);
%header.range_pe=intersect(header.range_pe,acsidx_pe);

minidx_pe=header.range_pe(1);
maxidx_pe=header.range_pe(end);

%if(header.range_pe(1)-header.pat*floor((header.grappa_width_pe-1)/2) < (header.Npe-round(parfourier_ratio*header.Npe)+1))
if(header.range_pe(1)-header.pat*floor((header.grappa_width_pe-1)/2) < sampidx_pe(1) )
   %tmpidx=find((header.range_pe-header.pat*floor((header.grappa_width_pe-1)/2))>(header.Npe-round(parfourier_ratio*header.Npe)));
   tmpidx=find((header.range_pe-header.pat*floor((header.grappa_width_pe-1)/2))>= sampidx_pe(1) );
   minidx_pe=header.range_pe(tmpidx(1));
end
%if(header.range_pe(end)+header.pat*ceil((header.grappa_width_pe-1)/2) > header.Npe)
if(header.range_pe(end)+header.pat*ceil((header.grappa_width_pe-1)/2) > sampidx_pe(end))
   %tmpidx=find((header.range_pe+header.pat*ceil((header.grappa_width_pe-1)/2))<=header.Npe);
   tmpidx=find((header.range_pe+header.pat*ceil((header.grappa_width_pe-1)/2))<=sampidx_pe(end));
   maxidx_pe=header.range_pe(tmpidx(end));
end
%index2fit_pe_all=[minidx_pe:header.pat:maxidx_pe];
index2fit_pe_all=[minidx_pe:1:maxidx_pe];
for bidx=1:header.blip_shift,
   for patidx=1:header.pat,
      [dummy tmpidx_array]=intersect(index2fit_pe_all,[sampidx_pe(bidx)+patidx-1:header.blip_shift*header.pat:sampidx_pe(end)]);
      index2fit_pe{bidx}{patidx}=index2fit_pe_all(tmpidx_array(1):header.blip_shift*header.pat:end);
      [sub2fit_pe{bidx}{patidx} sub2fit_fe]=ndgrid(index2fit_pe{bidx}{patidx},index2fit_fe);
      ind2fit{bidx}{patidx}=sub2ind([header.Npe header.Nfe],reshape(sub2fit_pe{bidx}{patidx},[],1),reshape(sub2fit_fe,[],1));
      sub4fit_lutable{bidx}{patidx}=[];
      for tidx=1:numel(ind2fit{bidx}{patidx}),
         %fprintf('patidx=%d, tidx=%d\n',patidx,tidx);
         range4fit_fe=[sub2fit_fe(tidx)-floor((header.grappa_width_fe-1)/2):1:sub2fit_fe(tidx)+ceil((header.grappa_width_fe-1)/2)];
         tmp_perange=[sub2fit_pe{bidx}{patidx}(tidx)-header.pat*floor((header.grappa_width_pe-1)/2):1:sub2fit_pe{bidx}{patidx}(tidx)+header.pat*ceil((header.grappa_width_pe-1)/2)];
         range4fit_pe{bidx}{patidx}=intersect(tmp_perange,sampidx_pe);
         [sub4fit_pe{bidx}{patidx} sub4fit_fe]=ndgrid(range4fit_pe{bidx}{patidx},range4fit_fe);
         ind4fit=sub2ind([header.Npe header.Nfe],reshape(sub4fit_pe{bidx}{patidx},[],1),reshape(sub4fit_fe,[],1));
         if(isempty(sub4fit_lutable{bidx}{patidx}))
            sub4fit_lutable{bidx}{patidx}=zeros(numel(ind4fit),numel(ind2fit{bidx}{patidx}),'single');
         end
         sub4fit_lutable{bidx}{patidx}(:,tidx)=ind4fit;
      end
   end %end of for patidx=1:header.pat,
end %end of for bidx=1:header.blip_shift,

if(flag_coilcompress==1)
   fprintf('Coil compression and whitening ...\n');
   %gre=header.refI_recon;
   gre=train_img;
   fctr = size(gre,1)*size(gre,2);
   X = fftshift(ifft(ifftshift(gre,1),[],1),1);
   gre = fftshift(ifft(ifftshift(X,2),[],2),2) * sqrt(fctr);
   gre = gre(1+round(N1/4):N1-round(N1/4),:,:,:);
   [n(1), n(2), ~, ~] = size(gre);
   % zero pad patref k-space
   rref = padarray(gre, ([N1,N2]-n)/2);
   X = fftshift(fft(ifftshift(rref,1),[],1),1);
   rref = fftshift(fft(ifftshift(X,2),[],2),2) / sqrt(fctr);

   if(~isempty(header.noise_data))
      noise_matrix = header.noise_data;
      nmat = permute(noise_matrix, [2, 1]);
      nmat = reshape(nmat, size(nmat, 1), prod(size(nmat))/size(nmat, 1));
   else
      fprintf('ERROR! The noise_data is needed for coil compression\n');
      return;
   end
   
   [rx, ry, rz, rc] = size(rref);
   % SVD to get coil compression matrix.
   rref = reshape(rref, rx * ry * rz, rc).';
   [u, s, ~] = svd(rref, 'econ');
   u = u(:, 1:num_coilcompress);
   s = diag(s);

   % Coil compressing noise.
   nmat = u' * nmat;
   
   % Estimating whitening matrix.
   covm = (nmat * nmat')/(size(nmat, 2) - 1);
   whmt = inv(chol(covm, 'lower'));
   whmt=whmt./max(max(abs(whmt)));

   % Joint coil compression and whitening matrix.
   whtcc = whmt * u';
   
   % Whiten and coil compress reference data.
   rref = whtcc * rref;
   % rref = u'*rref;
   rref = rref.';
   whtcc_ref = reshape(rref, rx, ry, rz, num_coilcompress);
   header.whtcc=whtcc;
   header.whtcc_ref=whtcc_ref;
   
   %Nc_orig=Nc;
   %Nc=num_coilcompress;
   acc_charray=reshape(permute(collapse_img_t,[4 1 2 3 5 6]),header.Nch,[]);
   header.Nch_orig=header.Nch;
   header.Nch=num_coilcompress;
   collapse_img_t=ipermute(reshape(header.whtcc*acc_charray,[header.Nch header.Npe header.Nfe header.Nsep, header.num_slc_pae, header.Nrep]),[4 1 2 3 5 6]);
   
   acc_charray=reshape(permute(collapse_img,[4 1 2 3 5]),header.Nch_orig,[]);
   collapse_img=ipermute(reshape(header.whtcc*acc_charray,[header.Nch, header.Npe, header.Nfe, header.Nsep, header.num_slc_pae]),[4 1 2 3 5]);
   acc_charray=[];
   
   train_img_orig=train_img;
   train_img=reshape(permute(train_img_orig,[4 1 2 3]),header.Nch_orig,[]);
   train_img=ipermute(reshape(header.whtcc*train_img,[header.Nch,header.Npe,header.Nfe,header.Nslc*header.num_slc_pae]),[4 1 2 3]);
else
   if(flag_whiten==1)
      fprintf('Whitening ...\n');
      if(~isempty(header.noise_data))
         noise_matrix = header.noise_data;
         nmat = permute(noise_matrix, [2, 1]);
         nmat = reshape(nmat, size(nmat, 1), prod(size(nmat))/size(nmat, 1));
      else
         fprintf('ERROR! The noise_data is needed for coil compression\n');
         return;
      end
      
      % Estimating whitening matrix.
      covm = (nmat * nmat')/(size(nmat, 2) - 1);
      whmt = inv(chol(covm, 'lower'));
      whmt=whmt./max(max(abs(whmt)));
      
      header.whmt=whmt;
      header.whtcc_ref=[];
      
      acc_charray=reshape(permute(collapse_img_t,[4 1 2 3 5 6]),header.Nch,[]);
      %header.Nch_orig=header.Nch;
      collapse_img_t=ipermute(reshape(header.whmt*acc_charray,[header.Nch header.Npe header.Nfe header.Nsep, header.num_slc_pae, header.Nrep]),[4 1 2 3 5 6]);
      
      acc_charray=reshape(permute(collapse_img,[4 1 2 3 5]),header.Nch,[]);
      %header.Nch_orig=header.Nch;
      collapse_img=ipermute(reshape(header.whmt*acc_charray,[header.Nch header.Npe header.Nfe header.Nsep, header.num_slc_pae]),[4 1 2 3 5]);
      acc_charray=[];
      
      train_img_orig=train_img;
      train_img=reshape(permute(train_img_orig,[4 1 2 3]),header.Nch,[]);
      train_img=ipermute(reshape(header.whmt*train_img,[header.Nch,header.Npe,header.Nfe,header.Nslc*header.num_slc_pae]),[4 1 2 3]);
   else
      %header.C0invsqrt=[];
      header.whtcc=[];
      header.whtcc_ref=[];
      header.whmt=[];
   end
end %end of if(flag_whiten==1)

K_kernel_perslc=[];
I_kernel_perslc=[];
flag_kernel_exist=0;
%blipidx_mtx=zeros(header.blip_shift,header.grappa_width_pe);
line_centeridx=floor(header.Npe/2)+1;
idxdiff_min=Inf;
for bidx1=1:header.blip_shift,
   tmp_pidx=find((index2fit_pe{bidx1}{1}-line_centeridx)>=0);
   tmp_min=min(index2fit_pe{bidx1}{1}(tmp_pidx)-line_centeridx);
   if(tmp_min<idxdiff_min)
      idxdiff_min=tmp_min;
      center_bgrpidx=bidx1;
   end
end
%center_bgrpidx=mod(line_centeridx,header.blip_shift);
bgrp_temparray=mod([1:header.blip_shift*ceil(header.grappa_width_pe/header.blip_shift)]',header.blip_shift);
bgrp_temparray(find(bgrp_temparray==0))=header.blip_shift;
tmp_array=find(bgrp_temparray==center_bgrpidx);
kernel_centeridx=ceil(header.grappa_width_pe/2);
bgrp_array=circshift(bgrp_temparray,kernel_centeridx-tmp_array(1));
for bidx1=1:header.blip_shift,
   %tmp_bgrp_array=circshift(bgrp_array,1-bidx1);
   tmp_bgrp_array=circshift(bgrp_array,center_bgrpidx-bidx1);
   tmp_bgrp_array=tmp_bgrp_array(1:header.grappa_width_pe);
   blipidx_mtx{bidx1}=zeros(header.blip_shift,header.grappa_width_pe);
   for bidx2=1:header.blip_shift,
      blipidx_mtx{bidx1}(bidx2,find(tmp_bgrp_array==bidx2))=1;
   end %end of for bidx2=1:header.blip_shift,
end %end of for bidx1=1:header.blip_shift,

%if(isempty(gcp))
%   parpool;
%end
cnt_fig=1;

if(isfield(header,'K_kernel'))
   flag_kernel_exist=1;
end

base_stidx=mod(header.base_slcidx,header.Nsep);
base_stidx(find(base_stidx==0))=header.Nsep; 
%for gidx=1:numel(base_stidx),
%   tmp_array=[base_stidx(gidx):numel(header.base_slcidx):header.Nslc*header.num_slc_pae];
%   header.mb3d_groupset(:,:,gidx)=reshape(tmp_array,[header.num_slc_pae,header.sms_factor])';
%end

fillup_idx_array=[];
for gidx=1:header.Nsep,
   tmp_array=repmat([floor((gidx-1)/2)*2:header.Nsep:header.Nslc-1]*header.num_slc_pae,[header.num_slc_pae 1]);
   tmp_array=tmp_array + repmat([2-mod(gidx,2):2:header.num_slc_pae*2]',[1 header.sms_factor]);
   fillup_idx_array(:,gidx)=tmp_array(:);
end
%fillup_idx_array=fillup_idx_array(base_stidx,:);
header.img_fillup_idxmtx=reshape(fillup_idx_array,[header.num_slc_pae,header.sms_factor,header.Nsep]);

kMask=zeros(header.Npe,1);
peidx_array=sampidx_pe';
kMask(peidx_array)=1;
N1idx_array=find(kMask>eps);
tmp_step=mean(diff(N1idx_array));
preN1idx_array=fliplr([N1idx_array(1)-tmp_step:-tmp_step:1])';

%symPEsamp=N1/2-N1idx_array(1)+1;
%symPEsamp_ratio=2*symPEsamp/N1;
%symFEsamp=round(symPEsamp_ratio*N2/2);

z_pos_vec=([0:header.sms_factor-1]-floor(header.sms_factor/2))*header.Nsep*Nshot; %(-(header.sms_factor-1)/2 + [0:1:(header.sms_factor-1)])*header.sms_gap;
tmpidx_fe =[floor(header.Nfe/2)+1-floor((header.grappa_width_fe-1)/2):1:floor(header.Nfe/2)+1+ceil((header.grappa_width_fe-1)/2)];
%tmpidx_pe =[floor(header.Npe/2)+1-floor((header.grappa_width_pe-1)/2):1:floor(header.Npe/2)+1+ceil((header.grappa_width_pe-1)/2)];

if(isfield(header,'K_kernel'))
   flag_kernel_exist=1;
end

base_stidx=mod(header.base_slcidx,header.Nsep);
base_stidx(find(base_stidx==0))=header.Nsep; 
for gidx=1:numel(base_stidx),
   tmp_array=[base_stidx(gidx):numel(header.base_slcidx):header.Nslc*header.num_slc_pae];
   header.mb3d_groupset(:,:,gidx)=reshape(tmp_array,[header.num_slc_pae,header.sms_factor])';
end

blip_moment=zeros(N1,1);
preA=2*pi*(header.blip_shift-1)/(2.0*header.blip_shift*header.Nsep*Nshot);
dA=-2*pi/(header.blip_shift*header.Nsep*Nshot);
tmp_bmoment=preA + dA*mod([0:1:(numel(N1idx_array)-1)]',header.blip_shift);
blip_moment(N1idx_array)=tmp_bmoment;
rp_cycle=header.blip_shift;
num_cycle=ceil(numel(preN1idx_array)/rp_cycle);
if(num_cycle>0)
   st_postidx=num_cycle*rp_cycle+1-numel(preN1idx_array);
   blip_moment(preN1idx_array)=tmp_bmoment(st_postidx:st_postidx+numel(preN1idx_array)-1);
end
%tmp_momentmtx=repmat(blip_moment,[1,N1*Nmb3d]);
BlipMtx=repmat(blip_moment(N1idx_array),[1,header.Nfe,header.sms_factor,header.Nch]);
BlipMtx=BlipMtx.*repmat(reshape(z_pos_vec,[1 1 header.sms_factor 1]),[numel(N1idx_array),header.Nfe,1,header.Nch]);

for bslc_idx=1:numel(header.base_slcidx),
   for sidx=1:header.sms_factor,
      fprintf('Processing baseSlice #%d, SMS slice #%d...\n',header.base_slcidx(bslc_idx),header.sms_groupset(bslc_idx,sidx));
      
      if(phscramble_mode==0)
         tmp_rndph=ones(header.num_slc_pae,header.sms_factor);
      elseif(phscramble_mode==1)
         tmp_ph=repmat(flipdim(reshape(mb3d_randph{header.sms_factor},[1, header.sms_factor]),2),[header.num_slc_pae, 1]);
         tmp_rndph=reshape(exp(-1j*tmp_ph),[header.num_slc_pae,header.sms_factor]);
      elseif(phscramble_mode==2)
         %tmp_rndph=reshape(exp(-1j*mb3d_randph{header.num_slc_pae*header.sms_factor}),[header.num_slc_pae,header.sms_factor]);
         tmp_rndph=reshape(exp(-1j*fliplr(mb3d_randph{header.num_slc_pae*header.sms_factor})),[header.num_slc_pae,header.sms_factor]);
      end
      
      for pidx=1:header.num_slc_pae,
         %if(flag_spsg==1)
            %%%% synthesize the blipped-CAIPI image for single slice %%%%
            train_itemp_syn=squeeze(train_img(:,:,header.mb3d_groupset(:,pidx,bslc_idx),:)); %[N_pe x N_fe x N_sms x N_ch]
            train_itemp_syn=train_itemp_syn.*repmat(reshape(tmp_rndph(pidx,:),[1 1 header.sms_factor 1]),[header.Npe,header.Nfe,1,header.Nch]);
            train_ktemp_syn=fftshift(fftshift(ifft(ifft(fftshift(fftshift(train_itemp_syn,1),2),[],1),[],2),1),2);
            train_kspace_syn=zeros(size(train_ktemp_syn),'single'); %[N_pe x N_fe x N_sms x N_ch]
            train_kspace_syn(N1idx_array,:,:,:)=train_ktemp_syn(N1idx_array,:,:,:).*exp(1j*BlipMtx);
            train_kspace_syn_trgslc=train_kspace_syn(:,:,sidx,:);
         %end
         
         train_ispace_data=reshape(train_img(:,:,header.mb3d_groupset(sidx,pidx,bslc_idx),:),[header.Npe,header.Nfe,header.Nch]); %[N_pe x N_fe x N_ch x N_pae]
         %tmp_ispace_data=reshape(train_ispace_data,[header.Npe,header.Nfe,header.Nch,header.num_slc_pae]);
         %collapse_ispace_data_t=reshape(collapse_img_t(:,:,bslc_idx,:,pidx,:),[header.Npe,header.Nfe,header.Nch,header.Nrep]); %[N_pe x N_fe x N_ch x N_pae x N_rep]
         clear K_kernel_perslc; clear I_kernel_perslc;
         for chidx = 1:header.Nch,
            collapse_kspace_data_t{chidx}=squeeze(fftshift(fftshift(ifft(ifft(ifftshift(ifftshift(collapse_img_t(:,:,bslc_idx,chidx,pidx,:),1),2),[],1),[],2),1),2)); %[N_pe x N_fe x N_ch x N_rep]
            tmpI_perchidx{chidx}=zeros([header.Npe,header.Nfe,header.Nrep],'single');
            train_kspace_data{chidx}=fftshift(fftshift(ifft2(ifftshift(ifftshift(squeeze(train_ispace_data(:,:,chidx)),1),2)),1),2);
         end
         
         for chidx = 1:header.Nch,
         %parfor chidx = 1:header.Nch,
            if(~flag_kernel_exist)
               if((bslc_idx>1) && (flag_apply1stkernel==1))
                  %K_kernel_perslc=K_kernel_perbase{sidx}{chidx};
                  %I_kernel_perslc=I_kernel_perbase{sidx}{chidx};
               else
                  K_kernel_perslc=zeros(header.Nch,header.Npe,header.Nfe,header.blip_shift);
                  I_kernel_perslc=zeros(header.Nch,header.Npe,header.Nfe,header.blip_shift);
               end
            else
               if((bslc_idx>1) && (flag_apply1stkernel==1))
                  %K_kernel_perslc=K_kernel_perbase{sidx}{chidx};
                  %I_kernel_perslc=I_kernel_perbase{sidx}{chidx};
               else
                  K_kernel_perslc=header.K_kernel{bslc_idx}{sidx}{chidx}{pidx};
                  I_kernel_perslc=header.I_kernel{bslc_idx}{sidx}{chidx}{pidx};
               end
            end
            
            if(~flag_kernel_exist)
               for bidx=1:header.blip_shift,
                  for patidx=1:header.pat,
                     %train_kspace_data=fftshift(fftshift(ifft2(ifftshift(ifftshift(squeeze(train_ispace_data(:,:,chidx)),1),2)),1),2);
                     %tmp_array=permute(train_kspace_data{chidx},[3 1 2]);
                     train_y=reshape(train_kspace_data{chidx}(ind2fit{bidx}{patidx}),[],1);
                     
                     if(flag_spsg==0)
                        collapse_ispace_data=permute(reshape(collapse_img(:,:,bslc_idx,:,pidx),[header.Npe,header.Nfe,header.Nch]),[3 1 2]); %[N_ch x N_pe x N_fe]
                        collapse_kspace_data=fftshift(fftshift(ifft(ifft(ifftshift(ifftshift(collapse_ispace_data,2),3),[],2),[],3),2),3); %[N_ch x N_pe x N_fe]
                        collapse_x=reshape(collapse_kspace_data(:,sub4fit_lutable{bidx}{patidx}(:)),[header.Nch size(sub4fit_lutable{bidx}{patidx},1) size(sub4fit_lutable{bidx}{patidx},2)]);
                        collapse_x=reshape(permute(collapse_x,[3 1 2]),numel(train_y),[]);
                     else
                        kspace_syn_all_x=permute(train_kspace_syn,[3 4 1 2]);
                        kspace_syn_all_x=reshape(kspace_syn_all_x(:,:,sub4fit_lutable{bidx}{patidx}(:)),[header.sms_factor header.Nch size(sub4fit_lutable{bidx}{patidx},1) size(sub4fit_lutable{bidx}{patidx},2)]);
                        kspace_syn_all_x=reshape(permute(kspace_syn_all_x,[4 2 3 1]),[numel(train_y),numel(sub4fit_lutable{bidx}{patidx})*header.Nch/numel(train_y),header.sms_factor]);
                        
                        kspace_syn_trg_x=permute(reshape(train_kspace_syn_trgslc,[header.Npe,header.Nfe,header.Nch]),[3 1 2]);
                        kspace_syn_trg_x=reshape(kspace_syn_trg_x(:,sub4fit_lutable{bidx}{patidx}(:)),[header.Nch size(sub4fit_lutable{bidx}{patidx},1) size(sub4fit_lutable{bidx}{patidx},2)]);
                        kspace_syn_trg_x=reshape(permute(kspace_syn_trg_x,[3 1 2]),numel(train_y),[]);
                     end
                     %collapse_ispace_data=permute(reshape(collapse_img(:,:,bslc_idx,:,pidx),[header.Npe,header.Nfe,header.Nch]),[3 1 2]); %[N_ch x N_pe x N_fe]
                     %collapse_kspace_data=fftshift(fftshift(ifft(ifft(ifftshift(ifftshift(collapse_ispace_data,2),3),[],2),[],3),2),3); %[N_ch x N_pe x N_fe]
                     %collapse_x=reshape(collapse_kspace_data(:,sub4fit_lutable{bidx}{patidx}(:)),[header.Nch size(sub4fit_lutable{bidx}{patidx},1) size(sub4fit_lutable{bidx}{patidx},2)]);
                     %collapse_x=reshape(permute(collapse_x,[3 1 2]),numel(train_y),[]);
                     
                     if(flag_spsg==0)
                        if(size(collapse_x,1)<size(collapse_x,2))
                           fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! !\n');
                           fprintf('slice_grappa_wt.m: the number of unknowns is higher than the number of training points!\n');
                           fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! !\n');
                           %return;
                        end
                           
                        if(flag_regularization==1)
                           %[tu ts tv]=svds(collapse_x,1);
                           %tmp_tol=ts*reg_ratio; %regularization
                           %k_coefficient = pinv(collapse_x,tmp_tol)*train_y; %[N_ch*(2*header.grappa_width_pe+1)*(2*header.grappa_width_fe+1) x 1]
                           %[tu ts tv]=svds(collapse_x,min(size(collapse_x)));
                           [tu ts tv]=svd(collapse_x,0);
                           %[tu ts tv]=svdecon(collapse_x);
                           lambda=max(diag(ts))*reg_ratio;
                           td=diag(ts)./(diag(ts).^2+ones(size(diag(ts)))*(lambda.^2));
                           tD=diag(td);
                           k_coefficient = tv*tD*(tu')*train_y;
                        else
                           k_coefficient = inv(collapse_x'*collapse_x)*(collapse_x')*train_y; %[N_ch*(2*header.grappa_width_pe+1)*(2*header.grappa_width_fe+1) x 1]
                        end
                     else
                        if(size(kspace_syn_trg_x,1)<size(kspace_syn_trg_x,2))
                           fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! !\n');
                           fprintf('slice_grappa_wt.m: the number of unknowns is higher than the number of training points!\n');
                           fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! !\n');
                           %return;
                        end
                        
                        spsg_w_vec=spsg_weight*ones(size(kspace_syn_all_x,3),1);
                        spsg_w_vec(sidx)=1;
                        kspace_syn_sum_x=zeros([size(kspace_syn_all_x,2),size(kspace_syn_all_x,2)]);
                        for ss=1:size(kspace_syn_all_x,3),
                           kspace_syn_sum_x=kspace_syn_sum_x+(spsg_w_vec(ss)^2)*kspace_syn_all_x(:,:,ss)'*kspace_syn_all_x(:,:,ss);
                        end
                        
                        if(flag_regularization==1)
                           [tu ts tv]=svd(kspace_syn_sum_x,0);
                           lambda=max(diag(ts))*(reg_ratio^2);
                           td=diag(ts)./(diag(ts).^2+ones(size(diag(ts)))*(lambda.^2));
                           tD=diag(td);
                           k_coefficient = tv*tD*(tu')*((spsg_w_vec(sidx)^2)*kspace_syn_trg_x')*train_y;
                        else
                           k_coefficient = inv(kspace_syn_sum_x'*kspace_syn_sum_x)*((spsg_w_vec(sidx)^2)*kspace_syn_trg_x')*train_y; %[N_ch*(2*header.grappa_width_pe+1)*(2*header.grappa_width_fe+1) x 1]
                        end
                     end
                     %disp(toc);
                     tmpidx_fe =[floor(header.Nfe/2)+1-floor((header.grappa_width_fe-1)/2):1:floor(header.Nfe/2)+1+ceil((header.grappa_width_fe-1)/2)];
                     %tmpidx_pe =[floor(header.Npe/2)+1-floor((header.grappa_width_pe-1)/2):1:floor(header.Npe/2)+1+ceil((header.grappa_width_pe-1)/2)];
                     tmprange_pe=[line_centeridx-header.pat*floor((header.grappa_width_pe-1)/2):1:line_centeridx+header.pat*ceil((header.grappa_width_pe-1)/2)];
                     tmpidx_pe =[line_centeridx-header.pat*floor((header.grappa_width_pe-1)/2):header.pat:line_centeridx+header.pat*ceil((header.grappa_width_pe-1)/2)]+1-patidx;
                     for bidx2=1:header.blip_shift,
                        fillin_idx=find(blipidx_mtx{bidx}(bidx2,:)>0);
                        tmpcoeffidx_pe=intersect(tmprange_pe,tmpidx_pe(fillin_idx));
                        valididx_pe=intersect(tmprange_pe,tmpidx_pe);
                        [dummy tmpfillin_idx]=intersect(valididx_pe,tmpidx_pe(fillin_idx));
                        tmp_mtx=reshape(k_coefficient,[header.Nch,numel(valididx_pe),numel(tmpidx_fe)]);
                        
                        %tmp_blipidx_mtx=circshift(blipidx_mtx,1-bidx,1);
                        K_kernel_perslc(:,valididx_pe(tmpfillin_idx),tmpidx_fe,bidx2)=tmp_mtx(:,tmpfillin_idx,:);
                     end
                  end %end of for patidx=1:header.pat,
               end %end of for bidx=1:header.blip_shift,
               
               K_kernel_perslc=flipdim(K_kernel_perslc,2);
               K_kernel_perslc=flipdim(K_kernel_perslc,3);
            end %end of if(~flag_kernel_exist)
         
            ima_all=zeros(header.Nch,header.Npe,header.Nfe,header.Nrep);
            %tmp_kernel=zeros(header.Nch,header.Npe,header.Nfe);
            
            %collapse_ispace_data_t=reshape(collapse_img_t(:,:,bslc_idx,:,pidx,:),[header.Npe,header.Nfe,header.Nch,header.Nrep]); %[N_pe x N_fe x N_ch x N_pae x N_rep]
            %collapse_kspace_data_t=fftshift(fftshift(ifft(ifft(ifftshift(ifftshift(collapse_ispace_data_t,1),2),[],1),[],2),1),2); %[N_pe x N_fe x N_ch x N_rep]
            if(recon_space==0)
               for chidx2=1:header.Nch,
                  for bidx=1:header.blip_shift,
                     tmp_kdatamtx=zeros(header.Npe,header.Nfe,header.Nrep);
                     tmp_kdatamtx(sampidx_pe(bidx):header.blip_shift*header.pat:sampidx_pe(end),:,:)=reshape(collapse_kspace_data_t{chidx2}(sampidx_pe(bidx):header.blip_shift*header.pat:sampidx_pe(end),:,:),[numel([sampidx_pe(bidx):header.blip_shift*header.pat:sampidx_pe(end)]),header.Nfe,header.Nrep]);
                     %tmp_idatamtx=ifftshift(ifftshift(fft(fft(fftshift(fftshift(tmp_kdatamtx,1),2),[],1),[],2),1),2);
                     tmp_idatamtx=fftshift(fftshift(fft(fft(ifftshift(ifftshift(tmp_kdatamtx,1),2),[],1),[],2),1),2);
                     if(~flag_kernel_exist)
                        I_kernel_perslc(chidx2,:,:,bidx)=fftshift(fftshift(fft2(ifftshift(ifftshift(squeeze(K_kernel_perslc(chidx2,:,:,bidx)),1),2)),1),2);
                     end
                     %keyboard;
                     ima_all(chidx2,:,:,:)=ima_all(chidx2,:,:,:)+reshape(repmat(squeeze(I_kernel_perslc(chidx2,:,:,bidx)),[1 1 header.Nrep]).*tmp_idatamtx,[1,header.Npe,header.Nfe,header.Nrep]);
                  end
               end
            else
               %for chidx2=1:header.Nch,
               %   for bidx=1:header.blip_shift,
               %      tmp_kdatamtx=zeros(header.Npe,header.Nfe,header.Nrep);
               %      tmp_kdatamtx(sampidx_pe(bidx):header.blip_shift*header.pat:sampidx_pe(end),:,:)=squeeze(collapse_kspace_data_t(sampidx_pe(bidx):header.blip_shift*header.pat:sampidx_pe(end),:,chidx2,:));
               %      tmpKernel=squeeze(K_kernel_perslc(chidx2,:,:,bidx));
               %      tmpKernel=flipdim(tmpKernel,1); tmpKernel=flipdim(tmpKernel,2);
               %      cropKernel=tmpKernel(tmpidx_pe(1):tmpidx_pe(end),tmpidx_fe(1):tmpidx_fe(end));
               %      cropKernel=flipdim(cropKernel,1); cropKernel=flipdim(cropKernel,2); 
               %      for tidx=1:header.Nrep,
               %         tmpK=conv2(squeeze(tmp_kdatamtx(:,:,tidx)),cropKernel,'same');
               %         tmpK2=zeros(size(tmpK));
               %         if((header.pat>1) || (header.PEshift>0))
               %            %tmpK2(sampidx_pe(1)+header.pat*floor((header.grappa_width_pe-1)/2):sampidx_pe(end)-header.pat*ceil((header.grappa_width_pe-1)/2),:)=tmpK(sampidx_pe(1)+header.pat*floor((header.grappa_width_pe-1)/2):sampidx_pe(end)-header.pat*ceil((header.grappa_width_pe-1)/2),:);
               %            tmpK2(sampidx_pe(2):sampidx_pe(end),:)=tmpK(sampidx_pe(2):sampidx_pe(end),:);
               %         else
               %            tmpK2=tmpK;
               %         end
               %         ima_all(chidx2,:,:,tidx)=ima_all(chidx2,:,:,tidx)+reshape(fftshift(fftshift(fft2(fftshift(fftshift(tmpK2,1),2)),1),2),[1,header.Npe,header.Nfe,1]);
               %      end
               %   end
               %end
               
               %not yet implemented
            end
            
            %tmp_recon_all(chidx,:,:,:)=squeeze(sum(ima_all,1)); %[N_pe x N_fe x N_rep]
            tmpI_perchidx{chidx}=squeeze(sum(ima_all,1));
            %%%% correct the shift along x and y axes due to i-space recon %%%%
            tmpI_perchidx{chidx}=fftshift(fftshift(ifft(ifft(ifftshift(ifftshift(tmpI_perchidx{chidx},1),2),[],1),[],2),1),2);
            tmpI_perchidx{chidx}=circshift(tmpI_perchidx{chidx},1,1);
            tmpI_perchidx{chidx}=circshift(tmpI_perchidx{chidx},1,2);
            tmpI_perchidx{chidx}=fftshift(fftshift(fft(fft(ifftshift(ifftshift(tmpI_perchidx{chidx},1),2),[],1),[],2),1),2);
            
            %I_recon(:,:,header.mb3d_groupset(sidx,pidx,bslc_idx),chidx,:)=squeeze(sum(ima_all,1)); %[N_pe x N_fe x N_rep]
            
            if((flag_parfour_recon==1) && (header.PEshift>0))
               if(header.pat==1)
                  demod_mtx=[];
                  for tidx=1:header.Nrep,
                     tmpK=fftshift(fftshift(ifft2(fftshift(fftshift(squeeze(sum(ima_all(:,:,:,tidx),1)),1),2)),1),2);
                     tmpK2=tmpK(sampidx_pe(1):end,:);
                     if(mod(tidx-1,header.num_slc_pae)==0)
                        demod_mtx=[];
                        [mtxIfull demod_mtx]=parfour_recon_wt(tmpK2,[header.Npe,header.Nfe],'demod_mtx',demod_mtx);
                     else
                        [mtxIfull demod_mtx]=parfour_recon_wt(tmpK2,[header.Npe,header.Nfe],'demod_mtx',demod_mtx);
                     end
                     tmpI_perchidx{chidx}(:,:,tidx)=reshape(mtxIfull,[header.Npe,header.Nfe,1,1,1]);
                  end
               end
            end
            
            %w_kernel(chidx,:,:,:)=squeeze(I_kernel_perslc(:,:,:)); %for g-factor calculation
            
            if(~flag_kernel_exist)
               %header.K_kernel{bslc_idx}{sidx}{chidx}{pidx}=K_kernel_perslc;
               %header.I_kernel{bslc_idx}{sidx}{chidx}{pidx}=I_kernel_perslc;
            end
         end %end of parfor chidx = 1:header.Nch
      
         for chidx = 1:header.Nch,
            I_recon(:,:,header.mb3d_groupset(sidx,pidx,bslc_idx),chidx,:)=reshape(tmpI_perchidx{chidx},[header.Npe,header.Nfe,1,1,header.Nrep]);
         end
      end %end of for pidx=1:header.num_slc_pae,
            
      if(flag_debug==1)
         for pidx=1:header.num_slc_pae,
            %if(flag_whiten==0)
            %   tmp_img1=squeeze(train_img_orig(:,:,header.sms_groupset(bslc_idx,sidx),:));
            %else
               tmp_img1=squeeze(train_img(:,:,header.mb3d_groupset(sidx,pidx,bslc_idx),:));
            %end
            disp_img1=squeeze(sqrt(sum(abs(tmp_img1).^2,3)));
            for didx=1:3,
               if(flag_flip_disp(didx)==1),
                  disp_img1=flipdim(disp_img1,didx);
               end
            end
            %tmp_img2=squeeze(mean(I_recon(:,:,header.sms_groupset(bslc_idx,sidx),:,pidx,:),6));
            tmp_img2=squeeze(mean(I_recon(:,:,header.mb3d_groupset(sidx,pidx,bslc_idx),:,:),5));
            disp_img2=squeeze(sqrt(sum(abs(tmp_img2).^2,3)));
            for didx=1:3,
               if(flag_flip_disp(didx)==1),
                  disp_img2=flipdim(disp_img2,didx);
               end
            end
            if(cnt_fig>100)
               new_figcnt=mod(cnt_fig,100);
               if(new_figcnt==0)
                  new_figcnt=100;
               end
               figure(hfig(new_figcnt));
            else
               hfig(cnt_fig)=figure;
               cnt_fig=cnt_fig+1;
            end
            subplot(211); imagesc(disp_img1); axis equal tight; colormap jet; colorbar; title('Train');
            subplot(212); imagesc(disp_img2); axis equal tight; colormap jet; colorbar; title('Recon');
            drawnow;
         end %end of for pidx=1:header.num_slc_pae,
      end
   end %end of for sidx=1:header.sms_factor,
end %end of for bslc_idx=1:numel(header.base_slcidx),

%delete(gcp('nocreate'));

return;
