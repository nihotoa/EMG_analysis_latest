function [data_str, day_num, muscle_num, timing_num] =  makeStructForXcorr(Pdata_base_dir, monkeyname, day_list, whole_task_EMG_str, each_timing_EMG_str)
data_str = struct();
day_num = length(day_list);
for day_id = 1:day_num
    % 該当する実験日の各種ファイル名を取得 & structに代入する時の実験日固有の名前を作成
    ref_day_name = num2str(day_list(day_id));
    ref_Pdata_name = [monkeyname ref_day_name '_Pdata.mat'];
    unique_day_name = [monkeyname ref_day_name];
    
    % 筋電の名前と、タイミングの切り出し範囲のデータを取得して構造体に入れる(初日データからのみ抽出すればok)
    if  day_id == 1
        load(fullfile(Pdata_base_dir, ref_Pdata_name), 'EMGs');
        muscle_num = length(EMGs);
        data_str.EMGs = EMGs;
    end
    
    % 該当する実験日の各タイミング付近の筋電データを取得して構造体に入れる(名前キモいので構造体に入れる時は名前変更して代入)
    timing_num = length(each_timing_EMG_str);
    for timing_id = 1:timing_num
        unique_timing_name = ['timing' num2str(timing_id)];

        if day_id == 1
            % 切り出し範囲の情報を構造体に代入
            data_str.task_range.cutout_range.(unique_timing_name) = each_timing_EMG_str{timing_id}.cutoutRange;
            data_str.task_range.plot_range.(unique_timing_name) = each_timing_EMG_str{timing_id}.plotRange;
        end

        % 各筋肉の筋電の情報を構造体に代入
        ref_EMG_data = each_timing_EMG_str{timing_id}.plotData_sel{day_id};
        for muscle_id = 1: muscle_num
            data_str.EMG_data.(unique_day_name).(unique_timing_name).(EMGs{muscle_id}) = ref_EMG_data(muscle_id, :);
        end
    end

    % タスク全体の筋電でも同じ処理(上とほぼ同じで冗長だから関数化する)
    data_str.task_range.cutout_range.whole_task = whole_task_EMG_str.cutoutRange;
    data_str.task_range.plot_range.whole_task = [0 100];
    ref_EMG_data = cell2mat(whole_task_EMG_str.plotData_sel{day_id});
    for muscle_id = 1:muscle_num
        data_str.EMG_data.(unique_day_name).whole_task.(EMGs{muscle_id}) = ref_EMG_data(muscle_id, :);
    end
end
end