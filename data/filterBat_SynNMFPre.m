%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code & select data by following guidance (which is displayed in command window after Running this code)

[role of this code]
Preform preprocessing on EMG data and save these filtered data (as .mat file).
(sequence of filter)
1. high-pass-filter
2. rectify
3. low-pass-filter
4. down sample

[Saved data location]
location: Yachimun/new_nmf_result/'~_standard' (ex.) F170516_standard
file name: the file name changes depending on the preprocessing content.
(ex.) BRD-hp50Hz-rect-lp20Hz-ds100Hz.mat

[procedure]
pre:SAVE4NMF.m
post:makeEMGNMFbtc_Oya.m

[Improvement points(Japanaese)]

%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
monkeyname = 'Hu'; % prefix of the recorded file
nmf_fold_name = 'new_nmf_result'; % name of nmf folder

% setting of filter 
band_pass_on = 0;
high_pass_on = 1;
rect_on = 1;
low_pass_on = 1;
resample_on = 1;

% setting of cut off frequency
band_pass_freq = [50 200]; % cut off frequency[Hz] of band pass filter
high_pass_freq = 50; % cut off frequency[Hz] of high pass filter
low_pass_freq = 20; % cut off frequency[Hz] of high pass filter
resample_freq = 100; % sampling Rate[Hz] after downsampling

%% code section
[realname] = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, nmf_fold_name);

% get the name of the floder that exists directly under 'Parent dir'
InputDirs   = dirdir(base_dir);
disp('【Plese select all day fold (which contains the data you want to filter】)')
InputDirs   = uiselect(InputDirs,1,'Please select folders which contains the data you want to analyze');

if(isempty(InputDirs))
    disp('User pressed cancel.')
    return;
end
InputDir    = InputDirs{1};

Tarfiles    = sortxls(dirmat(fullfile(base_dir,InputDir)));
disp('【Please select all muscle data(<muscle name>(uV).mat) which you want to filter】')
Tarfiles    = uiselect(Tarfiles,1,'Please select all muscle data');
if(isempty(Tarfiles))
    disp('User pressed cancel.')
    return;
end

for jj=1:length(InputDirs)  % each day
    try
        InputDir    = InputDirs{jj};
         for kk =1:length(Tarfiles)
             Tar = loaddata(fullfile(base_dir,InputDir,Tarfiles{kk}));
             OutputDir   = fullfile(base_dir,InputDir);
            
             if band_pass_on
                 Tar = makeContinuousChannel([Tar.Name,'-bandpass-' num2str(band_pass_freq(1)) 'Hz_to_' num2str(band_pass_freq(2)) 'Hz'], 'band-pass', Tar, band_pass_freq);
             end

             if high_pass_on
                 %highpass filtering
                 Tar = makeContinuousChannel([Tar.Name, '-hp' num2str(high_pass_freq) 'Hz'], 'butter', Tar, 'high', 6, high_pass_freq, 'both');
             end

             if rect_on
                 %full wave rectification
                 Tar = makeContinuousChannel([Tar.Name,'-rect'], 'rectify', Tar);
             end

             if low_pass_on
                 %lowpass filtering
                 Tar = makeContinuousChannel([Tar.Name,'-lp' num2str(low_pass_freq) 'Hz'], 'butter', Tar, 'low', 6, low_pass_freq, 'both');
             end
            
             if resample_on
                 %down sampling at 100Hz
                 Tar = makeContinuousChannel([Tar.Name,'-ds' num2str(resample_freq) 'Hz'], 'resample', Tar, resample_freq, 0);
             end
             
             % save data
             save(fullfile(OutputDir,[Tar.Name,'.mat']),'-struct','Tar');
             disp(fullfile(OutputDir,Tar.Name));     
         end
     catch
      disp(['****** Error occured in ',InputDirs{jj}]) ; 
    end
end
