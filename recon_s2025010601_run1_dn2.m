clear all;
close all;
fclose all;
dbclear all;
%dbstop in inplane_grappa_wt.m at 349;
%dbstop in inplane_grappa_wt.m at 271 if (slice_idx==25);
%dbstop in recon_mb3d_s2019041202_run5.m at 413;
%=================================================================
% environment setting
%=================================================================
addpath(genpath('/proj/weitangc/users/weitangc/matlab_lib/fhlin_toolbox'));
addpath /proj/weitangc/users/weitangc/matlab_lib/NIfTI_20140122;
addpath /proj/weitangc/users/weitangc/matlab_lib/welton_toolbox;
%addpath /nas/longleaf/apps/matlab/2019a/src/proxTV-master/matlab;
%addpath /proj/weitangc/users/weitangc/matlab_lib/NORDIC_Raw-main;
%dbstop in sms3d_grappa_wt.m at 381;
%dbstop in mb3d_grappa_wt3.m at 566;
%=================================================================
%  Parameter input
%=================================================================
datapn='/proj/weitangc/projects/MB3D/data/3T_s2025010601';
outdir='/proj/weitangc/projects/MB3D/analysis/3T_s2025010601';
subdir_prefix{1} ='vn4p2p3_cali_wtp1_0p9mm_TE33_PA_';
subdir_prefix{2} ='vn4p2p3_rest_wtp1_0p9mm_TE33_AP_';
subdir_prefix{3} ='vn4p2p3_cali_wtp1_0p9mm_TE46_PA_';
subdir_prefix{4} ='vn4p2p3_rest_wtp1_0p9mm_b8_AP_';
subdir_prefix{5} ='vn4p2p3_cali_wtp1_0p9mm_TE33_PA_';
subdir_prefix{6} ='vn4p2p3_FT18_wtp1_0p9mm_TE33_AP_';
subdir_prefix{7} ='vn4p2p3_cali_wtp1_0p9mm_TE46_PA_';
subdir_prefix{8} ='vn4p2p3_FT18_wtp1_0p9mm_b8_AP_';

noise_cov_fn=[];

filesin{1}= {'meas_MID01907_FID02371_vn4p2p3_cali_wtp1_0p9mm_TE33_PA.dat'};
filesin{2}= {'meas_MID01909_FID02373_vn4p2p3_rest_wtp1_0p9mm_TE33_AP.dat'};
filesin{3}= {'meas_MID01911_FID02375_vn4p2p3_cali_wtp1_0p9mm_TE46_PA.dat'};
filesin{4}= {'meas_MID01913_FID02377_vn4p2p3_rest_wtp1_0p9mm_b8_AP.dat'};
filesin{5}= {'meas_MID01915_FID02379_vn4p2p3_cali_wtp1_0p9mm_TE33_PA.dat'};
filesin{6}= {'meas_MID01917_FID02381_vn4p2p3_FT18_wtp1_0p9mm_TE33_AP.dat'};
filesin{7}= {'meas_MID01919_FID02383_vn4p2p3_cali_wtp1_0p9mm_TE46_PA.dat'};
filesin{8}= {'meas_MID01921_FID02385_vn4p2p3_FT18_wtp1_0p9mm_b8_AP.dat'};

matfile_in='var_mb3ddata.mat';
matfile_grappa_kernel='var_mb3dgrappa_kernel';
matfile_sentiv='var_espirit_sentiv';
niifile_out='recon'; %'sense'
txtfile_out='log';

%gre_mag_fn='/proj/weitangc/projects/MB3D/analysis/3T_s2020031001/GRE/002/gre_mag_allch';
%gre_ph_fn='/proj/weitangc/projects/MB3D/analysis/3T_s2020031001/GRE/004/gre_ph_allch';
%gre_magcomb_fn='/proj/weitangc/projects/MB3D/analysis/3T_s2020031001/GRE/003/gre_mag';

sentiv_outfhdr='sentivmap';
sentiv_outmat_fhdr='var_sentiv';
flag_flipdim_sentiv=[0 0 0];
dim_rl_ap_si_sentiv=[1 2 3];

%=================================================================
%  Default parameter setting
%=================================================================
acs_fhdr_fig='fig_train';
img_fhdr_fig='fig_mb3d';
train_fhdr_combimg='ref_comb';
train_fhdr_allchimg='ref_allch';

recon_method=0; %0: GRAPPA; 1: SENSE
flag_slcgrappa_reg=1; %0: No GRAPPA regularization; 1: GRAPPA regularization applied
flag_inpgrappa_reg=1; %0: No GRAPPA regularization; 1: GRAPPA regularization applied
%flag_inpsense_reg =1; %0: No SENSE regularization; 1: SENSE regularization applied
grappa_reg_ratio=0.05; %0.003; %for Tikhonov regularization
%inpgrappa_reg_ratio=0.01; %0.003; %for Tikhonov regularization
inpsense_reg_ratio =0.01; %for Tikhonov regularization
%b1_polyn_deg=5;
sampdata_dtype=0; %0: use the average image across time as the sampled dataset; 1: use the first image; 2: use the last image
flag_apply_exist_kernel=0; %0: do not apply existed GRAPPA kernel; 1: apply existed GRAPPA kernel
flag_slcgrappa_whiten=0;
flag_inpgrappa_whiten=0;
flag_inpsense_whiten=0;
flag_apply1stkernel=0;
flag_debug=0;
k_use_percent=75; % unit: % (percentage); the maximum needs to be < 100
grappa_width_fe=7; %use the kx points at Kx + delta_fe*[-floor((grappa_width_fe-1)/2), ..., 0 , ..., ceil((grappa_width_fe-1)/2)]
grappa_width_pe=5; %use the ky points at Ky + delta_pe*[-floor((grappa_width_pe-1)/2), ..., 0 , ..., ceil((grappa_width_pe-1)/2)]
%inpgrappa_width_fe=5; %valid only if pat>1. Use the kx points at Kx + delta_fe*[-floor((inpgrappa_width_fe-1)/2), ..., 0 , ..., ceil((inpgrappa_width_fe-1)/2)]
%inpgrappa_width_pe=4; %valid only if pat>1. Use the ky points at Ky + delta_pe*[-floor((inpgrappa_width_pe-1)/2), ..., 0 , ..., ceil((inpgrappa_width_pe-1)/2)]
num_coilcompress=16;

parfourier_ratio_all=[6/8 6/8 6/8 6/8 6/8 6/8 6/8 6/8]; %Partial Fourier
blip_shift_all=[2 2 2 2 2 2 2 2];
fov_xy_all={[189.375 202.0], [189.375 202.0], [189.375 202.0], [189.375 202.0], [189.375 202.0], [189.375 202.0], [189.375 202.0], [189.375 202.0]}; %[PE FE]; unit: mm
slcthickness_all=[2.7 2.7 2.7 2.7 2.7 2.7 2.7 2.7]; %unit: mm
sms_gap_all=[29.7 29.7 29.7 29.7 29.7 29.7 29.7 29.7];
ref_rfmode_all =[1 1 1 1 1 1 1 1]; %0: no ref scan; 1: 2D ref scan; 2: MB ref scan; 3: 3D ref scan
ref_force3d_all=[0 0 0 0 0 0 0 0];
%ref_kdist_all  =[1.0 1.0 1.0 1.0 1.0];
%num_acsline_perseg_all  =[0 38 38 0 40 40];
flag_dist_all=[0 0 0 0 0 0 0 0];
encode_shift_all=[0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0]; %unit: one partition
fovz_shift_all=[0 0 0 0 0 0 0 0]; %unit: mm
flag_flip_pae_all=[0 0 0 0 0 0 0 0];
flag_denoise_all=[2 2 2 2 2 2 2 2];
flag_dorecon_all=[1 1 1 1 1 1 1 1];
flag_mixVN_all=[0 0 0 0 0 0 0 0];
flag_spsg_all=[0 0 0 0 0 0 0 0];
spsg_weight_all=[0 0 0 0 0 0 0 0];
flag_coilcompress_all=[0 0 0 0 0 0 0 0];
flag_redo_recon=0;
flag_slcgrappa_parfr_recon=0;
flag_inprecon_parfr_recon=0;
flag_parfor=1;
type_slc_grappa=0; %0: Slice GRAPPA; 1: Split-slice GRAPPA;
%voxel_sz=[3 3 3]; %unit: mm; [PE FE Thickness]
%encode_shift=0; %unit: one partition
%flag_flip_disp=[0 0 0];
flag_slc_joint_est=0;
flag_slc_fft=0;
%flag_pae2ispace=1;
prism_decode_method=1; %0: FFT, 1: encoding matrix

flag_sentiv_cal=0;
num_ch=32;
sentiv_est_method=1; %0: polynomial fit; 1: normalize; 2: eSPIRiT
fovc_gre=[0.0, 12.1, 28.0]; %R-A-H 
fovc_data_all={[0.0, 12.1, 28.0],[0.0, 12.1, 28.0],[0.0, 12.1, 28.0],[0.0, 12.1, 28.0],[0.0, 12.1, 28.0],[0.0, 12.1, 28.0]}; %R-A-H 
fit_order=4;
tvd_Niter=100;
tvd_lam_3d=0.25;
tvd_lam_2d=0.1;
smooth_fwhm=6; %unit: mm

flag_whiten=1;

coil_comb_method=1; %0: sum of square; 1: Optimal
sentiv_kernel_width_fe=7; %only valid if coil_comb_method=1; use the kx points at Kx + delta_fe*[-floor((slckernel_width_fe-1)/2), ..., 0 , ..., ceil((slckernel_width_fe-1)/2)]
sentiv_kernel_width_pe=7; %only valid if coil_comb_method=1; use the ky points at Ky + delta_pe*[-floor((slckernel_width_pe-1)/2), ..., 0 , ..., ceil((slckernel_width_pe-1)/2)]
sentiv_kernel_width_pae=7; %only valid if coil_comb_method=1; use the kx points at Kz + delta_fe*[-floor((slckernel_width_pae-1)/2), ..., 0 , ..., ceil((slckernel_width_pae-1)/2)]
flag_savefig=1; %only valid if coil_comb_method=1;

flag_save_kernelmat=0;
flag_save_kernelfile=0;

TR_all=[4.05, 4.05, 4.05, 4.05, 4.05, 4.05, 4.05, 4.05];
flag_flip_disp_all ={[0 1 0],[1 0 0],[0 1 0],[1 0 0],[0 1 0],[1 0 0],[0 1 0],[1 0 0]};
flag_trsp_disp_all ={[0 0 0],[0 0 0],[0 0 0],[0 0 0],[0 0 0],[0 0 0],[0 0 0],[0 0 0]};
dim_rl_ap_si_all   ={[2 1 3],[2 1 3],[2 1 3],[2 1 3],[2 1 3],[2 1 3],[2 1 3],[2 1 3]};
%flag_shiftinslc_all={[],[],[],[],[],[],[],[]};

%%%% Set the pseudo random phase %%%%
prandn_phase={[0],[0,0],...
              [0,0.730,4.602],[0,3.875,5.940,6.197],...
              [0,3.778,5.335,0.872,0.471],[0,2.005,1.674,5.012,5.736,4.123],...
              [0,3.002,5.998,5.909,2.624,2.528,2.440],[0,1.036,3.414,3.778,3.215,1.756,4.555,2.467],...
              [0,1.250,1.783,3.558,0.739,3.319,1.296,0.521,5.332],[0,4.418,2.360,0.677,2.253,3.472,3.040,3.974,1.192,2.510],...
              [0,5.041,4.285,3.001,5.765,4.295,0.056,4.213,6.040,1.078,2.759],[0,2.755,5.491,4.447,0.231,2.499,3.539,2.931,2.759,5.376,4.554,3.479],...
              [0,0.603,0.009,4.179,4.361,4.837,0.816,5.995,4.150,0.417,1.520,4.517,1.729],...
              [0,3.997,0.830,5.712,3.838,0.084,1.685,5.328,0.237,0.506,1.356,4.025,4.483,4.084]...
              [0,4.126,2.266,0.957,4.603,0.815,3.475,0.977,1.449,1.192,0.148,0.939,2.531,3.612,4.801],...
              [0,4.359,3.510,4.410,1.750,3.357,2.061,5.948,3.000,2.822,0.627,2.768,3.875,4.173,4.224,5.941],...
              [0.0,0.047,2.651,1.315,1.947,3.920,5.142,1.726,3.609,0.391,4.360,1.527,4.059,3.769,2.277,1.753,2.238],...
              [0.0,3.025,3.073,0.535,4.711,4.528,1.884,3.544,2.538,1.422,2.440,3.214,5.146,4.247,0.326,4.432,0.051,4.312],...
              [0.0,2.505,0.961,2.981,5.031,0.975,2.001,4.166,3.954,3.685,4.671,5.544,3.643,0.885,5.453,4.018,3.763,3.935,2.438],...
              [0.0,2.966,6.099,4.444,2.359,6.028,4.045,4.009,0.482,0.175,5.115,5.403,1.294,2.657,1.696,2.935,1.919,3.112,0.341,1.280],...
              [0.0,0.421,2.198,1.308,6.277,3.596,0.486,0.702,0.994,4.113,6.037,1.134,4.090,1.516,4.520,2.940,2.751,2.918,0.000,0.269,5.681],...
              [0.0,3.467,4.370,3.680,1.926,1.816,5.490,1.428,4.503,0.346,1.836,4.927,3.132,0.797,4.805,3.622,4.543,0.178,4.801,4.213,5.600,4.886],...
              [0.0,5.695,0.324,5.757,1.513,3.863,3.299,3.109,1.989,5.286,1.689,4.174,1.483,1.700,4.970,2.239,0.764,1.995,3.373,0.251,0.374,3.309,2.449],...
              [0.0,0.240,5.749,3.521,4.588,4.820,3.091,0.940,0.587,3.504,4.267,0.583,1.559,4.808,0.441,3.370,1.908,3.950,5.166,4.211,3.503,5.324,4.421,6.008],...
              [0.0,2.410,0.351,5.117,2.016,5.427,1.078,2.412,1.816,5.856,5.791,6.051,4.874,3.755,3.407,1.043,4.123,4.903,3.756,0.407,0.653,5.192,0.807,1.586,2.762],...
              [0.0,5.336,0.285,0.738,5.043,1.146,5.835,0.380,2.370,0.384,2.832,3.113,1.900,0.038,1.643,0.021,4.867,5.495,3.845,1.522,1.111,4.284,5.307,1.619,2.468,5.253],...
              [0.0,1.854,2.283,4.407,6.007,4.121,1.312,3.217,0.727,0.616,2.554,3.494,1.966,2.782,3.586,2.213,0.319,0.910,6.145,0.492,3.345,5.421,3.524,1.552,6.264,3.653,2.510],...
              [0.0,5.825,4.148,3.915,5.526,1.776,1.818,4.660,5.374,0.932,3.216,6.003,3.667,3.029,5.909,3.288,0.267,4.043,0.867,3.858,5.158,2.868,0.338,0.256,2.175,2.714,2.452,3.192],...
              [0.0,0.473,3.291,3.917,3.742,0.940,0.127,1.574,5.872,5.017,2.780,3.657,0.394,3.802,2.717,3.544,1.448,3.757,0.101,3.215,0.051,0.681,0.481,0.751,2.215,1.286,0.076,3.150,1.149],...
              [0.0,3.623,0.480,2.488,2.955,0.405,4.927,0.053,3.034,0.749,0.409,3.295,3.386,0.830,0.422,1.813,0.984,3.298,4.516,2.568,3.186,3.725,3.418,4.100,4.626,1.860,2.879,2.316,0.548,0.704],...
              [0.0,3.649,2.870,0.672,4.524,3.748,4.791,6.098,5.751,6.161,5.495,4.549,3.476,3.622,3.608,0.103,0.575,2.047,4.577,4.210,0.307,2.558,0.233,1.976,1.612,5.751,1.316,3.310,0.893,3.151,5.641],...
              [0.0,4.281,1.405,5.180,0.235,4.390,4.586,6.109,0.000,5.382,2.147,5.560,0.353,2.397,5.819,4.883,0.061,1.394,4.307,1.998,2.280,4.216,4.552,4.531,2.838,1.921,1.767,0.349,5.666,0.555,0.336,2.826],...
              [0.0,1.561,2.776,0.031,1.746,3.448,2.909,2.593,1.889,0.672,0.997,4.077,4.212,1.655,0.637,3.865,4.619,1.702,0.453,3.418,0.931,2.161,0.251,3.355,5.945,6.118,3.130,0.834,4.053,3.229,5.437,4.521,0.308],...
              [0.0,5.177,5.806,4.393,2.440,2.042,1.139,3.841,0.205,4.868,0.462,6.007,2.508,2.715,3.674,3.397,2.899,3.348,2.403,3.824,3.524,1.134,3.611,5.065,0.156,1.425,4.305,3.383,0.343,0.995,3.435,4.608,2.549,4.866],...
              [0.0,5.808,4.310,3.816,3.617,0.879,4.464,1.409,5.050,6.211,5.124,5.265,3.185,4.261,5.764,5.540,0.101,3.335,5.977,4.527,4.668,5.946,0.791,4.029,0.603,2.059,3.138,1.911,1.781,3.341,1.684,4.494,4.433,0.849,6.042],...
              [0.0,0.940,3.609,6.211,5.886,5.098,1.871,4.154,5.609,4.195,0.571,4.951,1.731,3.586,4.186,0.662,1.818,4.409,3.371,2.927,3.624,5.256,5.093,4.558,1.169,3.533,2.850,4.901,2.993,0.164,5.819,5.838,6.265,3.999,2.104,1.990],...
              [0.0,5.996,5.738,5.234,2.874,1.904,5.850,4.951,5.280,4.864,4.295,5.015,4.608,0.682,5.290,1.788,0.945,5.230,4.386,1.424,1.795,4.812,0.503,1.779,2.357,2.343,4.433,0.116,1.867,4.528,6.215,4.208,1.503,5.487,1.809,4.845,2.015],...
              [0.0,3.885,4.475,0.752,3.109,4.852,4.688,2.519,0.363,5.545,6.153,3.956,2.607,2.621,2.685,0.381,0.869,0.227,1.667,0.139,1.486,3.515,1.881,4.947,4.511,2.368,2.363,4.927,2.343,0.676,0.733,2.561,2.420,3.986,1.546,0.069,1.611,2.904],...
              [0.0,4.682,2.268,2.433,2.509,4.254,4.702,2.645,2.840,1.548,2.830,2.167,4.842,1.479,2.567,1.641,5.245,1.860,3.219,0.375,3.391,3.730,1.007,3.081,1.309,3.683,4.185,5.564,4.939,3.237,4.948,1.520,1.180,0.953,0.296,4.725,1.300,3.739,4.414],...
              [0.0,3.224,5.486,2.089,6.028,2.951,2.846,2.407,1.216,1.254,1.165,4.793,0.803,5.683,4.529,1.953,5.311,0.366,0.504,2.893,2.188,3.274,3.530,3.720,4.449,4.960,5.264,2.728,4.434,3.964,2.588,1.275,5.236,4.509,2.087,4.666,6.021,1.041,2.461,4.811],...
              [0.0,1.351,0.642,4.702,4.910,2.980,3.320,0.265,1.737,4.037,2.425,2.729,5.126,3.227,5.979,3.867,0.071,0.117,0.387,2.234,1.848,4.501,0.791,5.518,3.361,0.279,3.921,0.169,0.078,5.714,5.876,0.178,1.057,5.118,4.333,6.239,6.068,3.487,0.925,1.721,5.720],...
              [0.0,0.535,2.790,3.841,0.615,2.187,2.900,0.471,4.076,3.935,0.867,4.935,5.074,4.133,4.173,0.255,3.823,1.887,1.942,3.003,3.342,4.646,2.721,5.912,2.779,3.339,1.838,1.249,2.260,2.858,4.721,1.929,5.634,3.132,0.864,2.371,0.197,4.241,4.828,3.857,3.026,1.721],...
              [0.0,2.695,4.303,0.315,3.410,3.708,0.119,3.739,3.578,5.439,0.131,0.368,1.595,3.244,1.320,0.169,3.674,1.737,3.594,0.226,0.116,1.108,2.854,0.615,4.531,0.846,4.105,2.988,3.101,2.817,1.591,5.034,0.322,0.813,3.442,2.393,3.390,2.102,2.311,0.877,0.856,3.420,2.175],...
              [0.0,0.868,2.849,5.367,2.683,0.737,3.681,3.057,2.062,4.559,2.228,3.497,2.594,4.783,0.963,5.184,5.065,1.296,4.749,5.852,5.219,4.974,0.032,2.600,3.421,3.272,4.125,4.051,3.535,6.229,0.950,4.246,2.100,5.968,4.200,4.187,3.705,1.907,3.250,0.179,0.290,0.366,3.808,3.772],...
              [0.0,5.205,0.933,4.786,0.962,5.531,6.159,4.288,0.331,0.108,1.765,1.597,4.087,3.105,0.923,0.721,6.070,3.234,3.033,0.069,4.997,1.036,3.400,6.160,1.330,3.275,1.212,2.244,4.028,4.035,2.594,5.130,4.204,1.542,4.508,0.485,1.086,1.050,3.958,5.091,4.917,3.218,3.392,1.456,1.157],...
              [0.0,4.195,1.006,0.232,1.708,4.769,5.434,3.246,2.027,0.469,5.859,0.357,4.011,6.029,4.762,0.776,2.398,0.060,2.463,3.341,1.149,2.168,4.933,4.836,2.499,4.397,4.660,5.475,2.150,0.350,0.089,2.009,2.137,4.159,3.841,5.374,0.406,4.067,2.825,4.655,3.520,3.701,2.920,2.327,4.023,5.623],...
              [0.0,5.876,3.472,1.988,5.252,2.896,3.999,2.419,4.619,4.407,5.898,5.120,3.636,4.214,4.894,4.043,3.583,2.301,2.792,0.820,2.428,1.345,1.044,3.705,3.805,2.432,3.730,0.505,5.574,1.463,4.715,4.152,2.114,3.658,4.522,5.148,0.836,3.711,0.587,3.916,4.871,2.526,0.038,0.267,1.249,3.339,5.064],...
              [0.0,1.442,4.348,5.056,2.436,3.778,0.376,1.418,1.783,0.743,3.400,2.444,5.873,1.312,1.412,3.154,1.306,5.894,3.611,5.194,1.300,1.085,1.606,5.522,4.495,1.424,5.177,5.669,1.495,6.238,0.315,0.381,0.789,4.176,2.947,2.477,2.218,3.484,3.060,2.056,0.978,4.431,6.079,1.193,5.854,1.913,4.640,1.480],...
              [0.0,6.220,4.819,0.173,3.910,2.845,5.007,4.529,0.172,2.363,3.153,2.256,2.313,2.927,2.716,0.523,1.646,5.431,2.018,0.407,2.350,4.795,1.252,2.249,3.217,2.003,4.581,5.781,2.190,6.019,3.866,0.713,5.935,4.754,2.827,0.602,2.345,0.561,1.153,6.223,0.609,2.683,2.699,4.564,4.405,2.197,2.813,0.347,5.482],...
              [0.0,5.170,0.751,0.984,4.962,0.068,5.048,3.874,5.454,1.051,3.267,2.627,6.014,0.007,0.414,3.521,2.471,2.192,1.316,2.308,1.437,5.219,1.257,5.630,1.378,4.866,0.119,2.551,0.169,1.049,3.803,2.328,1.310,0.833,0.719,3.677,0.271,4.172,2.739,0.393,3.015,4.160,4.921,4.249,5.728,0.696,1.037,4.062,1.208,2.045],...
              [0.0,0.448,5.704,1.753,5.881,5.143,2.987,2.436,0.763,3.228,1.057,3.892,2.479,4.026,4.197,1.956,4.682,4.045,2.073,0.249,1.108,3.060,1.486,0.968,4.203,0.647,3.340,0.195,1.400,5.702,3.943,2.316,2.783,0.952,3.225,4.128,0.146,2.773,3.345,4.710,0.104,2.662,2.282,2.827,3.215,5.661,5.496,1.221,3.461,2.126,3.267],...
              [0.0,1.072,0.029,4.015,5.691,3.093,2.975,2.123,3.748,4.819,3.106,4.054,5.038,0.654,4.668,1.188,1.661,5.463,0.144,0.521,0.181,5.659,1.165,4.505,4.462,6.066,5.122,2.655,0.344,4.567,0.083,0.214,0.430,5.323,4.486,2.497,5.240,5.014,0.109,4.703,4.695,1.606,1.785,1.695,5.244,2.351,4.054,5.059,6.072,2.820,2.170,3.600],...
              [0.0,3.465,0.188,6.109,1.159,1.918,3.349,0.565,2.723,2.812,2.211,0.536,1.917,0.250,2.327,4.981,3.604,1.764,1.363,0.052,2.281,2.552,1.161,1.667,5.407,1.938,4.510,5.144,5.235,4.386,2.764,2.752,0.441,2.017,1.248,1.911,3.599,0.561,3.452,0.254,0.668,1.646,4.478,0.976,5.666,4.239,5.669,4.253,3.320,0.982,6.219,0.382,3.620],...
              [0.0,0.027,1.370,4.201,4.075,2.389,3.650,3.780,4.540,4.730,2.406,1.975,1.821,4.782,2.042,3.398,2.970,3.074,0.257,4.597,0.933,4.205,0.764,1.442,4.879,1.655,4.091,6.219,5.714,0.827,1.086,1.746,5.614,3.462,0.555,6.060,0.731,1.704,4.291,4.968,4.139,3.102,0.210,1.947,5.808,5.352,0.144,0.559,5.875,3.697,1.790,0.545,1.242,1.614],...
              [0.0,0.512,2.435,3.590,2.363,4.581,0.699,1.658,4.228,0.398,4.741,0.424,5.447,4.338,1.808,6.095,2.933,2.652,4.059,3.945,3.221,1.797,3.760,1.572,3.816,1.580,2.944,4.794,3.429,0.886,1.500,5.055,0.577,2.169,1.551,5.719,0.235,2.528,2.160,0.282,1.826,1.857,1.581,1.011,3.321,1.081,4.749,0.839,2.233,4.317,4.243,3.542,3.302,1.161,1.592],...
              [0.0,0.835,3.440,5.181,1.443,0.714,1.605,3.164,1.467,1.351,3.353,3.438,1.799,4.977,4.365,3.840,4.163,3.357,6.045,3.976,3.523,3.846,3.903,3.870,0.656,2.128,1.207,4.151,6.249,5.016,0.505,3.521,2.139,5.113,3.071,0.523,4.265,0.406,0.040,3.163,3.371,6.147,1.836,5.051,5.426,3.831,2.010,0.353,1.027,5.402,0.874,5.378,4.865,2.694,4.837,3.699],...
              [0.0,1.163,1.645,5.489,3.864,4.883,1.463,3.585,5.512,2.518,0.596,2.570,3.305,3.665,1.465,4.513,0.966,3.081,5.553,3.261,3.054,5.355,1.424,3.881,3.606,1.129,1.930,4.659,5.506,6.186,4.989,4.384,5.013,0.104,3.218,1.508,4.838,4.028,2.914,3.382,2.605,4.386,3.915,5.565,4.913,2.662,2.430,1.370,2.813,0.408,4.526,2.033,1.526,4.573,3.891,3.674,1.995],...
              [0.0,3.202,1.423,4.222,3.120,3.894,6.081,1.161,0.088,4.097,4.937,1.514,3.920,0.256,3.207,3.774,2.868,2.884,4.669,1.643,4.182,0.534,0.652,2.667,3.869,3.582,3.335,1.638,5.956,2.398,3.644,3.251,2.044,2.602,1.930,5.238,1.982,0.426,0.359,1.899,2.073,0.330,4.155,2.041,0.296,1.042,0.032,4.929,3.273,3.587,3.238,4.132,2.373,2.671,4.039,5.591,0.159,2.669],...
              [0.0,5.569,6.036,4.685,5.993,0.713,0.879,5.098,5.604,3.265,2.492,0.126,2.445,5.181,1.387,0.391,1.270,3.364,4.018,1.156,2.885,5.242,2.623,1.594,2.466,3.671,3.028,6.106,6.066,3.672,2.283,0.347,0.504,3.129,5.859,0.303,1.295,1.439,0.914,3.310,2.333,0.742,2.592,2.527,0.444,5.172,5.665,0.398,4.998,2.244,5.865,3.148,2.454,0.253,3.207,0.529,5.653,1.630,3.519]};

%=================================================================
%  Loading the RAW data
%=================================================================
%dbstop in slice_grappa_wt.m at 127 if error;
%if(flag_pae2ispace==0)
%   append_str='f';
%else
%   append_str='i';
%end

for i=1, %1:length(filesin),
   encode_mtx_full=[];
   parfourier_ratio=parfourier_ratio_all(i);
   blip_shift=blip_shift_all(i);
   fov_xy=fov_xy_all{i};
   slcthickness=slcthickness_all(i);
   sms_gap=sms_gap_all(i);
   ref_rfmode=ref_rfmode_all(i); %0: no ref scan; 1: 2D ref scan; 2: MB ref scan; 3: 3D ref scan
   ref_force3d=ref_force3d_all(i);
   %ref_kdist=ref_kdist_all(i);
   encode_shift=encode_shift_all(i);
   fovz_shift=fovz_shift_all(i);
   flag_flip_pae=flag_flip_pae_all(i);
   flag_denoise=flag_denoise_all(i);
   flag_dorecon=flag_dorecon_all(i);
   flag_mixVN=flag_mixVN_all(i);
   flag_spsg=flag_spsg_all(i);
   flag_coilcompress=flag_coilcompress_all(i);
   if(flag_spsg==1)
      spsg_str='_sp';
      spsg_weight=spsg_weight_all(i);
   else
      spsg_str=[];
      spsg_weight=[];
   end
   %num_acsline_perseg=num_acsline_perseg_all(i);
   flag_dist=flag_dist_all(i);
   TR=TR_all(i);
   %fovc_data=fovc_data_all{i};
   
   flag_flip_disp=flag_flip_disp_all{i};
   flag_trsp_disp=flag_trsp_disp_all{i};
   dim_rl_ap_si=dim_rl_ap_si_all{i};
   
   if(flag_denoise~=2)
      matfile_out=sprintf('var_mb3d%s_dn%d%s%3.1f',niifile_out,flag_denoise,spsg_str,spsg_weight); %'var_mb3dsense';
      matfile_out(strfind(matfile_out,'.'))='p';
      matfile_out(strfind(matfile_out,' '))=[];
   else
      matfile_out=sprintf('var_mb3d%s_dn%d%s%3.1f',niifile_out,0,spsg_str,spsg_weight); %'var_mb3dsense';
      matfile_out(strfind(matfile_out,'.'))='p';
      matfile_out(strfind(matfile_out,' '))=[];
   end
   
   for j=1:length(filesin{i}),
      folder_name=sprintf('%s%d',subdir_prefix{i},j);
      fprintf('load %s/%s/%s ...',outdir,folder_name,matfile_in);
      %tmp_search=dir(sprintf('%s/%s/%s_%s.mat',outdir,folder_name,matfile_out,append_str));
      tmp_search=dir(sprintf('%s/%s/%s.mat',outdir,folder_name,matfile_out));
      if(isempty(tmp_search) || (flag_redo_recon==1))
         eval(sprintf('load %s/%s/%s train_volcplx prism_data noise_data nz pat flag_train_scan sms_factor num_slc_pae num_ref_pae ref_slcidx_all;',outdir,folder_name,matfile_in));
         fprintf('done!\n');
         train_volcplx=single(train_volcplx);
         %train_spsg_volcplx=single(train_spsg_volcplx);
         %acs_volcplx=single(acs_volcplx);
         prism_data=single(prism_data);
         %for test
         %prism_data=mean(prism_data,6);
         if(~isempty(noise_data))
            noise_data=single(noise_data);
         end
      else
         %eval(sprintf('load %s/%s/%s train_volcplx prism_data noise_data nz pat flag_train_scan sms_factor num_slc_pae num_ref_pae ref_slcidx_all;',outdir,folder_name,matfile_in));
         eval(sprintf('load %s/%s/%s train_volcplx noise_data nz pat flag_train_scan sms_factor num_slc_pae num_ref_pae ref_slcidx_all;',outdir,folder_name,matfile_in));
         fprintf('done!\n');
         %fprintf('load %s/%s/%s_%s.mat ...',outdir,folder_name,matfile_out,append_str);
         fprintf('load %s/%s/%s.mat ...',outdir,folder_name,matfile_out);
         %eval(sprintf('load %s/%s/%s_%s.mat I_recon;',outdir,folder_name,matfile_out,append_str));
         eval(sprintf('load %s/%s/%s.mat I_recon_comb recon_method header;',outdir,folder_name,matfile_out));
         fprintf('done!\n');
         
         eval(sprintf('save %s/%s/%s.mat I_recon_comb recon_method header -v7.3;',outdir,folder_name,matfile_out));
         
         train_volcplx=single(train_volcplx);
         %train_spsg_volcplx=single(train_spsg_volcplx);
         %acs_volcplx=single(acs_volcplx);
         if(~isempty(noise_data))
            noise_data=single(noise_data);
         end
      end
      
      %%%% Start GRAPPA reconstruction %%%%
      header.Nslc=nz;
      header.num_slc_pae=num_slc_pae;
      if(isempty(tmp_search) || (flag_redo_recon==1))
         header.Npe=size(prism_data,1);
         header.Nfe=size(prism_data,2);
         header.Nch=size(prism_data,4);
      else
         header.Npe=size(I_recon_comb,1);
         header.Nfe=size(I_recon_comb,2);
         header.Nch=32; %size(I_recon,4);
      end
      header.vox=[fov_xy(1)/header.Npe, fov_xy(2)/header.Nfe, slcthickness/header.num_slc_pae];
      header.sms_factor=sms_factor;
      %header.sms_lastslc_index=sms_lastslc_index;
      header.sms_gap=sms_gap;
      if(~exist('pat'))
         header.pat=1;
      else
         header.pat=pat;
      end
      header.flag_dist=flag_dist;
      header.blip_shift=blip_shift;
      header.Nsep=header.Nslc/header.sms_factor;
      if(isempty(tmp_search) || (flag_redo_recon==1))
         header.Nrep=size(prism_data,6);
      else
         %header.Nrep=size(I_recon,5);
         header.Nrep=size(I_recon_comb,4);
      end
      header.percent=k_use_percent;
      header.Nslc_full=round(header.sms_gap/slcthickness)*header.sms_factor;
      
      if(~isempty(noise_data))
         header.noise_data=noise_data;
         %header.C0=abs(cov(noise_data));
         %noise_ftdata=fftshift(ifft(ifftshift(noise_data,1),[],1),1);
         %header.ftC0=abs(cov(noise_ftdata));
      else
         %header.C0=[];
         header.noise_data=[];
      end
      
      if(mod(header.Nsep,2)==1)
         num_interlv_g1=floor(header.Nsep/2)+1;
         num_interlv_g2=floor(header.Nsep/2);
      else
         num_interlv_g1=header.Nsep/2;
         num_interlv_g2=header.Nsep/2;
      end
      
      if(mod(num_slc_pae,2)==0)
         sms_offset=0;
      else
         sms_offset=floor(header.sms_factor/2);
      end
      
      interlv_g1=([1:num_interlv_g1]'-1)*2+header.Nsep*sms_offset+mod(header.Nsep+1,2)+1;
      interlv_g2=([1:num_interlv_g2]'-1)*2+header.Nsep*sms_offset+mod(header.Nsep,2)+1;
      header.base_slcidx=cat(1,interlv_g1,interlv_g2);
      header.sms_groupset=zeros(header.Nsep,header.sms_factor);
      for tidx=1:header.sms_factor,
         header.sms_groupset(:,tidx)=header.base_slcidx+(tidx-1-floor(header.sms_factor/2))*header.Nsep;
      end
      header.sms_groupset=mod(header.sms_groupset-1,header.Nslc)+1;
      min_slicidx=min(header.base_slcidx);
      
      sz_refimg=size(train_volcplx);
      N3D=sms_gap*sms_factor*num_slc_pae/slcthickness;
      header.N3D=N3D;
      
      if(isempty(tmp_search))
         if(flag_denoise==1) %MPPCA
            fprintf('Start denoising ... \n');
            %if(flag_parfor==1)
            %   for eidx=1:size(prism_data,5),
            %      prism_data_orig{eidx}=prism_data(:,:,:,:,eidx,:);
            %   end
            %   if(isempty(gcp))
            %      p=parpool('local',12);
            %   end
            %   parfor eidx=1:size(prism_data,5),
            %      prism_data_orig{eidx}=denoise_kspace_wt(prism_data_orig{eidx},noise_data,[5 5 5],[5 5 5],'voxel',[],'','nuc',1);
            %   end
            %   delete(gcp('nocreate'));
            %   for eidx=1:size(prism_data,5),
            %      prism_data(:,:,:,:,eidx,:)=prism_data_orig{eidx};
            %   end
            %   clearvars prism_data_orig;
            %else
               prism_data_orig=prism_data;
               for eidx=1:size(prism_data,5),
                  prism_data(:,:,:,:,eidx,:)=denoise_kspace_wt(prism_data_orig(:,:,:,:,eidx,:),noise_data,[5 5 5],[5 5 5],'voxel',[],'','nuc',1);
               end
               clearvars prism_data_orig;
            %end
            %train_volcplx_orig=train_volcplx;
            %train_volcplx=denoise_kspace_wt(train_volcplx_orig,noise_data,[5 5 5],[5 5 5],'voxel',[],'','nuc',1);
            cur_dir=pwd;
            cd(tempdir);
            pack;
            cd(cur_dir);
            fprintf('done\n');
         end
      end
      fillup_idx_array=[];
      if(ref_rfmode==0) %MB3D_REF
         if(ref_force3d==0)
            for sidx=1:header.Nslc,
               fillup_idx_array(:,sidx)=sidx+header.Nslc*[0:1:num_slc_pae-1]';
            end
         else %(ref_force3d==1)
            for sidx=1:header.Nslc,
               fillup_idx_array(:,sidx)=[1:N3D]';
            end
         end %end of if(ref_force3d==0)
      elseif(ref_rfmode==1) %multislab slab
         if(ref_force3d==0)
            for sidx=1:header.Nsep,
               fillup_idx_array(:,sidx)=sidx+[0:header.Nsep:N3D-1]';
            end
         else
            for sidx=1:header.Nsep,
               fillup_idx_array(:,sidx)=[1:N3D]';
            end
         end
      elseif(ref_rfmode==2) %3D
         for sidx=1:1,
            fillup_idx_array(:,sidx)=[1:N3D]';
         end
      end
      
      if(flag_train_scan==1)
         %train_volall=fftshift(fft(ifftshift(train_volcplx,5),[],5),5);
         %train_volall=train_volcplx;
         
         %fprintf('preparing the sensitivity map...\n');
         %tmp_dir=dir(sprintf('%s/%s_data_mag.nii.gz',outdir,sentiv_outfhdr));
         %if(isempty(tmp_dir) || (flag_sentiv_cal==1))
         %   [dd1 dd2 dd3]=ndgrid(d1_vec,d2_vec,d3_vec);
         %   sz_img=[header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch];
         %   sz_img=sz_img([dim_rl_ap_si,4]);
         %   vox_img=header.vox(dim_rl_ap_si);
         %   
         %   d1d_vec=[0:1:sz_img(1)-1]*vox_img(1)-(sz_img(1)*vox_img(1)/2)+vox_img(1)/2;
         %   d2d_vec=[0:1:sz_img(2)-1]*vox_img(2)-(sz_img(2)*vox_img(2)/2)+vox_img(2)/2;
         %   d3d_vec=[0:1:sz_img(3)-1]*vox_img(3)-(sz_img(3)*vox_img(3)/2)+vox_img(3)/2;
         %   d1d_vec=d1d_vec+fovc_data(1);
         %   d2d_vec=d2d_vec+fovc_data(2);
         %   d3d_vec=d3d_vec+fovc_data(3);
         %   [d1d d2d d3d]=ndgrid(d1d_vec,d2d_vec,d3d_vec);
         %   
         %   sentiv_data_mag=zeros(sz_img,'single');
         %   if(sentiv_est_method==0)
         %      for chidx=1:header.Nch,
         %         %tmp_mag_vol=fit_mag_vol(:,:,:,chidx);
         %         %tmp_fit_vol=interpn(dd1,dd2,dd3,tmp_mag_vol,d1d,d2d,d3d,'spline');
         %         %tmp_fit_vol(find(isnan(tmp_fit_vol)))=0;
         %         %sentiv_data_mag(:,:,:,chidx)=tmp_fit_vol;
         %         fit_var=polyvaln(polym{chidx},[d1d(:),d2d(:),d3d(:)]);
         %         sentiv_data_mag(:,:,:,chidx)=reshape(fit_var,sz_img(1:3));
         %      end
         %   else
         %      for chidx=1:header.Nch,
         %         tmp_mag_vol=abs(est_sentiv(:,:,:,chidx));
         %         tmp_abs=interpn(dd1,dd2,dd3,tmp_mag_vol,d1d,d2d,d3d,'spline');
         %         tmp_abs(find(isnan(tmp_abs)))=0;
         %         sentiv_data_mag(:,:,:,chidx)=tmp_abs;
         %      end
         %   end
         %   
         %   sentiv_data_ph=zeros(sz_img,'single');
         %   for chidx=1:header.Nch,
         %      tmp_ph_vol=angle(est_sentiv(:,:,:,chidx));
         %      tmp_cplx=interpn(dd1,dd2,dd3,exp(sqrt(-1)*tmp_ph_vol),d1d,d2d,d3d,'spline');
         %      tmp_cplx(find(isnan(tmp_cplx)))=0;
         %      sentiv_data_ph(:,:,:,chidx)=angle(tmp_cplx);
         %   end
         %   sentiv_data=sentiv_data_mag.*exp(sqrt(-1)*sentiv_data_ph);
         %   out_nii=make_nii(abs(sentiv_data),vox_img,fovc_data,16);
         %   fstr_out=sprintf('%s/%s_data_mag.nii.gz',outdir,sentiv_outfhdr);
         %   save_nii(out_nii,fstr_out);
         %   out_nii=make_nii(angle(sentiv_data)*180/pi,vox_img,fovc_data,16);
         %   fstr_out=sprintf('%s/%s_data_ph.nii.gz',outdir,sentiv_outfhdr);
         %   save_nii(out_nii,fstr_out);
         %else
         %   fstr_mag=sprintf('%s/%s_data_mag.nii.gz',outdir,sentiv_outfhdr);
         %   voldata_mag=load_nii(fstr_mag);
         %   fstr_ph=sprintf('%s/%s_data_ph.nii.gz',outdir,sentiv_outfhdr);
         %   voldata_ph=load_nii(fstr_ph);
         %   sentiv_data=voldata_mag.img.*exp(sqrt(-1)*voldata_ph.img*pi/180);
         %end
         %
         %sentiv_data=ipermute(sentiv_data,[dim_rl_ap_si,4]);
         %for didx=1:3,
         %   if(flag_flip_disp(didx)==1)
         %      sentiv_data=flipdim(sentiv_data,didx);
         %   end
         %end
         
         %%if(flag_denoise>0)
         %if(flag_denoise==2)
         %   fstr_magout=sprintf('%s/%s/%s_mag_dn.nii.gz',outdir,folder_name,train_fhdr_allchimg);
         %   fstr_phout=sprintf('%s/%s/%s_ph_dn.nii.gz',outdir,folder_name,train_fhdr_allchimg);
         %else
            fstr_magout=sprintf('%s/%s/%s_mag.nii.gz',outdir,folder_name,train_fhdr_allchimg);
            fstr_phout=sprintf('%s/%s/%s_ph.nii.gz',outdir,folder_name,train_fhdr_allchimg);
         %end
         tmp_dir=dir(fstr_magout);
         if(isempty(tmp_dir))
            if(ref_force3d==0)
               refI_recon = zeros(header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, 'single');
               if(ref_rfmode==0) %single slab
                  tmp_ph=flipdim(reshape(prandn_phase{header.num_slc_pae},[1 1 1 header.num_slc_pae]),4);
                  for sidx=1:header.Nslc,
                     tmp_mtx=train_volcplx(:,:,sidx,:,:); %[header.Npe, header.Nfe, 1, header.Nch, header.num_slc_pae]
                     tmp_mtx=reshape(fftshift(fft(ifftshift(tmp_mtx,5),[],5),5),[header.Npe, header.Nfe, header.Nch, header.num_slc_pae]);
                     tmp_mtx=tmp_mtx.*repmat(exp(sqrt(-1)*tmp_ph),[header.Npe, header.Nfe, header.Nch, 1]);
                     refI_recon(:,:,fillup_idx_array(:,sidx),:)=permute(tmp_mtx,[1 2 4 3]);
                  end
               elseif(ref_rfmode==1) %multislab slab
                  tmp_ph=flipdim(reshape(prandn_phase{header.num_slc_pae*header.sms_factor},[1 1 1 header.num_slc_pae*header.sms_factor]),4);
                  for gidx=1:header.Nsep,
                     tmp_mtx=reshape(train_volcplx(:,:,gidx,:,:),[header.Npe, header.Nfe, header.Nch, header.num_slc_pae*header.sms_factor]); %[header.Npe, header.Nfe, 1, header.Nch, header.num_slc_pae*header.sms_factor]
                     tmp_mtx=fftshift(fft(ifftshift(tmp_mtx,4),[],4),4);
                     tmp_mtx=tmp_mtx.*repmat(exp(sqrt(-1)*tmp_ph),[header.Npe, header.Nfe, header.Nch, 1]);
                     refI_recon(:,:,fillup_idx_array(:,gidx),:)=permute(tmp_mtx,[1 2 4 3]);
                  end
               elseif(ref_rfmode==2) %3D
                  tmp_mtx=reshape(train_volcplx(:,:,1,:,:),[header.Npe, header.Nfe, header.Nch, N3D]); %[header.Npe, header.Nfe, 1, header.Nch, header.num_slc_pae*header.sms_factor]
                  tmp_mtx=fftshift(fft(ifftshift(tmp_mtx,4),[],4),4);
                  refI_recon(:,:,fillup_idx_array(:,1),:)=permute(tmp_mtx,[1 2 4 3]);
               end
            else
               if(ref_rfmode==0) %single slab
                  refI_recon = zeros(header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, header.Nslc,'single');
               elseif(ref_rfmode==1) %multislab slab
                  refI_recon = zeros(header.Npe, header.Nfe, N3D, header.Nch, header.Nsep,'single');
                  for gidx=1:header.Nsep,
                     tmp_mtx=reshape(train_volcplx(:,:,gidx,:,:),[header.Npe, header.Nfe, header.Nch, N3D]); %[header.Npe, header.Nfe, 1, header.Nch, header.num_slc_pae*header.sms_factor]
                     tmp_mtx=fftshift(fft(ifftshift(tmp_mtx,4),[],4),4);
                     refI_recon(:,:,fillup_idx_array(:,gidx),:,gidx)=permute(tmp_mtx,[1 2 4 3]);
                  end
               elseif(ref_rfmode==2) %3D
                  refI_recon = zeros(header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, 'single');
               end
            end %end of else(ref_force3d==0)
            
            %%if(flag_denoise>0)
            %if(flag_denoise==2)
            %   fprintf('Start denoising ... \n');
            %   refI_recon_orig=refI_recon;
            %   %refI_recon=denoise_kspace_wt(refI_recon_orig,noise_data,[5 5 1],[5 5 1],'voxel',[],'','nuc',1);
            %   %refI_recon=denoise_kspace_wt(refI_recon_orig,noise_data,[5 5 5],[5 5 5],'voxel',[],'','nuc',1,1);
            %   refI_recon=denoise_kspace_wt(refI_recon_orig,noise_data,[5 5 5],[5 5 5],'voxel',[],'','mppca',1,1);
            %   clearvars refI_recon_orig;
            %   %cur_dir=pwd;
            %   %cd(tempdir);
            %   %pack;
            %   %cd(cur_dir);
            %   fprintf('done\n');
            %end
            
            trainI_recon=refI_recon;
            for didx=1:3,
               if(flag_flip_disp(didx)==1)
                  trainI_recon=flipdim(trainI_recon,didx);
               end
            end
            trainI_recon=permute(trainI_recon,[dim_rl_ap_si,4]);
            
            out_nii=make_nii(abs(trainI_recon),header.vox(dim_rl_ap_si),[],16);
            save_nii(out_nii,fstr_magout);
            out_nii=make_nii(angle(trainI_recon),header.vox(dim_rl_ap_si),[],16);
            save_nii(out_nii,fstr_phout);
         else
            invol_mag=load_nii(fstr_magout);
            invol_ph=load_nii(fstr_phout);
            
            trainI_recon=(invol_mag.img).*exp(1j*invol_ph.img);
            refI_recon=trainI_recon;
            refI_recon=ipermute(refI_recon,[dim_rl_ap_si,4]);
            for didx=1:3,
               if(flag_flip_disp(didx)==1)
                  refI_recon=flipdim(refI_recon,didx);
               end
            end
         end
         
         %if(flag_denoise>0)
         %   fstr_mag=sprintf('%s/%s/%s_mag_dn.nii.gz',outdir,folder_name,train_fhdr_combimg);
         %   fstr_ph=sprintf('%s/%s/%s_ph_dn.nii.gz',outdir,folder_name,train_fhdr_combimg);
         %else
            fstr_mag=sprintf('%s/%s/%s_mag.nii.gz',outdir,folder_name,train_fhdr_combimg);
            fstr_ph=sprintf('%s/%s/%s_ph.nii.gz',outdir,folder_name,train_fhdr_combimg);
         %end
         tmp_dir=dir(fstr_mag);
         if(isempty(tmp_dir))
            if(coil_comb_method==0)
               train_volcomb=squeeze(sqrt(sum(abs(trainI_recon).^2,4)));
            else
               %train_volcomb=sum(conj(sentiv_data).*trainI_recon,4);
               train_volcomb=coilCombine_wt(trainI_recon);
            end
            out_nii=make_nii(abs(train_volcomb),header.vox(dim_rl_ap_si),[],16);
            save_nii(out_nii,fstr_mag);
            out_nii=make_nii(angle(train_volcomb),header.vox(dim_rl_ap_si),[],16);
            save_nii(out_nii,fstr_ph);
         else
            invol_mag=load_nii(fstr_mag);
            invol_ph=load_nii(fstr_ph);
            train_volcomb=invol_mag.img.*exp(1j*invol_ph.img);
         end
         
         if(flag_coilcompress==1)
            fprintf('Reference image: coil compression and whitening ...\n');
            gre=refI_recon;
            N1 = header.Npe;
            N2 = header.Nfe;
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
            %header.whtcc=whtcc;
            %header.whtcc_ref=whtcc_ref;
            
            fstr_mag=sprintf('%s/%s/%s_whtcc_mag.nii.gz',outdir,folder_name,train_fhdr_combimg);
            fstr_ph=sprintf('%s/%s/%s_whtcc_ph.nii.gz',outdir,folder_name,train_fhdr_combimg);
            tmp_dir=dir(fstr_mag);
            if(isempty(tmp_dir))
               if(coil_comb_method==0)
                  train_volcomb=squeeze(sqrt(sum(abs(whtcc_ref).^2,4)));
               else
                  %train_volcomb=sum(conj(sentiv_data).*trainI_recon,4);
                  train_volcomb=coilCombine_wt(whtcc_ref);
               end
               
               for didx=1:3,
                  if(flag_flip_disp(didx)==1)
                     train_volcomb=flipdim(train_volcomb,didx);
                  end
               end
               train_volcomb=permute(train_volcomb,[dim_rl_ap_si,4]);
            
               out_nii=make_nii(abs(train_volcomb),header.vox(dim_rl_ap_si),[],16);
               save_nii(out_nii,fstr_mag);
               out_nii=make_nii(angle(train_volcomb),header.vox(dim_rl_ap_si),[],16);
               save_nii(out_nii,fstr_ph);
            end
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
               
               train_img=reshape(permute(refI_recon,[4 1 2 3]),header.Nch,[]);
               train_img=ipermute(reshape(whmt*train_img,[header.Nch,header.Npe,header.Nfe,header.Nslc*header.num_slc_pae]),[4 1 2 3]);
               
               fstr_mag=sprintf('%s/%s/%s_wht_mag.nii.gz',outdir,folder_name,train_fhdr_combimg);
               fstr_ph=sprintf('%s/%s/%s_wht_ph.nii.gz',outdir,folder_name,train_fhdr_combimg);
               tmp_dir=dir(fstr_mag);
               if(isempty(tmp_dir))
                  if(coil_comb_method==0)
                     train_volcomb=squeeze(sqrt(sum(abs(train_img).^2,4)));
                  else
                     train_volcomb=coilCombine_wt(train_img);
                  end
                  
                  for didx=1:3,
                     if(flag_flip_disp(didx)==1)
                        train_volcomb=flipdim(train_volcomb,didx);
                     end
                  end
                  train_volcomb=permute(train_volcomb,[dim_rl_ap_si,4]);
               
                  out_nii=make_nii(abs(train_volcomb),header.vox(dim_rl_ap_si),[],16);
                  save_nii(out_nii,fstr_mag);
                  out_nii=make_nii(angle(train_volcomb),header.vox(dim_rl_ap_si),[],16);
                  save_nii(out_nii,fstr_ph);
               end
            end %end of if(flag_whiten==1)
         end %end of if(flag_coilcompress==1)

         %figure; fmri_mont(abs(train_volcomb)); colormap jet; colorbar;
         %title(sprintf('SMS training scan'));
         %fstr_train=sprintf('%s/%s/%s.tif',outdir,folder_name,acs_fhdr_fig);
         %saveas(gcf,fstr_train,'tif');
      end %end of if(flag_train_scan==1)
      
      %if(~isempty(train_spsg_volcplx))
      %   %acs_vol=squeeze(prism_data(:,:,1,:,:));
      %   train_spsg_img=squeeze(sqrt(sum(abs(train_spsg_volcplx).^2,4)));
      %   for pidx=1:num_slc_pae,
      %      figure; fmri_mont(squeeze(train_spsg_img(:,:,:,pidx))); colormap jet; colorbar;
      %      title(sprintf('SPSG training scan #%d',pidx));
      %      fstr_train=sprintf('%s/%s/%s_pae%d.tif',outdir,folder_name,acs_fhdr_fig,pidx);
      %      saveas(gcf,fstr_train,'tif');
      %   end
      %end
      
      if(flag_dorecon==1)
         if(isempty(tmp_search) || (flag_redo_recon==1))
            if(header.sms_factor>1 || header.pat > 1)
               header.grappa_width_fe=grappa_width_fe;
               header.grappa_width_pe=grappa_width_pe;
               
               %tmp_accimg=squeeze(prism_data(:,:,header.base_slcidx(1),1,1,1));
               tmp_accimg=squeeze(prism_data(:,:,header.base_slcidx(1)-min_slicidx+1,1,1,1));
               tmpk_accimg=abs(fftshift(ifft(fftshift(tmp_accimg,1),[],1),1));
               tmpk_mask=zeros(size(tmp_accimg),'single');
               tmpk_mask(find(tmpk_accimg>(max(tmpk_accimg(:))/1e5)))=1;
               tmpk_vec=sum(tmpk_mask,2);
               tmpidx=find(tmpk_vec>0);
               k_pat_stidx=tmpidx(1);
               k_pat_endidx=tmpidx(end);
               
               %sms_nz=nz/sms_factor;
               %if(mod(sms_nz,2)==1)
               %   smsslc_endidx=sms_lastslc_index+2;
               %   smsslc_stidx=smsslc_endidx-sms_nz+1;
               %else
               %   smsslc_endidx=sms_lastslc_index+1;
               %   smsslc_stidx=smsslc_endidx-sms_nz+1;
               %end
               %collapse_img=prism_data(:,:,header.base_slcidx,:,:,:);
               collapse_img=prism_data(:,:,header.base_slcidx-min_slicidx+1,:,:,:);
               prism_img_end=squeeze(sqrt(sum(abs(collapse_img(:,:,:,:,1,end)).^2,4)));
               figure; fmri_mont(prism_img_end); colormap gray; colorbar;
               fstr_img=sprintf('%s/%s/%s_acq.tif',outdir,folder_name,img_fhdr_fig);
               saveas(gcf,fstr_img,'tif');
               
               prism_data=[];
               %collapse_img=reshape(permute(prism_vol_t,[1 2 3 5 4 6]),header.Npe,header.Nfe,header.Nsep,header.Nch,header.num_slc_pae,header.Nrep);
               %header.Ntimepoint=size(collapse_img,5);
               
               if(recon_method==0) %GRAPPA
                  %train_volall = zeros(header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, 'single');
                  if(ref_rfmode==0) %single slab
                     %train_volall=reshape(permute(train_volall,[5 1 2 3 4]),header.num_slc_pae,[]);
                     %train_volall=ipermute(reshape(inv(ref_encode_mtx_full)*train_volall,[header.num_slc_pae, header.Npe, header.Nfe, header.Nslc, header.Nch]),[5 1 2 3 4]);
                     
                     %for sidx=1:header.Nslc,
                     %   tmp_mtx=train_volcplx(:,:,sidx,:,:); %[header.Npe, header.Nfe, 1, header.Nch, header.num_slc_pae]
                     %   tmp_mtx=reshape(fftshift(fft(ifftshift(tmp_mtx,5),[],5),5),[header.Npe, header.Nfe, header.Nch, header.num_slc_pae]);
                     %   train_volall(:,:,fillup_idx_array(:,sidx),:)=permute(tmp_mtx,[1 2 4 3]);
                     %end
                     
                     %collapse_img=reshape(permute(collapse_img,[5 1 2 3 4 6]),header.num_slc_pae,[]);
                     %collapse_img=ipermute(reshape(inv(single_encode_mtx_full)*collapse_img,[header.num_slc_pae, header.Npe, header.Nfe, header.Nsep, header.Nch, header.Nrep]),[5 1 2 3 4 6]);
                     acc_encode_mtx=fftshift(dftmtx(header.num_slc_pae),2);
                     tmp_shift=mod(floor(header.num_slc_pae*header.sms_factor/2),header.num_slc_pae);
                     acc_encode_mtx=circshift(acc_encode_mtx,tmp_shift,1);
                     tmp_mtx=permute(collapse_img,[5 1 2 3 4 6]);
                     sz_tmpmtx=size(tmp_mtx);
                     collapse_img=ipermute(reshape(acc_encode_mtx*tmp_mtx(:,:),sz_tmpmtx),[5 1 2 3 4 6]);
                     %collapse_img=fftshift(fft(ifftshift(collapse_img,5),[],5),5);
                  elseif(ref_rfmode==1) %multislab slab
                     %temp_vol=reshape(fftshift(fft(ifftshift(train_volall,5),[],5),5),[header.Npe,header.Nfe,header.Nsep,header.Nch,header.num_slc_pae*header.sms_factor]);
                     %train_volall=zeros([header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch],'single');
                     %for gidx=1:numel(ref_slcidx_all),
                     %   train_volall(:,:,[gidx:header.Nsep:header.Nslc*header.num_slc_pae],:)=permute(reshape(temp_vol(:,:,gidx,:,:),[header.Npe,header.Nfe,header.Nch,header.num_slc_pae*header.sms_factor]),[1 2 4 3]);
                     %end
                     
                     %for gidx=1:header.Nsep,
                     %   tmp_mtx=reshape(train_volcplx(:,:,gidx,:,:),[header.Npe, header.Nfe, header.Nch, header.num_slc_pae*header.sms_factor]); %[header.Npe, header.Nfe, 1, header.Nch, header.num_slc_pae*header.sms_factor]
                     %   tmp_mtx=fftshift(fft(ifftshift(tmp_mtx,4),[],4),4);
                     %   train_volall(:,:,fillup_idx_array(:,gidx),:)=permute(tmp_mtx,[1 2 4 3]);
                     %end
                     
                     acc_encode_mtx=fftshift(dftmtx(header.num_slc_pae),2);
                     tmp_shift=mod(floor(header.num_slc_pae*header.sms_factor/2),header.num_slc_pae);
                     acc_encode_mtx=circshift(acc_encode_mtx,tmp_shift,1);
                     tmp_mtx=permute(collapse_img,[5 1 2 3 4 6]);
                     sz_tmpmtx=size(tmp_mtx);
                     collapse_img=ipermute(reshape(acc_encode_mtx*tmp_mtx(:,:),sz_tmpmtx),[5 1 2 3 4 6]);
                  elseif(ref_rfmode==2) %3D
                     %tmp_mtx=reshape(train_volcplx(:,:,1,:,:),[header.Npe, header.Nfe, header.Nch, N3D]); %[header.Npe, header.Nfe, 1, header.Nch, header.num_slc_pae*header.sms_factor]
                     %tmp_mtx=fftshift(fft(ifftshift(tmp_mtx,4),[],4),4);
                     %train_volall(:,:,fillup_idx_array(:,1),:)=permute(tmp_mtx,[1 2 4 3]);
                     
                     collapse_img=fftshift(fft(ifftshift(collapse_img,5),[],5),5);
                  end
                  
                  if(flag_parfor==1)
                     if(flag_mixVN==1)
                        Nrep_orig=header.Nrep;
                        header.Nrep=numel([1:2:Nrep_orig]);
                        [I_recon1 header]= mb3d_grappa_wt3p(refI_recon, collapse_img(:,:,:,:,:,1:2:end), header,'collapse_img',mean(collapse_img(:,:,:,:,:,1),6),'sampdata_dtype',sampdata_dtype,'parfourier_ratio',parfourier_ratio,...
                                                    'flag_regularization',flag_slcgrappa_reg,'reg_ratio',grappa_reg_ratio,'flag_whiten',flag_whiten,...
                                                    'flag_parfour_recon',flag_slcgrappa_parfr_recon,'k_pat_stidx',k_pat_stidx,'k_pat_endidx',k_pat_endidx,...
                                                    'flag_debug',flag_debug,'flag_flip_disp',flag_flip_disp,'flag_spsg',flag_spsg,'spsg_weight',spsg_weight,...
                                                    'flag_coilcompress',flag_coilcompress,'mb3d_randph',prandn_phase);
                        I_recon1=reshape(I_recon1,[header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, 1, header.Nrep]);
                        header.Nrep=numel([2:2:Nrep_orig]);
                        [I_recon2 header]= mb3d_grappa_wt3p(refI_recon, collapse_img(:,:,:,:,:,2:2:end), header,'collapse_img',mean(collapse_img(:,:,:,:,:,2),6),'sampdata_dtype',sampdata_dtype,'parfourier_ratio',parfourier_ratio,...
                                                    'flag_regularization',flag_slcgrappa_reg,'reg_ratio',grappa_reg_ratio,'flag_whiten',flag_whiten,...
                                                    'flag_parfour_recon',flag_slcgrappa_parfr_recon,'k_pat_stidx',k_pat_stidx,'k_pat_endidx',k_pat_endidx,...
                                                    'flag_debug',flag_debug,'flag_flip_disp',flag_flip_disp,'flag_spsg',flag_spsg,'spsg_weight',spsg_weight,...
                                                    'flag_coilcompress',flag_coilcompress,'mb3d_randph',prandn_phase);
                        I_recon2=reshape(I_recon2,[header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, 1, header.Nrep]);
                        if(mod(Nrep_orig,2)==0)
                           I_recon=reshape(cat(5,I_recon1,I_recon2),[header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, Nrep_orig]);
                        else
                           I_recon=reshape(cat(5,I_recon1(:,:,:,:,:,1:end-1),I_recon2),[header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, Nrep_orig-1]);
                           I_recon=cat(5,I_recon,reshape(I_recon1(:,:,:,:,:,end),[header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, 1]));
                        end
                        header.Nrep=Nrep_orig;
                        I_recon1=[];
                        I_recon2=[];
                     else
                        [I_recon header]= mb3d_grappa_wt3p(refI_recon, collapse_img(:,:,:,:,:,:), header,'collapse_img',mean(collapse_img(:,:,:,:,:,1),6),'sampdata_dtype',sampdata_dtype,'parfourier_ratio',parfourier_ratio,...
                                                    'flag_regularization',flag_slcgrappa_reg,'reg_ratio',grappa_reg_ratio,'flag_whiten',flag_whiten,...
                                                    'flag_parfour_recon',flag_slcgrappa_parfr_recon,'k_pat_stidx',k_pat_stidx,'k_pat_endidx',k_pat_endidx,...
                                                    'flag_debug',flag_debug,'flag_flip_disp',flag_flip_disp,'flag_spsg',flag_spsg,'spsg_weight',spsg_weight,...
                                                    'flag_coilcompress',flag_coilcompress,'mb3d_randph',prandn_phase);
                     end
                  else
                     if(flag_mixVN==1)
                        Nrep_orig=header.Nrep;
                        header.Nrep=numel([1:2:Nrep_orig]);
                        [I_recon1 header]= mb3d_grappa_wt3(refI_recon, collapse_img(:,:,:,:,:,1:2:end), header,'collapse_img',mean(collapse_img(:,:,:,:,:,1),6),'sampdata_dtype',sampdata_dtype,'parfourier_ratio',parfourier_ratio,...
                                                    'flag_regularization',flag_slcgrappa_reg,'reg_ratio',grappa_reg_ratio,'flag_whiten',flag_whiten,...
                                                    'flag_parfour_recon',flag_slcgrappa_parfr_recon,'k_pat_stidx',k_pat_stidx,'k_pat_endidx',k_pat_endidx,...
                                                    'flag_debug',flag_debug,'flag_flip_disp',flag_flip_disp,'flag_spsg',flag_spsg,'spsg_weight',spsg_weight,...
                                                    'flag_coilcompress',flag_coilcompress,'mb3d_randph',prandn_phase);
                        I_recon1=reshape(I_recon1,[header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, 1, header.Nrep]);
                        header.Nrep=numel([2:2:Nrep_orig]);
                        [I_recon2 header]= mb3d_grappa_wt3(refI_recon, collapse_img(:,:,:,:,:,2:2:end), header,'collapse_img',mean(collapse_img(:,:,:,:,:,2),6),'sampdata_dtype',sampdata_dtype,'parfourier_ratio',parfourier_ratio,...
                                                    'flag_regularization',flag_slcgrappa_reg,'reg_ratio',grappa_reg_ratio,'flag_whiten',flag_whiten,...
                                                    'flag_parfour_recon',flag_slcgrappa_parfr_recon,'k_pat_stidx',k_pat_stidx,'k_pat_endidx',k_pat_endidx,...
                                                    'flag_debug',flag_debug,'flag_flip_disp',flag_flip_disp,'flag_spsg',flag_spsg,'spsg_weight',spsg_weight,...
                                                    'flag_coilcompress',flag_coilcompress,'mb3d_randph',prandn_phase);
                        I_recon2=reshape(I_recon2,[header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, 1, header.Nrep]);
                        if(mod(Nrep_orig,2)==0)
                           I_recon=reshape(cat(5,I_recon1,I_recon2),[header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, Nrep_orig]);
                        else
                           I_recon=reshape(cat(5,I_recon1(:,:,:,:,:,1:end-1),I_recon2),[header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, Nrep_orig-1]);
                           I_recon=cat(5,I_recon,reshape(I_recon1(:,:,:,:,:,end),[header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nch, 1]));
                        end
                        header.Nrep=Nrep_orig;
                        I_recon1=[];
                        I_recon2=[];
                     else
                        [I_recon header]= mb3d_grappa_wt3(refI_recon, collapse_img(:,:,:,:,:,:), header,'collapse_img',mean(collapse_img(:,:,:,:,:,1),6),'sampdata_dtype',sampdata_dtype,'parfourier_ratio',parfourier_ratio,...
                                                    'flag_regularization',flag_slcgrappa_reg,'reg_ratio',grappa_reg_ratio,'flag_whiten',flag_whiten,...
                                                    'flag_parfour_recon',flag_slcgrappa_parfr_recon,'k_pat_stidx',k_pat_stidx,'k_pat_endidx',k_pat_endidx,...
                                                    'flag_debug',flag_debug,'flag_flip_disp',flag_flip_disp,'flag_spsg',flag_spsg,'spsg_weight',spsg_weight,...
                                                    'flag_coilcompress',flag_coilcompress,'mb3d_randph',prandn_phase);
                     end
                     %[I_recon header]= mb3d_grappa_wt2(refI_recon, collapse_img(:,:,:,:,:,:), header,'collapse_img',mean(collapse_img(:,:,:,:,:,1),6),'sampdata_dtype',sampdata_dtype,'parfourier_ratio',parfourier_ratio,...
                     %                            'flag_regularization',flag_slcgrappa_reg,'reg_ratio',grappa_reg_ratio,'flag_whiten',flag_whiten,...
                     %                            'flag_parfour_recon',flag_slcgrappa_parfr_recon,'k_pat_stidx',k_pat_stidx,'k_pat_endidx',k_pat_endidx,...
                     %                            'flag_debug',flag_debug,'flag_flip_disp',flag_flip_disp,'flag_spsg',flag_spsg,'spsg_weight',spsg_weight,'mb3d_randph',prandn_phase);
                  end
                  if(coil_comb_method==0)
                     I_recon_comb=squeeze(sqrt(sum(abs(I_recon).^2,4)));
                  else
                     %I_recon_comb=squeeze(abs(sum(repmat(conj(sentiv_data),[1 1 1 1 size(I_recon,5)]).*I_recon,4)));
                     I_recon_comb=coilCombine_wt(I_recon);
                  end
               else
                  if(flag_parfor==1)
                     [I_recon_comb header]= mb3d_sense_wtp(sentiv_data, collapse_img, header,...
                                                 'sampdata_dtype',sampdata_dtype,'parfourier_ratio',parfourier_ratio,...
                                                 'flag_regularization',flag_slcgrappa_reg,'flag_whiten',flag_whiten,...
                                                 'flag_parfour_recon',flag_slcgrappa_parfr_recon,'k_pat_stidx',k_pat_stidx,'k_pat_endidx',k_pat_endidx,...
                                                 'flag_debug',flag_debug,'flag_flip_disp',flag_flip_disp,'sense_reg_ratio',inpsense_reg_ratio,...
                                                 'mb3d_randph',[]); %prandn_phase);
                  else
                     [I_recon_comb header]= mb3d_sense_wt(sentiv_data, collapse_img, header,...
                                                 'sampdata_dtype',sampdata_dtype,'parfourier_ratio',parfourier_ratio,...
                                                 'flag_regularization',flag_slcgrappa_reg,'flag_whiten',flag_whiten,...
                                                 'flag_parfour_recon',flag_slcgrappa_parfr_recon,'k_pat_stidx',k_pat_stidx,'k_pat_endidx',k_pat_endidx,...
                                                 'flag_debug',flag_debug,'flag_flip_disp',flag_flip_disp,'sense_reg_ratio',inpsense_reg_ratio,...
                                                 'mb3d_randph',[]); %prandn_phase);
                  end
                  %I_recon_comb=I_recon;
                  I_recon=[];
               end
               
               %%%% save the kernels as .mat file %%%%
               if(flag_save_kernelmat==1)
                  %fprintf('save %s/%s/%s_%s.mat ...\n',outdir,folder_name,matfile_grappa_kernel,append_str);
                  fprintf('save %s/%s/%s.mat ...\n',outdir,folder_name,matfile_grappa_kernel);
                  %eval(sprintf('save %s/%s/%s_%s.mat header -v7.3;',outdir,folder_name,matfile_grappa_kernel,append_str));
                  eval(sprintf('save %s/%s/%s.mat header -v7.3;',outdir,folder_name,matfile_grappa_kernel));
               end
               %%%% save the kernels as images %%%%
               if(flag_save_kernelfile==1)
                  %outdir_kernel=sprintf('%s/%s/Kernel_%s',outdir,folder_name,append_str);
                  outdir_kernel=sprintf('%s/%s/Kernel',outdir,folder_name);
                  fprintf('save %s ...\n',outdir_kernel);
                  eval(sprintf('!mkdir -p %s',outdir_kernel));
                  for bslc_idx=1:numel(header.base_slcidx),
                     for sidx=1:header.sms_factor,
                        for chidx = 1:header.Nch,
                           if(flag_slc_joint_est==0)
                              for pidx=1:header.num_slc_pae,
                                 I_kernel_perslc=header.I_kernel{bslc_idx}{sidx}{chidx}{pidx}; %[Nch x Npe x Nfe x blip_shift]
                                 fstr_kout=sprintf('%s/kw%dx%dmag_g%ds%dc%dp%d.nii.gz',outdir_kernel,grappa_width_fe,grappa_width_pe,bslc_idx,sidx,chidx,pidx);
                                 out_nii=make_nii(abs(I_kernel_perslc),ones(1,3),[],16);
                                 save_nii(out_nii,fstr_kout);
                                 fstr_kout=sprintf('%s/kw%dx%dph_g%ds%dc%dp%d.nii.gz',outdir_kernel,grappa_width_fe,grappa_width_pe,bslc_idx,sidx,chidx,pidx);
                                 out_nii=make_nii(angle(I_kernel_perslc),ones(1,3),[],16);
                                 save_nii(out_nii,fstr_kout);
                              end
                           else
                              I_kernel_perslc=header.I_kernel{bslc_idx}{sidx}{chidx}; %[Nch x Npe x Nfe x blip_shift]
                              fstr_kout=sprintf('%s/kw%dx%dmag_g%ds%dc%d.nii.gz',outdir_kernel,grappa_width_fe,grappa_width_pe,bslc_idx,sidx,chidx);
                              out_nii=make_nii(abs(I_kernel_perslc),ones(1,3),[],16);
                              save_nii(out_nii,fstr_kout);
                              fstr_kout=sprintf('%s/kw%dx%dph_g%ds%dc%d.nii.gz',outdir_kernel,grappa_width_fe,grappa_width_pe,bslc_idx,sidx,chidx);
                              out_nii=make_nii(angle(I_kernel_perslc),ones(1,3),[],16);
                              save_nii(out_nii,fstr_kout);
                           end %end of if(flag_slc_joint_est==0)
                        end %end of for chidx = 1:header.Nch,
                     end %end of for sidx=1:header.sms_factor,
                  end %end of for bslc_idx=1:numel(header.base_slcidx),
               end %end of if(flag_save_kernelfile==1)
               
               if(isfield(header,'K_kernel'))
                  header=rmfield(header,'K_kernel');
               end
               if(isfield(header,'I_kernel'))
                  header=rmfield(header,'I_kernel');
               end
            else
               %I_recon=permute(reshape(prism_data,[header.Npe,header.Nfe,header.Nslc,header.num_slc_pae,header.Nch,header.Nrep]),[1 2 3 5 4 6]);
               prism_data=fftshift(fft(ifftshift(prism_data,5),[],5),5);
               I_recon=reshape(permute(prism_data,[1 2 3 5 4 6]),[header.Npe,header.Nfe,header.Nslc*header.num_slc_pae,header.Nch,header.Nrep]);
            end
            
            %I_recon=single(I_recon);
            
            %fprintf('save %s/%s/%s_%s.mat ...',outdir,folder_name,matfile_out,append_str);
            fprintf('save %s/%s/%s.mat ...',outdir,folder_name,matfile_out);
            %eval(sprintf('save %s/%s/%s.mat I_recon I_recon_comb recon_method header -v7.3;',outdir,folder_name,matfile_out));
            eval(sprintf('save %s/%s/%s.mat I_recon_comb recon_method header -v7.3;',outdir,folder_name,matfile_out));
            fprintf('done!\n');
         else
            %eval(sprintf('load %s/%s/%s.mat I_recon I_recon_comb recon_method header;',outdir,folder_name,matfile_out));
            eval(sprintf('load %s/%s/%s.mat I_recon_comb recon_method header;',outdir,folder_name,matfile_out));
            %if(coil_comb_method==0)
            %   I_recon_comb=squeeze(sqrt(sum(abs(I_recon).^2,4)));
            %else
            %   %I_recon_comb=squeeze(abs(sum(repmat(conj(sentiv_data),[1 1 1 1 size(I_recon,5)]).*I_recon,4)));
            %   I_recon_comb=coilCombine_wt(I_recon);
            %end
         end %end of if(isempty(tmp_search) || (flag_redo_recon==1))
         
         disp_fov=[header.Npe*header.vox(1), header.Nfe*header.vox(2), header.Nslc*header.num_slc_pae*header.vox(3)];
         
         if(flag_denoise~=2)
            %I_recon_comb=reshape(permute(I_recon_comb,[1 2 4 3 5]),[header.Npe, header.Nfe, header.Nslc*header.num_slc_pae, header.Nrep]);
            I_recon_comb_avg=squeeze(mean(abs(I_recon_comb),4));
            
            %abscorr_map = zeros(header.Npe, header.Nfe, header.Nslc*header.num_slc_pae,'single');
            %%abscorr_map2 = zeros(header.Npe, header.Nfe, header.Nslc*header.num_slc_pae,'single');
            %%corr_cnt_array=zeros([header.Nslc*header.num_slc_pae,1],'single');
            %%corr_cnt_array2=zeros([header.Nslc*header.num_slc_pae,1],'single');
            %for sidx=1:(header.num_slc_pae*header.Nsep),
            %   seed_sidx=sidx;
            %   corr_sidx=[sidx:header.num_slc_pae*header.Nsep:header.Nslc*header.num_slc_pae];
            %   corr_sidx=setdiff(corr_sidx,seed_sidx);
            %   corr_sidx_sel=corr_sidx;
            %   seed_tmtx=reshape(permute(I_recon_comb(:,:,seed_sidx,:),[4 1 2 3]),header.Nrep,[]);
            %   seed_tmtx=seed_tmtx-repmat(mean(seed_tmtx,1),[header.Nrep 1]);
            %   tmp_corr_plane=zeros([header.Npe,header.Nfe],'single');
            %   for cidx=1:numel(corr_sidx_sel),
            %      corr_tmtx=reshape(permute(I_recon_comb(:,:,corr_sidx_sel(cidx),:),[4 1 2 3]),header.Nrep,[]);
            %      corr_tmtx=corr_tmtx-repmat(mean(corr_tmtx,1),[header.Nrep 1]);
            %      tmp_corrmtx=mean(seed_tmtx.*corr_tmtx,1)./(std(seed_tmtx,0,1).*std(corr_tmtx,0,1));
            %      tmp_corrmtx(find(~isfinite(tmp_corrmtx)))=0;
            %      tmp_corr_plane=tmp_corr_plane+reshape(abs(tmp_corrmtx),[header.Npe, header.Nfe, 1]);
            %      %abscorr_map(:,:,corr_sidx(cidx))=abscorr_map(:,:,corr_sidx(cidx))+reshape(abs(tmp_corrmtx),[header.Npe, header.Nfe, 1]);
            %      %corr_cnt_array(corr_sidx(cidx))=corr_cnt_array(corr_sidx(cidx))+1;
            %   end %end of for cidx=1:numel(corr_sidx),
            %   abscorr_map(:,:,seed_sidx)=tmp_corr_plane/numel(corr_sidx_sel);
            %   
            %   %corr_sidx2=(header.sms_groupset(gidx,sidx)-1)*header.num_slc_pae+[1:header.num_slc_pae]';
            %   %corr_sidx2=setdiff(corr_sidx2,seed_sidx);
            %   %if(~isempty(corr_sidx2))
            %   %   for cidx=1:numel(corr_sidx2),
            %   %      corr_tmtx=reshape(permute(I_recon_comb(:,:,corr_sidx2(cidx),:),[4 1 2 3]),header.Nrep,[]);
            %   %      corr_tmtx=corr_tmtx-repmat(mean(corr_tmtx,1),[header.Nrep 1]);
            %   %      tmp_corrmtx=mean(seed_tmtx.*corr_tmtx,1)./(std(seed_tmtx,0,1).*std(corr_tmtx,0,1));
            %   %      tmp_corrmtx(find(~isfinite(tmp_corrmtx)))=0;
            %   %      abscorr_map2(:,:,corr_sidx2(cidx))=abscorr_map2(:,:,corr_sidx2(cidx))+reshape(abs(tmp_corrmtx),[header.Npe, header.Nfe, 1]);
            %   %      corr_cnt_array2(corr_sidx2(cidx))=corr_cnt_array2(corr_sidx2(cidx))+1;
            %   %   end %end of for cidx=1:numel(corr_sidx2),
            %   %end %end of if(~isempty(corr_sidx2))
            %end %end of for sidx1=1:header.sms_factor*header.num_slc_pae,
            %%abscorr_map=abscorr_map./repmat(reshape(corr_cnt_array,[1 1 header.Nslc*header.num_slc_pae]),[header.Npe, header.Nfe, 1]);
            %%if(header.num_slc_pae>1)
            %%   abscorr_map2=abscorr_map2./repmat(reshape(corr_cnt_array2,[1 1 header.Nslc*header.num_slc_pae]),[header.Npe, header.Nfe, 1]);
            %%end
            for didx=1:3,
               if(flag_flip_disp(didx)==1)
                  I_recon_comb=flipdim(I_recon_comb,didx);
                  I_recon_comb_avg=flipdim(I_recon_comb_avg,didx);
               end
            end
            I_recon_comb=permute(I_recon_comb,[dim_rl_ap_si,4]);
            I_recon_comb_avg=permute(I_recon_comb_avg,dim_rl_ap_si);
            
            vol_mask=zeros(size(I_recon_comb_avg),'single');
            vol_mask(find(I_recon_comb_avg(:)>(max(I_recon_comb_avg(:))/1000)))=1;
            vol_mask=imfill(vol_mask);
            maskidx=find(vol_mask>0);
            
            snr_map=zeros(size(vol_mask),'single');
            if(~isempty(header.C0))
               n_std=sqrt(sum(diag(header.C0))*header.Nfe*round(header.Npe*parfourier_ratio)*header.num_slc_pae);
               snr_map(maskidx)=I_recon_comb_avg(maskidx)/n_std;
            end
            snr_map_nii=snr_map;
            %for didx=1:3,
            %   if(flag_flip_disp(didx)==0)
            %      snr_map_nii=flipdim(snr_map_nii,didx);
            %   end
            %end
            %snr_map_nii=permute(snr_map_nii,[dim_rl_ap_si,4]);
            
            if(size(I_recon_comb,4)>1)
               tsnr_map=zeros(size(vol_mask),'single');
               tstd_map=squeeze(std(abs(I_recon_comb),0,4));
               tsnr_map(maskidx)=I_recon_comb_avg(maskidx)./tstd_map(maskidx);
               tsnr_map_nii=tsnr_map;
               %for didx=1:3,
               %   if(flag_flip_disp(didx)==0)
               %      tsnr_map_nii=flipdim(tsnr_map_nii,didx);
               %   end
               %end
               %tsnr_map_nii=permute(tsnr_map_nii,[dim_rl_ap_si,4]);
            end
            
            %%%% save the reconstructed images %%%%
            fstr_recon_tall=sprintf('%s/%s_%s_dn%d.nii.gz',outdir,niifile_out,folder_name,flag_denoise);
            nii_tall=make_nii(abs(I_recon_comb),header.vox(dim_rl_ap_si),[],16); %data type = 'float'
            nii_tall.hdr.dime.pixdim(5)=TR;
            save_nii(nii_tall,fstr_recon_tall);
            
            fstr_recon_tall=sprintf('%s/%s_%s_dn%d_ph.nii.gz',outdir,niifile_out,folder_name,flag_denoise);
            nii_tall=make_nii(angle(I_recon_comb)*180/pi,header.vox(dim_rl_ap_si),[],16); %data type = 'float'
            nii_tall.hdr.dime.pixdim(5)=TR;
            save_nii(nii_tall,fstr_recon_tall);
            
            %fstr_recon_tavg=sprintf('%s/%s_%s%s_tavg.nii.gz',outdir,niifile_out,folder_name,append_str);
            fstr_recon_tavg=sprintf('%s/%s_%s_tavg_dn%d.nii.gz',outdir,niifile_out,folder_name,flag_denoise);
            nii_tavg=make_nii(I_recon_comb_avg,header.vox(dim_rl_ap_si),[],16); %data type = 'float'
            nii_tavg.hdr.dime.pixdim(5)=TR;
            save_nii(nii_tavg,fstr_recon_tavg);
            
            %fstr_snr=sprintf('%s/%s_%s%s_snr.nii.gz',outdir,niifile_out,folder_name,append_str);
            fstr_snr=sprintf('%s/%s_%s_snr_dn%d.nii.gz',outdir,niifile_out,folder_name,flag_denoise);
            nii_tall=make_nii(snr_map_nii,header.vox(dim_rl_ap_si),[],16); %data type = 'float'
            nii_tall.hdr.dime.pixdim(5)=TR;
            save_nii(nii_tall,fstr_snr);
            
            %fstr_txt_snr=sprintf('%s/%s_%s%s_snr.txt',outdir,txtfile_out,folder_name,append_str);
            fstr_txt_snr=sprintf('%s/%s_%s_snr_dn%d.txt',outdir,txtfile_out,folder_name,flag_denoise);
            fid=fopen(fstr_txt_snr,'w');
            fprintf(fid,'Max, Min, mean, 5 percent, 95 percent\n');
            fprintf(fid,'%f\n',max(snr_map_nii(maskidx)));
            fprintf(fid,'%f\n',min(snr_map_nii(maskidx)));
            fprintf(fid,'%f\n',mean(snr_map_nii(maskidx)));
            fprintf(fid,'%f\n',prctile(snr_map_nii(maskidx),5));
            fprintf(fid,'%f\n',prctile(snr_map_nii(maskidx),95));
            fclose(fid);
            
            if(size(I_recon_comb,4)>1)
               %fstr_tsnr=sprintf('%s/%s_%s%s_tsnr.nii.gz',outdir,niifile_out,folder_name,append_str);
               fstr_tsnr=sprintf('%s/%s_%s_tsnr_dn%d.nii.gz',outdir,niifile_out,folder_name,flag_denoise);
               nii_tall=make_nii(tsnr_map_nii,header.vox(dim_rl_ap_si),[],16); %data type = 'float'
               nii_tall.hdr.dime.pixdim(5)=TR;
               save_nii(nii_tall,fstr_tsnr);
               
               %fstr_txt_tsnr=sprintf('%s/%s_%s%s_tsnr.txt',outdir,txtfile_out,folder_name,append_str);
               fstr_txt_tsnr=sprintf('%s/%s_%s_tsnr_dn%d.txt',outdir,txtfile_out,folder_name,flag_denoise);
               fid=fopen(fstr_txt_tsnr,'w');
               fprintf(fid,'Max, Min, mean, 5 percent, 95 percent\n');
               fprintf(fid,'%f\n',max(tsnr_map_nii(maskidx)));
               fprintf(fid,'%f\n',min(tsnr_map_nii(maskidx)));
               fprintf(fid,'%f\n',mean(tsnr_map_nii(maskidx)));
               fprintf(fid,'%f\n',prctile(tsnr_map_nii(maskidx),5));
               fprintf(fid,'%f\n',prctile(tsnr_map_nii(maskidx),95));
               fclose(fid);
            end
         else
            fstr_recon_mag=sprintf('%s/%s_%s_dn%d%s%3.1f',outdir,niifile_out,folder_name,0,spsg_str,spsg_weight);
            fstr_recon_mag(strfind(fstr_recon_mag,'.'))='p';
            fstr_recon_mag(strfind(fstr_recon_mag,' '))=[];
            fstr_recon_mag=sprintf('%s.nii.gz',fstr_recon_mag);
            fstr_recon_ph=sprintf('%s/%s_%s_dn%d%s%3.1f_ph',outdir,niifile_out,folder_name,0,spsg_str,spsg_weight);
            fstr_recon_ph(strfind(fstr_recon_ph,'.'))='p';
            fstr_recon_ph(strfind(fstr_recon_ph,' '))=[];
            fstr_recon_ph=sprintf('%s.nii.gz',fstr_recon_ph);
            tmp_dir=dir(fstr_recon_mag);
            if(isempty(tmp_dir))
               for didx=1:3,
                  if(flag_flip_disp(didx)==1)
                     I_recon_comb=flipdim(I_recon_comb,didx);
                  end
               end
               I_recon_comb=permute(I_recon_comb,[dim_rl_ap_si,4]);
               
               %%%% save the reconstructed images %%%%
               nii_tall=make_nii(abs(I_recon_comb),header.vox(dim_rl_ap_si),[],16); %data type = 'float'
               nii_tall.hdr.dime.pixdim(5)=TR;
               save_nii(nii_tall,fstr_recon_mag);
               
               nii_tall=make_nii(angle(I_recon_comb)*180/pi,header.vox(dim_rl_ap_si),[],16); %data type = 'float'
               nii_tall.hdr.dime.pixdim(5)=TR;
               save_nii(nii_tall,fstr_recon_ph);
            end
            
            fsr_outhdr=sprintf('%s_%s_dnraw',niifile_out,folder_name);
            ARG.DIROUT=sprintf('%s/',outdir);
            ARG.temporal_phase=1;
            ARG.phase_filter_width=10;
            ARG.make_complex_nii=1;
            %ARG.kernel_size_PCA=[4 4 4];
            NIFTI_NORDIC_wt(fstr_recon_mag,fstr_recon_ph,fsr_outhdr,ARG);
            fstr_mag=sprintf('%s/%smagn.nii',outdir,fsr_outhdr);
            invol_mag=load_nii(fstr_mag);
            out_nii=make_nii(abs(invol_mag.img),header.vox(dim_rl_ap_si),[],16); %data type = 'float'
            out_nii.hdr.dime.pixdim(5)=TR;
            fstr_recon_mag=sprintf('%s/%s_%s_dn%d%s%3.1f',outdir,niifile_out,folder_name,flag_denoise,spsg_str,spsg_weight);
            fstr_recon_mag(strfind(fstr_recon_mag,'.'))='p';
            fstr_recon_mag(strfind(fstr_recon_mag,' '))=[];
            fstr_recon_mag=sprintf('%s.nii.gz',fstr_recon_mag);
            save_nii(out_nii,fstr_recon_mag);
            str=sprintf('!rm -f %s/%smagn.nii',outdir,fsr_outhdr);
            eval(str);
            
            fstr_ph=sprintf('%s/%sphase.nii',outdir,fsr_outhdr);
            invol_ph=load_nii(fstr_ph);
            out_nii=make_nii(invol_ph.img*180/pi,header.vox(dim_rl_ap_si),[],16); %data type = 'float'
            out_nii.hdr.dime.pixdim(5)=TR;
            fstr_recon_ph=sprintf('%s/%s_%s_dn%d%s%3.1f_ph',outdir,niifile_out,folder_name,flag_denoise,spsg_str,spsg_weight);
            fstr_recon_ph(strfind(fstr_recon_ph,'.'))='p';
            fstr_recon_ph(strfind(fstr_recon_ph,' '))=[];
            fstr_recon_ph=sprintf('%s.nii.gz',fstr_recon_ph);
            fstr_recon_mag=sprintf('%s/%s_%s_dn%d%s%3.1f',outdir,niifile_out,folder_name,flag_denoise,spsg_str,spsg_weight);
            fstr_recon_mag(strfind(fstr_recon_mag,'.'))='p';
            fstr_recon_mag(strfind(fstr_recon_mag,' '))=[];
            fstr_recon_mag=sprintf('%s.nii.gz',fstr_recon_mag);
            save_nii(out_nii,fstr_recon_ph);
            str=sprintf('!rm -f %s/%sphase.nii',outdir,fsr_outhdr);
            eval(str);
            
            fstr_recon_tavg=sprintf('%s/%s_%s_tavg_dn%d%s%3.1f',outdir,niifile_out,folder_name,flag_denoise,spsg_str,spsg_weight);
            fstr_recon_tavg(strfind(fstr_recon_tavg,'.'))='p';
            fstr_recon_tavg(strfind(fstr_recon_tavg,' '))=[];
            fstr_recon_tavg=sprintf('%s.nii.gz',fstr_recon_tavg);
            str=sprintf('!fslmaths %s -Tmean %s',fstr_recon_mag,fstr_recon_tavg);
            eval(str);
            
            if(size(invol_mag.img,4)>1)
               %fstr_tsnr=sprintf('%s/%s_%s%s_tsnr.nii.gz',outdir,niifile_out,folder_name,append_str);
               fstr_tsnr=sprintf('%s/%s_%s_tsnr_dn%d%s%3.1f',outdir,niifile_out,folder_name,flag_denoise,spsg_str,spsg_weight);
               fstr_tsnr(strfind(fstr_tsnr,'.'))='p';
               fstr_tsnr(strfind(fstr_tsnr,' '))=[];
               fstr_tsnr=sprintf('%s.nii.gz',fstr_tsnr);
               std_img=std(invol_mag.img,0,4);
               mean_img=mean(invol_mag.img,4);
               vol_mask=zeros(size(mean_img),'single');
               vol_mask(find(mean_img(:)>(max(mean_img(:))/1000)))=1;
               vol_mask=imfill(vol_mask);
               maskidx=find(vol_mask>0);
               tsnr_map=zeros(size(vol_mask),'single');
               tsnr_map(maskidx)=mean_img(maskidx)./std_img(maskidx);
               nii_tall=make_nii(tsnr_map,header.vox(dim_rl_ap_si),[],16); %data type = 'float'
               nii_tall.hdr.dime.pixdim(5)=TR;
               save_nii(nii_tall,fstr_tsnr);
               
               %fstr_txt_tsnr=sprintf('%s/%s_%s%s_tsnr.txt',outdir,txtfile_out,folder_name,append_str);
               fstr_txt_tsnr=sprintf('%s/%s_%s_tsnr_dn%d%s%3.1f',outdir,txtfile_out,folder_name,flag_denoise,spsg_str,spsg_weight);
               fstr_txt_tsnr(strfind(fstr_txt_tsnr,'.'))='p';
               fstr_txt_tsnr(strfind(fstr_txt_tsnr,' '))=[];
               fstr_txt_tsnr=sprintf('%s.txt',fstr_txt_tsnr);
               fid=fopen(fstr_txt_tsnr,'w');
               fprintf(fid,'Max, Min, mean, 5 percent, 95 percent\n');
               fprintf(fid,'%f\n',max(tsnr_map(maskidx)));
               fprintf(fid,'%f\n',min(tsnr_map(maskidx)));
               fprintf(fid,'%f\n',mean(tsnr_map(maskidx)));
               fprintf(fid,'%f\n',prctile(tsnr_map(maskidx),5));
               fprintf(fid,'%f\n',prctile(tsnr_map(maskidx),95));
               fclose(fid);
            end
         end
      end %end of if(flag_dorecon==1)
   end %end of for j=1:length(filesin{i}),
end %end of for i=1:length(filesin),

