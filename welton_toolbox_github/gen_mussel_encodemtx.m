function [Emtx_all] = gen_mussel_encodemtx(sentiv_map, grp_idx, header, varargin)
%function [Emtx_all] = gen_mussel_encodemtx(sentiv_map, grp_idx, header, varargin)
%	
%	Wei-Tang Chang, UNC-Chapel Hill
%  May 28, 2019
%
% Usage			: generate the encoding matrix of MUSSEL
% Input arguments:
%  sentiv_map: the sensitivity map with [N_pe x N_fe x N_slc x N_ch]
%  grp_idx   : the SMS group index
%  header: the structural variable of imaging protocol
%  (optional)
%
% output:
%  Emtx_all  : the encoding matrix with matrix dimension of [(N_ss x N_fe x N_ch x N_pae),(N_pe x N_fe x N_mb x N_pae)]
%              N_ss is the number of subsampled points along ky
%              N_mb is the number of simultaneously-excited slices (N_sms x N_pae)
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
for sidx=1:header.Nsep,
   fillup_idx_array(:,sidx)=sidx+[0:header.Nsep:header.N3D-1]';
end

%pe_dftmtx=fftshift(fftshift(dftmtx(header.Npe),2),1);
pe_ifftmtx=inv(fftshift(fftshift(dftmtx(header.Npe),2),1));
pe_fftmtx=fftshift(fftshift(dftmtx(header.Npe),2),1);
fe_ifftmtx=inv(fftshift(fftshift(dftmtx(header.Nfe),2),1));
fe_fftmtx=fftshift(fftshift(dftmtx(header.Nfe),2),1);
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

mb_factor=header.num_slc_pae*header.sms_factor;
%pae_ifftmtx=fftshift(fftshift(dftmtx(mb_factor),2),1);
zpos_vec=[fliplr([0:-header.Nsep:-floor(header.Nslc*header.num_slc_pae/2)]),[header.Nsep:header.Nsep:floor(header.Nslc*header.num_slc_pae/2)]];
%fft_mtx=fftshift(fftshift(dftmtx(mb_factor),2),1);
%pae_ifftmtx=inv(fft_mtx);

peidx_array=[k_pat_stidx:header.pat:k_pat_endidx];

if(isempty(mb3d_randph))
   tmp_randph=zeros(1,mb_factor);
else
   tmp_randph=fliplr(mb3d_randph{mb_factor}); %mb3d_randph{mb_factor};
end
PhWongmtx=reshape(repmat(reshape(exp(-sqrt(-1)*tmp_randph),[1,mb_factor]),[header.Npe*header.Nfe,1]),[],1);

%if(k_pat_stidx<(header.pat+1))
%   full_peidx_array=peidx_array;
%else
%   %full_peidx_array=cat(2,fliplr([k_pat_stidx-header.pat:-header.pat:1]),[k_pat_stidx:header.pat:k_pat_endidx]);
%   full_peidx_array=cat(2,fliplr([k_pat_stidx-header.pat:-header.pat:1]),[k_pat_stidx:header.pat:header.Npe]);
%end
%subsamp_vec=zeros(header.Npe,1);
subsamp_vec(peidx_array)=1;
%subsamp_vec(full_peidx_array)=1;

pefe_fftmtx=kron(fe_fftmtx,pe_fftmtx);
pefe_ifftmtx=kron(fe_ifftmtx,pe_ifftmtx);
ss_pefe_ifftmtx=kron(fe_ifftmtx,pe_ifftmtx(peidx_array,:));

preA=2*pi*(header.blip_shift-1)/(2.0*header.blip_shift*header.Nsep*header.num_slc_pae);
dA=-2*pi/(header.blip_shift*header.Nsep*header.num_slc_pae);
%tmp_array=[0:1:(header.Nslc*header.num_slc_pae-1)];
%blip_moment=zeros(header.Npe,1);
%blip_moment(peidx_array)=preA + dA*mod([0:1:(numel(peidx_array)-1)]',header.blip_shift);
blip_moment=preA + dA*mod([0:1:(numel(peidx_array)-1)]',header.blip_shift);
%full_blip_moment=zeros(header.Npe,1);
%full_blip_moment(peidx_array)=preA + dA*mod([0:1:(numel(peidx_array)-1)]',header.blip_shift);
%full_blip_moment([k_pat_stidx-header.pat:-header.pat:1])=preA + dA*mod([-1:-1:-numel([k_pat_stidx-header.pat:-header.pat:1])]',header.blip_shift);
%zpos_idx=[0:1:(header.Nslc*header.num_slc_pae-1)]-floor(header.Nslc*header.num_slc_pae/2);
tmp_momentmtx=repmat(blip_moment,[1,header.Npe]);
blk_momentmtx=sparse([]);
for fidx=1:header.Nfe,
   blk_momentmtx=blkdiag(blk_momentmtx,tmp_momentmtx);
end
catblk_momentmtx=sparse([]);
catblk_fftmtx=sparse([]);
catblk_ifftmtx=sparse([]);
for sidx=1:mb_factor,
   catblk_momentmtx=cat(2,catblk_momentmtx,blk_momentmtx);
   catblk_fftmtx=blkdiag(catblk_fftmtx,pefe_fftmtx);
   %catblk_ifftmtx=blkdiag(catblk_ifftmtx,ss_pefe_ifftmtx);
   catblk_ifftmtx=cat(2,catblk_ifftmtx,ss_pefe_ifftmtx);
end
%tmp_posmtx=repmat(reshape(repmat(zpos_vec,[header.Npe*header.Nfe,1]),1,[]),[numel(peidx_array)*header.Nfe,1]);
tmp_posmtx=reshape(repmat(zpos_vec,[header.Npe*header.Nfe,1]),[],1);
%Blipmtx=exp(sqrt(-1)*catblk_momentmtx.*tmp_posmtx);
Blipmtx=exp(sqrt(-1)*catblk_momentmtx*tmp_posmtx);
if(~isempty(bg_phimg))
   BgPhmtx=reshape(exp(sqrt(-1)*bg_phimg(:,:,fillup_idx_array(:,grp_idx))),[],1);
else
   BgPhmtx=ones(header.Npe*header.Nfe*mb_factor,1);
end
%Gmtx=repmat(pe_ifftmtx,[1,mb_factor]);

Emtx_all=sparse([]);
for pae_idx=1:header.num_slc_pae,
   pae_freqscale=pae_idx-1-floor(header.num_slc_pae/2);
   pae_ifftmtx=exp(sqrt(-1)*2*pi*pae_freqscale*zpos_vec./(header.Nsep*header.num_slc_pae));
   %PAEmtx=reshape(repmat(reshape(pae_ifftmtx(pae_idx,:),1,[]),[header.Npe,1]),[],1);
   PAEmtx=reshape(repmat(reshape(pae_ifftmtx,1,[]),[header.Npe*header.Nfe,1]),[],1);
   
   Smtx=[];
   Emtx_pershot=[];
   for chidx=1:header.Nch,
      Smtx{chidx}=reshape(sentiv_map(:, :, fillup_idx_array(:,grp_idx), chidx),[],1);
      %Smtx{chidx}=abs(reshape(sentiv_map(:, fe_idx, fillup_idx_array(:,grp_idx), chidx),[],1));
      Emtx_pershot=cat(1, Emtx_pershot, (catblk_ifftmtx.*Blipmtx)*sparse(diag(double(Smtx{chidx}.*PAEmtx.*PhWongmtx.*BgPhmtx)))*catblk_fftmtx);
   end
   
   Emtx_all=blkdiag(Emtx_all,Emtx_pershot);
end %end of for pae_idx=1:header.num_slc_pae,

return;

