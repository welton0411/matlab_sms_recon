clear all;
close all;
fclose all;
dbclear all;
%=================================================================
% environment setting
%=================================================================
%addpath /proj/weitangc/users/weitangc/matlab_lib/ice_master_vd13;
addpath(genpath('/proj/weitangc/users/weitangc/matlab_lib/fhlin_toolbox'));
addpath /proj/weitangc/users/weitangc/matlab_lib/welton_toolbox;
addpath /proj/weitangc/users/weitangc/matlab_lib/NIfTI_20140122;
%dbstop in ice_master_welton2.m at 430 if (s==2 && ch==22);
%dbstop in ice_master_welton2.m at 430;
%dbstop in datapack2_VE.m at 390;
%dbstop in mapVBVDVE_wt.m at 380;
%=================================================================
%  Parameter input
%=================================================================
datapn='/proj/weitangc/projects/MB3D/data/3T_s2025010601';
outdir='/proj/weitangc/projects/MB3D/analysis/3T_s2025010601';
subdir_prefix{1} ='vn4p2p3_cali_wtp1_0p9mm_TE33_PA_';
subdir_prefix{2} ='vn4p2p3_rest_wtp1_0p9mm_TE33_AP_';
subdir_prefix{3} ='vn4p2p3_cali_wtp1_0p9mm_TE46_PA_';
subdir_prefix{4} ='vn4p2p3_rest_wtp1_0p9mm_b8_AP_';
subdir_prefix{5} ='vn4p2p3_FT18_wtp1_0p9mm_TE33_AP_';
subdir_prefix{6} ='vn4p2p3_FT18_wtp1_0p9mm_b8_AP_';

noise_cov_fn=[];

filesin{1}= {'meas_MID01907_FID02371_vn4p2p3_cali_wtp1_0p9mm_TE33_PA.dat','meas_MID01915_FID02379_vn4p2p3_cali_wtp1_0p9mm_TE33_PA.dat'};
filesin{2}= {'meas_MID01909_FID02373_vn4p2p3_rest_wtp1_0p9mm_TE33_AP.dat'};
filesin{3}= {'meas_MID01911_FID02375_vn4p2p3_cali_wtp1_0p9mm_TE46_PA.dat','meas_MID01919_FID02383_vn4p2p3_cali_wtp1_0p9mm_TE46_PA.dat'};
filesin{4}= {'meas_MID01913_FID02377_vn4p2p3_rest_wtp1_0p9mm_b8_AP.dat'};
filesin{5}= {'meas_MID01917_FID02381_vn4p2p3_FT18_wtp1_0p9mm_TE33_AP.dat'};
filesin{6}= {'meas_MID01921_FID02385_vn4p2p3_FT18_wtp1_0p9mm_b8_AP.dat'};

filesout='var_mb3ddata.mat';

%=================================================================
%  Default parameter setting
%=================================================================
%n_channel=32;
flag_debug=0;
flag_3d=0;
%n_row=96;
%n_col=96;

flag_ice_read=1;

fov_xy_all={[189.375 202.0], [189.375 202.0], [189.375 202.0], [189.375 202.0], [189.375 202.0], [189.375 202.0], [189.375 202.0], [189.375 202.0]}; %[PE FE]; unit: mm
mtxsz_xy_all={[210 224], [210 224], [210 224], [210 224], [210 224], [210 224], [210 224], [210 224]}; %[PE FE]; unit: mm
nz_all                  =[44 44 44 44 44 44 44 44];
num_slc_pae_all         =[3 3 3 3 3 3 3 3];
flag_phase_cor_all      =[1 1 1 1 1 1 1 1];
flag_train_scan_all     =[1 1 1 1 1 1 1 1];
ref_rfmode_all          =[1 1 1 1 1 1 1 1]; %0: 2D ref scan; 1: MB ref scan; 2: 3D ref scan
ref_force3d_all         =[0 0 0 0 0 0 0 0];
ref_kdist_all           =[1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0];
%gap_dist_all            =[32.0 33.0 28.8 28.8];
slcthickness_all        =[2.7 2.7 2.7 2.7 2.7 2.7 2.7 2.7];
flag_train_spsg_all     =[0 0 0 0 0 0 0 0];
sms_factor_all          =[4 4 4 4 4 4 4 4];
pat_all                 =[2 2 2 2 2 2 2 2];
peshift_voxel_all       =[0 0 0 0 0 0 0 0]; %the positive point toward the PE direction, e.g. if PE direction is H >> F, the positive value of shift will shift the object toward the foot
%num_acsline_perseg_all  =[0 38 38 0 40 40];
%eval(sprintf('addpath %s;',datapn));

%=================================================================
%  Loading the RAW data
%=================================================================
%dbstop in ice_react_on_flags_welton.m at 83;

for ridx=1:numel(nz_all),
   nz_sms=nz_all(ridx)/sms_factor_all(ridx);
   if(sms_factor_all(ridx)>1)
      half_sms=floor((sms_factor_all(ridx)-1)/2);
      sms_lastslc_index_all(ridx)=(half_sms+1)*nz_sms-2; %0'-based
   else
      sms_lastslc_index_all(ridx)=nz_all(ridx)-2; %0'-based
      %sms_lastslc_index_all(ridx)=nz_all(ridx)-1; %0'-based
   end
end

for i=1, %1:length(filesin),
   for j=1:length(filesin{i}),
      folder_name=sprintf('%s%d',subdir_prefix{i},j);
      eval(sprintf('!mkdir -p %s/%s',outdir,folder_name));
      cur_dir=pwd;
      eval(sprintf('cd %s/%s/',outdir,folder_name));
      
      filename=sprintf('%s/%s',datapn,filesin{i}{j});
      fov_xy=fov_xy_all{i};
      mtxsz_xy=mtxsz_xy_all{i};
      fov_pe=fov_xy(1);
      fov_fe=fov_xy(2);
      n_pe=mtxsz_xy(1);
      n_fe=mtxsz_xy(2);
      nz=nz_all(i);
      flag_phase_cor=flag_phase_cor_all(i);
      flag_train_scan=flag_train_scan_all(i);
      ref_rfmode=ref_rfmode_all(i);
      ref_force3d=ref_force3d_all(i);
      ref_kdist=ref_kdist_all(i);
      %gap_dist=gap_dist_all(i);
      slcthickness=slcthickness_all(i);
      flag_train_spsg=flag_train_spsg_all(i);
      sms_factor=sms_factor_all(i);
      pat=pat_all(i);
      %num_acsline_perseg=num_acsline_perseg_all(i);
      sms_lastslc_index=sms_lastslc_index_all(i);
      num_slc_pae=num_slc_pae_all(i);
      peshift_voxel=peshift_voxel_all(i);
      
      noise_data=[];
      train_volcplx=[];
      prism_data=[];
      Ntime = [];
      
      if(flag_ice_read==1)
         noise_data=[];
         %keyboard;
         %flag_phase_cor=0;
         %twix_obj = mapVBVDVE_wt(filename,'regrid','removeos');
         twix_obj = mapVBVD_wt(filename,'regrid','removeos');
         %twix_obj = mapVBVDVE_wt(filename,'regrid','readhdr');
         %[noise_data train_volcplx prism_data]=datapack_VB(twix_obj,'flag_phase_cor',flag_phase_cor,'flag_phase_cor_mgh',1,...
         %                                       'flag_phase_cor_algorithm_lsq',1,'pat',pat,'num_slc_pae',num_slc_pae,'sms_factor',sms_factor,...
         %                                       'n_pe',n_pe,'flag_train_scan',flag_train_scan);
         [noise_data train_volcplx prism_data ref_slcidx_all]=datapack4_VE(twix_obj,'flag_phase_cor',flag_phase_cor,'flag_phase_cor_mgh',1,'fov_pe',fov_pe,...
                                                'flag_phase_cor_algorithm_conv',1,'pat',pat,'num_slc_pae',num_slc_pae,'sms_factor',sms_factor,...
                                                'n_pe',n_pe,'flag_train_scan',flag_train_scan,'peshift_voxel',peshift_voxel,...
                                                'ref_rfmode',ref_rfmode,'ref_force3d',ref_force3d,'ref_kdist',ref_kdist,'slcthickness',slcthickness);
      else
         eval(sprintf('load %s/%s/%s train_volcplx prism_data noise_data nz pat flag_train_scan sms_factor num_slc_pae num_ref_pae ref_slcidx_all;',outdir,folder_name,filesout));
      end
      
      if(flag_train_scan==1)
         sz_refimg=size(train_volcplx);
         train_volimg =reshape(sqrt(sum(abs(train_volcplx).^2,4)),[sz_refimg(1:3),size(train_volcplx,5)]);
         %N3D=gap_dist*sms_factor*num_slc_pae/slcthickness;
         N3D=nz*num_slc_pae;
         
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
         
         if(num_ref_pae==N3D)
            num_slc=sz_refimg(3);
            for sidx=1:num_slc,
               figure; fmri_mont(squeeze(train_volimg(:,:,sidx,:))); colormap jet; colorbar;
               title(sprintf('Ref scan Slice #%d',sidx));
            end
         else
            for pidx=1:num_ref_pae,
               figure; fmri_mont(squeeze(train_volimg(:,:,:,pidx))); colormap jet; colorbar;
               title(sprintf('Ref scan PAE #%d',pidx));
            end
         end
      end
      %train_volcplx=squeeze(train_volcplx);
      
      prism_img_disp=squeeze(sqrt(sum(abs(prism_data(:,:,:,:,floor(num_slc_pae/2)+1,end)).^2,4)));
      figure; fmri_mont(prism_img_disp); colormap jet; colorbar;
      
      %if(~isempty(findstr('sag',subdir_prefix{i}))) %Saggital projection
      %   prism_data = permute(prism_data,[1 2 5 4 3]);
      %elseif (~isempty(findstr('cor',subdir_prefix{i})))
      %   prism_data = permute(prism_data,[1 2 5 4 3]);
      %else
      %   prism_data = permute(prism_data,[1 2 5 4 3]);
      %end
      
      eval(sprintf('save %s/%s/%s train_volcplx prism_data noise_data nz pat flag_train_scan sms_factor num_slc_pae num_ref_pae ref_slcidx_all -v7.3;',outdir,folder_name,filesout));
      fprintf('Done!\n');
      cd(cur_dir);
   end %end of for j=1:length(filesin{i}),
end %end of for i=1:length(filesin),
