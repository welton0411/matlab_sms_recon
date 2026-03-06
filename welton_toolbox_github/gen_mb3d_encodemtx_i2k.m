function [Emtx_all Emtx_perch] = gen_mb3d_encodemtx_i2k(sentiv_map, flag_ref, pae_idx, grp_idx, fe_idx, header, varargin)
%function [Emtx_all Emtx_perch] = gen_mb3d_encodemtx_i2k(sentiv_map, flag_ref, pae_idx, grp_idx, fe_idx, header, varargin)
%	
%	Wei-Tang Chang, UNC-Chapel Hill
%  May 28, 2019
%
% Usage			: generate the encoding matrix of MB3D
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

mb3d_randph=[];
%snr_data=[];
ref_rfmode=0;
k_pat_stidx=1;
k_pat_endidx=header.Npe;
C0=[];
bg_phimg=[];

for i=1:floor(length(varargin)/2)
   option=varargin{i*2-1};
   option_value=varargin{i*2};
   switch lower(option)
      case 'mb3d_randph',
         mb3d_randph=option_value;
      %case 'snr_data',
      %   snr_data=option_value;
      case 'ref_rfmode',
         ref_rfmode=option_value;
      case 'k_pat_stidx',
         k_pat_stidx=option_value;
      case 'k_pat_endidx',
         k_pat_endidx=option_value;
      case 'c0',
         C0=option_value;
      case 'bg_phimg',
         bg_phimg=option_value;
      otherwise
          fprintf('unknown option [%s]!\n',option);
          fprintf('error!\n');
          return;
   end
end

fillup_idx_array=[];
if(flag_ref==1)
   if(ref_rfmode==0) %MB3D_REF
      for sidx=1:header.Nslc,
         fillup_idx_array(:,sidx)=sidx+header.Nslc*[0:1:header.num_slc_pae-1]';
      end
   elseif(ref_rfmode==1) %multislab slab
      for sidx=1:header.Nsep,
         fillup_idx_array(:,sidx)=sidx+[0:header.Nsep:header.N3D-1]';
      end
   end
else
   for sidx=1:header.Nsep,
      fillup_idx_array(:,sidx)=sidx+[0:header.Nsep:header.N3D-1]';
   end
end
%keyboard;
%pe_dftmtx=fftshift(fftshift(dftmtx(header.Npe),2),1);
pe_ifftmtx=inv(fftshift(fftshift(dftmtx(header.Npe),2),1));
pe_fftmtx=fftshift(fftshift(dftmtx(header.Npe),2),1);
if(~isempty(C0))
   [u_C,s_C,v_C]=svd(C0);
   tmp=diag(s_C);
   cutidx=find((cumsum(tmp)/sum(tmp))>0.99);
   n_noise_proj=length(tmp)-cutidx(1)+1;
   if(n_noise_proj>4)
      n_noise_proj=4;
   elseif(n_noise_proj==1)
      n_noise_proj=0;
   end
   tmp(end-n_noise_proj+1:end)=inf;
   s=tmp;
   ww=diag(1./sqrt(s))*u_C';
   
   sentiv_map_orig=sentiv_map;
   sz_img=size(sentiv_map_orig);
   sentiv_map=reshape(permute(sentiv_map,[4 1 2 3]),header.Nch,[]);
   sentiv_map=ipermute(reshape(ww*sentiv_map,[header.Nch,sz_img(1:3)]),[4 1 2 3]);
end

if(flag_ref==1)
   if(ref_rfmode==0)
      mb_factor=header.num_slc_pae;
   elseif(ref_rfmode==1)
      mb_factor=header.num_slc_pae*header.sms_factor;
   end
   fft_mtx=fftshift(fftshift(dftmtx(mb_factor),2),1);
   pae_ifftmtx=inv(fft_mtx);
   PAEmtx=reshape(repmat(reshape(pae_ifftmtx(pae_idx,:),1,[]),[header.Npe,1]),1,[]);
   if(isempty(mb3d_randph))
      tmp_randph=zeros(1,mb_factor);
   else
      tmp_randph=fliplr(mb3d_randph{mb_factor}); %mb3d_randph{mb_factor};
   end
   PhWongmtx=reshape(repmat(reshape(exp(-sqrt(-1)*tmp_randph),[1,mb_factor]),[header.Npe,1]),1,[]);
   
   for patidx=1:header.pat,
      peidx_array=[k_pat_stidx+(patidx-1):header.pat:k_pat_endidx];
      if(k_pat_stidx<(header.pat+1))
         full_peidx_array=peidx_array;
      else
         %full_peidx_array=cat(2,fliplr([k_pat_stidx+(patidx-1)-header.pat:-header.pat:1]),[k_pat_stidx+(patidx-1):header.pat:k_pat_endidx]);
         full_peidx_array=cat(2,fliplr([k_pat_stidx+(patidx-1)-header.pat:-header.pat:1]),[k_pat_stidx+(patidx-1):header.pat:header.Npe]);
      end
      subsamp_vec=zeros(header.Npe,1);
      subsamp_vec(full_peidx_array)=1;
      
      %Gmtx=repmat(pe_ifftmtx(peidx_array,:),[1,mb_factor]);
      %Gmtx=pe_fftmtx*diag(subsamp_vec)*pe_ifftmtx;
      Gmtx=repmat(pe_ifftmtx,[1,mb_factor]);
      Smtx=[];
      Emtx_all{patidx}=zeros(header.Npe*header.Nch,header.Npe*mb_factor);
      for chidx=1:header.Nch,
         Smtx{chidx}=reshape(sentiv_map(:, fe_idx, fillup_idx_array(:,grp_idx), chidx),1,[]);
         %Smtx{chidx}=abs(reshape(sentiv_map(:, fe_idx, fillup_idx_array(:,grp_idx), chidx),1,[]));
         %Emtx_all{patidx}=cat(1, Emtx_all{patidx}, pe_fftmtx*(repmat(subsamp_vec,[1,size(Gmtx,2)]).*Gmtx.*repmat(Smtx{chidx}.*PAEmtx.*PhWongmtx,[size(pe_fftmtx,2),1])));
         Emtx_all{patidx}((chidx-1)*header.Npe+1:chidx*header.Npe,:)=pe_fftmtx*(repmat(subsamp_vec,[1,size(Gmtx,2)]).*Gmtx.*repmat(Smtx{chidx}.*PAEmtx.*PhWongmtx,[size(pe_fftmtx,2),1]));
      end
      Emtx_perch{patidx}=pe_fftmtx*(repmat(subsamp_vec,[1,size(Gmtx,2)]).*Gmtx.*repmat(PAEmtx.*PhWongmtx,[size(pe_fftmtx,2),1]));
      %keyboard;
   end %end of for patidx=1:header.pat,
else
   mb_factor=header.num_slc_pae*header.sms_factor;
   %pae_ifftmtx=fftshift(fftshift(dftmtx(mb_factor),2),1);
   zpos_vec=[fliplr([0:-header.Nsep:-floor(header.Nslc*header.num_slc_pae/2)]),[header.Nsep:header.Nsep:floor(header.Nslc*header.num_slc_pae/2)]];
   %fft_mtx=fftshift(fftshift(dftmtx(mb_factor),2),1);
   %pae_ifftmtx=inv(fft_mtx);
   pae_freqscale=pae_idx-1-floor(header.num_slc_pae/2);
   pae_ifftmtx=exp(sqrt(-1)*2*pi*pae_freqscale*zpos_vec./(header.Nsep*header.num_slc_pae));
   %PAEmtx=reshape(repmat(reshape(pae_ifftmtx(pae_idx,:),1,[]),[header.Npe,1]),[],1);
   PAEmtx=reshape(repmat(reshape(pae_ifftmtx,1,[]),[header.Npe,1]),[],1);
   if(isempty(mb3d_randph))
      tmp_randph=zeros(1,mb_factor);
   else
      tmp_randph=fliplr(mb3d_randph{mb_factor}); %mb3d_randph{mb_factor};
   end
   PhWongmtx=reshape(repmat(reshape(exp(-sqrt(-1)*tmp_randph),[1,mb_factor]),[header.Npe,1]),[],1);
   
   peidx_array=[k_pat_stidx:header.pat:k_pat_endidx];
   if(k_pat_stidx<(header.pat+1))
      full_peidx_array=peidx_array;
   else
      %full_peidx_array=cat(2,fliplr([k_pat_stidx-header.pat:-header.pat:1]),[k_pat_stidx:header.pat:k_pat_endidx]);
      full_peidx_array=cat(2,fliplr([k_pat_stidx-header.pat:-header.pat:1]),[k_pat_stidx:header.pat:header.Npe]);
   end
   subsamp_vec=zeros(header.Npe,1);
   subsamp_vec(full_peidx_array)=1;
   %subsamp_vec(peidx_array)=1;
   
   preA=2*pi*(header.blip_shift-1)/(2.0*header.blip_shift*header.Nsep*header.num_slc_pae);
   dA=-2*pi/(header.blip_shift*header.Nsep*header.num_slc_pae);
   %tmp_array=[0:1:(header.Nslc*header.num_slc_pae-1)];
   blip_moment=zeros(header.Npe,1);
   blip_moment(peidx_array)=preA + dA*mod([0:1:(numel(peidx_array)-1)]',header.blip_shift);
   full_blip_moment=zeros(header.Npe,1);
   full_blip_moment(peidx_array)=preA + dA*mod([0:1:(numel(peidx_array)-1)]',header.blip_shift);
   full_blip_moment([k_pat_stidx-header.pat:-header.pat:1])=preA + dA*mod([-1:-1:-numel([k_pat_stidx-header.pat:-header.pat:1])]',header.blip_shift);
   %zpos_idx=[0:1:(header.Nslc*header.num_slc_pae-1)]-floor(header.Nslc*header.num_slc_pae/2);
   tmp_momentmtx=repmat(full_blip_moment,[1,mb_factor*header.Npe]);
   tmp_posmtx=repmat(reshape(repmat(zpos_vec,[header.Npe,1]),1,[]),[size(pe_ifftmtx,1),1]);
   Blipmtx=exp(sqrt(-1)*tmp_momentmtx.*tmp_posmtx);
   if(~isempty(bg_phimg))
      BgPhmtx=reshape(exp(sqrt(-1)*bg_phimg(:, fe_idx, fillup_idx_array(:,grp_idx))),[],1);
   else
      BgPhmtx=ones(header.Npe*mb_factor,1);
   end
   %Gmtx=repmat(pe_ifftmtx(peidx_array,:),[1,mb_factor]);
   Gmtx=repmat(pe_ifftmtx,[1,mb_factor]);

   Smtx=[];
   Emtx_perch=[];
   Emtx_all=[];
   for chidx=1:header.Nch,
      Smtx{chidx}=reshape(sentiv_map(:, fe_idx, fillup_idx_array(:,grp_idx), chidx),[],1);
      %Smtx{chidx}=abs(reshape(sentiv_map(:, fe_idx, fillup_idx_array(:,grp_idx), chidx),[],1));
      Emtx_all=cat(1, Emtx_all, pe_fftmtx*diag(subsamp_vec)*(Gmtx.*Blipmtx)*diag(Smtx{chidx}.*PAEmtx.*PhWongmtx.*BgPhmtx));
   end
   %Emtx_perch=pe_fftmtx*diag(subsamp_vec)*(Gmtx.*Blipmtx)*diag(PAEmtx.*PhWongmtx.*BgPhmtx);
end

return;
