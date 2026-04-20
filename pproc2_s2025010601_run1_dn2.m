close all;
clear all;
fclose all;

%=================================================================
%  SETUP FOR INPUT DATA
%=================================================================
addpath(genpath('/proj/weitangc/users/weitangc/matlab_lib/fhlin_toolbox'));
addpath /proj/weitangc/users/weitangc/matlab_lib/NIfTI_20140122;
addpath /proj/weitangc/users/weitangc/matlab_lib/welton_toolbox;

%=================================================================
%  Parameter input
%=================================================================
in_dir='/proj/weitangc/projects/MB3D/analysis/3T_s2025010601';
datapath={{'recon_vn4p2p3_rest_wtp1_0p9mm_TE33_AP_1_dn2'},...
          {'recon_vn4p2p3_rest_wtp1_0p9mm_b8_AP_1_dn2'},...
          {'recon_vn4p2p3_FT18_wtp1_0p9mm_TE33_AP_1_dn2'},...
          {'recon_vn4p2p3_FT18_wtp1_0p9mm_b8_AP_1_dn2'}};
out_fn={{'axi_0p9_vn4p2p3_rest_wtp1_TE33_dn2'},...
        {'axi_0p9_vn4p2p3_rest_wtp1_b8_dn2'},...
        {'axi_0p9_vn4p2p3_FT18_wtp1_TE33_dn2'},...
        {'axi_0p9_vn4p2p3_FT18_wtp1_b8_dn2'}};
%anatpath=[]; %'FSE';
%mc_filein_flag=[0];

num_scans=[300 300 266 266];
%discard_scans={[1:15,586:600]};

epi_anat_dir={{'/proj/weitangc/projects/MB3D/analysis/3T_s2025010601/vn4p2p3_rest_wtp1_0p9mm_TE33_AP_1'},...
              {'/proj/weitangc/projects/MB3D/analysis/3T_s2025010601/vn4p2p3_rest_wtp1_0p9mm_b8_AP_1'},...
              {'/proj/weitangc/projects/MB3D/analysis/3T_s2025010601/vn4p2p3_FT18_wtp1_0p9mm_TE33_AP_1'},...
              {'/proj/weitangc/projects/MB3D/analysis/3T_s2025010601/vn4p2p3_FT18_wtp1_0p9mm_b8_AP_1'}};
epi_anat_fn={{'ref_comb_mag'},...
             {'ref_comb_mag'},...
             {'ref_comb_mag'},...
             {'ref_comb_mag'}};
brain_anat_dir='/proj/weitangc/projects/MB3D/analysis/3T_s2025010601/coreg';
brain_anat_fn ='brain_crop';
gm_mask_fn='gm_mask_crop';
wm_mask_fn='wm_mask_crop';
%t1_anat_fn ='T1_crop';
%temp_dir='/proj/weitangc/projects/r21_hippoc/data/mni_icbm152_nlin_asym_09a_nifti/mni_icbm152_nlin_asym_09a';
%temp_fn='mni_icbm152_t1_tal_nlin_asym_09a';
%ref_dir='/new_home/changw/matlab/GenPurpose/coreg/bruker_data';
%geom_human={'epi4d_fmri_humanx10.nii'};
%geom_mouse={'epi4d_fmri_mouse.nii'};

featfsf_template_dir='/proj/weitangc/projects/MB3D/code';
featfsf_template_fn='template_feat_r10min.fsf';
%featfsf_run_fn={'axi_0p9_mb6x1_pat2_task_b0_dn2',...
%                'axi_0p9_mb6x1_pat2_task_b9_dn2',...
%                'axi_0p9_mb6x1_pat2_task_b18_dn2'};
featfsf_run_fn={'axi_0p9_vn4p2p3_rest_wtp1_TE33_dn2',...
                'axi_0p9_vn4p2p3_rest_wtp1_b8_dn2',...
                'axi_0p9_vn4p2p3_FT18_wtp1_TE33_dn2',...
                'axi_0p9_vn4p2p3_FT18_wtp1_b8_dn2'};

icafsf_template_dir='/proj/weitangc/projects/MB3D/code';
icafsf_template_fn='template_melodic_1run.fsf';
%icafsf_run_fn={'axi_0p9_mb6x1_pat2_task_b0_dn2',...
%               'axi_0p9_mb6x1_pat2_task_b9_dn2',...
%               'axi_0p9_mb6x1_pat2_task_b18_dn2'};
icafsf_run_fn={'axi_0p9_vn4p2p3_rest_wtp1_TE33_dn2',...
               'axi_0p9_vn4p2p3_rest_wtp1_b8_dn2',...
               'axi_0p9_vn4p2p3_FT18_wtp1_TE33_dn2',...
               'axi_0p9_vn4p2p3_FT18_wtp1_b8_dn2'};

fwdph_fn={{'vn4p2p3_rest_wtp1_0p9mm_TE33_AP_1/ref_comb_mag'},...
          {'vn4p2p3_rest_wtp1_0p9mm_b8_AP_1/ref_comb_mag'},...
          {'vn4p2p3_FT18_wtp1_0p9mm_TE33_AP_1/ref_comb_mag'},...
          {'vn4p2p3_FT18_wtp1_0p9mm_b8_AP_1/ref_comb_mag'}};
revph_fn={{'vn4p2p3_cali_wtp1_0p9mm_TE33_PA_1/ref_comb_mag'},...
          {'vn4p2p3_cali_wtp1_0p9mm_TE46_PA_1/ref_comb_mag'},...
          {'vn4p2p3_cali_wtp1_0p9mm_TE33_PA_2/ref_comb_mag'},...
          {'vn4p2p3_cali_wtp1_0p9mm_TE46_PA_2/ref_comb_mag'}};
out_fwdph_fn={{'vn4p2p3_rest_wtp1_0p9mm_TE33_AP_1_comb_mag'},...
              {'vn4p2p3_rest_wtp1_0p9mm_b8_AP_1_comb_mag'},...
              {'vn4p2p3_FT18_wtp1_0p9mm_TE33_AP_1_comb_mag'},...
              {'vn4p2p3_FT18_wtp1_0p9mm_b8_AP_1_comb_mag'}};
out_revph_fn={{'vn4p2p3_cali_wtp1_0p9mm_TE33_PA_1_comb_mag'},...
              {'vn4p2p3_cali_wtp1_0p9mm_TE46_PA_1_comb_mag'},...
              {'vn4p2p3_cali_wtp1_0p9mm_TE33_PA_2_comb_mag'},...
              {'vn4p2p3_cali_wtp1_0p9mm_TE46_PA_2_comb_mag'}};

sms_factor_all=[4, 4, 4, 4];
TR_all=[4.05, 4.05, 4.05, 4.05];
echo_spacing_all=[0.94, 0.94, 0.94, 0.94]/2.0;
flag_mixVN_all=[0 0 0 0];
flag_denoise_all=2*ones(1,length(datapath)); %zeros(1,length(datapath));
use_glmphase_all=[1, 1, 1, 1]; %[0, 0];

%=================================================================
%  SETUP FOR OUTPUT
%=================================================================
%outimgfhdr='i';

%=================================================================
%  SETUP FOR DESIGN MATRIX
%=================================================================
%secs_per_scan=2; %unit :second
%secs_per_param=1; %unit: second
%li_cfound_flag=1; %linear confound. 0: not include; 1: include
%sin_cfound_flag=0; %oscillation confound. 0: not include; 1: include
%cos_cfound_flag=0; %oscillation confound. 0: not include; 1: include
%mc_cfound_flag=1; %motion correction confound. 0: not include; 1: include; 2: depends on the motion parameters

%=================================================================
%  SETUP FOR PREPROCESSING
%=================================================================
flag_dataprep=1;
flag_mc=1;
flag_mc_ph=0; %1: apply motion correction to phase image; 2: just copy the motion-uncorrected phase images as motion corrected phase images
flag_glmphase=0;

flag_slctiming=1;
%TR=2; %unit: second
%sms_factor=6;
num_shot=1;

flag_distcor=1;
script_dir='/proj/weitangc/projects/MB3D/code';
fn_cnf='b02b0_wt';
%fn_acqparam='my_acq_param';
fn_acqparam='my_acq_param_0p9mm';
%echo_spacing=0.93/2.0; %unit: ms
flag_flip_fwdrev ={[1 0 1],[0 1 1]};
dim_rl_ap_si     ={[2 1 3],[2 1 3]};

flag_melodic=0;
flag_feat=0;
flag_ica=0;
fn_indv_anat='brain_crop';
flag_clean=0;
flag_fixclean=0; %only valid if flag_clean=1
fixtrain_prefix='fixtrain_run1_dn2';
%fixtrain_prefix='fixtrain_allruns';
fixtrain_dir='/proj/weitangc/projects/MB3D/analysis';
fix_thresh=15;
clean_compidx={{[1,2,3,4,6,7,8]},...
               {[1,3,5,8,10]},...
               {[1,2,4,5,6,7,8,9,10]},...
               {[1,2,3,4,5,7,10]} };
%clean_compidx={{[1 2 3 4 5 6 7 8 9 10 11 12 14 15 16 17 18 19 20 22 23 24 25 27 30 31 32 35 40 42 50],...
%                [1 2 3 4 5 6 7 8 10 14 16 17 19 20 21 23 24 26 30 31 32 34 35 38 39 40 41 42 43 44 49 50 55]},...
%               {[],...
%                [],...
%                [],...
%                [],...
%                [],...
%                []},...
%               {} };

flag_filter=1;
flt_band={[0.01],[0.01],[0.01],[0.01]}; %unit:Hz
filt_order=2;
num_cuttpnts=filt_order*4;

flag_warp=0;
label_dir='/proj/weitangc/projects/MB3D/analysis/3T_s2025010601/coreg';
labelin_fn={'lh.hippoAmygLabels-T1.v21.CA.FSvoxelSpace_crop','rh.hippoAmygLabels-T1.v21.CA.FSvoxelSpace_crop',...
            'ThalamicNuclei.v12.T1.FSvoxelSpace_crop'};
labelout_fn={'lh_hippoCA','rh_hippoCA','thalamicNuclei'};

flag_smooth=0; %0: do not smooth 3D data; 1: smooth the 3D data
smooth_fwhm=[1 1 1]; %unit: mm
%kernel=[];

%=================================================================
%  SETUP FOR DISPLAYING STATISTICAL MAPS
%=================================================================
%pvalue_th=1e-2;
%flag_check_rest=1;

%disp_th=3; %unit: voxel
%roi_radius=1; %unit: voxel

%%%%%%% automatic setting %%%%%%%
%t_th=sqrt(2)*erfcinv(pvalue_th*2);
%dbstop in fmri_overlay_roitcourse.m at 182;
%=================================
% load data
%=================================
%%%% Data processing for resting-state data %%%%
str=sprintf('!mkdir -p %s/coreg',in_dir);
eval(str);      
for fidx=1, %1:length(datapath),
   TR=TR_all(fidx);
   echo_spacing=echo_spacing_all(fidx);
   sms_factor=sms_factor_all(fidx);
   use_glmphase=use_glmphase_all(fidx);
   flag_denoise=flag_denoise_all(fidx);
   flag_mixVN=flag_mixVN_all(fidx);
   
	for j=1, %1:length(datapath{fidx}),
      if(flag_dataprep==1)
         fprintf('Preparing the file %s ... ',datapath{fidx}{j});
         %str=sprintf('!fslchfiletype NIFTI_GZ %s/%s %s/coreg/%s',in_dir,datapath{fidx}{j},in_dir,out_fn{fidx}{j});
         fstr_out=sprintf('%s/coreg/%s.nii.gz',in_dir,out_fn{fidx}{j});
         tmp_dir=dir(fstr_out);
         if(isempty(tmp_dir))
            str=sprintf('!ln -s %s/%s.nii.gz %s/coreg/%s.nii.gz',in_dir,datapath{fidx}{j},in_dir,out_fn{fidx}{j});
            eval(str);
         end
         fstr_out=sprintf('%s/coreg/%s_ph.nii.gz',in_dir,out_fn{fidx}{j});
         tmp_dir=dir(fstr_out);
         if(isempty(tmp_dir))
            str=sprintf('!ln -s %s/%s_ph.nii.gz %s/coreg/%s_ph.nii.gz',in_dir,datapath{fidx}{j},in_dir,out_fn{fidx}{j});
            eval(str);
         end
         str=sprintf('!fslmaths %s/coreg/%s -Tmean %s/coreg/%s_mean',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j});
         eval(str);
         fprintf('Done!\n');
      end %end of if(flag_dataprep==1)
      
      if(flag_mc==1)
         fprintf('Motion correction on the magnitude images ...\n');
         fstr=sprintf('%s/coreg/r_%s.nii.gz',in_dir,out_fn{fidx}{j});
         tmpdir=dir(fstr);
         if(~isempty(tmpdir))
            eval(sprintf('!rm %s',fstr));
            eval(sprintf('!rm %s/coreg/r_%s_mean.nii.gz',in_dir,out_fn{fidx}{j}));
            eval(sprintf('!rm -rf %s/coreg/r_%s.mat',in_dir,out_fn{fidx}{j}));
         end
         %str=sprintf('!mcflirt -in %s/coreg/%s -out %s/coreg/r_%s -meanvol',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j});
         %str=sprintf('!mcflirt -in %s/coreg/%s -out %s/coreg/r_%s -meanvol -mats',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j});
         str=sprintf('!mcflirt -in %s/coreg/%s -out %s/coreg/r_%s -meanvol -mats -spline_final',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j});
         eval(str);
         str=sprintf('!fslchfiletype NIFTI_GZ %s/coreg/r_%s_mean_reg %s/coreg/r_%s_mean',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j});
         eval(str);
         str=sprintf('!imrm %s/coreg/r_%s_mean_reg',in_dir,out_fn{fidx}{j});
         eval(str);
      end
      
      if(flag_mc_ph==1)
         fprintf('Preparing motion correction on the phase images ...\n');     
         fstr_mag=sprintf('%s/coreg/%s.nii.gz',in_dir,out_fn{fidx}{j});
         fstr_ph=sprintf('%s/coreg/%s_ph.nii.gz',in_dir,out_fn{fidx}{j});
         invol_mag=load_nii(fstr_mag);
         invol_ph=load_nii(fstr_ph);
         outimg_cplx=invol_mag.img.*exp(1j*invol_ph.img*pi/180);
         outimg_real=real(outimg_cplx);
         outimg_imag=imag(outimg_cplx);
         fstr_real=sprintf('%s/coreg/%s_real.nii.gz',in_dir,out_fn{fidx}{j});
         tmp_vox=invol_mag.hdr.dime.pixdim(2:4);
         outvol_real=make_nii(outimg_real,tmp_vox,[],16);
         save_nii(outvol_real,fstr_real);
         fstr_imag=sprintf('%s/coreg/%s_imag.nii.gz',in_dir,out_fn{fidx}{j});
         tmp_vox=invol_mag.hdr.dime.pixdim(2:4);
         outvol_imag=make_nii(outimg_imag,tmp_vox,[],16);
         save_nii(outvol_imag,fstr_imag);
         
         srcvol=invol_mag;
         srcvol.img=[];
         srcvol.hdr.dime.dim(5)=1;
         outvol_ph=invol_ph;
         outvol_mag=invol_mag;
         %str=sprintf('!fslnvols %s/coreg/%s > %s/coreg/tmp%d_%d.txt',in_dir,out_fn{fidx}{j},in_dir,fidx,j);
         %eval(str);
         %num_vols=textread(sprintf('%s/coreg/tmp%d_%d.txt',in_dir,fidx,j));
         num_vols=size(invol_mag.img,4);
         fdir_xfm=sprintf('%s/coreg/r_%s.mat',in_dir,out_fn{fidx}{j});
         cur_dir=pwd;
         eval(sprintf('cd %s',fdir_xfm));
         fprintf('Start applying motion transformation to phase images\n');
         for tidx=1:num_vols,
            fprintf('.');
            tmp_outvol_real=outvol_real;
            tmp_outvol_real.img=outvol_real.img(:,:,:,tidx);
            tmp_outvol_real.hdr.dime.dim(5)=1;
            tmp_fstr_real=sprintf('real_t%d.nii.gz',tidx-1);
            save_nii(tmp_outvol_real,tmp_fstr_real);
            tmp_fstr_xfm=sprintf('MAT_%04d',tidx-1);
            %str=sprintf('!flirt -in %s -ref %s -out mc_%s -init %s -applyxfm',tmp_fstr_real,tmp_fstr_real,tmp_fstr_real,tmp_fstr_xfm);
            str=sprintf('!flirt -interp spline -in %s -ref %s -out mc_%s -init %s -applyxfm',tmp_fstr_real,tmp_fstr_real,tmp_fstr_real,tmp_fstr_xfm);
            eval(str);
            
            tmp_outvol_imag=outvol_imag;
            tmp_outvol_imag.img=outvol_imag.img(:,:,:,tidx);
            tmp_outvol_imag.hdr.dime.dim(5)=1;
            tmp_fstr_imag=sprintf('imag_t%d.nii.gz',tidx-1);
            save_nii(tmp_outvol_imag,tmp_fstr_imag);
            tmp_fstr_xfm=sprintf('MAT_%04d',tidx-1);
            %str=sprintf('!flirt -in %s -ref %s -out mc_%s -init %s -applyxfm',tmp_fstr_imag,tmp_fstr_imag,tmp_fstr_imag,tmp_fstr_xfm);
            str=sprintf('!flirt -interp spline -in %s -ref %s -out mc_%s -init %s -applyxfm',tmp_fstr_imag,tmp_fstr_imag,tmp_fstr_imag,tmp_fstr_xfm);
            eval(str);
            
            tmpmc_fstr_real=sprintf('mc_%s',tmp_fstr_real);
            tmp_invol_real=load_nii(tmpmc_fstr_real);
            tmp_invol_real.img(find(~isfinite(tmp_invol_real.img(:))))=0;
            tmpmc_fstr_imag=sprintf('mc_%s',tmp_fstr_imag);
            tmp_invol_imag=load_nii(tmpmc_fstr_imag);
            tmp_invol_imag.img(find(~isfinite(tmp_invol_imag.img(:))))=0;
            outvol_ph.img(:,:,:,tidx)=angle(complex(tmp_invol_real.img,tmp_invol_imag.img))*180/pi;
            outvol_mag.img(:,:,:,tidx)=abs(complex(tmp_invol_real.img,tmp_invol_imag.img));
         end
         eval(sprintf('cd %s',cur_dir));
         fsrt_phout=sprintf('%s/coreg/r_%s_ph.nii.gz',in_dir,out_fn{fidx}{j});
         save_nii(outvol_ph,fsrt_phout);
         fsrt_magout=sprintf('%s/coreg/r_%s_mag.nii.gz',in_dir,out_fn{fidx}{j});
         save_nii(outvol_mag,fsrt_magout);
         
         fsrt_mag=sprintf('%s/coreg/r_%s.nii.gz',in_dir,out_fn{fidx}{j});
         outvol_mag=load_nii(fstr_mag);
         
         outimg_cplx=outvol_mag.img.*exp(1j*outvol_ph.img*pi/180);
         outimg_real=real(outimg_cplx);
         outimg_imag=imag(outimg_cplx);
         fstr_real=sprintf('%s/coreg/r_%s_real.nii.gz',in_dir,out_fn{fidx}{j});
         tmp_vox=invol_mag.hdr.dime.pixdim(2:4);
         outvol_real=make_nii(outimg_real,tmp_vox,[],16);
         save_nii(outvol_real,fstr_real);
         fstr_imag=sprintf('%s/coreg/r_%s_imag.nii.gz',in_dir,out_fn{fidx}{j});
         tmp_vox=invol_mag.hdr.dime.pixdim(2:4);
         outvol_imag=make_nii(outimg_imag,tmp_vox,[],16);
         save_nii(outvol_imag,fstr_imag);
         
         fprintf('   done\n');
      elseif(flag_mc_ph==2)
         fprintf('Motion correction on the phase images ...\n');
         fstr_mag=sprintf('%s/coreg/%s.nii.gz',in_dir,out_fn{fidx}{j});
         fstr_ph=sprintf('%s/coreg/%s_ph.nii.gz',in_dir,out_fn{fidx}{j});
         invol_mag=load_nii(fstr_mag);
         invol_ph=load_nii(fstr_ph);
         outimg_cplx=invol_mag.img.*exp(1j*invol_ph.img*pi/180);
         outimg_real=real(outimg_cplx);
         outimg_imag=imag(outimg_cplx);
         fstr_real=sprintf('%s/coreg/%s_real.nii.gz',in_dir,out_fn{fidx}{j});
         tmp_vox=invol_mag.hdr.dime.pixdim(2:4);
         outvol_real=make_nii(outimg_real,tmp_vox,[],16);
         save_nii(outvol_real,fstr_real);
         fstr_imag=sprintf('%s/coreg/%s_imag.nii.gz',in_dir,out_fn{fidx}{j});
         tmp_vox=invol_mag.hdr.dime.pixdim(2:4);
         outvol_imag=make_nii(outimg_imag,tmp_vox,[],16);
         save_nii(outvol_imag,fstr_imag);
         
         fstr_rout=sprintf('%s/coreg/r_%s_real.nii.gz',in_dir,out_fn{fidx}{j});
         str=sprintf('!rsync -av %s %s',fstr_real,fstr_rout);
         eval(str);
         fstr_iout=sprintf('%s/coreg/r_%s_imag.nii.gz',in_dir,out_fn{fidx}{j});
         str=sprintf('!rsync -av %s %s',fstr_imag,fstr_iout);
         eval(str);
      end
      
      if(use_glmphase==1)
         str_glmph='v';
         if(flag_glmphase==1)
            fstr_mag=sprintf('%s/coreg/r_%s.nii.gz',in_dir,out_fn{fidx}{j});
            fstr_ph=sprintf('%s/coreg/r_%s_ph.nii.gz',in_dir,out_fn{fidx}{j});
            invol_mag=load_nii(fstr_mag);
            invol_ph=load_nii(fstr_ph);
            sz_img=size(invol_mag.img);
            ctrst_vec=[0 1]';
            fprintf('Phase regression for plane #');
            img_avg=mean(invol_mag.img,4);
            neg_idx=find(img_avg(:)<eps);
            img_avg(neg_idx)=eps;
            pos_idx=setdiff([1:prod(sz_img(1:3))]',neg_idx);
            maskidx=find(img_avg>(prctile(img_avg(pos_idx),99)*0.05));
            outimg=zeros(sz_img(1:3));
            outimg(maskidx)=1;
            out_nii=make_nii(outimg,invol_mag.hdr.dime.pixdim(2:4),[],2);
            fstr_mask=sprintf('%s/coreg/vr_%s_mask.nii.gz',in_dir,out_fn{fidx}{j});
            save_nii(out_nii,fstr_mask);
            fprintf('Processing voxel #');
            tmpX_ph=ones(sz_img(4),2);
            tmpX_ph(:,2)=linspace(-0.5,0.5,sz_img(4));
            tmpWinv_ph=inv(tmpX_ph'*tmpX_ph)*tmpX_ph';
            for vidx=1:numel(maskidx),
               if(mod(vidx,10000)==0)
                  fprintf('%d ',vidx);
               end
               tmpX=ones(sz_img(4),1);
               [xidx,yidx,zidx]=ind2sub(sz_img(1:3),maskidx(vidx));
               tmpvec_orig=reshape(invol_ph.img(xidx,yidx,zidx,:)*pi/180,[],1);
               tmpvec=unwrap(tmpvec_orig);
               tmpbeta_ph=tmpWinv_ph*tmpvec;
               tmpvec=tmpvec-tmpX_ph*tmpbeta_ph;
               tmpX=cat(2,tmpX,tmpvec);
               tmpy1=reshape(invol_mag.img(xidx,yidx,zidx,:),[],1);
               tmpy1(find(~isfinite(tmpy1(:))))=0;
               if(mean(tmpvec)~=0 && std(tmpvec)~=0)
                  beta_est=inv(tmpX'*tmpX)*tmpX'*tmpy1;
                  tmpy2=tmpy1 - tmpX*(ctrst_vec.*beta_est);
                  tmpy2(find(~isfinite(tmpy2(:))))=0;
               else
                  tmpy2=tmpy1;
               end
               invol_mag.img(xidx,yidx,zidx,:)=reshape(tmpy2,[1 1 1 sz_img(4)]);
            end
            fprintf('\n');
            fstr_out=sprintf('%s/coreg/vr_%s.nii.gz',in_dir,out_fn{fidx}{j});
            save_nii(invol_mag,fstr_out);
         end
      else
         str_glmph='';
      end
      
      if(flag_slctiming==1)
         fstr_in=sprintf('%s/coreg/%sr_%s.nii.gz',in_dir,str_glmph,out_fn{fidx}{j});
         in_vol=load_nii(fstr_in);
         in_vol.img=ipermute(in_vol.img,[dim_rl_ap_si{1},4]);
         for didx=1:3,
            if(flag_flip_fwdrev{1}(didx)==1)
               in_vol.img=flipdim(in_vol.img,didx);
            end
         end
         sz_img=size(in_vol.img);
         
         %fstr_real=sprintf('%s/coreg/r_%s_real.nii.gz',in_dir,out_fn{fidx}{j});
         %in_vol_real=load_nii(fstr_real);
         %fstr_imag=sprintf('%s/coreg/r_%s_imag.nii.gz',in_dir,out_fn{fidx}{j});
         %in_vol_imag=load_nii(fstr_imag);
         %img_cplx=complex(in_vol_real.img,in_vol_imag.img);
         %img_cplx=ipermute(img_cplx,[dim_rl_ap_si{1},4]);
         %for didx=1:3,
         %   if(flag_flip_fwdrev{1}(didx)==1)
         %      img_cplx=flipdim(img_cplx,didx);
         %   end
         %end
         
         in_vol.img=permute(in_vol.img,[4 1 2 3]);
         %img_cplx=permute(img_cplx,[4 1 2 3]);
         N3D=sz_img(3);
         Nsep=N3D/(sms_factor*num_shot);
         fillup_idx_array=[];
         for sidx=1:Nsep,
            fillup_idx_array(:,sidx)=sidx+[0:Nsep:N3D-1]';
         end
         if(mod(Nsep,2)==1)
            num_interlv_g1=floor(Nsep/2)+1;
            num_interlv_g2=floor(Nsep/2);
         else
            num_interlv_g1=Nsep/2;
            num_interlv_g2=Nsep/2;
         end
         interlv_g1=([1:num_interlv_g1]'-1)*2+mod(Nsep+1,2)+1;
         interlv_g2=([1:num_interlv_g2]'-1)*2+mod(Nsep,2)+1;
         base_slcidx=cat(1,interlv_g1,interlv_g2);
         
         delta_t=TR/numel(base_slcidx);
         slct_shift=-1.0*([0:numel(base_slcidx)-1]-floor(Nsep/2))*delta_t;
         outimg=zeros(size(in_vol.img));
         %outimg_cplx=zeros(size(img_cplx));
         for gidx=1:Nsep,
            tmp_tcimg=reshape(in_vol.img(:,:,:,fillup_idx_array(:,base_slcidx(gidx))),sz_img(4),[]);
            tmp_tcimg=SincResample(tmp_tcimg,sz_img(4),1/TR,slct_shift(gidx));
            outimg(:,:,:,fillup_idx_array(:,base_slcidx(gidx)))=reshape(tmp_tcimg,[sz_img(4),sz_img(1:2),sms_factor*num_shot]);
            
            %tmp_tcimg_cplx=reshape(img_cplx(:,:,:,fillup_idx_array(:,base_slcidx(gidx))),sz_img(4),[]);
            %tmp_tcimg_cplx=SincResample(tmp_tcimg_cplx,sz_img(4),1/TR,slct_shift(gidx));
            %outimg_cplx(:,:,:,fillup_idx_array(:,base_slcidx(gidx)))=reshape(tmp_tcimg_cplx,[sz_img(4),sz_img(1:2),sms_factor*num_shot]);
         end
         outimg=ipermute(outimg,[4 1 2 3]);
         %outimg_cplx=ipermute(outimg_cplx,[4 1 2 3]);
         for didx=1:3,
            if(flag_flip_fwdrev{1}(didx)==1)
               outimg=flipdim(outimg,didx);
               %outimg_cplx=flipdim(outimg_cplx,didx);
            end
         end
         outimg=permute(outimg,[dim_rl_ap_si{1},4]);
         %outimg_cplx=permute(outimg_cplx,[dim_rl_ap_si{1},4]);
         
         fstr_out=sprintf('%s/coreg/a%sr_%s.nii.gz',in_dir,str_glmph,out_fn{fidx}{j});
         tmp_vox=in_vol.hdr.dime.pixdim(2:4);
         out_nii=make_nii(outimg,tmp_vox,[],16);
         out_nii.hdr.dime.pixdim(5)=TR;
         save_nii(out_nii,fstr_out);
         
         %fstr_out2=sprintf('%s/coreg/ar_%s_real.nii.gz',in_dir,out_fn{fidx}{j});
         %out_nii2=make_nii(real(outimg_cplx),tmp_vox,[],16);
         %out_nii2.hdr.dime.pixdim(5)=TR;
         %save_nii(out_nii2,fstr_out2);
         %
         %fstr_out3=sprintf('%s/coreg/ar_%s_imag.nii.gz',in_dir,out_fn{fidx}{j});
         %out_nii3=make_nii(imag(outimg_cplx),tmp_vox,[],16);
         %out_nii3.hdr.dime.pixdim(5)=TR;
         %save_nii(out_nii3,fstr_out3);
         %
         %fstr_out4=sprintf('%s/coreg/ar_%s_mag.nii.gz',in_dir,out_fn{fidx}{j});
         %out_nii4=make_nii(abs(outimg_cplx),tmp_vox,[],16);
         %out_nii4.hdr.dime.pixdim(5)=TR;
         %save_nii(out_nii4,fstr_out4);
         %
         %fstr_out5=sprintf('%s/coreg/ar_%s_ph.nii.gz',in_dir,out_fn{fidx}{j});
         %out_nii5=make_nii(angle(outimg_cplx)*180/pi,tmp_vox,[],16);
         %out_nii5.hdr.dime.pixdim(5)=TR;
         %save_nii(out_nii5,fstr_out5);
         
         str=sprintf('!fslmaths %s/coreg/a%sr_%s -Tmean %s/coreg/a%sr_%s_mean',in_dir,str_glmph,out_fn{fidx}{j},in_dir,str_glmph,out_fn{fidx}{j});
         eval(str);
      end
      
      if(flag_distcor==1)
         tmp_ls=dir(sprintf('%s/coreg/%s.nii.gz',in_dir,out_fwdph_fn{fidx}{j}));
         if(isempty(tmp_ls))
            fprintf('Preparing the file %s ... ',fwdph_fn{fidx}{j});
            str=sprintf('!fslchfiletype NIFTI_GZ %s/%s %s/coreg/%s',in_dir,fwdph_fn{fidx}{j},in_dir,out_fwdph_fn{fidx}{j});
            eval(str);
            fprintf('Done!\n');
         end
         tmp_ls=dir(sprintf('%s/coreg/%s.nii.gz',in_dir,out_revph_fn{fidx}{j}));
         if(isempty(tmp_ls))
            fprintf('Preparing the file %s ... ',revph_fn{fidx}{j});
            str=sprintf('!fslchfiletype NIFTI_GZ %s/%s %s/coreg/%s',in_dir,revph_fn{fidx}{j},in_dir,out_revph_fn{fidx}{j});
            eval(str);
            fprintf('Done!\n');
         end
         
         tmp_ls=dir(sprintf('%s/coreg/nrot_tu_%s_fieldcoef.nii.gz',in_dir,out_fn{fidx}{j}));
         if(isempty(tmp_ls))
            fstr_fwd=sprintf('%s/coreg/%s.nii.gz',in_dir,out_fwdph_fn{fidx}{j});
            fwd_vol=load_nii(fstr_fwd);
            fwd_vol.img=ipermute(fwd_vol.img,dim_rl_ap_si{1});
            for didx=1:3,
               if(flag_flip_fwdrev{1}(didx)==1)
                  fwd_vol.img=flipdim(fwd_vol.img,didx);
               end
            end
            tmp_vox=fwd_vol.hdr.dime.pixdim(2:4);
            inv_order=dim_rl_ap_si{1}(dim_rl_ap_si{1});
            fstr_outfwd=sprintf('%s/coreg/nrot_%s.nii.gz',in_dir,out_fwdph_fn{fidx}{j});
            out_nii=make_nii(fwd_vol.img,tmp_vox(inv_order),[],16);
            out_nii.hdr.dime.pixdim(5)=TR;
            save_nii(out_nii,fstr_outfwd);
            fstr_rev=sprintf('%s/coreg/%s.nii.gz',in_dir,out_revph_fn{fidx}{j});
            rev_vol=load_nii(fstr_rev);
            rev_vol.img=ipermute(rev_vol.img,dim_rl_ap_si{1});
            for didx=1:3,
               if(flag_flip_fwdrev{1}(didx)==1)
                  rev_vol.img=flipdim(rev_vol.img,didx);
               end
            end
            tmp_vox=rev_vol.hdr.dime.pixdim(2:4);
            inv_order=dim_rl_ap_si{1}(dim_rl_ap_si{1});
            fstr_outrev=sprintf('%s/coreg/nrot_%s.nii.gz',in_dir,out_revph_fn{fidx}{j});
            out_nii=make_nii(rev_vol.img,tmp_vox(inv_order),[],16);
            out_nii.hdr.dime.pixdim(5)=TR;
            save_nii(out_nii,fstr_outrev);   
            
            total_inpacqt=echo_spacing*(size(fwd_vol.img,1)-1)/1000;
            fstr_txt=sprintf('%s/coreg/%s_run%d.txt',in_dir,fn_acqparam,fidx);
            fid=fopen(fstr_txt,'w');
            fprintf(fid,'-1 0 0 %f\n',total_inpacqt);
            fprintf(fid,' 1 0 0 %f\n',total_inpacqt);
            fclose(fid);
            
            str=sprintf('!fslmerge -t %s/coreg/nrot_imgFR%d_%d %s/coreg/nrot_%s %s/coreg/nrot_%s',in_dir,fidx,j,in_dir,out_fwdph_fn{fidx}{j},in_dir,out_revph_fn{fidx}{j});
            eval(str);
            str=sprintf('!topup --imain=%s/coreg/nrot_imgFR%d_%d --datain=%s --config=%s/%s.cnf --out=%s/coreg/nrot_tu_%s --iout=%s/coreg/nrot_tus_%s --fout=%s/coreg/nrot_tuf_%s',in_dir,fidx,j,fstr_txt,script_dir,fn_cnf,in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j});
            eval(str);
            %str=sprintf('!fslmaths %s/coreg/nrot_tuf_%s -mul 6.2831853 %s/coreg/nrot_fmap_%s',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j});
            %eval(str);
         
            %%%% prepare the artificial reverse-phase file %%%%
            fprintf('Preparing the artificial reverse-phase file...\n');
            str=sprintf('!fslnvols %s/coreg/%s > %s/coreg/tmp%d_%d.txt',in_dir,out_fn{fidx}{j},in_dir,fidx,j);
            eval(str);
            %keyboard;
            num_vols=textread(sprintf('%s/coreg/tmp%d_%d.txt',in_dir,fidx,j));
            power_nvols=ceil(log(num_vols)/log(2));
            for pidx=1:power_nvols,
               if(pidx>1)
                  str=sprintf('!fslmerge -t %s/coreg/rev_nrot_%s %s/coreg/rev_nrot_%s %s/coreg/rev_nrot_%s',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j});
                  eval(str);
               else
                  %str=sprintf('!fslmerge -t %s/coreg/rev_nrot_%s %s/coreg/nrot_%s %s/coreg/nrot_%s',in_dir,out_fn{fidx}{j},in_dir,out_revph_fn{fidx}{j},in_dir,out_revph_fn{fidx}{j});
                  str=sprintf('!fslmerge -t %s/coreg/rev_nrot_%s %s/coreg/nrot_%s %s/coreg/nrot_%s',in_dir,out_fn{fidx}{j},in_dir,out_revph_fn{fidx}{j},in_dir,out_revph_fn{fidx}{j});
                  eval(str);
               end
            end
            str=sprintf('!fslroi %s/coreg/rev_nrot_%s %s/coreg/rev_nrot_%s 0 %d',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j},num_vols);
            eval(str);
         end %end of if(isempty(tmp_ls))
         
         %%%% prepare the non-rotated fmri data %%%%
         fprintf('Preparing the non-rotated fmri data ...\n');
         fstr_outfmri=sprintf('%s/coreg/nrot_a%sr_%s.nii.gz',in_dir,str_glmph,out_fn{fidx}{j});
         tmp_ls=dir(fstr_outfmri);
         %if(isempty(tmp_ls))
            fstr_fmri=sprintf('%s/coreg/a%sr_%s.nii.gz',in_dir,str_glmph,out_fn{fidx}{j});
            fmri_vol=load_nii(fstr_fmri);
            fmri_vol.img=ipermute(fmri_vol.img,[dim_rl_ap_si{1},4]);
            for didx=1:3,
               if(flag_flip_fwdrev{1}(didx)==1)
                  fmri_vol.img=flipdim(fmri_vol.img,didx);
               end
            end
            tmp_vox=fmri_vol.hdr.dime.pixdim(2:4);
            inv_order=dim_rl_ap_si{1}(dim_rl_ap_si{1});
            out_nii=make_nii(fmri_vol.img,tmp_vox(inv_order),[],16);
            out_nii.hdr.dime.pixdim(5)=TR;
            save_nii(out_nii,fstr_outfmri);
         %end
            
         %%%% distortion correction by topup %%%%
         fstr_txt=sprintf('%s/coreg/%s_run%d.txt',in_dir,fn_acqparam,fidx);
         str=sprintf('!applytopup -i %s/coreg/nrot_a%sr_%s,%s/coreg/rev_nrot_%s --topup=%s/coreg/nrot_tu_%s --datain=%s --inindex=1,2 --out=%s/coreg/nrot_u_%s',in_dir,str_glmph,out_fn{fidx}{j},in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j},fstr_txt,in_dir,out_fn{fidx}{j});
         eval(str);
         %str=sprintf('!rm %s/coreg/rev_nrot_%s.nii.gz',in_dir,out_fn{fidx}{j});
         %eval(str);
         fstr_fmri=sprintf('%s/coreg/nrot_u_%s.nii.gz',in_dir,out_fn{fidx}{j});
         fmri_vol=load_nii(fstr_fmri);
         %keyboard;
         for didx=1:3,
            if(flag_flip_fwdrev{1}(didx)==1)
               fmri_vol.img=flipdim(fmri_vol.img,didx);
            end
         end
         fmri_vol.img=permute(fmri_vol.img,[dim_rl_ap_si{1},4]);
         tmp_vox=fmri_vol.hdr.dime.pixdim(2:4);
         inv_order=dim_rl_ap_si{1};
         fstr_outfmri=sprintf('%s/coreg/ua%sr_%s.nii.gz',in_dir,str_glmph,out_fn{fidx}{j});
         out_nii=make_nii(fmri_vol.img,tmp_vox(inv_order),[],16);
         out_nii.hdr.dime.pixdim(5)=TR;
         save_nii(out_nii,fstr_outfmri);
         
         str=sprintf('!fslmaths %s/coreg/ua%sr_%s -Tmean %s/coreg/ua%sr_%s_mean',in_dir,str_glmph,out_fn{fidx}{j},in_dir,str_glmph,out_fn{fidx}{j});
         eval(str);
         
         %%%%%% rotate the real/imaginary images %%%%
         %fstr_outfmri=sprintf('%s/coreg/nrot_a%sr_%s_real.nii.gz',in_dir,str_glmph,out_fn{fidx}{j});
         %tmp_ls=dir(fstr_outfmri);
         %%if(isempty(tmp_ls))
         %   fstr_fmri=sprintf('%s/coreg/a%sr_%s_real.nii.gz',in_dir,str_glmph,out_fn{fidx}{j});
         %   fmri_vol=load_nii(fstr_fmri);
         %   fmri_vol.img=ipermute(fmri_vol.img,[dim_rl_ap_si{1},4]);
         %   for didx=1:3,
         %      if(flag_flip_fwdrev{1}(didx)==1)
         %         fmri_vol.img=flipdim(fmri_vol.img,didx);
         %      end
         %   end
         %   tmp_vox=fmri_vol.hdr.dime.pixdim(2:4);
         %   inv_order=dim_rl_ap_si{1}(dim_rl_ap_si{1});
         %   out_nii=make_nii(fmri_vol.img,tmp_vox(inv_order),[],16);
         %   out_nii.hdr.dime.pixdim(5)=TR;
         %   save_nii(out_nii,fstr_outfmri);
         %%end
         %fstr_txt=sprintf('%s/coreg/%s_run%d.txt',in_dir,fn_acqparam,fidx);
         %str=sprintf('!applytopup -i %s/coreg/nrot_a%sr_%s_real --topup=%s/coreg/nrot_tu_%s --datain=%s --method=jac --inindex=1 --out=%s/coreg/nrot_u_%s_real',in_dir,str_glmph,out_fn{fidx}{j},in_dir,out_fn{fidx}{j},fstr_txt,in_dir,out_fn{fidx}{j});
         %eval(str);
         %%str=sprintf('!rm %s/coreg/rev_nrot_%s_real.nii.gz',in_dir,out_fn{fidx}{j});
         %%eval(str);
         %fstr_fmri=sprintf('%s/coreg/nrot_u_%s_real.nii.gz',in_dir,out_fn{fidx}{j});
         %fmri_vol=load_nii(fstr_fmri);
         %for didx=1:3,
         %   if(flag_flip_fwdrev{1}(didx)==1)
         %      fmri_vol.img=flipdim(fmri_vol.img,didx);
         %   end
         %end
         %fmri_vol.img=permute(fmri_vol.img,[dim_rl_ap_si{1},4]);
         %tmp_vox=fmri_vol.hdr.dime.pixdim(2:4);
         %inv_order=dim_rl_ap_si{1};
         %fstr_outfmri=sprintf('%s/coreg/uar_%s_real.nii.gz',in_dir,out_fn{fidx}{j});
         %out_nii=make_nii(fmri_vol.img,tmp_vox(inv_order),[],16);
         %out_nii.hdr.dime.pixdim(5)=TR;
         %save_nii(out_nii,fstr_outfmri);
         %
         %fstr_outfmri=sprintf('%s/coreg/nrot_ar_%s_imag.nii.gz',in_dir,out_fn{fidx}{j});
         %tmp_ls=dir(fstr_outfmri);
         %%if(isempty(tmp_ls))
         %   fstr_fmri=sprintf('%s/coreg/ar_%s_imag.nii.gz',in_dir,out_fn{fidx}{j});
         %   fmri_vol=load_nii(fstr_fmri);
         %   fmri_vol.img=ipermute(fmri_vol.img,[dim_rl_ap_si{1},4]);
         %   for didx=1:3,
         %      if(flag_flip_fwdrev{1}(didx)==1)
         %         fmri_vol.img=flipdim(fmri_vol.img,didx);
         %      end
         %   end
         %   tmp_vox=fmri_vol.hdr.dime.pixdim(2:4);
         %   inv_order=dim_rl_ap_si{1}(dim_rl_ap_si{1});
         %   out_nii=make_nii(fmri_vol.img,tmp_vox(inv_order),[],16);
         %   out_nii.hdr.dime.pixdim(5)=TR;
         %   save_nii(out_nii,fstr_outfmri);
         %%end
         %fstr_txt=sprintf('%s/coreg/%s_run%d.txt',in_dir,fn_acqparam,fidx);
         %str=sprintf('!applytopup -i %s/coreg/nrot_ar_%s_imag --topup=%s/coreg/nrot_tu_%s --datain=%s --method=jac --inindex=1 --out=%s/coreg/nrot_u_%s_imag',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j},fstr_txt,in_dir,out_fn{fidx}{j});
         %eval(str);
         %%str=sprintf('!rm %s/coreg/rev_nrot_%s_imag.nii.gz',in_dir,out_fn{fidx}{j});
         %%eval(str);
         %fstr_fmri=sprintf('%s/coreg/nrot_u_%s_imag.nii.gz',in_dir,out_fn{fidx}{j});
         %fmri_vol=load_nii(fstr_fmri);
         %for didx=1:3,
         %   if(flag_flip_fwdrev{1}(didx)==1)
         %      fmri_vol.img=flipdim(fmri_vol.img,didx);
         %   end
         %end
         %fmri_vol.img=permute(fmri_vol.img,[dim_rl_ap_si{1},4]);
         %tmp_vox=fmri_vol.hdr.dime.pixdim(2:4);
         %inv_order=dim_rl_ap_si{1};
         %fstr_outfmri=sprintf('%s/coreg/uar_%s_imag.nii.gz',in_dir,out_fn{fidx}{j});
         %out_nii=make_nii(fmri_vol.img,tmp_vox(inv_order),[],16);
         %out_nii.hdr.dime.pixdim(5)=TR;
         %save_nii(out_nii,fstr_outfmri);
         %
         %fstr_real=sprintf('%s/coreg/uar_%s_real.nii.gz',in_dir,out_fn{fidx}{j});
         %invol_real=load_nii(fstr_real);
         %fstr_imag=sprintf('%s/coreg/uar_%s_imag.nii.gz',in_dir,out_fn{fidx}{j});
         %invol_imag=load_nii(fstr_imag);
         %outimg=complex(invol_real.img,invol_imag.img);
         %fstr_mag=sprintf('%s/coreg/uar_%s_mag.nii.gz',in_dir,out_fn{fidx}{j});
         %outvol=make_nii(abs(outimg),invol_real.hdr.dime.pixdim(2:4),[],16);
         %outvol.hdr.dime.pixdim(5)=TR;
         %save_nii(outvol,fstr_mag);
         %fstr_ph=sprintf('%s/coreg/uar_%s_ph.nii.gz',in_dir,out_fn{fidx}{j});
         %outvol=make_nii(angle(outimg)*180/pi,invol_real.hdr.dime.pixdim(2:4),[],16);
         %outvol.hdr.dime.pixdim(5)=TR;
         %save_nii(outvol,fstr_ph);
         %
         %%%%%% rotate the field map (in radian/s) and field magnitude %%%%
         %%fstr_fmap=sprintf('%s/coreg/nrot_fmap_%s.nii.gz',in_dir,out_fn{fidx}{j});
         %%fmap_vol=load_nii(fstr_fmap);
         %%%keyboard;
         %%for didx=1:3,
         %%   if(flag_flip_fwdrev{1}(didx)==1)
         %%      fmap_vol.img=flipdim(fmap_vol.img,didx);
         %%   end
         %%end
         %%fmap_vol.img=permute(fmap_vol.img,dim_rl_ap_si{1});
         %%tmp_vox=fmap_vol.hdr.dime.pixdim(2:4);
         %%inv_order=dim_rl_ap_si{1};
         %%fstr_outfmap=sprintf('%s/coreg/fmap_%s.nii.gz',in_dir,out_fwdph_fn{fidx}{j});
         %%out_nii=make_nii(fmap_vol.img,tmp_vox(inv_order),[],16);
         %%save_nii(out_nii,fstr_outfmap);
         %%
         %%avg_fstr=sprintf('%s/coreg/%s',in_dir,out_fwdph_fn{fidx}{j});
         %%str=sprintf('!bet %s %s_b -m -f 0.15',avg_fstr,avg_fstr);
         %%eval(str);
         %%str=sprintf('!fslmaths %s_b_mask -dilF %s_bmask',avg_fstr,avg_fstr);
         %%eval(str);
         %%str=sprintf('!fslmaths %s -mas %s_bmask %s_brain',avg_fstr,avg_fstr,avg_fstr);
         %%eval(str);
      end
      
      if(flag_melodic==1)
         avg_fstr=sprintf('%s/coreg/ua%sr_%s_mean',in_dir,str_glmph,out_fn{fidx}{j});
         str=sprintf('!bet %s %s_b -m -f 0.15',avg_fstr,avg_fstr);
         eval(str);
         str=sprintf('!fslmaths %s_b_mask -dilF %s_bmask',avg_fstr,avg_fstr);
         %str=sprintf('!immv %s_b_mask %s_bmask',avg_fstr,avg_fstr);
         eval(str);
         %str=sprintf('!fslmaths %s -bin %s_bmask',avg_fstr,avg_fstr);
         %eval(str);
         mask_fstr=sprintf('%s_bmask',avg_fstr);
         
         fstr_temp=sprintf('%s/%s',featfsf_template_dir,featfsf_template_fn);
         fstr_fsf=sprintf('%s/coreg/%s_%d_%ddn%d%s_sm.fsf',in_dir,featfsf_run_fn{fidx},fidx,j,flag_denoise,str_glmph);
         fid_in=fopen(fstr_temp,'r');
         fid_out=fopen(fstr_fsf,'w');
         while 1
            tline=fgetl(fid_in);
            if (~ischar(tline))
                break;
            else
               if (strncmp(tline,'set fmri(outputdir) ',20))
                  tmpline=tline;
                  tmpline(21:end)=[];
                  tline=[tmpline,sprintf('"%s/coreg/run%d_%ddn%d%s_sm"',in_dir,fidx,j,flag_denoise,str_glmph)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set fmri(tr) ',13))
                  tmpline=tline;
                  tmpline(14:end)=[];
                  %tline=[tmpline,sprintf('%d',length(out_fn{fidx}))];
                  tline=[tmpline,sprintf('%f',TR)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set fmri(npts) ',15))
                  tmpline=tline;
                  tmpline(16:end)=[];
                  %tline=[tmpline,sprintf('%d',length(out_fn{fidx}))];
                  tline=[tmpline,sprintf('%d',num_scans(fidx))];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set fmri(multiple) ',19))
                  tmpline=tline;
                  tmpline(20:end)=[];
                  %tline=[tmpline,sprintf('%d',length(out_fn{fidx}))];
                  tline=[tmpline,sprintf('%d',1)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'# 4D AVW data or FEAT directory (1)',35))
                  tmpline1=tline;
                  tmpline1(34:end)=[];
                  tline=fgetl(fid_in);
                  tmpline2=tline;
                  tmpline2(16:end)=[];
                  %tline=[tmpline1,sprintf('%d)',fidx)];
                  tline=[tmpline1,sprintf('%d)',1)];
                  fprintf(fid_out,'%s\n',tline);
                  %tline=[tmpline2,sprintf('%d) "%s/coreg/%s"',fidx,in_dir,out_fn{fidx}{j})];
                  tline=[tmpline2,sprintf('%d) "%s/coreg/ua%sr_%s"',1,in_dir,str_glmph,out_fn{fidx}{j})];
                  fprintf(fid_out,'%s\n\n',tline);
               elseif (strncmp(tline,'set fmri(multiple) ',19))
                  tmpline=tline;
                  tmpline(20:end)=[];
                  %tline=[tmpline,sprintf('%d',length(out_fn{fidx}))];
                  tline=[tmpline,sprintf('%d',1)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set fmri(smooth) ',17))
                  tmpline=tline;
                  tmpline(18:end)=[];
                  tline=[tmpline,sprintf('%3.1f',0.1)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set fmri(alternative_mask) ',27))
                  tmpline=tline;
                  tmpline(28:end)=[];
                  tline=[tmpline,sprintf('"%s"',mask_fstr)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set highres_files(1) ',21))
                  tmpline=tline;
                  tmpline(22:end)=[];
                  tline=[tmpline,sprintf('"%s/%s"',brain_anat_dir,brain_anat_fn)];
                  fprintf(fid_out,'%s\n',tline);
               else
                  fprintf(fid_out,'%s\n',tline);
               end
            end %end of if (~ischar(tline))
         end %end of while 1
         fclose all;
         
         fstr_dir=sprintf('%s/coreg/run%d_%ddn%d%s_sm.feat',in_dir,fidx,j,flag_denoise,str_glmph);
         tmp_dir=dir(fstr_dir);
         if(~isempty(tmp_dir))
            fstr_dir2=sprintf('%s/coreg/run%d_%ddn%d%s_sm_bk.feat',in_dir,fidx,j,flag_denoise,str_glmph);
            tmp_dir2=dir(fstr_dir2);
            if(~isempty(tmp_dir2))
               str=sprintf('!rm -rf %s/coreg/run%d_%ddn%d%s_sm_bk.feat',in_dir,fidx,j,flag_denoise,str_glmph);
               eval(str);
            end
            str=sprintf('!mv %s/coreg/run%d_%ddn%d%s_sm.feat %s/coreg/run%d_%ddn%d%s_sm_bk.feat',in_dir,fidx,j,flag_denoise,str_glmph,in_dir,fidx,j,flag_denoise,str_glmph);
            eval(str);
         end
         str=sprintf('!feat %s',fstr_fsf);
         eval(str);
      end %end of if(flag_melodic==1)
      
      if(flag_feat==1)
         avg_fstr=sprintf('%s/coreg/ua%sr_%s_mean',in_dir,str_glmph,out_fn{fidx}{j});
         str=sprintf('!bet %s %s_b -m -f 0.15',avg_fstr,avg_fstr);
         eval(str);
         str=sprintf('!fslmaths %s_b_mask -dilF %s_bmask',avg_fstr,avg_fstr);
         %str=sprintf('!immv %s_b_mask %s_bmask',avg_fstr,avg_fstr);
         eval(str);
         %str=sprintf('!fslmaths %s -bin %s_bmask',avg_fstr,avg_fstr);
         %eval(str);
         mask_fstr=sprintf('%s_bmask',avg_fstr);
         
         fstr_temp=sprintf('%s/%s',featfsf_template_dir,featfsf_template_fn);
         fstr_fsf=sprintf('%s/coreg/%s_%d_%ddn%d%s.fsf',in_dir,featfsf_run_fn{fidx},fidx,j,flag_denoise,str_glmph);
         fid_in=fopen(fstr_temp,'r');
         fid_out=fopen(fstr_fsf,'w');
         while 1
            tline=fgetl(fid_in);
            if (~ischar(tline))
                break;
            else
               if (strncmp(tline,'set fmri(outputdir) ',20))
                  tmpline=tline;
                  tmpline(21:end)=[];
                  tline=[tmpline,sprintf('"%s/coreg/run%d_%ddn%d%s"',in_dir,fidx,j,flag_denoise,str_glmph)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set fmri(tr) ',13))
                  tmpline=tline;
                  tmpline(14:end)=[];
                  %tline=[tmpline,sprintf('%d',length(out_fn{fidx}))];
                  tline=[tmpline,sprintf('%f',TR)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set fmri(npts) ',15))
                  tmpline=tline;
                  tmpline(16:end)=[];
                  %tline=[tmpline,sprintf('%d',length(out_fn{fidx}))];
                  tline=[tmpline,sprintf('%d',num_scans(fidx))];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set fmri(multiple) ',19))
                  tmpline=tline;
                  tmpline(20:end)=[];
                  %tline=[tmpline,sprintf('%d',length(out_fn{fidx}))];
                  tline=[tmpline,sprintf('%d',1)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'# 4D AVW data or FEAT directory (1)',35))
                  tmpline1=tline;
                  tmpline1(34:end)=[];
                  tline=fgetl(fid_in);
                  tmpline2=tline;
                  tmpline2(16:end)=[];
                  %tline=[tmpline1,sprintf('%d)',fidx)];
                  tline=[tmpline1,sprintf('%d)',1)];
                  fprintf(fid_out,'%s\n',tline);
                  %tline=[tmpline2,sprintf('%d) "%s/coreg/%s"',fidx,in_dir,out_fn{fidx}{j})];
                  tline=[tmpline2,sprintf('%d) "%s/coreg/ua%sr_%s"',1,in_dir,str_glmph,out_fn{fidx}{j})];
                  fprintf(fid_out,'%s\n\n',tline);
               elseif (strncmp(tline,'set fmri(mc) ',13))
                  tmpline=tline;
                  tmpline(14:end)=[];
                  %tline=[tmpline,sprintf('%d',length(out_fn{fidx}))];
                  tline=[tmpline,sprintf('%d',1)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set fmri(multiple) ',19))
                  tmpline=tline;
                  tmpline(20:end)=[];
                  %tline=[tmpline,sprintf('%d',length(out_fn{fidx}))];
                  tline=[tmpline,sprintf('%d',1)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set fmri(smooth) ',17))
                  tmpline=tline;
                  tmpline(18:end)=[];
                  tline=[tmpline,sprintf('%2.1f',0)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set fmri(melodic_yn) ',21))
                  tmpline=tline;
                  tmpline(22:end)=[];
                  tline=[tmpline,sprintf('%d',0)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set fmri(alternative_mask) ',27))
                  tmpline=tline;
                  tmpline(28:end)=[];
                  tline=[tmpline,sprintf('"%s"',mask_fstr)];
                  fprintf(fid_out,'%s\n',tline);
               elseif (strncmp(tline,'set highres_files(1) ',21))
                  tmpline=tline;
                  tmpline(22:end)=[];
                  tline=[tmpline,sprintf('"%s/%s"',brain_anat_dir,brain_anat_fn)];
                  fprintf(fid_out,'%s\n',tline);
               else
                  fprintf(fid_out,'%s\n',tline);
               end
            end %end of if (~ischar(tline))
         end %end of while 1
         fclose all;
         
         fstr_dir=sprintf('%s/coreg/run%d_%ddn%d%s.feat',in_dir,fidx,j,flag_denoise,str_glmph);
         tmp_dir=dir(fstr_dir);
         if(~isempty(tmp_dir))
            fstr_dir2=sprintf('%s/coreg/run%d_%ddn%d%s_bk.feat',in_dir,fidx,j,flag_denoise,str_glmph);
            tmp_dir2=dir(fstr_dir2);
            if(~isempty(tmp_dir2))
               str=sprintf('!rm -rf %s/coreg/run%d_%ddn%d%s_bk.feat',in_dir,fidx,j,flag_denoise,str_glmph);
               eval(str);
            end
            str=sprintf('!mv %s/coreg/run%d_%ddn%d%s.feat %s/coreg/run%d_%ddn%d%s_bk.feat',in_dir,fidx,j,flag_denoise,str_glmph,in_dir,fidx,j,flag_denoise,str_glmph);
            eval(str);
         end
         str=sprintf('!feat %s',fstr_fsf);
         eval(str);
      end %end of if(flag_feat==1)
   end %end of for j=1, %1:length(datapath{fidx}),
   
   if(flag_ica==1)
      for j=1:length(datapath{fidx}),
         avg_fstr=sprintf('%s/coreg/r_%s_mean',in_dir,out_fn{fidx}{j});
         str=sprintf('!bet %s %s_b -m -f 0.15',avg_fstr,avg_fstr);
         eval(str);
         str=sprintf('!fslmaths %s_b_mask -dilF %s_bmask',avg_fstr,avg_fstr);
         %str=sprintf('!immv %s_b_mask %s_bmask',avg_fstr,avg_fstr);
         eval(str);
         %str=sprintf('!fslmaths %s -bin %s_bmask',avg_fstr,avg_fstr);
         %eval(str);
         mask_fstr=sprintf('%s_bmask',avg_fstr);
      end
      
      fstr_temp=sprintf('%s/%s',icafsf_template_dir,icafsf_template_fn);
      fstr_fsf=sprintf('%s/coreg/%s.fsf',in_dir,icafsf_run_fn{fidx});
      fid_in=fopen(fstr_temp,'r');
      fid_out=fopen(fstr_fsf,'w');
      while 1
         tline=fgetl(fid_in);
         if (~ischar(tline))
             break;
         else
            if (strncmp(tline,'set fmri(outputdir) ',20))
               tmpline=tline;
               tmpline(21:end)=[];
               tline=[tmpline,sprintf('"%s/coreg/run%d_dn2"',in_dir,fidx)];
               fprintf(fid_out,'%s\n',tline);
            elseif (strncmp(tline,'set fmri(npts) ',15))
               tmpline=tline;
               tmpline(16:end)=[];
               %tline=[tmpline,sprintf('%d',length(out_fn{fidx}))];
               tline=[tmpline,sprintf('%d',num_scans(fidx))];
               fprintf(fid_out,'%s\n',tline);
            elseif (strncmp(tline,'set fmri(multiple) ',19))
               tmpline=tline;
               tmpline(20:end)=[];
               tline=[tmpline,sprintf('%d',length(out_fn{fidx}))];
               %tline=[tmpline,sprintf('%d',1)];
               fprintf(fid_out,'%s\n',tline);
            elseif (strncmp(tline,'# 4D AVW data or FEAT directory (1)',35))
               tmpline1=tline;
               tmpline1(34:end)=[];
               tline=fgetl(fid_in);
               tmpline2=tline;
               tmpline2(16:end)=[];
               %tline=[tmpline1,sprintf('%d)',fidx)];
               tline=[tmpline1,sprintf('%d)',1)];
               fprintf(fid_out,'%s\n',tline);
               %tline=[tmpline2,sprintf('%d) "%s/coreg/%s"',fidx,in_dir,out_fn{fidx}{j})];
               tline=[tmpline2,sprintf('%d) "%s/coreg/%s"',1,in_dir,out_fn{fidx}{1})];
               fprintf(fid_out,'%s\n\n',tline);
            %elseif (strncmp(tline,'# 4D AVW data or FEAT directory (2)',35))
            %   tmpline1=tline;
            %   tmpline1(34:end)=[];
            %   tline=fgetl(fid_in);
            %   tmpline2=tline;
            %   tmpline2(16:end)=[];
            %   %tline=[tmpline1,sprintf('%d)',fidx)];
            %   tline=[tmpline1,sprintf('%d)',2)];
            %   fprintf(fid_out,'%s\n',tline);
            %   %tline=[tmpline2,sprintf('%d) "%s/coreg/%s"',fidx,in_dir,out_fn{fidx}{j})];
            %   tline=[tmpline2,sprintf('%d) "%s/coreg/%s"',2,in_dir,out_fn{fidx}{2})];
            %   fprintf(fid_out,'%s\n\n',tline);
            elseif (strncmp(tline,'set fmri(regstandard) ',22))
               tmpline=tline;
               tmpline(23:end)=[];
               %tline=[tmpline,sprintf('%d',length(out_fn{fidx}))];
               tline=[tmpline,sprintf('"%s/%s"',epi_anat_dir{fidx}{1},epi_anat_fn{fidx}{1})];
               fprintf(fid_out,'%s\n',tline);
            elseif (strncmp(tline,'set highres_files(1) ',21))
               tmpline=tline;
               tmpline(22:end)=[];
               tline=[tmpline,sprintf('"%s/%s"',epi_anat_dir{fidx}{1},epi_anat_fn{fidx}{1})];
               fprintf(fid_out,'%s\n',tline);
            elseif (strncmp(tline,'set highres_files(2) ',21))
               tmpline=tline;
               tmpline(22:end)=[];
               tline=[tmpline,sprintf('"%s/%s"',epi_anat_dir{fidx}{2},epi_anat_fn{fidx}{2})];
               fprintf(fid_out,'%s\n',tline);
            elseif (strncmp(tline,'set fmri(alternative_mask) ',27))
               tmpline=tline;
               tmpline(28:end)=[];
               tline=[tmpline,sprintf('"%s"',mask_fstr)];
               fprintf(fid_out,'%s\n',tline);
            elseif (strncmp(tline,'set fmri(regstandard_res) ',26))
               tmpline=tline;
               tmpline(27:end)=[];
               tline=[tmpline,sprintf('%6.4f',1.0)];
               fprintf(fid_out,'%s\n',tline);
            elseif (strncmp(tline,'set fmri(reginitial_highres_search) ',36))
               tmpline=tline;
               tmpline(37:end)=[];
               tline=[tmpline,sprintf('%d',45)];
               fprintf(fid_out,'%s\n',tline);
            elseif (strncmp(tline,'set fmri(regstandard_search) ',29))
               tmpline=tline;
               tmpline(30:end)=[];
               tline=[tmpline,sprintf('%d',45)];
               fprintf(fid_out,'%s\n',tline);
            elseif (strncmp(tline,'set fmri(regstandard_dof) ',26))
               tmpline=tline;
               tmpline(27:end)=[];
               tline=[tmpline,sprintf('%d',3)];
               fprintf(fid_out,'%s\n',tline);
            elseif (strncmp(tline,'set fmri(reghighres_dof) ',25))
               tmpline=tline;
               tmpline(26:end)=[];
               tline=[tmpline,sprintf('%d',3)];
               fprintf(fid_out,'%s\n',tline);
            else
               fprintf(fid_out,'%s\n',tline);
            end
         end %end of if (~ischar(tline))
      end %end of while 1
      fclose all;
      %keyboard;
      str=sprintf('!feat %s',fstr_fsf);
      eval(str);
   end %end of if(flag_ica==1)
   
   for j=1:length(datapath{fidx}),
      if(flag_clean==1)
         tmp_ls=dir(sprintf('%s/coreg/iua%sr_%s.nii',in_dir,str_glmph,out_fn{fidx}{j}));
         if(~isempty(tmp_ls))
            str=sprintf('!rm %s/coreg/iua%sr_%s.nii',in_dir,str_glmph,out_fn{fidx}{j});
            eval(str);
         end
         
         %fstr_html=sprintf('%s/coreg/run%d_%d.feat/report_log.html',in_dir,fidx,j);
         %fid_html=fopen(fstr_html,'r');
         %while 1
         %   tline=fgetl(fid_html);
         %   if (~ischar(tline))
         %       break;
         %   else
         %      if (~isempty(strfind(tline,'fslmaths prefiltered_func_data_smooth -mul ')))
         %         st_idx=strfind(tline,'fslmaths prefiltered_func_data_smooth -mul ');
         %         img_scale=sscanf(tline(st_idx+43:end),'%f');
         %         break;
         %      end
         %   end %end of if (~ischar(tline))
         %end %end of while 1
         %fclose(fid_html);
         %%str=sprintf('!fslmaths %s/coreg/r_%s -mul %f %s/coreg/mul_r_%s',in_dir,out_fn{fidx}{j},img_scale,in_dir,out_fn{fidx}{j});
         %%eval(str);
         %fstr_txt=sprintf('%s/coreg/img_scale%d_%d.txt',in_dir,fidx,j);
         %fid_txt=fopen(fstr_txt,'w');
         %fprintf(fid_txt,'%f\n',img_scale);
         %fclose(fid_txt);
         
         if(flag_fixclean==0)
            %str=sprintf('!fsl_regfilt -i %s/coreg/run%d_%d.feat/filtered_func_data -o %s/coreg/ir_%s -d %s/coreg/run%d_%d.feat/filtered_func_data.ica/melodic_mix -f "',in_dir,fidx,j,in_dir,out_fn{fidx}{j},in_dir,fidx,j);
            str=sprintf('!fsl_regfilt -i %s/coreg/run%d_%ddn%d%s.feat/filtered_func_data -o %s/coreg/iua%sr_%s -d %s/coreg/run%d_%ddn%d%s_sm.feat/filtered_func_data.ica/melodic_mix -f "',in_dir,fidx,j,flag_denoise,str_glmph,in_dir,str_glmph,out_fn{fidx}{j},in_dir,fidx,j,flag_denoise,str_glmph);
            
            for cidx=1:numel(clean_compidx{fidx}{j}),
               str=[str,num2str(clean_compidx{fidx}{j}(cidx))];
               if(cidx<numel(clean_compidx{fidx}{j}))
                  str=[str,','];
               else
                  str=[str,'"'];
               end
            end
            eval(str);
            
            %%%%% artifact regression on phase image %%%%
            %fstr_mag=sprintf('%s/coreg/iuar_%s.nii.gz',in_dir,out_fn{fidx}{j});
            %fstr_ph=sprintf('%s/coreg/uar_%s_ph.nii.gz',in_dir,out_fn{fidx}{j});
            %invol_mag=load_nii(fstr_mag);
            %invol_ph=load_nii(fstr_ph);
            %outvol_ph=invol_ph;
            %sz_img=size(invol_ph.img);
            %img_avg=mean(invol_mag.img,4);
            %neg_idx=find(img_avg(:)<eps);
            %img_avg(neg_idx)=eps;
            %pos_idx=setdiff([1:prod(sz_img(1:3))]',neg_idx);
            %maskidx=find(img_avg>(prctile(img_avg(pos_idx),99)*0.05));
            %img_ph=permute(invol_ph.img,[4 1 2 3])*pi/180;
            %tmpvec_orig=img_ph(:,maskidx);
            %tmpvec_orig(find(~isfinite(tmpvec_orig(:))))=0;
            %tmpvec=unwrap(tmpvec_orig,[],1);
            %
            %tmpX_ph=ones(sz_img(4),1);
            %for cidx=1:numel(clean_compidx{fidx}{j}),
            %   fstr_txt=sprintf('%s/coreg/run%d_%d_sm.feat/filtered_func_data.ica/report/t%d.txt',in_dir,fidx,j,clean_compidx{fidx}{j}(cidx));
            %   tmp_array=textread(fstr_txt,'%f');
            %   tmp_tcourse=reshape(tmp_array(1:sz_img(4)),[],1);
            %   tmp_tcourse=tmp_tcourse-mean(tmp_tcourse);
            %   tmpX_ph=cat(2,tmpX_ph,tmp_tcourse);
            %end
            %[tu ts tv]=svd(tmpX_ph,0);
            %lambda=max(diag(ts))*0.02;
            %td=diag(ts)./(diag(ts).^2+ones(size(diag(ts)))*(lambda.^2));
            %tD=diag(td);
            %tmpbeta_ph = tv*tD*(tu')*tmpvec;
            %
            %%tmpWinv_ph=inv(tmpX_ph'*tmpX_ph)*tmpX_ph';
            %%tmpbeta_ph=tmpWinv_ph*tmpvec;
            %
            %tmpvec=tmpvec-tmpX_ph(:,2:end)*tmpbeta_ph(2:end,:);
            %outimg=zeros([sz_img(4), sz_img(1:3)]);
            %outimg(:,maskidx)=angle(exp(1j*tmpvec))*180/pi;
            %fstrout_ph=sprintf('%s/coreg/iuar_%s_ph.nii.gz',in_dir,out_fn{fidx}{j});
            %outvol_ph.img=ipermute(outimg,[4 1 2 3]);
            %save_nii(outvol_ph,fstrout_ph);
            %
            %%str=sprintf('!fslchfiletype NIFTI %s/coreg/ir_%s',in_dir,out_fn{fidx}{j});
            %%eval(str);
         else
            %%%% copy the ICA results to .feat directory %%%%
            str=sprintf('!rsync -av %s/coreg/run%d_%d_sm.feat/filtered_func_data.ica %s/coreg/run%d_%d.feat/',in_dir,fidx,j,in_dir,fidx,j);
            eval(str);
            
            %%%% FIX processing %%%%
            str=sprintf('!fix -f %s/coreg/run%d_%d_sm.feat',in_dir,fidx,j);
            eval(str);
            str=sprintf('!rsync -av %s/coreg/run%d_%d_sm.feat/fix %s/coreg/run%d_%d.feat/',in_dir,fidx,j,in_dir,fidx,j);
            eval(str);
            str=sprintf('!fix -c %s/coreg/run%d_%d.feat %s/%s.RData %d',in_dir,fidx,j,fixtrain_dir,fixtrain_prefix,fix_thresh);
            eval(str);
            
            %fstr_fix=sprintf('%s/coreg/run%d_%d.feat/fix4melview_%s_thr%d.txt',in_dir,fidx,j,fixtrain_prefix,fix_thresh);
            %fid_fix=fopen(fstr_fix,'r');
            %while 1
            %   tline=fgetl(fid_fix);
            %   if (~ischar(tline))
            %       break;
            %   else
            %      if (~isempty(strfind(tline,'[')))
            %         str_fixcmps=tline;
            %         break;
            %      end
            %   end %end of if (~ischar(tline))
            %end %end of while 1
            %fclose(fid_fix);
            %eval(['fix_compidx=',str_fixcmps,';']);
            %str=sprintf('!fsl_regfilt -i %s/coreg/mul_r_%s -o %s/coreg/ir_%s -d %s/coreg/run%d_%d.feat/filtered_func_data.feat/melodic_mix -f "',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j},in_dir,fidx,j);
            %for cidx=1:numel(fix_compidx),
            %   str=[str,num2str(fix_compidx(cidx))];
            %   if(cidx<numel(fix_compidx))
            %      str=[str,','];
            %   else
            %      str=[str,'"'];
            %   end
            %end
            %eval(str);
            
            %str=sprintf('!fix -a %s/coreg/run%d_%d.feat/fix4melview_%s_thr%d.txt -A',in_dir,fidx,j,fixtrain_prefix,fix_thresh);
            %str=sprintf('!fix -a %s/coreg/run%d_%d.feat/fix4melview_%s_thr%d.txt',in_dir,fidx,j,fixtrain_prefix,fix_thresh);
            str=sprintf('!fix -a %s/coreg/run%d_%d.feat/fix4melview_%s_thr%d.txt -A -m',in_dir,fidx,j,fixtrain_prefix,fix_thresh);
            
            eval(str);
            str=sprintf('!imcp %s/coreg/run%d_%d.feat/filtered_func_data_clean %s/coreg/iuar_%s',in_dir,fidx,j,in_dir,out_fn{fidx}{j});
            eval(str);
         end
      end
      
      if(flag_filter==1)
         if(numel(flt_band{fidx})==2)
            [B A]=butter(filt_order,flt_band{fidx}*2*TR);
            flt_type=3;
         else
            if(flt_band{fidx}>0.05)
               [B A]=butter(filt_order,flt_band{fidx}*2*TR,'low');
               flt_type=1;
            else
               [B A]=butter(filt_order,flt_band{fidx}*2*TR,'high');
               flt_type=2;
            end
         end
         
         in_fstr=sprintf('%s/coreg/ua%sr_%s.nii.gz',in_dir,str_glmph,out_fn{fidx}{j});
         out_fstr=sprintf('%s/coreg/fua%sr_%s.nii.gz',in_dir,str_glmph,out_fn{fidx}{j});
         nii_volin=load_nii(in_fstr);
         sz_vol=size(nii_volin.img);
         nii_volout=nii_volin;
         mean_img=squeeze(mean(nii_volin.img,4));
         tmpvol=filtfilt(B,A,reshape(permute(double(nii_volin.img),[4 1 2 3]),sz_vol(4),[]));
         if(flt_type==1)
            tmpvol_avg=mean(tmpvol,1);
            neg_vidx=find(tmpvol_avg<eps);
            tmpvol(:,neg_vidx)=eps;
            nii_volout.img=ipermute(reshape(abs(tmpvol),[sz_vol(4),sz_vol(1:3)]),[4 1 2 3]);
         else
            nii_volout.img=abs(ipermute(reshape(tmpvol,[sz_vol(4),sz_vol(1:3)]),[4 1 2 3])+repmat(mean_img,[1 1 1 sz_vol(4)]));
         end
         save_nii(nii_volout,out_fstr);
         
         %in_fstr=sprintf('%s/coreg/uar_%s_ph.nii.gz',in_dir,out_fn{fidx}{j});
         %out_fstr=sprintf('%s/coreg/fuar_%s_ph.nii.gz',in_dir,out_fn{fidx}{j});
         %nii_vol_ph=load_nii(in_fstr);
         %outimg=abs(nii_volin.img).*exp(1j*nii_vol_ph.img*pi/180);
         %sz_vol=size(outimg);
         %tmpvol=filtfilt(B,A,reshape(permute(double(outimg),[4 1 2 3]),sz_vol(4),[]));
         %%tmpvol(:,neg_vidx)=eps;
         %nii_volout=[];
         %nii_volout=nii_vol_ph;
         %tmpvol=ipermute(reshape(tmpvol,[sz_vol(4),sz_vol(1:3)]),[4 1 2 3])+repmat(mean_img,[1 1 1 sz_vol(4)]);
         %nii_volout.img=ipermute(reshape(angle(tmpvol)*180/pi,[sz_vol(4),sz_vol(1:3)]),[4 1 2 3]);
         %save_nii(nii_volout,out_fstr);
         
         str=sprintf('!fslmaths %s/coreg/fua%sr_%s -Tmean %s/coreg/fua%sr_%s_mean',in_dir,str_glmph,out_fn{fidx}{j},in_dir,str_glmph,out_fn{fidx}{j});
         eval(str);
         str=sprintf('!fslmaths %s/coreg/fua%sr_%s -Tstd %s/coreg/fua%sr_%s_std',in_dir,str_glmph,out_fn{fidx}{j},in_dir,str_glmph,out_fn{fidx}{j});
         eval(str);
         nii_avg=load_nii(sprintf('%s/coreg/fua%sr_%s_mean.nii.gz',in_dir,str_glmph,out_fn{fidx}{j}));
         nii_std=load_nii(sprintf('%s/coreg/fua%sr_%s_std.nii.gz',in_dir,str_glmph,out_fn{fidx}{j}));
         mask_img=zeros(size(nii_avg.img),'single');
         tmp_th=prctile(nii_avg.img(:),95)/10;
         mask_img(find(nii_avg.img(:)>tmp_th))=1;
         mask_img=imfill(mask_img,'holes');
         maskidx=find(mask_img>0);
         nii_tsnr=nii_avg;
         nii_tsnr.img=zeros(size(mask_img),'single');
         nii_tsnr.img(maskidx)=nii_avg.img(maskidx)./nii_std.img(maskidx);
         save_nii(nii_tsnr,sprintf('%s/coreg/fua%sr_%s_tsnr.nii.gz',in_dir,str_glmph,out_fn{fidx}{j}));
      end
      
      if(flag_warp==1)
         cur_dir=pwd;
         str=sprintf('cd %s/coreg',in_dir);
         eval(str);
         
         %%%% from T1 to reconstructed EPI image %%%%
         fhdr_out1=sprintf('run%d_%danat2epi',fidx,j);
         fstr_transform1=sprintf('%s/coreg/%sAffine.txt',in_dir,fhdr_out1);
         %epi_fstr=sprintf('%s/%s',epi_anat_dir{fidx}{j},epi_anat_fn{fidx}{j});
         epi_fstr=sprintf('%s/coreg/fuar_%s_mean',in_dir,out_fn{fidx}{j});
         tmp_ls=dir(fstr_transform1);
         %if(isempty(tmp_ls))
         %   %str=sprintf('!bet %s %s_b -m -f 0.15',epi_fstr,epi_fstr);
         %   %eval(str);
         %   %str=sprintf('!fslmaths %s_b_mask -dilF %s_bmask',epi_fstr,epi_fstr);
         %   %eval(str);
         %   %str=sprintf('!fslmaths %s -mas %s_bmask %s_brain',epi_fstr,epi_fstr,epi_fstr);
         %   %eval(str);
         %   %str=sprintf('!fast -t 2 -n 4 -g -o %s/episeg %s_brain',epi_anat_dir{fidx}{j},epi_fstr);
         %   %eval(str);
         %   %str=sprintf('!fslmaths %s/episeg_pve_0 -thr 0.99 %s/episeg_csfmask',epi_anat_dir{fidx}{j},epi_anat_dir{fidx}{j});
         %   %eval(str);
         %   %str=sprintf('!fslmaths %s/episeg_pve_3 -thr 0.99 %s/episeg_darkmask',epi_anat_dir{fidx}{j},epi_anat_dir{fidx}{j});
         %   %eval(str);
         %   %str=sprintf('!fslmaths %s/episeg_csfmask -add %s/episeg_darkmask %s/episeg_nullmask',epi_anat_dir{fidx}{j},epi_anat_dir{fidx}{j},epi_anat_dir{fidx}{j});
         %   %eval(str);
         %   %str=sprintf('!fslmaths %s/episeg_nullmask -binv %s/episeg_nvmask',epi_anat_dir{fidx}{j},epi_anat_dir{fidx}{j});
         %   %eval(str);
         %   %str=sprintf('!fslmaths %s/episeg_nvmask -mas %s_bmask %s/episeg_tmpmask',epi_anat_dir{fidx}{j},epi_fstr,epi_anat_dir{fidx}{j});
         %   %eval(str);
         %   %str=sprintf('!fslmaths %s/episeg_tmpmask -fillh %s/episeg_nvmask2',epi_anat_dir{fidx}{j},epi_anat_dir{fidx}{j});
         %   %eval(str);
         %   %%str=sprintf('!fslmaths %s/episeg_tmpmask -binv %s/episeg_tmpmask',epi_anat_dir{fidx}{j},epi_anat_dir{fidx}{j});
         %   %%eval(str);
         %   %str=sprintf('!fslmaths %s/episeg_nvmask2 -kernel box 1.2 -dilF %s/episeg_nvmask2F',epi_anat_dir{fidx}{j},epi_anat_dir{fidx}{j});
         %   %eval(str);
         %   %str=sprintf('!fslmaths %s_brain -mas %s/episeg_nvmask2F %s_brain2',epi_fstr,epi_anat_dir{fidx}{j},epi_fstr);
         %   %eval(str);
         %   %
         %   %gm_mask=sprintf('%s/%s',brain_anat_dir,gm_mask_fn);
         %   %wm_mask=sprintf('%s/%s',brain_anat_dir,wm_mask_fn);
         %   %str=sprintf('!fslmaths %s.nii.gz -add %s.nii.gz %s/gmwm_mask_crop.nii.gz',gm_mask,wm_mask,brain_anat_dir);
         %   %eval(str);
         %   %str=sprintf('!fslmaths %s/gmwm_mask_crop -kernel boxv 3 -dilF %s/gmwm_mask_cropF',brain_anat_dir,brain_anat_dir);
         %   %eval(str);
         %   %str=sprintf('!fslmaths %s/gmwm_mask_cropF -fillh %s/gmwm_mask_cropF',brain_anat_dir,brain_anat_dir);
         %   %eval(str);
         %   %str=sprintf('!fslmaths %s/%s.nii.gz -mas %s/gmwm_mask_cropF.nii.gz %s/%s_gmwm.nii.gz',brain_anat_dir,brain_anat_fn,brain_anat_dir,brain_anat_dir,brain_anat_fn);
         %   %eval(str);
         %   
         %   %fstr_in=sprintf('%s/%s_gmwm.nii.gz',brain_anat_dir,brain_anat_fn);
         %   fstr_in=sprintf('%s/%s.nii.gz',brain_anat_dir,brain_anat_fn);
         %   fstr_targ=sprintf('%s.nii.gz',epi_fstr);
         %   %fstr_targ=sprintf('%s/%s_gmwm.nii.gz',brain_anat_dir,brain_anat_fn);
         %   %fstr_in=sprintf('%s_brain2.nii.gz',epi_fstr);
         %   %str=sprintf('!antsIntroduction.sh -d 3 -r %s -i %s -o %s -s PR -t GR -m 12x12x20',fstr_targ,fstr_in,fhdr_out1);
         %   %str=sprintf('!antsIntroduction.sh -d 3 -r %s -i %s -o %s -t GR -m 8x8x8',fstr_targ,fstr_in,fhdr_out1);
         %   str=sprintf('!antsIntroduction.sh -d 3 -r %s -i %s -o %s -t RA -n 1 -m 8x8x8',fstr_targ,fstr_in,fhdr_out1);
         %   eval(str);
         %end %end of if(isempty(fstr_transform1))   
         %   
         %%%%%% from reference EPI image to EPI %%%%
         %%fhdr_out2=sprintf('run%d_%depi2epi',fidx,j);
         %%fstr_transform2=sprintf('%s/coreg/%sAffine.txt',in_dir,fhdr_out2);
         %%tmp_ls=dir(fstr_transform2);
         %%if(isempty(tmp_ls))
         %%   fstr_targ=sprintf('%s/coreg/fuar_%s_mean.nii.gz',in_dir,out_fn{fidx}{j});
         %%   fstr_in=sprintf('%s.nii.gz',epi_fstr);
         %%   %str=sprintf('!antsIntroduction.sh -d 3 -r %s -i %s -o %s -s PR -t GR -m 12x12x20',fstr_targ,fstr_in,fhdr_out2);
         %%   %str=sprintf('!antsIntroduction.sh -d 3 -r %s -i %s -o %s -t GR -m 8x8x8',fstr_targ,fstr_in,fhdr_out2);
         %%   str=sprintf('!antsIntroduction.sh -d 3 -r %s -i %s -o %s -t RA -n 1 -m 8x8x8',fstr_targ,fstr_in,fhdr_out2);
         %%   eval(str);
         %%end %end of if(isempty(fstr_transform2))
         
         %%%% Transform hippocampal lables from T1 to EPI %%%%
         for lidx=1:length(labelin_fn),
            fstr_labelin=sprintf('%s/%s',label_dir,labelin_fn{lidx});
            fstr_targ=sprintf('%s/coreg/fuar_%s_mean.nii.gz',in_dir,out_fn{fidx}{j});
            str=sprintf('!antsApplyTransforms -d 3 -e 3 -i %s.nii.gz -r %s -o %s/coreg/%s_%s.nii.gz -t %s/coreg/%sAffine.txt -n NearestNeighbor',fstr_labelin,fstr_targ,in_dir,labelout_fn{lidx},out_fn{fidx}{j},in_dir,fhdr_out1);
            eval(str);
         end %end of for lidx=1:length(labelin_fn),
         
         str=sprintf('cd %s',cur_dir);
         eval(str);
      end
      
      if(flag_smooth==1)
         fprintf('Applying smoothing ...');
         smooth_sigma=smooth_fwhm(fidx)/sqrt(8*log(2));
         fstr=sprintf('%s/coreg/safir_%s.nii',in_dir,out_fn{fidx}{j});
         tmp_ls=dir(fstr);
         if(~isempty(tmp_ls))
            str=sprintf('!rm %s/coreg/safir_%s.nii',in_dir,out_fn{fidx}{j});
            eval(str);
         end
         str=sprintf('!fslmaths %s/coreg/afir_%s -s %5.3f %s/coreg/safir_%s',in_dir,out_fn{fidx}{j},smooth_sigma,in_dir,out_fn{fidx}{j});
         eval(str);
         str=sprintf('!fslnvols %s/coreg/safir_%s > tmp_num.txt',in_dir,out_fn{fidx}{j});
         eval(str);
         num_tpnts=textread('tmp_num.txt','%d');
         eval(sprintf('!rm tmp_num.txt'));
         num_cut_begin=ceil(num_cuttpnts/2);
         num_cut_end  =num_cuttpnts-num_cut_begin;
         num_trim_tpnts=num_tpnts-num_cuttpnts;
         str=sprintf('!fslroi %s/coreg/safir_%s %s/coreg/tsafir_%s %d %d',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j},num_cut_begin+1,num_trim_tpnts);
         eval(str);
         %str=sprintf('!fslchfiletype NIFTI %s/coreg/safir_%s',in_dir,out_fn{fidx}{j});
         %eval(str);
         str=sprintf('!fslmaths %s/coreg/safir_%s -Tmean %s/coreg/safir_%s_mean',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j});
         eval(str);
         
         %fstr=sprintf('%s/coreg/swafir_%s.nii',in_dir,out_fn{fidx}{j});
         %tmp_ls=dir(fstr);
         %if(~isempty(tmp_ls))
         %   str=sprintf('!rm %s/coreg/swafir_%s.nii',in_dir,out_fn{fidx}{j});
         %   eval(str);
         %end
         %str=sprintf('!fslmaths %s/coreg/wafir_%s -s %5.3f %s/coreg/swafir_%s',in_dir,out_fn{fidx}{j},smooth_sigma,in_dir,out_fn{fidx}{j});
         %eval(str);
         %str=sprintf('!fslnvols %s/coreg/swafir_%s > tmp_num.txt',in_dir,out_fn{fidx}{j});
         %eval(str);
         %num_tpnts=textread('tmp_num.txt','%d');
         %eval(sprintf('!rm tmp_num.txt'));
         %num_cut_begin=ceil(num_cuttpnts/2);
         %num_cut_end  =num_cuttpnts-num_cut_begin;
         %num_trim_tpnts=num_tpnts-num_cuttpnts;
         %str=sprintf('!fslroi %s/coreg/swafir_%s %s/coreg/tswafir_%s %d %d',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j},num_cut_begin+1,num_trim_tpnts);
         %eval(str);
         %str=sprintf('!fslchfiletype NIFTI %s/coreg/swafir_%s',in_dir,out_fn{fidx}{j});
         %eval(str);
         %str=sprintf('!fslmaths %s/coreg/swafir_%s -Tmean %s/coreg/swafir_%s_mean',in_dir,out_fn{fidx}{j},in_dir,out_fn{fidx}{j});
         %eval(str);
         fprintf('done!\n');
      end
   end %end of for j=1:length(datapath{fidx}),
end %end of for fidx=1:length(datapath),

