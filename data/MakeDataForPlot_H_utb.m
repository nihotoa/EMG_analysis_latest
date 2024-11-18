%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code & select data by following guidance (which is displayed in command window after Running this code)

[role of this code]
・cut out the temporal pattern of muscle synergy for each trial and put it into array
・save data which is related in displaying temporal synergy

[Saved data location]
location: 
    EMG_analysis/data/Yachimun/new_nmf_result/synData/

[procedure]
pre: dispNMF_W.m
post: plotTarget.m 

[caution!!]
In order to use the function 'resample', 'signal processing toolbox' must be installed

[Improvement points(Japanaese)]
・Kを用いてtestデータを連結させるところがkf=4の前提で書かれているので改善する
・タイミングの数が4つである前提で書かれているので、改善する(plotEasyData_utbとかなり似ている)
・timを求める際のダウンサンプリング後のサンプリング周波数が100Hzの前提で書かれているので改善する
・alignDataと,alignDataEXはplotEasyData_utbと全く同じものを使っているので、ローカル関数ではなくて、独立した関数として作って、
それを読み込んで使うように変更する
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
term_select_type = 'manual'; %'auto' / 'manual'
term_type = 'pre'; %(if term_select_type == 'auto') pre / post / all 
monkeyname = 'Hu';
synergy_num = 4; % number of synergy you want to analyze
save_data = 1; % whether you want to save data (basically, set 1)
nmf_fold_name = 'new_nmf_result'; % name of nmf folder

range_struct = struct();
% change the range of trimming for each monkey
switch monkeyname
    case 'Ni'
        range_struct.trig1_per = [50 50];
        range_struct.trig2_per = [50 50];
        range_struct.trig3_per = [50 50];
        range_struct.trig4_per = [50 50];
        range_struct.task_per = [25,105];
    case 'Hu'
        range_struct.trig1_per = [50 50];
        range_struct.trig2_per = [50 50];
        range_struct.trig3_per = [50 50];
        range_struct.trig4_per = [50 50];
        range_struct.trig5_per = [50 50];
        range_struct.trig6_per = [50 50];
        range_struct.task_per = [25,105];
    otherwise
        range_struct.trig1_per = [50 50];
        range_struct.trig2_per = [50 50];
        range_struct.trig3_per = [50 50];
        range_struct.trig4_per = [50 50];
        range_struct.task_per = [25,105];
end

%% code section
realname = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, nmf_fold_name);
standard_data_name_list = getGroupedDates(base_dir, monkeyname, term_select_type, term_type);
if isempty(standard_data_name_list)
    disp('user pressed "cancel" button');
    return;
end

date_num = length(standard_data_name_list);
prefix_date_name_list = strrep(standard_data_name_list, '_standard','');
date_name_list = strrep(prefix_date_name_list, monkeyname, '');

% Find the number of EMGs used in the synergy analysis
load(fullfile(base_dir, standard_data_name_list{1}, [standard_data_name_list{1} '.mat']), 'TargetName'); 
EMG_num = length(TargetName);

% Create an empty array to store the synergy time pattern (synergy H)
all_H = cell(1, date_num);

% load order information (as order_data_struct)
order_fold_path = fullfile(base_dir, 'order_tim_list', [prefix_date_name_list{1} 'to' date_name_list{end} '_' num2str(length(prefix_date_name_list))]);
order_file_name = [prefix_date_name_list{1} 'to' date_name_list{end} '_' num2str(length(prefix_date_name_list)) '_' num2str(synergy_num) '.mat'];
if not(exist(fullfile(order_fold_path, order_file_name), 'file'))
    error(['There was no file in the "order_tim_list" directory corresponding to the synergy number and date combination you selected.' ...
        '      Please run "dispNMF_W.m" with the same date combination & synergy_num first to create "order_tim_list" file']);
end
order_data_struct = load(fullfile(order_fold_path, order_file_name));

%% Linking temporal pattern data(synergy H) & arrange order of Synergies between each date.
cutout_flag_list = false(1, date_num);
for date_id =1:date_num %session loop
    % Get the path of the data to be accessed.
    synergy_data_fold_path = fullfile(base_dir, [prefix_date_name_list{date_id} '_standard']);
    synergy_data_file_path = ['t_' standard_data_name_list{date_id} '.mat'];

    H_synergy_data_fold_path = fullfile(synergy_data_fold_path, [prefix_date_name_list{date_id} '_syn_result_' sprintf('%02d',EMG_num)], [prefix_date_name_list{date_id} '_H']);
    H_synergy_data_file_name = [prefix_date_name_list{date_id} '_aveH3_' sprintf('%d',synergy_num) '.mat'];

    % Load data based on PATH.
    % order_in_section_struct is the order data required for the linkage of 'test' data to each other.
    try 
        order_in_section_struct = load(fullfile(H_synergy_data_fold_path, H_synergy_data_file_name), 'k_arr'); 
    catch
        disp([standard_data_name_list{date_id} 'does not have trimmed H_synergy data']);
        continue;
    end

    % Get 'test' data on the number of synergies of the target & Concatenate all 'test' data for each synergy.
    synergy_data = load(fullfile(synergy_data_fold_path, synergy_data_file_path));
    load(fullfile(H_synergy_data_fold_path, H_synergy_data_file_name), 'Wt_coefficient_matrix');
    H_data = synergy_data.test.H; % Data on synergy_H at each synergy number.
    sorted_W_coefficient_matrix = Wt_coefficient_matrix;
    [~, section_num] = size(order_in_section_struct.k_arr);
    use_H_data = H_data(synergy_num, :);
    alt_H = cell(1, section_num);

    for section_id = 1:section_num
        sort_order = order_in_section_struct.k_arr(:, section_id);
        for jj = 1:length(sort_order)
            sort_id = sort_order(jj);
            alt_H{section_id}(jj, :) = use_H_data{section_id}(sort_id, :) * sorted_W_coefficient_matrix{section_id}(jj);
        end
    % alt_H{section_id} = use_H_data{section_id}(sort_order, :);
    end
    alt_H = cell2mat(alt_H);

    % Store the concatenated day-by-day synergies in the order of the first day's synergies.
    % Extracting the order of synergies of date(date_id) from 'k_arr'
    day_index =  find(order_data_struct.days==str2double(date_name_list{date_id}));
    synergy_order = order_data_struct.k_arr(:, day_index); 
    all_H{date_id} = alt_H(synergy_order, :);
    
    % change the flag that determines whether the data of reference day has been cut out or not
    if isfield(synergy_data, 'event_timings_after_trimmed')
        cutout_flag_list(date_id) = true;
    end
end


%%  Cut out synergy H around each task timing.

% Creating arrays from which to store data.
ResAVE.tData1_AVE = cell(1,synergy_num);
ResAVE.tData2_AVE = cell(1,synergy_num);
ResAVE.tData3_AVE = cell(1,synergy_num);
ResAVE.tData4_AVE = cell(1,synergy_num);
ResAVE.tDataTask_AVE = cell(1,synergy_num);

% Get the path of the previous level.
[monkey_dir_path, ~, ~] = fileparts(base_dir);

% Cutting out synergy H data for each date.
for date_id = 1:date_num 
    ref_flag = cutout_flag_list(date_id);
    if ref_flag
        standard_file_name = standard_data_name_list{date_id};
        synergy_data_fold_path = fullfile(base_dir, standard_file_name);
        synergy_data_file_name = [standard_file_name '.mat'];
        load(fullfile(synergy_data_fold_path, synergy_data_file_name), 'event_timings_after_trimmed')
        timing_data_for_filtered_EMG = event_timings_after_trimmed;
    else
         % get the path of EasyData(which contains each timing data)
        easy_data_fold_path = fullfile(monkey_dir_path, 'easyData', standard_data_name_list{date_id});
        easy_data_file_name = [prefix_date_name_list{date_id} '_EasyData.mat'];
    
        timing_data_struct = load(fullfile(easy_data_fold_path, easy_data_file_name)); % load the timing data of each trial
        timing_data_for_filtered_EMG = floor(timing_data_struct.Tp ./ (timing_data_struct.SampleRate/100)); % down sample (to 100Hz)
    end

   [trial_num, ~] = size(timing_data_for_filtered_EMG);
   pre_per = 50; % How long do you want to see the signals before 'lever1 on' starts.
   post_per = 50; % How long do you want to see the signals after 'lever2 off' starts.
   
   % Cut out synergyH for each trial
   [alignedData, alignedDataAVE, AllT, Timing_ave, ~, ~, TIME_W] = alignData(all_H{date_id}', timing_data_for_filtered_EMG, trial_num, pre_per, post_per, synergy_num, monkeyname);
   taskRange = [-1*pre_per, 100+post_per];

    % Cut out synergyH for each trial, around each timing.
   [Res, timing_num] = alignDataEx(alignedData, timing_data_for_filtered_EMG, range_struct, pre_per, TIME_W, synergy_num, monkeyname);

   % Store the information about the cut out range around each timing in structure range_struct
  range_struct.LdTask = length(Res.tDataTask_AVE{1});
  range_struct.RangeTask = range_struct.task_per;
  ResAVE.tDataTask_AVE = Res.tDataTask_AVE;
  for timing_id = 1:timing_num
      range_struct.(['Ld' num2str(timing_id)]) = length(Res.(['tData' num2str(timing_id) '_AVE']){1});
      range_struct.(['Range' num2str(timing_id)]) = range_struct.(['trig' num2str(timing_id) '_per']);
      ResAVE.(['tData' num2str(timing_id) '_AVE']) = Res.(['tData' num2str(timing_id) '_AVE']);
  end
   
   % save data
   if save_data == 1
       xpdate = date_name_list(date_id);

       % Specify the path of the directory to save
       save_data_fold_path = fullfile(base_dir, 'synData');
       save_data_file_name = [monkeyname '_Syn' sprintf('%d',synergy_num) '_' date_name_list{date_id} '_Pdata.mat'];
       
       % save data
       makefold(save_data_fold_path);
       D = range_struct; % to be consistent with legacy codes
       save(fullfile(save_data_fold_path, save_data_file_name), 'monkeyname','xpdate','D',...
                                                         'alignedDataAVE','ResAVE',...
                                                         'AllT','TIME_W','Timing_ave','taskRange');
       disp(['Pdata is saved as: ' fullfile(save_data_fold_path, save_data_file_name)]);
   end
end


