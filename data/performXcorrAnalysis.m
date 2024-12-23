%{
ネスト深すぎる．しょうがない気もするけど
%}
clear;
%% set param
monkeyname = 'F';
must_plot_EMGs = {'EDCprox', 'FDSprox'};
figure_row_num = 4; % 1ページに含める筋電の数(colはタイミングの数に決まる)
TT_surgery_day = 20170530;

%% code section
realname = get_real_name(monkeyname);
easyData_dir = fullfile(pwd, realname, 'easyData');

% 実験日データをpreとpostに分けてlistにまとめる
pre_standard_data_list = getGroupedDates(easyData_dir, monkeyname, 'auto', 'pre');
post_standard_data_list = getGroupedDates(easyData_dir, monkeyname, 'auto', 'post');
all_standard_data_list = getGroupedDates(easyData_dir, monkeyname, 'auto', 'all');

pre_day_list = get_days(pre_standard_data_list);
post_day_list = get_days(post_standard_data_list);
all_day_list = get_days(all_standard_data_list);

% 使用する筋電データのロード
Pdata_base_dir = fullfile(easyData_dir, 'P-DATA');
all_day_num = length(all_day_list);
EMG_data_file_path = fullfile(Pdata_base_dir, [monkeyname num2str(all_day_list(1)) 'to' monkeyname num2str(all_day_list(end)) '_' num2str(all_day_num)]);
load(fullfile(EMG_data_file_path, 'alignedEMG_data.mat'), 'Pall', 'Ptrig', 'timing_name_list');

% preとpostのPdata.matから必要な情報を抜き取って構造体にまとめる
[pre_session_data_str, pre_day_num, muscle_num, timing_num] =  makeStructForXcorr(Pdata_base_dir, monkeyname, pre_day_list, Pall, Ptrig);
[all_session_data_str, all_day_num] =  makeStructForXcorr(Pdata_base_dir, monkeyname, all_day_list, Pall, Ptrig);

% 各筋肉のコントロールデータの活動平均を求める
control_data_EMG_str = struct();
control_data_EMG_str.task_range = pre_session_data_str.task_range;
control_data_EMG_str.EMGs = pre_session_data_str.EMGs;
EMGs = pre_session_data_str.EMGs;

for timing_id = 1:(timing_num+1)
    if timing_id == timing_num+1
        unique_timing_name = 'whole_task';
    else
        unique_timing_name = ['timing' num2str(timing_id)];
    end
    
    for muscle_id = 1:muscle_num
        ref_muscle_name = EMGs{muscle_id};
        ref_muscle_control_EMG = cell(pre_day_num, 1);
        % 対象の筋肉のデータ抽出していく
        for pre_day_id = 1: pre_day_num
            ref_day_name = num2str(pre_day_list(pre_day_id));
            unique_day_name = [monkeyname ref_day_name];
            ref_muscle_control_EMG{pre_day_id} = pre_session_data_str.EMG_data.(unique_day_name).(unique_timing_name).(EMGs{muscle_id});
        end
        ref_muscle_control_EMG = cell2mat(ref_muscle_control_EMG);
        control_data_EMG_str.EMG_data.(unique_timing_name).(EMGs{muscle_id}) = mean(ref_muscle_control_EMG);
    end
end

% xcorrを計算していく
xcorr_data_str = struct();
xcorr_data_str.task_range = pre_session_data_str.task_range;
xcorr_data_str.EMGs = pre_session_data_str.EMGs;

for day_id = 1:all_day_num
    ref_day_name = num2str(all_day_list(day_id));
    unique_day_name = [monkeyname ref_day_name];
    ref_day_EMG_data_struct = all_session_data_str.EMG_data.(unique_day_name);
    for timing_id = 1:(timing_num+1)
        if timing_id == (timing_num+1)
            unique_timing_name = 'whole_task';
        else
            unique_timing_name = ['timing' num2str(timing_id)];
        end
        ref_timing_EMG_datas = ref_day_EMG_data_struct.(unique_timing_name);
        ref_timing_control_EMG_datas = control_data_EMG_str.EMG_data.(unique_timing_name);

        cutout_range = all_session_data_str.task_range.cutout_range.(unique_timing_name);
        validate_range = all_session_data_str.task_range.plot_range.(unique_timing_name);
        validate_indices = find(and(cutout_range >= -25, cutout_range <= 5));

        % 2つの信号をピックアップして総当たりでcorr_coeffを計算
        for ref_muscle_id = 1:muscle_num
            % 1つ目の信号を抽出(対象実験日の任意の筋肉のEMG)
            ref_muscle_name = EMGs{ref_muscle_id};
            ref_EMG_data = ref_timing_EMG_datas.(ref_muscle_name);

            for control_muscle_id = 1:muscle_num
                % 2つ目の信号を抽出(コントロールデータの任意の筋肉のEMG)
                control_muscle_name = EMGs{control_muscle_id};
                control_EMG_data = ref_timing_control_EMG_datas.(control_muscle_name);

                % 有効な範囲(図としてプロットした範囲)のデータのみ採用する
                validate_ref_EMG_data = ref_EMG_data(validate_indices);
                validate_control_EMG_data = control_EMG_data(validate_indices);
    
                % 相互相関係数(相互相関関数における位相差0の時の値)を求める
                xcorr_coef = corr(validate_control_EMG_data', validate_ref_EMG_data');
    
                xcorr_data_str.xcorr_data.(unique_day_name).(unique_timing_name).(ref_muscle_name).(['vs_control_' control_muscle_name]) = xcorr_coef;
            end
        end
    end
end

% 生成したデータを元に図を作っていく
% まずは、個々のタイミングの個々の筋肉における、選択したcontrol筋肉に対する図を生成する
common_save_figure_fold_path = fullfile(easyData_dir, 'xcorr_result');
elapsed_day_list = zeros(1, all_day_num);
for day_id = 1:all_day_num
    ref_day = all_day_list(day_id);
    elapsed_day_list(day_id) = CountElapsedDate(ref_day, TT_surgery_day);
end
post_first_elapsed_day = elapsed_day_list(find((elapsed_day_list > 0), 1 ));

for timing_id = 1:(timing_num+1)
    if timing_id == (timing_num+1)
        unique_timing_name = 'whole_task';
        timing_name_for_plot = 'whole_task';
    else
        unique_timing_name = ['timing' num2str(timing_id)];
        timing_name_for_plot = timing_name_list{timing_id};
    end
   
    for ref_muscle_id = 1:muscle_num
        % plotに使用するデータを格納する構造体を作る
        ref_muscle_name = EMGs{ref_muscle_id};
        plot_control_muscle_name = unique([ref_muscle_name, must_plot_EMGs]);
        plot_control_muscle_num = length(plot_control_muscle_name);
        plot_xcorr_values = zeros(plot_control_muscle_num, all_day_num);
        for control_muscle_id = 1:plot_control_muscle_num
            unique_contorol_EMG_name = ['vs_control_' plot_control_muscle_name{control_muscle_id}];
            for day_id = 1:all_day_num
                ref_day_name = num2str(all_day_list(day_id));
                unique_day_name = [monkeyname ref_day_name];
                plot_xcorr_values(control_muscle_id, day_id) = xcorr_data_str.xcorr_data.(unique_day_name).(unique_timing_name).(ref_muscle_name).(unique_contorol_EMG_name);
            end
        end
        
        % 一枚の図にプロットする
        main_muscle_id = find(strcmp(plot_control_muscle_name, ref_muscle_name));
        not_main_muscle_indices = 1:plot_control_muscle_num;
        not_main_muscle_indices(main_muscle_id) = [];

        figure();
        muscle_name_for_legend = regexprep(plot_control_muscle_name{main_muscle_id}, 'dist|prox', '');
        plot(elapsed_day_list, plot_xcorr_values(main_muscle_id, :), LineWidth=1.2, DisplayName=['vs control-' muscle_name_for_legend]);
        hold on;
        for ii = 1:length(not_main_muscle_indices)
            plot_muscle_id = not_main_muscle_indices(ii);
            muscle_name_for_legend = regexprep(plot_control_muscle_name{plot_muscle_id}, 'dist|prox', '');
            plot(elapsed_day_list, plot_xcorr_values(plot_muscle_id, :), LineWidth=1.2, DisplayName=['vs control-' muscle_name_for_legend]);
        end

        % decoration(不可能範囲のrectangle)
        muscle_name_for_title = regexprep(ref_muscle_name, 'dist|prox', '');
        title(['timing: ' timing_name_for_plot ', eachDay-' muscle_name_for_title ' vs']);
        ylabel('coefficient')
        xlabel('elapsed term from Tendon Transfer [day]')
        set(gca, fontsize=12)
        legend('Location','best', FontSize=8);
        rectangle('Position', [0, -1, post_first_elapsed_day - 1, 2], 'FaceColor',[1, 1, 1], 'EdgeColor', 'K', 'LineWidth',1.2);
        ylim([-1 1]);
        xlim([elapsed_day_list(1) elapsed_day_list(end)]);
        grid on;

        % save設定
        save_figure_fold_name = fullfile(common_save_figure_fold_path, unique_timing_name);
        makefold(save_figure_fold_name);
        save_figure_file_name = ref_muscle_name;
        saveas(gcf, fullfile(save_figure_fold_name, [save_figure_file_name '.fig']));
        saveas(gcf, fullfile(save_figure_fold_name, [save_figure_file_name '.png']));
        close all;
    end
end
disp(['figures are saved in: ' common_save_figure_fold_path]);

% それぞれの図をまとめて、全体の図を作成する
 page_num = ceil(muscle_num / figure_row_num);
 figures_str = struct();