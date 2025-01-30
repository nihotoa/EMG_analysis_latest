%{
ネスト深すぎる．しょうがない気もするけど
alignData.matのパスがsynegryとEMGで違いすぎる．構造のリファクタリングする際に統一してこのコードもリファクタリングするべき
構造違うけど、図の出力のための応急処置としてシナジー解析する時のPdataをH＿figuresディレクトリの中にコピペしているが、本来あるべき場所じゃないので、
リファクタリングするときは注意する
・loadするデータの名前(alignedDataEMGも変更するべき)
%}
clear;
%% set param
monkeyname = 'F';
plot_data_type = 'Synergy'; %'EMG'/'Synergy'
must_plot_elements = {'synergy2', 'synergy4'};
synergy_num = 4;
figure_row_num = 4; % 1ページに含める筋電の数(colはタイミングの数に決まる)
TT_surgery_day = 20170530;

%% code section
realname = get_real_name(monkeyname);
switch plot_data_type
    case 'EMG'
        ref_dir_path = fullfile(pwd, realname, 'easyData');
    case 'Synergy'
        ref_dir_path = fullfile(pwd, realname, 'new_nmf_result');
end

% 実験日データをpreとpostに分けてlistにまとめる
pre_standard_data_list = getGroupedDates(ref_dir_path, monkeyname, 'auto', 'pre');
post_standard_data_list = getGroupedDates(ref_dir_path, monkeyname, 'auto', 'post');
all_standard_data_list = getGroupedDates(ref_dir_path, monkeyname, 'auto', 'all');

pre_day_list = get_days(pre_standard_data_list);
post_day_list = get_days(post_standard_data_list);
all_day_list = get_days(all_standard_data_list);
all_day_num = length(all_day_list);

% 使用する筋電データのロード
switch plot_data_type
    case 'EMG'
        Pdata_base_dir = fullfile(ref_dir_path, 'P-DATA');
        load_file_path = fullfile(Pdata_base_dir, [monkeyname num2str(all_day_list(1)) 'to' monkeyname num2str(all_day_list(end)) '_' num2str(all_day_num)]);
    case 'Synergy'
        Pdata_base_dir = fullfile(ref_dir_path, 'syn_figures', 'H_figures');
        load_file_path = fullfile(Pdata_base_dir, [monkeyname '_Syn' num2str(synergy_num)  '_' num2str(all_day_list(1)) 'to' monkeyname '_Syn' num2str(synergy_num)  '_' num2str(all_day_list(end)) '_' num2str(all_day_num)]);
end
load(fullfile(load_file_path, 'alignedEMG_data.mat'), 'Pall', 'Ptrig', 'timing_name_list');

% preとpostのPdata.matから必要な情報を抜き取って構造体にまとめる
[pre_session_data_str, pre_day_num, element_num, timing_num] =  makeStructForXcorr(Pdata_base_dir, monkeyname, pre_day_list, Pall, Ptrig, plot_data_type);
[all_session_data_str, all_day_num] =  makeStructForXcorr(Pdata_base_dir, monkeyname, all_day_list, Pall, Ptrig, plot_data_type);

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
common_save_figure_fold_path = fullfile(ref_dir_path, 'xcorr_result');
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
        save_figure_fold_name = fullfile(common_save_figure_fold_path, unique_timing_name);
        makefold(save_figure_fold_name);
        save_figure_file_name = ref_elements_name;
        saveas(gcf, fullfile(save_figure_fold_name, [save_figure_file_name '.fig']));
        saveas(gcf, fullfile(save_figure_fold_name, [save_figure_file_name '.png']));
        close all;
    end
end
disp(['figures are saved in: ' common_save_figure_fold_path]);

% それぞれの図をまとめて、全体の図を作成する
 page_num = ceil(element_num / figure_row_num);
 figures_str = struct();