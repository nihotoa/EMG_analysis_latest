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
pre:prepareRawEMGDataForNMF.m
post:synergyExtractionByNMF.m

[Improvement points(Japanaese)]
+ 中の処理がどうやって動いているのかわからないから確認する(武井さんが作ったコード?)
+ 設定したextract_EMG_typeの生データがなかった時のエラーハンドリングの追加(prepareRawEMGDataForNMFを実行しろ!っていう文章)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
monkey_prefix = 'Hu'; % prefix of the recorded file
extract_EMG_type = 'only_trial'; % 'only_trial', 'full'

% setting of filter 
band_pass_on = false;
high_pass_on = true;
rect_on = true;
low_pass_on = true;
resample_on = true;

% setting of cut off frequency
band_pass_freq = [50 200]; % cut off frequency[Hz] of band pass filter
high_pass_freq = 50; % cut off frequency[Hz] of high pass filter
low_pass_freq = 20; % cut off frequency[Hz] of high pass filter
resample_freq = 100; % sampling Rate[Hz] after downsampling

%% code section
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir_path = fileparts(pwd);
base_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'Synergy', 'row_EMG_data', extract_EMG_type);

% get the name of the floder that exists directly under 'Parent dir'
InputDirs   = dirdir(base_dir_path);
disp('【Plese select all day fold (which contains the data you want to filter】)')
InputDirs   = uiselect(InputDirs,1,'Please select folders which contains the data you want to analyze');

if(isempty(InputDirs))
    disp('User pressed cancel.')
    return;
end
InputDir = InputDirs{1};

muscle_file_list = dirPlus(fullfile(base_dir_path, InputDir));
target_files = {muscle_file_list.name};
disp('【Please select all muscle data(<muscle name>(uV).mat) which you want to filter】')
target_files = uiselect(target_files,1,'Please select all muscle data');
if(isempty(target_files))
    disp('User pressed cancel.')
    return;
end

trimmed_flag = false;
if contains(target_files(1), '_trimmed')
    trimmed_flag = true;
end

common_save_dir = strrep(base_dir_path, 'row_EMG_data', 'filtered_EMG_data');
for day_id=1:length(InputDirs)  
    InputDir = InputDirs{day_id};
     for muscle_id =1:length(target_files)
         target_data = loaddata(fullfile(base_dir_path,InputDir,target_files{muscle_id}));
         if band_pass_on
             target_data = makeContinuousChannel([target_data.Name,'-bandpass-' num2str(band_pass_freq(1)) 'Hz_to_' num2str(band_pass_freq(2)) 'Hz'], 'band-pass', target_data, band_pass_freq);
         end

         if high_pass_on
             %highpass filtering
             target_data = makeContinuousChannel([target_data.Name, '-hp' num2str(high_pass_freq) 'Hz'], 'butter', target_data, 'high', 6, high_pass_freq, 'both');
         end

         if rect_on
             %full wave rectification
             target_data = makeContinuousChannel([target_data.Name,'-rect'], 'rectify', target_data);
         end

         if low_pass_on
             %lowpass filtering
             target_data = makeContinuousChannel([target_data.Name,'-lp' num2str(low_pass_freq) 'Hz'], 'butter', target_data, 'low', 6, low_pass_freq, 'both');
         end
        
         if resample_on
             %down sampling at 100Hz
             if trimmed_flag
                 target_data.event_timings_after_trimmed = round(target_data.event_timings_after_trimmed * (resample_freq / target_data.SampleRate));
             end
             target_data = makeContinuousChannel([target_data.Name,'-ds' num2str(resample_freq) 'Hz'], 'resample', target_data, resample_freq, 0);
         end
            
         if contains(target_files(1), '_trimmed')
             target_data.Name = [target_data.Name, '-trimmed'];
         end

         % save data
         save_dir_path = fullfile(common_save_dir, InputDir);
         makefold(save_dir_path);
         save(fullfile(save_dir_path, [target_data.Name,'.mat']),'-struct','target_data');
         disp(fullfile(save_dir_path, target_data.Name));     
     end
end
