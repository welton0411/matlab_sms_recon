function [noise_data refscan_data image_data]=datapack_VE(twix_obj,varargin)

noise_data=[];
refscan_data=[];
image_data=[];

%setting up defaults
file_prot='meas.asc';   %default protocol file name
file_raw='meas.out';    %defualt rawdata file name

flag_debug=0;
flag_debug_file=0;

output_stem='meas';
flag_scan_mdh_only=0;
flag_output_reim=1;
flag_output_maph=0;
flag_output_burst=0;
n_measurement=1;

flag_phase_cor=1;
flag_phase_cor_mgh=1;
flag_phase_cor_jbm=0;

flag_train_scan=1;

flag_phase_cor_algorithm_jbm=0;
flag_phase_cor_algorithm_lsq=1;

flag_shimming_cor=0;

flag_epi=1;
flag_pepsi=0;
flag_svs=0;
flag_ini3d=0;
flag_multiecho=0;
sms_factor=1;
pat=1;
%num_acsline_perseg=12;
flag_train_spsg=0;

slice_order='interleave';		%slice order can be "interleave" or "sequential".

n_channel=[];
array_index=[];

Npe=[];
Nfe=[];
nz=[];
fov_pe=[];
peshift_voxel=0;
max_avg=inf;

PartialFourtierRatio=[]; %added by Welton on Sep.17,2010

global ice_obj;

if(nargin==0)
    file_prot='meas.asc';
    file_raw='meas.out';
    file_stem='meas';
    fprintf('using [meas.asc] and [meas.out] as input files.\n');
else
    for i=1:length(varargin)/2
        option=varargin{i*2-1};
        option_value=varargin{i*2};

        switch(lower(option))
            case 'flag_debug'
                flag_debug=option_value;
                if(flag_debug)
                    fprintf('debug ON! flag_debug = [%d]\n',flag_debug);
                else
                    fprintf('debug OFF!\n');
                end;
            case 'flag_phase_cor'
                flag_phase_cor=option_value;
                if(flag_phase_cor)
                    fprintf('EPI phase correction enabled!\n');
                end;
            case 'flag_phase_cor_mgh'
                flag_phase_cor_mgh=option_value;
                if(flag_phase_cor_mgh)
                    flag_phase_cor_jbm=0;
                end;
                if(flag_phase_cor_mgh)
                    fprintf('Estimate EPI phase correction using 3-scan at the center of k-space!\n');
                end;
            case 'flag_phase_cor_jbm'
                flag_phase_cor_jbm=option_value;
                if(flag_phase_cor_jbm)
                    flag_phase_cor_mgh=0;
                end;
                if(flag_phase_cor_jbm)
                    fprintf('Estimate EPI phase correction using whole image!\n');
                end;
            case 'flag_phase_cor_algorithm_jbm'
                flag_phase_cor_algorithm_jbm=option_value;
                if(flag_phase_cor_algorithm_jbm)
                    flag_phase_cor_algorithm_lsq=0;
                end;
            case 'flag_phase_cor_algorithm_lsq'
                flag_phase_cor_algorithm_lsq=option_value;
                if(flag_phase_cor_algorithm_lsq)
                    flag_phase_cor_algorithm_jbm=0;
                end;
            case 'fov_pe'
                fov_pe=option_value;
                if(flag_phase_cor_algorithm_lsq)
                    flag_phase_cor_algorithm_jbm=0;
                end;
            case 'flag_epi'
                flag_epi=option_value;
                flag_svs=0;
                flag_pepsi=0;
                flag_ini3d=0;
                %flag_multiecho=0;
                fprintf('reading EPI data!\n');
            case 'flag_pepsi'
                flag_pepsi=option_value;
                flag_epi=0;
                flag_svs=0;
                flag_ini3d=0;
                flag_multiecho=0;
                fprintf('reading PEPSI data!\n');
            case 'flag_multiecho'
                flag_multiecho=option_value;
                flag_svs=0;
                flag_pepsi=0;
                flag_ini3d=0;
            case 'flag_svs'
                flag_svs=option_value;
                flag_epi=0;
                flag_pepsi=0;
                flag_ini3d=0;
                flag_multiecho=0;
                fprintf('reading SVS data!\n');
            case 'n_pe'
                Npe=option_value;
            case 'n_fe'
                Nfe=option_value;
            case 'nz'
                nz=option_value;
            case 'partialfourtierratio' %added by Welton on Sep.17,2010
               PartialFourtierRatio=option_value;
            case 'sms_factor',
               sms_factor=option_value;
            case 'pat',
               pat=option_value;
            case 'num_slc_pae',
               num_slc_pae=option_value;
            case 'flag_train_scan',
               flag_train_scan=option_value;
            case 'flag_train_spsg',
               flag_train_spsg=option_value;
            case 'peshift_voxel',
               peshift_voxel=option_value;
            otherwise
                fprintf('unknown option [%s]. Error!\n\n',option);
                return;
        end;
    end;
end;

ice_obj.flag_debug=flag_debug;
ice_obj.flag_phase_cor=flag_phase_cor;
ice_obj.flag_phase_cor_mgh=flag_phase_cor_mgh;
ice_obj.flag_phase_cor_jbm=flag_phase_cor_jbm;
ice_obj.flag_phase_cor_algorithm_jbm=flag_phase_cor_algorithm_jbm;
ice_obj.flag_phase_cor_algorithm_lsq=flag_phase_cor_algorithm_lsq;

ice_obj.flag_epi=flag_epi;
ice_obj.flag_pepsi=flag_pepsi;
ice_obj.flag_svs=flag_svs;
ice_obj.flag_ini3d=flag_ini3d;
ice_obj.flag_multiecho=flag_multiecho;
ice_obj.sms_factor=sms_factor;
ice_obj.pat=pat;
%ice_obj.num_acsline_perseg=num_acsline_perseg;
ice_obj.flag_train_spsg=flag_train_spsg;
ice_obj.num_slc_pae=num_slc_pae;
ice_obj.slice_order=slice_order;		%slice order can be "interleave" or "sequential".

ice_obj.Npe=Npe;
ice_obj.Nfe=Nfe;
%ice_obj.nz=nz;

ice_obj.PartialFourtierRatio=PartialFourtierRatio; %added by Welton on Sep.17,2010

noise_rawdata=twix_obj{1}.noise.unsorted();
noise_data=reshape(permute(noise_rawdata,[1 3 2]),[],twix_obj{1}.noise.NCha);

for s=2:length(twix_obj),
   PEshift(s-1)=  round(ice_obj.Npe/twix_obj{s}.hdr.Config.PhasePartialFourierFactor);
   %PEshift(s-1)=  round(ice_obj.Npe/twix_obj{s}.hdr.Config.PhasePartialFourierFactor) - 3;
   PartialFourtierRatio(s-1)=1-1/double(twix_obj{s}.hdr.Config.PhasePartialFourierFactor);
   
   for f = fieldnames( twix_obj{s} ).'
      if(~(strcmp(f,'hdr') || strcmp(f,'vop')))
         fprintf('Reading %s ... ',f{1});
         str=sprintf('%s_rawdata = twix_obj{s}.(f{1}).unsorted();',f{1});
         eval(str);
         fprintf('done!\n');
      end
   end
   
   if(flag_phase_cor)
      if(~isfield(twix_obj{s},'phasecor'))
         fprintf('ERROR! No navigator echoes are found for phase correction.\n');
         return;
      end
      %keyboard;
      phasecor_rawdata=fftshift(fft(fftshift(phasecor_rawdata,1),[],1),1);
      %phasecor_rawdata=fftshift(ifft(fftshift(phasecor_rawdata,1),[],1),1);
   end
   image_rawdata=fftshift(fft(ifftshift(image_rawdata,1),[],1),1);
   %image_rawdata=fftshift(ifft(fftshift(image_rawdata,1),[],1),1);
   %keyboard;
   n_acqLperKplane=twix_obj{s}.hdr.Config.RawLin;
   nav_echo=[];
   
   if(isfield(twix_obj{s},'refscan'))
      refscan_data{s-1}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, twix_obj{s}.hdr.Config.NSlc, twix_obj{s}.refscan.NCha, num_slc_pae, 'single');
      num_ref_kplane=twix_obj{s}.refscan.NAcq/n_acqLperKplane;
      ice_obj.Nfe=twix_obj{s}.hdr.Config.BaseResolution;
      %ice_obj.Npe=twix_obj{s}.hdr.Config.PhaseEncodingLines;
      ice_obj.Nch=twix_obj{s}.image.NCha;
      ice_obj.NSlc=twix_obj{s}.hdr.Config.NSlc;
      num_refAcqSlc=numel(unique(twix_obj{s}.refscan.Sli));
      
      refscan_rawdata=fftshift(fft(ifftshift(refscan_rawdata,1),[],1),1);
            
      for kidx=1:num_ref_kplane,
         pae_idx=ceil(kidx/(num_refAcqSlc*ice_obj.pat));
         kL_offset=(kidx-1)*n_acqLperKplane;
         ref_slcidx=unique(twix_obj{s}.refscan.Sli(kL_offset+1:kL_offset+n_acqLperKplane));
         if(numel(ref_slcidx)>1)
            fprintf('ERROR! The in-plane k lines should belong to the same slice.\n');
            return;
         end
            
         if(flag_phase_cor)
            phcor_slcidx=unique(twix_obj{s}.phasecor.Sli((kidx-1)*3+1:kidx*3));
            if(numel(phcor_slcidx)>1)
               fprintf('ERROR! The 3 navigator echoes should belong to the same slice.\n');
               return;
            end
            if(phcor_slcidx~=ref_slcidx)
               fprintf('ERROR! The naviator echoes and reference data do not share the same slice (%d v.s. %d).\n',phcor_slcidx,ref_slcidx);
               return;
            end
            
            for nvidx=1:3,
               nav_echo{phcor_slcidx, twix_obj{s}.phasecor.Seg((kidx-1)*3+nvidx)}=phasecor_rawdata(:,:,(kidx-1)*3+nvidx);
            end
            %keyboard;
            calc_epi_phase_correction(nav_echo, phcor_slcidx);
            
            oddline_idx=find(twix_obj{s}.refscan.Seg(kL_offset+1:kL_offset+n_acqLperKplane)==2);
            tmp_kplane=refscan_rawdata(:,:,kL_offset+1:kL_offset+n_acqLperKplane);
            tmp_kplane(:,:,oddline_idx)=apply_epi_phase_correction(refscan_rawdata(:,:,oddline_idx+kL_offset));
            %fprintf('kidx=%d',kidx);
            %keyboard;
            refscan_data{s-1}(PEshift(s-1)+twix_obj{s}.refscan.Lin(kL_offset+1:kL_offset+n_acqLperKplane),:,ref_slcidx,:,pae_idx)=reshape(permute(tmp_kplane,[3 1 2]),[n_acqLperKplane, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.refscan.NCha, 1]);
         else
            refscan_data{s-1}(PEshift(s-1)+twix_obj{s}.refscan.Lin(kL_offset+1:kL_offset+n_acqLperKplane),:,ref_slcidx,:,pae_idx)=reshape(permute(refscan_rawdata(:,:,kL_offset+1:kL_offset+n_acqLperKplane),[3 1 2]),[n_acqLperKplane, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.refscan.NCha, 1]);
         end
      end %end of for kidx=1:num_ref_kplane,
      
      refscan_data{s-1}=refscan_data{s-1}(1:ice_obj.Npe,:,:,:,:);
      
      if(~isempty(fov_pe) && (peshift_voxel~=0))
         tmp_kz=[0:ice_obj.Npe-1]'-floor(ice_obj.Npe/2);
         tmp_kz=tmp_kz/fov_pe;
         peshift_mm=peshift_voxel*fov_pe/ice_obj.Npe;
         tmp_addphase=exp(sqrt(-1)*2*pi*tmp_kz*peshift_mm);
         sz_refscan=size(refscan_data{s-1});
         refscan_data{s-1}=refscan_data{s-1}.*repmat(tmp_addphase,[1 sz_refscan(2:end)]);
      end
      refscan_data{s-1}=fftshift(fft(fftshift(refscan_data{s-1},1),[],1),1);
   else
      if(flag_train_scan==1)
         refscan_data{s-1}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, twix_obj{s}.hdr.Config.NSlc, twix_obj{s}.image.NCha, num_slc_pae, 'single');
         
         tmpnum_kplane=numel(find(twix_obj{s}.image.Rep==1))/twix_obj{s}.hdr.Config.RawLin;
         num_ref_kplane=tmpnum_kplane-twix_obj{s}.hdr.Config.RawSlc/ice_obj.sms_factor;
         
         ice_obj.Nfe=twix_obj{s}.hdr.Config.BaseResolution;
         %ice_obj.Npe=twix_obj{s}.hdr.Config.PhaseEncodingLines;
         ice_obj.Nch=twix_obj{s}.image.NCha;
         ice_obj.NSlc=twix_obj{s}.hdr.Config.NSlc;
         num_refAcqSlc=twix_obj{s}.hdr.Config.RawSlc;
         
         for kidx=1:num_ref_kplane,
            pae_idx=ceil(kidx/(num_refAcqSlc*ice_obj.pat));
            kL_offset=(kidx-1)*n_acqLperKplane;
            ref_slcidx=unique(twix_obj{s}.image.Sli(kL_offset+1:kL_offset+n_acqLperKplane));
            if(numel(ref_slcidx)>1)
               fprintf('ERROR! The in-plane k lines should belong to the same slice.\n');
               return;
            end
               
            if(flag_phase_cor)
               phcor_slcidx=unique(twix_obj{s}.phasecor.Sli((kidx-1)*3+1:kidx*3));
               if(numel(phcor_slcidx)>1)
                  fprintf('ERROR! The 3 navigator echoes should belong to the same slice.\n');
                  return;
               end
               if(phcor_slcidx~=ref_slcidx)
                  fprintf('ERROR! The naviator echoes and reference data do not share the same slice (%d v.s. %d).\n',phcor_slcidx,ref_slcidx);
                  return;
               end
               
               for nvidx=1:3,
                  nav_echo{phcor_slcidx, twix_obj{s}.phasecor.Seg((kidx-1)*3+nvidx)}=phasecor_rawdata(:,:,(kidx-1)*3+nvidx);
               end
               
               calc_epi_phase_correction(nav_echo, phcor_slcidx);
               
               oddline_idx=find(twix_obj{s}.image.Seg(kL_offset+1:kL_offset+n_acqLperKplane)==2);
               tmp_kplane=image_rawdata(:,:,kL_offset+1:kL_offset+n_acqLperKplane);
               tmp_kplane(:,:,oddline_idx)=apply_epi_phase_correction(image_rawdata(:,:,oddline_idx+kL_offset));
               %fprintf('kidx=%d',kidx);
               %keyboard;
               refscan_data{s-1}(PEshift+twix_obj{s}.image.Lin(kL_offset+1:kL_offset+n_acqLperKplane),:,ref_slcidx,:,pae_idx)=reshape(permute(tmp_kplane,[3 1 2]),[n_acqLperKplane, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.image.NCha, 1]);
            else
               %keyboard;
               refscan_data{s-1}(PEshift+twix_obj{s}.image.Lin(kL_offset+1:kL_offset+n_acqLperKplane),:,ref_slcidx,:,pae_idx)=reshape(permute(image_rawdata(:,:,kL_offset+1:kL_offset+n_acqLperKplane),[3 1 2]),[n_acqLperKplane, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.image.NCha, 1]);
            end
         end %end of for kidx=1:num_ref_kplane,
         
         refscan_data{s-1}=refscan_data{s-1}(1:ice_obj.Npe,:,:,:,:);
         
         if(~isempty(fov_pe) && (peshift_voxel~=0))
            tmp_kz=[0:ice_obj.Npe-1]'-floor(ice_obj.Npe/2);
            tmp_kz=tmp_kz/fov_pe;
            peshift_mm=peshift_voxel*fov_pe/ice_obj.Npe;
            tmp_addphase=exp(sqrt(-1)*2*pi*tmp_kz*peshift_mm);
            sz_refscan=size(refscan_data{s-1});
            refscan_data{s-1}=refscan_data{s-1}.*repmat(tmp_addphase,[1 sz_refscan(2:end)]);
         end
         
         refscan_data{s-1}=fftshift(fft(fftshift(refscan_data{s-1},1),[],1),1);
      end %end of if(flag_train_scan==1)
   end %end of if(isfield(twix_obj{s},'refscan'))
   %twix_obj{s}.hdr.Dicom.lAccelFactPE
   
   image_data{s-1}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, twix_obj{s}.hdr.Config.NSlc, twix_obj{s}.image.NCha, num_slc_pae, twix_obj{s}.hdr.Config.RawRep/num_slc_pae,'single');
   %n_acqLperKplane=twix_obj{s}.hdr.Config.RawLin;
   if(isfield(twix_obj{s},'refscan'))
      num_img_kplane=twix_obj{s}.image.NAcq/n_acqLperKplane;
      num_imgAcqSlc=numel(unique(twix_obj{s}.image.Sli));
   else
      if(flag_train_scan==1)
         num_img_kplane=twix_obj{s}.image.NAcq/n_acqLperKplane-num_ref_kplane;
         num_imgAcqSlc=numel(unique(twix_obj{s}.image.Sli(num_ref_kplane*n_acqLperKplane+1:end)));
      end
   end
   for kidx=1:num_img_kplane,
      vol_idx=ceil(kidx/num_imgAcqSlc);
      pae_idx=mod(vol_idx-1,num_slc_pae)+1;
      rep_idx=ceil(vol_idx/num_slc_pae);
      if(isfield(twix_obj{s},'refscan'))
         kL_offset=(kidx-1)*n_acqLperKplane;
      else
         if(flag_train_scan==1)
            kL_offset=(kidx-1+num_ref_kplane)*n_acqLperKplane;
         end
      end
      img_slcidx=unique(twix_obj{s}.image.Sli(kL_offset+1:kL_offset+n_acqLperKplane));
      if(numel(img_slcidx)>1)
         fprintf('ERROR! The in-plane k lines should belong to the same slice.\n');
         return;
      end
         
      if(flag_phase_cor)
         phcor_slcidx=unique(twix_obj{s}.phasecor.Sli((kidx+num_ref_kplane-1)*3+1:(kidx+num_ref_kplane)*3));
         if(numel(phcor_slcidx)>1)
            fprintf('ERROR! The 3 navigator echoes should belong to the same slice.\n');
            return;
         end
         if(phcor_slcidx~=img_slcidx)
            fprintf('ERROR! The naviator echoes and reference data do not share the same slice (%d v.s. %d).\n',phcor_slcidx,img_slcidx);
            return;
         end
         
         for nvidx=1:3,
            nav_echo{phcor_slcidx, twix_obj{s}.phasecor.Seg((kidx+num_ref_kplane-1)*3+nvidx)}=phasecor_rawdata(:,:,(kidx+num_ref_kplane-1)*3+nvidx);
         end
         
         calc_epi_phase_correction(nav_echo, phcor_slcidx);
         
         oddline_idx=find(twix_obj{s}.image.Seg(kL_offset+1:kL_offset+n_acqLperKplane)==2);
         tmp_kplane=image_rawdata(:,:,kL_offset+1:kL_offset+n_acqLperKplane);
         tmp_kplane(:,:,oddline_idx)=apply_epi_phase_correction(image_rawdata(:,:,oddline_idx+kL_offset));
         %image_rawdata(:,:,oddline_idx+kL_offset)=tmp_kplane;
         image_data{s-1}(PEshift(s-1)+twix_obj{s}.image.Lin(kL_offset+1:kL_offset+n_acqLperKplane),:,img_slcidx,:,pae_idx,rep_idx)=reshape(permute(tmp_kplane,[3 1 2]),[n_acqLperKplane, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.image.NCha, 1, 1]);
      else
         image_data{s-1}(PEshift(s-1)+twix_obj{s}.image.Lin(kL_offset+1:kL_offset+n_acqLperKplane),:,img_slcidx,:,pae_idx,rep_idx)=reshape(permute(image_rawdata(:,:,kL_offset+1:kL_offset+n_acqLperKplane),[3 1 2]),[n_acqLperKplane, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.image.NCha, 1, 1]);
      end
   end %end of for kidx=1:num_ref_kplane,
   
   image_data{s-1}=image_data{s-1}(1:ice_obj.Npe,:,:,:,:,:);
   if(~isempty(fov_pe) && (peshift_voxel~=0))
      tmp_kz=[0:ice_obj.Npe-1]'-floor(ice_obj.Npe/2);
      tmp_kz=tmp_kz/fov_pe;
      peshift_mm=peshift_voxel*fov_pe/ice_obj.Npe;
      tmp_addphase=exp(sqrt(-1)*2*pi*tmp_kz*peshift_mm);
      sz_imagescan=size(image_data{s-1});
      image_data{s-1}=image_data{s-1}.*repmat(tmp_addphase,[1 sz_imagescan(2:end)]);
   end
   image_data{s-1}=fftshift(fft(fftshift(image_data{s-1},1),[],1),1);
   %image_data{s-1}=fftshift(ifft(fftshift(image_data{s-1},1),[],1),1);
end %end of for s=2:length(twix_obj),

if length(twix_obj) == 2
   image_data = image_data{1};
   refscan_data = refscan_data{1};
end

fprintf('DONE!\n\n');

return;


function []=calc_epi_phase_correction(nav_echo,slice_idx)

global ice_obj;
odd=nav_echo{slice_idx,2};         %from line "1"
even=nav_echo{slice_idx,1};        %from line "0"
%keyboard;
nav_data_fraction=0.3;
%nav_phase_slope=[];
%nav_phase_offset=[];
if(~isempty(even)&~isempty(odd))    
   %use the biggest (1-fraction) proportion of the data to estimate phase
   %weighted least square fitting 
   if(ice_obj.flag_phase_cor_algorithm_lsq) %least-square
      for i=1:size(even,2)
          RR=abs(even(:,i).*odd(:,i));
          Rs=sort(RR);
          idx=find(RR>Rs(round(length(Rs)*(1-nav_data_fraction))));
          R=diag(RR(idx));
          RR=diag(RR);
          
          phase=unwrap(angle(even(idx,:)./odd(idx,:)));
          x=([0:size(even,1)-1]-size(even,1)/2+0.5)';
          XX=[x, ones(size(x))];
          X=XX(idx,:);
          
          phi(:,i)=inv(X'*pinv(R)*X)*X'*pinv(R)*phase(:,i);
      end;
    
      ice_obj.nav_phase_slope=phi(1,:)';
      ice_obj.nav_phase_offset=phi(2,:)';
   end;
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %if(ice_obj.flag_phase_cor_algorithm_jbm)    %jbm's algorithm
   %   %original JBM algorithm
   %   odd2=odd(1:end-1,:);
   %   odd1=odd(2:end,:);
   %   even2=even(1:end-1,:);
   %   even1=even(2:end,:);
   %   
   %   odd_linear_angle=angle(diag(odd1'*odd2));
   %   even_linear_angle=angle(diag(even1'*even2));
   %   
   %   offset=angle(diag(even'*odd));
   %   ice_obj.nav_phase_slope=odd_linear_angle-even_linear_angle;
   %   if(~ice_obj.flag_phase_cor_offset)
	%      ice_obj.nav_phase_offset=zeros(size(offset));
   %   else
	%      ice_obj.nav_phase_offset=-offset;
   %   end;
   %end;
end;

return;



function [pc_kplane]=apply_epi_phase_correction(data_kplane)

global ice_obj;

sz_kplane_orig=size(data_kplane);
sz_kplane=size(data_kplane(:,:,:));

x=([0:sz_kplane(1)-1]-sz_kplane(1)/2+0.5)';
x=repmat(x,[1, sz_kplane(2)]);
%keyboard;
offset=repmat(transpose(ice_obj.nav_phase_offset),[sz_kplane(1),1]);

%phi=exp(sqrt(-1).*(offset+x.*repmat(reshape(ice_obj.nav_phase_slope,[1 sz_kplane(2) 1]),[sz_kplane(1),1,sz_kplane(3)])));
phi=exp(sqrt(-1).*(offset+x*diag(ice_obj.nav_phase_slope)));
%for debug
%if(sMdh.sLC.ushLine==1)
%   fprintf('WT: Slice #%02d, Line #%02d, phi=%f\n',sMdh.sLC.ushSlice,sMdh.sLC.ushLine,phi(1));
%end

%replicate phase correction term for multiple echoes
%phi=repmat(phi,[1,1,size(ice_m_data,5)]);

phi=repmat(phi,[1,1,sz_kplane(3)]);
pc_kplane=data_kplane(:,:,:).*phi;
pc_kplane=reshape(pc_kplane,sz_kplane_orig);
%sFifo.FCData=sFifo.FCData.*phi;
return;
