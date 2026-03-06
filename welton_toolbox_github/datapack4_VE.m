function [noise_data refscan_data image_data ref_slcidx_all]=datapack4_VE(twix_obj,varargin)

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
ref_force3d=0;

flag_phase_cor_algorithm_jbm=0;
flag_phase_cor_algorithm_lsq=0;
flag_phase_cor_algorithm_conv=1;

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

OS_factor = 5; % oversampling factor
ShiftFracForLine1 = 0.5; % the fraction of the shift that will be applied to the odd line group

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
                    flag_phase_cor_algorithm_conv=0;
                end;
            case 'flag_phase_cor_algorithm_lsq'
                flag_phase_cor_algorithm_lsq=option_value;
                if(flag_phase_cor_algorithm_lsq)
                    flag_phase_cor_algorithm_jbm=0;
                    flag_phase_cor_algorithm_conv=0;
                end;
            case 'flag_phase_cor_algorithm_conv'
                flag_phase_cor_algorithm_conv=option_value;
                if(flag_phase_cor_algorithm_conv)
                    flag_phase_cor_algorithm_jbm=0;
                    flag_phase_cor_algorithm_lsq=0;
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
            case 'ref_rfmode',
               ref_rfmode=option_value;
            case 'ref_kdist',
               ref_kdist=option_value;
            case 'ref_force3d',
               ref_force3d=option_value;
            %case 'gap_dist',
            %   gap_dist=option_value;
            case 'slcthickness',
               slcthickness=option_value;
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
ice_obj.flag_phase_cor_algorithm_conv=flag_phase_cor_algorithm_conv;

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

objL=length(twix_obj);
for idx=1:objL,
   if(isfield(twix_obj{idx},'phasecor'))
      dataobj_idx=idx;
      break;
   end
end
%N3D=gap_dist*sms_factor*num_slc_pae/slcthickness;
N3D=twix_obj{dataobj_idx}.hdr.Config.NSlc*num_slc_pae;
if(ref_rfmode==0) %single slab
   if(ref_force3d==0)
      num_ref_pae=num_slc_pae;
   else
      num_ref_pae=N3D;
   end
elseif(ref_rfmode==1) %multislab slab
   if(ref_force3d==0)
      num_ref_pae=num_slc_pae*sms_factor;
   else
      num_ref_pae=N3D;
   end
elseif(ref_rfmode==2) %3D
   num_ref_pae=N3D;
end
      
if(isfield(twix_obj{dataobj_idx},'noise')==1)
   noise_rawdata=twix_obj{dataobj_idx}.noise.unsorted();
   noise_data=reshape(permute(noise_rawdata,[1 3 2]),[],twix_obj{dataobj_idx}.noise.NCha);
end

obj_cnt=0;
for s=dataobj_idx:length(twix_obj), %2:length(twix_obj),
   obj_cnt=obj_cnt+1;
   PEshift(obj_cnt)=  round(ice_obj.Npe/twix_obj{s}.hdr.Config.PhasePartialFourierFactor);
   %PEshift(obj_cnt)=  round(ice_obj.Npe/twix_obj{s}.hdr.Config.PhasePartialFourierFactor) - 3;
   PartialFourtierRatio(obj_cnt)=1-1/double(twix_obj{s}.hdr.Config.PhasePartialFourierFactor);
   
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
      refscan_data{obj_cnt}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, twix_obj{s}.hdr.Config.NSlc, twix_obj{s}.refscan.NCha, num_slc_pae, 'single');
      num_ref_kplane=twix_obj{s}.refscan.NAcq/n_acqLperKplane;
      ice_obj.Nfe=twix_obj{s}.hdr.Config.BaseResolution;
      %ice_obj.Npe=twix_obj{s}.hdr.Config.PhaseEncodingLines;
      ice_obj.Nch=twix_obj{s}.image.NCha;
      ice_obj.NSlc=twix_obj{s}.hdr.Config.NSlc;
      num_refSlcOrig=numel(unique(twix_obj{s}.refscan.Sli));
      
      refscan_rawdata=fftshift(fft(ifftshift(refscan_rawdata,1),[],1),1);
            
      for kidx=1:num_ref_kplane,
         pae_idx=ceil(kidx/(num_refSlcOrig*ice_obj.pat));
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
            %for nvidx=1:2,
               nav_echo{phcor_slcidx, twix_obj{s}.phasecor.Seg((kidx-1)*3+nvidx)}=phasecor_rawdata(:,:,(kidx-1)*3+nvidx);
            end
            %keyboard;
            calc_epi_phase_correction(nav_echo, phcor_slcidx);
            
            if(~ice_obj.flag_phase_cor_algorithm_conv)
               oddline_idx=find(twix_obj{s}.refscan.Seg(kL_offset+1:kL_offset+n_acqLperKplane)==2);
               tmp_kplane=refscan_rawdata(:,:,kL_offset+1:kL_offset+n_acqLperKplane);
               tmp_kplane(:,:,oddline_idx)=apply_epi_phase_correction(refscan_rawdata(:,:,oddline_idx+kL_offset));
               %fprintf('kidx=%d',kidx);
               %keyboard;
               refscan_data{obj_cnt}(PEshift(obj_cnt)+twix_obj{s}.refscan.Lin(kL_offset+1:kL_offset+n_acqLperKplane),:,ref_slcidx,:,pae_idx)=reshape(permute(tmp_kplane,[3 1 2]),[n_acqLperKplane, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.refscan.NCha, 1]);
            else
               evenline_idx=find(twix_obj{s}.refscan.Seg(kL_offset+1:kL_offset+n_acqLperKplane)==1);
               oddline_idx=find(twix_obj{s}.refscan.Seg(kL_offset+1:kL_offset+n_acqLperKplane)==2);
               tmp_kplane=refscan_rawdata(:,:,kL_offset+1:kL_offset+n_acqLperKplane);
               LineLength = size(tmp_kplane,1);
               linesReshapeCorrected=zeros([size(tmp_kplane,1), size(tmp_kplane,3), size(tmp_kplane,2)]);
               for DataSetCount = 1:size(tmp_kplane,2)
                  Line1 = reshape(tmp_kplane(:,DataSetCount,evenline_idx),size(refscan_rawdata,1),[]);
                  Line2 = reshape(tmp_kplane(:,DataSetCount,oddline_idx) ,size(refscan_rawdata,1),[]);
                  
                  ConstPhaseDiff = ice_obj.nav_phase_constant(DataSetCount);
                  Total_SecondLineShiftBy = ice_obj.nav_line_shift(DataSetCount);
                  Line1Shift = -Total_SecondLineShiftBy*ShiftFracForLine1;
                  Line2Shift = Total_SecondLineShiftBy + Line1Shift;
                  
                  Phase1 = exp(-sqrt(-1)*2*pi* (-ceil((LineLength-1)/2):floor((LineLength-1) /2))/LineLength *(Line1Shift/OS_factor) ).';
                  linesReshapeCorrected(:, evenline_idx, DataSetCount) = Line1.*repmat(Phase1,1,size(Line1,2))  /exp(sqrt(-1)*ConstPhaseDiff);
                  Phase2 = exp(-sqrt(-1)*2*pi* (-ceil((LineLength-1)/2):floor((LineLength-1) /2))/LineLength *(Line2Shift/OS_factor) ).';
                  linesReshapeCorrected(:, oddline_idx, DataSetCount) = Line2.*repmat(Phase2,1,size(Line2,2));
               end
               refscan_data{obj_cnt}(PEshift(obj_cnt)+twix_obj{s}.refscan.Lin(kL_offset+1:kL_offset+n_acqLperKplane),:,ref_slcidx,:,pae_idx)=reshape(permute(linesReshapeCorrected,[2 1 3]),[n_acqLperKplane, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.refscan.NCha, 1]);
            end
         else
            refscan_data{obj_cnt}(PEshift(obj_cnt)+twix_obj{s}.refscan.Lin(kL_offset+1:kL_offset+n_acqLperKplane),:,ref_slcidx,:,pae_idx)=reshape(permute(refscan_rawdata(:,:,kL_offset+1:kL_offset+n_acqLperKplane),[3 1 2]),[n_acqLperKplane, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.refscan.NCha, 1]);
         end
      end %end of for kidx=1:num_ref_kplane,
      
      refscan_data{obj_cnt}=refscan_data{obj_cnt}(1:ice_obj.Npe,:,:,:,:);
      
      if(~isempty(fov_pe) && (peshift_voxel~=0))
         tmp_kz=[0:ice_obj.Npe-1]'-floor(ice_obj.Npe/2);
         tmp_kz=tmp_kz/fov_pe;
         peshift_mm=peshift_voxel*fov_pe/ice_obj.Npe;
         tmp_addphase=exp(sqrt(-1)*2*pi*tmp_kz*peshift_mm);
         sz_refscan=size(refscan_data{obj_cnt});
         refscan_data{obj_cnt}=refscan_data{obj_cnt}.*repmat(tmp_addphase,[1 sz_refscan(2:end)]);
      end
      refscan_data{obj_cnt}=fftshift(fft(fftshift(refscan_data{obj_cnt},1),[],1),1);
   else
      if(flag_train_scan==1)
         %N3D=gap_dist*sms_factor*num_slc_pae/slcthickness;
         N3D=twix_obj{s}.hdr.Config.NSlc*num_slc_pae;
         if(ref_rfmode==0) %single slab
            if(ref_force3d==0)
               refscan_data{obj_cnt}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, twix_obj{s}.hdr.Config.NSlc, twix_obj{s}.image.NCha, num_slc_pae, 'single');
            else
               refscan_data{obj_cnt}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, twix_obj{s}.hdr.Config.NSlc, twix_obj{s}.image.NCha, N3D, 'single');
            end
         elseif(ref_rfmode==1) %multislab slab
            if(ref_force3d==0)
               %refscan_data{obj_cnt}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, twix_obj{s}.hdr.Config.NSlc/sms_factor, twix_obj{s}.image.NCha, num_slc_pae*sms_factor, 'single');
               refscan_data{obj_cnt}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, twix_obj{s}.hdr.Config.NSlc, twix_obj{s}.image.NCha, num_slc_pae*sms_factor, 'single');
            else
               %refscan_data{obj_cnt}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, twix_obj{s}.hdr.Config.NSlc/sms_factor, twix_obj{s}.image.NCha, N3D, 'single');
               refscan_data{obj_cnt}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, twix_obj{s}.hdr.Config.NSlc, twix_obj{s}.image.NCha, N3D, 'single');
            end
         elseif(ref_rfmode==2) %3D
            %refscan_data{obj_cnt}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.image.NCha, N3D, 'single');
            refscan_data{obj_cnt}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, twix_obj{s}.hdr.Config.NSlc, twix_obj{s}.image.NCha, N3D, 'single');
         end
         %tmpnum_kplane=numel(find(twix_obj{s}.image.Rep==1))/twix_obj{s}.hdr.Config.RawLin;
         %num_ref_kplane=tmpnum_kplane-twix_obj{s}.hdr.Config.RawSlc/ice_obj.sms_factor;
         
         ice_obj.Nfe=twix_obj{s}.hdr.Config.BaseResolution;
         %ice_obj.Npe=twix_obj{s}.hdr.Config.PhaseEncodingLines;
         ice_obj.Nch=twix_obj{s}.image.NCha;
         ice_obj.NSlc=twix_obj{s}.hdr.Config.NSlc;
         num_refSlcOrig=twix_obj{s}.hdr.Config.RawSlc;
         
         if(ref_rfmode==0) %single slab
            num_refAcqSlc=num_refSlcOrig;
         elseif(ref_rfmode==1) %multislab slab
            num_refAcqSlc=num_refSlcOrig/sms_factor;
         elseif(ref_rfmode==2) %3D
            num_refAcqSlc=1;
         end
         
         num_ref_kplane=ice_obj.pat*num_refAcqSlc*num_ref_pae;
         ref_slcidx_all=unique(twix_obj{s}.image.Sli(1:num_ref_kplane*n_acqLperKplane));
         
         if(flag_phase_cor)
            sz_phcor=size(phasecor_rawdata(:,:,1:num_ref_kplane*3));
            phcor_data=reshape(phasecor_rawdata(:,:,1:num_ref_kplane*3),[sz_phcor(1),sz_phcor(2),3,num_refAcqSlc,ice_obj.pat,num_ref_pae]);
            phcor_data=fftshift(fft(ifftshift(phcor_data,6),[],6),6);
         end
         
         sz_img=size(image_rawdata(:,:,1:num_ref_kplane*n_acqLperKplane));
         refimg_data=reshape(image_rawdata(:,:,1:num_ref_kplane*n_acqLperKplane),[sz_img(1),sz_img(2),n_acqLperKplane,num_refAcqSlc,ice_obj.pat,num_ref_pae]);
         refimg_data=fftshift(fft(ifftshift(refimg_data,6),[],6),6);
         
         for paeidx=1:num_ref_pae,
            nav_echo=[];
            for sidx=1:num_refAcqSlc,
               for pidx=1:ice_obj.pat,
                  pat_offset=(pidx-1)*n_acqLperKplane*num_refAcqSlc;
                  img_slcidx=unique(twix_obj{s}.image.Sli(pat_offset+(sidx-1)*n_acqLperKplane+1:pat_offset+sidx*n_acqLperKplane));
                  if(numel(img_slcidx)>1)
                     fprintf('ERROR! The in-plane k lines should belong to the same slice.\n');
                     return;
                  end
                  
                  if(flag_phase_cor)
                     for nvidx=1:3,
                     %for nvidx=1:2,
                        nav_echo{sidx, twix_obj{s}.phasecor.Seg(nvidx)}=reshape(phcor_data(:,:,nvidx,sidx,pidx,paeidx),[sz_phcor(1),sz_phcor(2)]);
                     end
                     calc_epi_phase_correction(nav_echo, sidx);
                     
                     if(~ice_obj.flag_phase_cor_algorithm_conv)
                        oddline_idx=find(twix_obj{s}.image.Seg(1:n_acqLperKplane)==2);
                        tmp_kplane=reshape(refimg_data(:,:,:,sidx,pidx,paeidx),[sz_img(1),sz_img(2),n_acqLperKplane]);
                        pc_kplane=tmp_kplane;
                        pc_kplane(:,:,oddline_idx)=apply_epi_phase_correction(tmp_kplane(:,:,oddline_idx));
                     else
                        evenline_idx=find(twix_obj{s}.image.Seg(1:n_acqLperKplane)==1);
                        oddline_idx =find(twix_obj{s}.image.Seg(1:n_acqLperKplane)==2);
                        tmp_kplane=reshape(refimg_data(:,:,:,sidx,pidx,paeidx),[sz_img(1),sz_img(2),n_acqLperKplane]);
                        %pc_kplane=tmp_kplane;
                        LineLength = size(tmp_kplane,1);
                        linesReshapeCorrected=zeros([size(tmp_kplane,1), size(tmp_kplane,3), size(tmp_kplane,2)]);
                        for DataSetCount = 1:size(tmp_kplane,2)
                           Line1 = reshape(tmp_kplane(:,DataSetCount,evenline_idx),size(refimg_data,1),[]);
                           Line2 = reshape(tmp_kplane(:,DataSetCount,oddline_idx) ,size(refimg_data,1),[]);
                           
                           ConstPhaseDiff = ice_obj.nav_phase_constant(DataSetCount);
                           Total_SecondLineShiftBy = ice_obj.nav_line_shift(DataSetCount);
                           Line1Shift = -Total_SecondLineShiftBy*ShiftFracForLine1;
                           Line2Shift = Total_SecondLineShiftBy + Line1Shift;
                           
                           Phase1 = exp(-sqrt(-1)*2*pi* (-ceil((LineLength-1)/2):floor((LineLength-1) /2))/LineLength *(Line1Shift/OS_factor) ).';
                           linesReshapeCorrected(:, evenline_idx, DataSetCount) = Line1.*repmat(Phase1,1,size(Line1,2))  /exp(sqrt(-1)*ConstPhaseDiff);
                           Phase2 = exp(-sqrt(-1)*2*pi* (-ceil((LineLength-1)/2):floor((LineLength-1) /2))/LineLength *(Line2Shift/OS_factor) ).';
                           linesReshapeCorrected(:, oddline_idx, DataSetCount) = Line2.*repmat(Phase2,1,size(Line2,2));
                        end
                        pc_kplane=permute(linesReshapeCorrected,[1 3 2]);
                     end
                  else
                     pc_kplane=reshape(refimg_data(:,:,:,sidx,pidx,paeidx),[sz_img(1),sz_img(2),n_acqLperKplane]);
                  end
                  
                  refscan_data{obj_cnt}(PEshift(obj_cnt)+twix_obj{s}.image.Lin(pat_offset+1:pat_offset+n_acqLperKplane),:,img_slcidx,:,paeidx)=reshape(permute(pc_kplane,[3 1 2]),[n_acqLperKplane, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.image.NCha, 1]);
               end
            end
         end
         
         refscan_data{obj_cnt}=fftshift(ifft(ifftshift(refscan_data{obj_cnt},5),[],5),5);
         refscan_data{obj_cnt}=refscan_data{obj_cnt}(1:ice_obj.Npe,:,ref_slcidx_all,:,:);
         
         if(~isempty(fov_pe) && (peshift_voxel~=0))
            tmp_kz=[0:ice_obj.Npe-1]'-floor(ice_obj.Npe/2);
            tmp_kz=tmp_kz/fov_pe;
            peshift_mm=peshift_voxel*fov_pe/ice_obj.Npe;
            tmp_addphase=exp(sqrt(-1)*2*pi*tmp_kz*peshift_mm);
            sz_refscan=size(refscan_data{obj_cnt});
            refscan_data{obj_cnt}=refscan_data{obj_cnt}.*repmat(tmp_addphase,[1 sz_refscan(2:end)]);
         end
         
         refscan_data{obj_cnt}=fftshift(fft(fftshift(refscan_data{obj_cnt},1),[],1),1);
      end %end of if(flag_train_scan==1)
   end %end of if(isfield(twix_obj{s},'refscan'))
   %twix_obj{s}.hdr.Dicom.lAccelFactPE
   
   %n_acqLperKplane=twix_obj{s}.hdr.Config.RawLin;
   if(isfield(twix_obj{s},'refscan'))
      num_img_kplane=twix_obj{s}.image.NAcq/n_acqLperKplane;
      acc_slcidx_all=unique(twix_obj{s}.image.Sli);
      num_imgAcqSlc=numel(acc_slcidx_all);
   else
      if(flag_train_scan==1)
         num_img_kplane=twix_obj{s}.image.NAcq/n_acqLperKplane-num_ref_kplane;
         acc_slcidx_all=unique(twix_obj{s}.image.Sli(num_ref_kplane*n_acqLperKplane+1:end));
         num_imgAcqSlc=numel(acc_slcidx_all);
      end
   end
   min_slicidx=min(acc_slcidx_all);
   
   sz_img=size(image_rawdata(:,:,num_ref_kplane*n_acqLperKplane+1:end));
   Nrep=sz_img(3)/(n_acqLperKplane*num_imgAcqSlc*num_slc_pae);
   accimg_data=reshape(image_rawdata(:,:,num_ref_kplane*n_acqLperKplane+1:end),[sz_img(1),sz_img(2),n_acqLperKplane,num_imgAcqSlc,num_slc_pae,Nrep]);
   accimg_data=fftshift(fft(ifftshift(accimg_data,5),[],5),5);
   
   %image_data{obj_cnt}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, twix_obj{s}.hdr.Config.NSlc, twix_obj{s}.image.NCha, num_slc_pae, Nrep,'single');
   image_data{obj_cnt}=zeros(ice_obj.Npe, twix_obj{s}.hdr.Config.BaseResolution, num_imgAcqSlc, twix_obj{s}.image.NCha, num_slc_pae, Nrep,'single');
   
   if(flag_phase_cor)
      sz_phcor=size(phasecor_rawdata(:,:,num_ref_kplane*3+1:end));
      phcor_data=reshape(phasecor_rawdata(:,:,num_ref_kplane*3+1:end),[sz_phcor(1),sz_phcor(2),3,num_imgAcqSlc,num_slc_pae,Nrep]);
      phcor_data=fftshift(fft(ifftshift(phcor_data,5),[],5),5);
   end
   
   for ridx=1:Nrep,
      for pidx=1:num_slc_pae,
         nav_echo=[];
         for sidx=1:num_imgAcqSlc,
            img_slcidx=unique(twix_obj{s}.image.Sli((num_ref_kplane+sidx-1)*n_acqLperKplane+1:(num_ref_kplane+sidx)*n_acqLperKplane));
            if(numel(img_slcidx)>1)
               fprintf('ERROR! The in-plane k lines should belong to the same slice.\n');
               return;
            end
            
            if(flag_phase_cor)
               for nvidx=1:3,
               %for nvidx=1:2,
                  nav_echo{sidx, twix_obj{s}.phasecor.Seg(nvidx)}=reshape(phcor_data(:,:,nvidx,sidx,pidx,ridx),[sz_phcor(1),sz_phcor(2)]);
               end
               calc_epi_phase_correction(nav_echo, sidx);
               
               if(~ice_obj.flag_phase_cor_algorithm_conv)
                  oddline_idx=find(twix_obj{s}.image.Seg((num_ref_kplane+sidx-1)*n_acqLperKplane+1:(num_ref_kplane+sidx)*n_acqLperKplane)==2);
                  tmp_kplane=reshape(accimg_data(:,:,:,sidx,pidx,ridx),[sz_img(1),sz_img(2),n_acqLperKplane]);
                  pc_kplane=tmp_kplane;
                  pc_kplane(:,:,oddline_idx)=apply_epi_phase_correction(tmp_kplane(:,:,oddline_idx));
               else
                  evenline_idx=find(twix_obj{s}.image.Seg((num_ref_kplane+sidx-1)*n_acqLperKplane+1:(num_ref_kplane+sidx)*n_acqLperKplane)==1);
                  oddline_idx =find(twix_obj{s}.image.Seg((num_ref_kplane+sidx-1)*n_acqLperKplane+1:(num_ref_kplane+sidx)*n_acqLperKplane)==2);
                  tmp_kplane=reshape(accimg_data(:,:,:,sidx,pidx,ridx),[sz_img(1),sz_img(2),n_acqLperKplane]);
                  %pc_kplane=tmp_kplane;
                  LineLength = size(tmp_kplane,1);
                  linesReshapeCorrected=zeros([size(tmp_kplane,1), size(tmp_kplane,3), size(tmp_kplane,2)]);
                  for DataSetCount = 1:size(tmp_kplane,2)
                     Line1 = reshape(tmp_kplane(:,DataSetCount,evenline_idx),size(accimg_data,1),[]);
                     Line2 = reshape(tmp_kplane(:,DataSetCount,oddline_idx) ,size(accimg_data,1),[]);
                     
                     ConstPhaseDiff = ice_obj.nav_phase_constant(DataSetCount);
                     Total_SecondLineShiftBy = ice_obj.nav_line_shift(DataSetCount);
                     Line1Shift = -Total_SecondLineShiftBy*ShiftFracForLine1;
                     Line2Shift = Total_SecondLineShiftBy + Line1Shift;
                     
                     Phase1 = exp(-sqrt(-1)*2*pi* (-ceil((LineLength-1)/2):floor((LineLength-1) /2))/LineLength *(Line1Shift/OS_factor) ).';
                     linesReshapeCorrected(:, evenline_idx, DataSetCount) = Line1.*repmat(Phase1,1,size(Line1,2))  /exp(sqrt(-1)*ConstPhaseDiff);
                     Phase2 = exp(-sqrt(-1)*2*pi* (-ceil((LineLength-1)/2):floor((LineLength-1) /2))/LineLength *(Line2Shift/OS_factor) ).';
                     linesReshapeCorrected(:, oddline_idx, DataSetCount) = Line2.*repmat(Phase2,1,size(Line2,2));
                  end
                  pc_kplane=permute(linesReshapeCorrected,[1 3 2]);
               end
            else
               pc_kplane=reshape(accimg_data(:,:,:,sidx,pidx,ridx),[sz_img(1),sz_img(2),n_acqLperKplane]);
            end
            
            %image_data{obj_cnt}(PEshift(obj_cnt)+twix_obj{s}.image.Lin((num_ref_kplane+sidx-1)*n_acqLperKplane+1:(num_ref_kplane+sidx)*n_acqLperKplane),:,img_slcidx,:,pidx,ridx) = reshape(permute(pc_kplane,[3 1 2]),[n_acqLperKplane, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.image.NCha, 1, 1]);
            image_data{obj_cnt}(PEshift(obj_cnt)+twix_obj{s}.image.Lin((num_ref_kplane+sidx-1)*n_acqLperKplane+1:(num_ref_kplane+sidx)*n_acqLperKplane),:,img_slcidx-min_slicidx+1,:,pidx,ridx) = reshape(permute(pc_kplane,[3 1 2]),[n_acqLperKplane, twix_obj{s}.hdr.Config.BaseResolution, 1, twix_obj{s}.image.NCha, 1, 1]);
         end %end of for sidx=1:num_imgAcqSlc,
      end %end of for pidx=1:num_slc_pae,
   end %end of for ridx=1:Nrep,
   
   image_data{obj_cnt}=fftshift(ifft(ifftshift(image_data{obj_cnt},5),[],5),5);
   image_data{obj_cnt}=image_data{obj_cnt}(1:ice_obj.Npe,:,:,:,:,:);
   
   if(~isempty(fov_pe) && (peshift_voxel~=0))
      tmp_kz=[0:ice_obj.Npe-1]'-floor(ice_obj.Npe/2);
      tmp_kz=tmp_kz/fov_pe;
      peshift_mm=peshift_voxel*fov_pe/ice_obj.Npe;
      tmp_addphase=exp(sqrt(-1)*2*pi*tmp_kz*peshift_mm);
      sz_imagescan=size(image_data{obj_cnt});
      image_data{obj_cnt}=image_data{obj_cnt}.*repmat(tmp_addphase,[1 sz_imagescan(2:end)]);
   end
   image_data{obj_cnt}=fftshift(fft(fftshift(image_data{obj_cnt},1),[],1),1);
   %image_data{obj_cnt}=fftshift(ifft(fftshift(image_data{obj_cnt},1),[],1),1);
end %end of for s=2:length(twix_obj),

%if length(twix_obj) == 2
if(obj_cnt == 1)
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
   ice_obj.nav_phase_slope=[];
   ice_obj.nav_phase_offset=[];
   ice_obj.nav_line_shift=[];
   ice_obj.nav_phase_constant=[];
   
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
      
      if(ice_obj.flag_phase_cor_algorithm_conv) %use conv to estimate the shift; then calculate the constant phase
         phi=zeros(2,size(even,2));
         for i=1:size(even,2),
            [phi(1,i) phi(2,i)]=conv_artifact_ghost_compute_wt(even(:,i), odd(:,i));  
         end
         ice_obj.nav_phase_constant = phi(1,:)';
         ice_obj.nav_line_shift = phi(2,:)';
      end
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

function [ConstPhaseDiff, SecondLineShiftBy, Line1_corrected] = conv_artifact_ghost_compute_wt(Line1,Line2,OS_factor)
   
   % Kawin Setsompop
   % 7/29/2012
   
   if nargin == 2
       OS_factor = 5; % oversampling factor
   end
   
   % convention here is to fix Line1
   
   Line1 = double(Line1); 
   Line2 = double(Line2);
   
   
   %% STEP 1: need to pad the data to get higher resolution to get aacurate calculation for the
   % shift that needs to be corrected 
   LineLength = size(Line1,1);
   PadOnEachSide = floor(LineLength*(OS_factor-1)/2);
   
   %Line1_OS = mrir_fDFT(mrir_zeropad( mrir_iDFT(Line1,1),PadOnEachSide,'both'),1);
   %Line2_OS = mrir_fDFT(mrir_zeropad( mrir_iDFT(Line2,1),PadOnEachSide,'both'),1);
   Line1_OS = fftshift(ifft(ifftshift(mrir_zeropad( Line1,PadOnEachSide,'both'),1),[],1),1);
   Line2_OS = fftshift(ifft(ifftshift(mrir_zeropad( Line2,PadOnEachSide,'both'),1),[],1),1);
   
   %% STEP 2: calculate the shift based on cross-correlation (this is better
   % than using conv as it does not wrap and only use points that exist on
   % both shifted dataset for a given shift)
   
   [value,shift] = max(abs(  conv(Line1_OS,conj(Line2_OS(end:-1:1))) ));
   %[value,shift] = max(abs(xcorr(Line1_OS,Line2_OS)));
   SecondLineShiftBy = shift-size(Line1_OS,1);
   
   
   %% STEP 3: fix the shift (might also want to do conjugation to the shifted point)
   Line1_OSshifted = circshift(Line1_OS,-SecondLineShiftBy);
   
   if(0)
       % use conjugate symetry approximation here.....
       if SecondLineShiftBy<0
           Line1_OSshifted(1:SecondLineShiftBy) = conj(Line1_OSshifted(1:SecondLineShiftBy));
       else
           Line1_OSshifted(end-SecondLineShiftBy:end) = conj(Line1_OSshifted(end-SecondLineShiftBy:end));
       end
   end
   
   %figure; plot(abs(Line1_OSshifted)); hold on; plot(abs(Line2_OS),'r');plot(abs(Line1_OS),'g'); 
   
   %% STEP 4: calculate the constant phase diff between the lines and fix it 
   PhaseDiff = angle(Line1_OSshifted./Line2_OS); 
   IntensityMask = abs(Line1_OSshifted) > max(abs(Line1_OSshifted))* 0.1 ;
   PhaseDiffSubset = PhaseDiff(IntensityMask); 
   
   ConstPhaseDiff = lscov(ones(size(PhaseDiffSubset)),PhaseDiffSubset,abs(Line1_OSshifted(IntensityMask))); % weighted fit where weighting is based on abs(Line1_shifted)
   
   Line1_OScorrected = Line1_OSshifted/exp(sqrt(-1)*ConstPhaseDiff);
   
   %% STEP 5: down sample the final data by 3
   
   %Line1_corrected = 3*Line1_OScorrected(1:OS_factor:end); % work only for even number of points along the line
   
   %Image_Line1_OScorrected = mrir_iDFT(Line1_OScorrected,1);
   %Line1_corrected = mrir_fDFT(Image_Line1_OScorrected(1+PadOnEachSide:LineLength+PadOnEachSide),1);
   Image_Line1_OScorrected = fftshift(fft(ifftshift(Line1_OScorrected,1),[],1),1);
   Line1_corrected = fftshift(ifft(ifftshift(Image_Line1_OScorrected(1+PadOnEachSide:LineLength+PadOnEachSide),1),[],1),1);
   
   if (0)
   %     figure
   %     plot(abs(Line1_OScorrected)); hold on; plot(abs(Line2_OS),'r')
       
       figure;
       subplot(3,1,1); plot(abs(Line1_corrected)); hold on; plot(abs(Line2),'r'); title('Magnitude aligning'); 
   
       subplot(3,1,2); plot(PhaseDiff); hold on; plot(IntensityMask,'r'); title('PhaseDiff and IntensityMask'); 
   
       subplot(3,1,3);  plot(PhaseDiffSubset);
       hold on; plot(ConstPhaseDiff*ones(size(PhaseDiffSubset)),'r'); title('PhaseDiffSubset and fitted constant'); 
       
   end
return;

function b = mrir_zeropad(a, padsize, direction)
   %MRIR_ZEROPAD pad an array with zeros
   %
   % B = MRIR_ZEROPAD(A,PADSIZE) pads array A with PADSIZE(k) number of zeros
   % along the k-th dimension of A. PADSIZE should be a vector of positive
   % integers.
   %
   % B = MRIR_ZEROPAD(A,PADSIZE,DIRECTION) pads A in the direction specified by
   % the string DIRECTION. DIRECTION can be one of the following strings.
   %
   %       string values for DIRECTION
   %       'pre'         pads before the first array element along each
   %                     dimension .
   %       'post'        pads after the last array element along each
   %                     dimension.
   %       'both'        pads before the first array element and after the
   %                     last array element along each dimension.
   
   % (this function is a subset of matlab's PADARRAY, which is a part of the
   % Image Processing toolbox---and therefore eats a precious license when its
   % called.)
   
   % jonathan polimeni <jonp@nmr.mgh.harvard.edu>, 2009/dec/04
   % $Id: mrir_zeropad.m,v 1.2 2011/03/28 04:14:47 jonp Exp $
   %**************************************************************************%
   
   %VERSION = '$Revision: 1.2 $';
   %if ( nargin == 0 ), help(mfilename); return; end;
   
   
   %==--------------------------------------------------------------------==%
   
   % preprocess the padding size
   if ( numel(padsize) < ndims(a) ),
     padsize           = padsize(:);
     padsize(ndims(a)) = 0;
   end;
   
   numDims = numel(padsize);
   
   % form index vectors to subsasgn input array into output array.
   % also compute the size of the output array.
   idx   = cell(1,numDims);
   sizeB = zeros(1,numDims);
   for k = 1:numDims,
     M = size(a,k);
     switch direction,
      case 'pre',
       idx{k}   = (1:M) + padsize(k);
       sizeB(k) = M + padsize(k);
   
      case 'post',
       idx{k}   = 1:M;
       sizeB(k) = M + padsize(k);
   
      case 'both',
       idx{k}   = (1:M) + padsize(k);
       sizeB(k) = M + 2*padsize(k);
     end;
   end;
   
   % initialize output array with the padding value and make sure the
   % output array is the same type as the input
   b         = cast( repmat(0, sizeB), class(a) );
   b(idx{:}) = a;
return;


