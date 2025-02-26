function [data_str, day_num, element_num, timing_num, timing_name_list] =  makeStructForXcorr(Pdata_dir, each_timing_pattern_dir, monkeyname, day_list, plot_data_type)
data_str = struct();
day_num = length(day_list);
for day_id = 1:day_num
    % 該当する実験日の各種ファイル名を取得 & structに代入する時の実験日固有の名前を作成
    ref_day_name = num2str(day_list(day_id));
    ref_Pdata_name = [monkeyname ref_day_name '_Pdata.mat'];
    unique_day_name = [monkeyname ref_day_name];
    load(fullfile(each_timing_pattern_dir, [unique_day_name '_each_timing_pattern.mat']), 'each_timing_EMG_cell', 'whole_task_EMG_struct', 'timing_name_list');
    
    % 筋電の名前と、タイミングの切り出し範囲のデータを取得して構造体に入れる(初日データからのみ抽出すればok)
    if  day_id == 1
        if strcmp(plot_data_type, 'EMG')
            load(fullfile(Pdata_dir, ref_Pdata_name), 'EMGs');
            elements = EMGs;
        else
            synergy_num = size(each_timing_EMG_cell{1}.time_normalized_EMG{1}, 1);
            elements = generateSequentialNames('synergy', synergy_num);
        end
        element_num = length(elements);
        data_str.elements = elements;
    end
    
    % 該当する実験日の各タイミング付近の筋電データを取得して構造体に入れる(名前キモいので構造体に入れる時は名前変更して代入)
    timing_num = length(timing_name_list);
    for timing_id = 1:timing_num
        ref_timing_data_struct = each_timing_EMG_cell{timing_id};
        unique_timing_name = ['timing' num2str(timing_id)];
        
        if day_id == 1
            % 切り出し範囲の情報を構造体に代入
            data_str.task_range.cutout_range.(unique_timing_name) = ref_timing_data_struct.cutout_range;
            data_str.task_range.plot_range.(unique_timing_name) = ref_timing_data_struct.plot_range;
        end

        % 各筋肉の筋電の情報を構造体に代入
        ref_activity_data = ref_timing_data_struct.time_normalized_EMG;
        for element_id = 1: element_num
            data_str.activity_data.(unique_day_name).(unique_timing_name).(elements{element_id}) = ref_activity_data(element_id, :);
        end
    end

    % タスク全体の筋電でも同じ処理(上とほぼ同じで冗長だから関数化する)
    data_str.task_range.cutout_range.whole_task = whole_task_EMG_struct.cutout_range;
    data_str.task_range.plot_range.whole_task = [0 100];
    ref_activity_data = whole_task_EMG_struct.time_normalized_EMG;
    for element_id = 1:element_num
        data_str.activity_data.(unique_day_name).whole_task.(elements{element_id}) = ref_activity_data(element_id, :);
    end
end
end