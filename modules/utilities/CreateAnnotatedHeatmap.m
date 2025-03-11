%{
[input arguments]
colormap_matrix: [double matrix],  cmap (the output of the 'colormap' function)
value_data_matrix: [double matrix],  contains value to be wrriten in each pixel
colormap_id_matrix: [double matrix],  contains id (this is corresponding to row index of 'colormap_matrix')
x_labels: [cell vector], label of x-axis (the size of this vector matches the number of columns in 'value_data_matrix')
y_labels: [cell vector], label of y-axis (the size of this vector matches the number of rows in 'value_data_matrix')
title_str: [char]. the titile of the figure
save_fold_path: [char], 
save_file_name: [char], 

[improvement point]
引数がなかった時のデフォルトの引数値等は用意していないので、narginの数によって条件分岐することでデフォルトあたいを設定するべき
colorbarの設定はハードコーディングなので、他で使う機会があった時に、柔軟にclorobarを作成できるように作成する

[caution!!]
figureオブジェクトはグローバル変数のような扱いなので、入力引数に指定しなくていいし、返り値として指定する必要もない

%}
function [] = CreateAnnotatedHeatmap(colormap_matrix, value_data_matrix, colormap_id_matrix, x_labels, y_labels, title_str, save_fold_path, save_file_name)
% セーブ先のpathが設定されている場合(この関数の呼び出し元でfigureオブジェクトが作成されていない場合)
if nargin==8
    figure('position', [100, 100, 1200, 1200])
end
[row_num, col_num] = size(value_data_matrix);
colormap(colormap_matrix);

% 色のみをプロット
imagesc(colormap_id_matrix);
colorbar off;
axis equal tight;

% 各マスの上にテキストを入れていく
textStrings = num2str(value_data_matrix(:), '%.2f');
textStrings = strtrim(cellstr(textStrings));
[x, y] = meshgrid(1:size(value_data_matrix, 2), 1:size(value_data_matrix, 1));
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center', 'Color', 'k', 'FontSize',20);
nanIndex_list = isnan(value_data_matrix(:));
set(hStrings(nanIndex_list), 'Color', 'k');

%decoration
xline((0.5:1:col_num-0.5))
yline((0.5:1:row_num-0.5))
xticks(1:col_num); yticks(1:row_num);
xticklabels(x_labels);
yticklabels(y_labels);
xtickangle(90);
set(gca, 'FontSize', 15)
title(title_str, 'FontSize', 20)

% ハーコーディングなので一旦コメントアウト．
% c = colorbar;
% c.Ticks = [1.25 1.75];
% c.TickLabels = {'n.s.', 'Sig.'};
% c.FontSize=20;

% save figure(この関数内でfigure objectが作られた場合)
if nargin == 8
    makefold(save_fold_path);
    saveas(gcf, fullfile(save_fold_path, [save_file_name '.fig']));
    saveas(gcf, fullfile(save_fold_path, [save_file_name '.png']));
    close all;
end
end

