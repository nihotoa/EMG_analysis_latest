%{
[function]
既存のfigureをsubplotに割り当てて、1枚の図を作成する

[input arguments]
figure_file_path_list: [cell array], 各要素はchar型であり、figファイルのpathが絶対パスで入っている.
save_fold_path: [char], セーブフォルダの絶対パス
save_file_name:[char], セーブファイルの名前

(任意の入力引数)
row_name_list: [cell vector], row_nameのリスト. figure_file_path_listの行数と同じ次元のベクトル
col_name_list: [cell vector], col_nameのリスト. figure_file_path_listの列数と同じ次元のベクトル
%}

function [] = mergeFigures(figure_file_path_list, save_fold_path, save_file_name, row_name_list, col_name_list)
label_operation_flag = true;
if nargin == 3
    label_operation_flag = false;
end

% preparation
[row_num, col_num] = size(figure_file_path_list);

% assign each .fig into subplot
for row_id = 1:row_num
    for col_id = 1:col_num
        element_id = col_num * (row_id-1) + col_id;
        if element_id == 1
            figure('position', [100, 100, 400 * col_num, 200 * row_num]);
            hold on;
        end
        subplot(row_num, col_num, element_id);
        ref_subplot = gca;
        ref_figure = openfig(figure_file_path_list{row_id, col_id}, 'invisible');
        ref_figure_parts = findobj(ref_figure, 'Type', 'axes');
        ref_fig_main = get(ref_figure_parts, "Children"); % figureのメイン部分を取得
        copyobj(ref_fig_main, ref_subplot) 
        
        % decoration
        ref_subplot.XTick = 1:length(ref_figure_parts.XTickLabel);
        ref_subplot.XTickLabel = ref_figure_parts.XTickLabel;
        close(ref_figure)
        if label_operation_flag
            if col_id == 1
                ylabel(row_name_list{row_id}, 'FontSize', 20)
            end
            if row_id == 1
                title(col_name_list{col_id}, 'FontSize', 25);
            end
        end
    end
end
hold off;

% save setting
makefold(save_fold_path)
saveas(gcf, fullfile(save_fold_path, [save_file_name '.fig']));
saveas(gcf, fullfile(save_fold_path, [save_file_name '.png']));

close all;
end
