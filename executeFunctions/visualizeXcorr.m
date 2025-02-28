%{
+ ネスト深すぎる．しょうがない気もするけど
+ Pdataの使用は、makeStructForXcorrの中でEMGsをロードする時のみなので、EMGsをvisualizeEMGAndSynergyから作成できるファイルに含めてPdataに関する処理を削除する
+ 今はすべてのデータを使用する仕様になっているので、使用するpre,postデータをピックアップできるようにする
+ 参照フォルダがPdata_dirなのおかしい(each_timing_patternフォルダに変更する)
+ 列挙型にするか、もう一つcaseを作ってエラーハンドリングするか
+ 'Synergy'か'synergy'かでめちゃくちゃ変わるので、どうにかする

[caution]
+ シナジーの場合は、1対1対応になっていないと、この解析の意味がないことに注意
%}
clear;
%% set param
monkeyname = 'Hu';
plot_data_type = 'synergy'; %'EMG'/'synergy'
must_plot_elements = {'synergy1', 'synergy2'};
figure_row_num = 4; % 1ページに含める要素の数(列数はタイミングの数に決まる)

% if plot_type == 'Synergy'
use_EMG_type = 'only_task'; %' full' / 'only_task'
synergy_num = 4; % number of synergy you want to analyze

%% code section
root_dir = fileparts(pwd);
realname = get_real_name(monkeyname);

switch plot_data_type
    case 'EMG'
        base_dir = fullfile(root_dir, 'saveFold', realname, 'data', 'EMG_ECoG');
        Pdata_dir = fullfile(base_dir, 'P-DATA');
    case 'synergy'
        base_dir = fullfile(root_dir, 'saveFold', realname, 'data', 'Synergy');
        Pdata_dir = fullfile(base_dir, 'synergy_across_sessions', use_EMG_type, ['synergy_num==' num2str(synergy_num)], 'temporal_pattern_data');
end

% 実験日データをpreとpostに分けてlistにまとめる
pre_file_names = getGroupedDates(Pdata_dir, monkeyname, 'auto', 'pre');
post_file_names = getGroupedDates(Pdata_dir, monkeyname, 'auto', 'post');
[all_file_names, TT_surgery_day] = getGroupedDates(Pdata_dir, monkeyname, 'auto', 'all');

if isempty(pre_file_names)
    warning(['preのデータ(' TT_surgery_day '以前のデータ)が1つも選択されていません．選択し直してください'])
    return;
elseif isempty(post_file_names)
   warning(['postのデータ(' TT_surgery_day '以降のデータ)が1つも選択されていません．選択し直してください'])
    return;
end

pre_day_list = get_days(pre_file_names);
post_day_list = get_days(post_file_names);
all_day_list = get_days(all_file_names);

% 使用する筋電データのロード
switch plot_data_type
    case 'EMG'
        each_timing_pattern_dir = fullfile(base_dir, 'EMG_across_sessions', 'EMG_for_each_timing');
    case 'synergy'
        each_timing_pattern_dir = fullfile(fileparts(Pdata_dir), 'temporal_pattern_for_each_timing');
end

% preとpostのPdata.matから必要な情報を抜き取って構造体にまとめる
[pre_session_data_str, pre_day_num, element_num, timing_num, timing_name_list] =  makeStructForXcorr(Pdata_dir, each_timing_pattern_dir, monkeyname, pre_day_list, plot_data_type);
[all_session_data_str, all_day_num] =  makeStructForXcorr(Pdata_dir, each_timing_pattern_dir, monkeyname, all_day_list, plot_data_type);

% 各筋肉のコントロールデータの活動平均を求める
control_data_activity_str = struct();
control_data_activity_str.task_range = pre_session_data_str.task_range;
control_data_activity_str.elements = pre_session_data_str.elements;
elements = pre_session_data_str.elements;

for timing_id = 1:(timing_num+1)
    if timing_id == timing_num+1
        unique_timing_name = 'whole_task';
    else
        unique_timing_name = ['timing' num2str(timing_id)];
    end
    
    for element_id = 1:element_num
        ref_elements_name = elements{element_id};
        ref_elements_control_activity = cell(pre_day_num, 1);
        % 対象の筋肉のデータ抽出していく
        for pre_day_id = 1: pre_day_num
            ref_day_name = num2str(pre_day_list(pre_day_id));
            unique_day_name = [monkeyname ref_day_name];
            ref_elements_control_activity{pre_day_id} = pre_session_data_str.activity_data.(unique_day_name).(unique_timing_name).(elements{element_id});
        end
        ref_elements_control_activity = cell2mat(ref_elements_control_activity);
        control_data_activity_str.activity_data.(unique_timing_name).(elements{element_id}) = mean(ref_elements_control_activity);
    end
end

% xcorrを計算していく
xcorr_data_str = struct();
xcorr_data_str.task_range = pre_session_data_str.task_range;
xcorr_data_str.elements = pre_session_data_str.elements;

for day_id = 1:all_day_num
    ref_day_name = num2str(all_day_list(day_id));
    unique_day_name = [monkeyname ref_day_name];
    ref_day_activity_data_struct = all_session_data_str.activity_data.(unique_day_name);
    for timing_id = 1:(timing_num+1)
        if timing_id == (timing_num+1)
            unique_timing_name = 'whole_task';
        else
            unique_timing_name = ['timing' num2str(timing_id)];
        end
        ref_timing_activity_datas = ref_day_activity_data_struct.(unique_timing_name);
        ref_timing_control_activity_datas = control_data_activity_str.activity_data.(unique_timing_name);

        cutout_range = all_session_data_str.task_range.cutout_range.(unique_timing_name);
        validate_range = all_session_data_str.task_range.plot_range.(unique_timing_name);
        validate_indices = find(and(cutout_range >= -25, cutout_range <= 5));

        % 2つの信号をピックアップして総当たりでcorr_coeffを計算
        for ref_elements_id = 1:element_num
            % 1つ目の信号を抽出(対象実験日の任意の筋肉のactivity)
            ref_elements_name = elements{ref_elements_id};
            ref_activity_data = ref_timing_activity_datas.(ref_elements_name);

            for control_elements_id = 1:element_num
                % 2つ目の信号を抽出(コントロールデータの任意の筋肉のactivity)
                control_elements_name = elements{control_elements_id};
                control_activity_data = ref_timing_control_activity_datas.(control_elements_name);

                % 有効な範囲(図としてプロットした範囲)のデータのみ採用する
                validate_ref_activity_data = ref_activity_data(validate_indices);
                validate_control_activity_data = control_activity_data(validate_indices);
    
                % 相互相関係数(相互相関関数における位相差0の時の値)を求める
                xcorr_coef = corr(validate_control_activity_data', validate_ref_activity_data');
    
                xcorr_data_str.xcorr_data.(unique_day_name).(unique_timing_name).(ref_elements_name).(['vs_control_' control_elements_name]) = xcorr_coef;
            end
        end
    end
end

% 生成したデータを元に図を作っていく
% まずは、個々のタイミングの個々の筋肉における、選択したcontrol筋肉に対する図を生成する
switch plot_data_type
    case 'EMG'
        xcorr_figure_fold_path = fullfile(root_dir, 'saveFold', realname, 'figure', 'EMG', 'xcorr_result');
    case 'synergy'
        xcorr_figure_fold_path = fullfile(root_dir, 'saveFold', realname, 'figure', 'Synergy', 'xcorr_result');
end


elapsed_day_list = zeros(1, all_day_num);
for day_id = 1:all_day_num
    ref_day = all_day_list(day_id);
    elapsed_day_list(day_id) = CountElapsedDate(ref_day, TT_surgery_day);
end
post_first_elapsed_day = elapsed_day_list(find((elapsed_day_list > 0), 1 ));

for timing_id = 1:(timing_num+1)
    if timing_id == (timing_num+1)
        unique_timing_name = 'whole_task';
        timing_name_for_plot = 'whole-task';
    else
        unique_timing_name = ['timing' num2str(timing_id)];
        timing_name_for_plot = timing_name_list{timing_id};
    end
   
    for ref_elements_id = 1:element_num
        % plotに使用するデータを格納する構造体を作る
        ref_elements_name = elements{ref_elements_id};
        plot_control_elements_name = unique([ref_elements_name, must_plot_elements]);
        plot_control_elements_num = length(plot_control_elements_name);
        plot_xcorr_values = zeros(plot_control_elements_num, all_day_num);
        for control_elements_id = 1:plot_control_elements_num
            unique_contorol_activity_name = ['vs_control_' plot_control_elements_name{control_elements_id}];
            for day_id = 1:all_day_num
                ref_day_name = num2str(all_day_list(day_id));
                unique_day_name = [monkeyname ref_day_name];
                plot_xcorr_values(control_elements_id, day_id) = xcorr_data_str.xcorr_data.(unique_day_name).(unique_timing_name).(ref_elements_name).(unique_contorol_activity_name);
            end
        end
        
        % 一枚の図にプロットする
        main_elements_id = find(strcmp(plot_control_elements_name, ref_elements_name));
        not_main_elements_indices = 1:plot_control_elements_num;
        not_main_elements_indices(main_elements_id) = [];

        figure();
        elements_name_for_legend = regexprep(plot_control_elements_name{main_elements_id}, 'dist|prox', '');
        plot(elapsed_day_list, plot_xcorr_values(main_elements_id, :), LineWidth=1.2, DisplayName=['vs control-' elements_name_for_legend]);
        hold on;
        for ii = 1:length(not_main_elements_indices)
            plot_elements_id = not_main_elements_indices(ii);
            elements_name_for_legend = regexprep(plot_control_elements_name{plot_elements_id}, 'dist|prox', '');
            plot(elapsed_day_list, plot_xcorr_values(plot_elements_id, :), LineWidth=1.2, DisplayName=['vs control-' elements_name_for_legend]);
        end

        % decoration(不可能範囲のrectangle)
        elements_name_for_title = regexprep(ref_elements_name, 'dist|prox', '');
        title(['timing: ' timing_name_for_plot ', eachDay-' elements_name_for_title ' vs']);
        ylabel('coefficient')
        xlabel('elapsed term from Tendon Transfer [day]')
        legend('Location','best', FontSize=15);
        rectangle('Position', [0, -1, post_first_elapsed_day - 1, 2], 'FaceColor',[1, 1, 1], 'EdgeColor', 'K', 'LineWidth',1.2);
        ylim([-1 1]);
        xlim([elapsed_day_list(1) elapsed_day_list(end)]);
        grid on;
        set(gca, fontsize=20)

        % save設定
        save_figure_fold_name = fullfile(xcorr_figure_fold_path, unique_timing_name);
        makefold(save_figure_fold_name);
        save_figure_file_name = ref_elements_name;
        saveas(gcf, fullfile(save_figure_fold_name, [save_figure_file_name '.fig']));
        saveas(gcf, fullfile(save_figure_fold_name, [save_figure_file_name '.png']));
        close all;
    end
end
disp(['figures are saved in: ' xcorr_figure_fold_path]);

% それぞれの図をまとめて、全体の図を作成する
 page_num = ceil(element_num / figure_row_num);
 figures_str = struct();