%{
[explanation of this func]

[input arguments]

[output arguments]

[Improvement point(Japanese)]

%}

function [] = plotCosineDistance(cosine_distance_matrix, condition_num, labels, title_str, save_fold_path, save_file_name)
figure('position', [100, 100, 1200, 800])
imagesc(cosine_distance_matrix);

%decoration
colormap(jet);
colorbar;
h = colorbar;
ylabel(h, 'cosine distance', 'FontSize', 25)
axis xy;
if condition_num <= 50
    xticks(1:condition_num); yticks(1:condition_num);
    xticklabels(labels);
    yticklabels(labels);
    xtickangle(90);
end
set(gca, 'FontSize', 25)
title_str = sprintf(title_str);
title(title_str, 'FontSize', 25)

% save
saveas(gcf, fullfile(save_fold_path, [save_file_name '.fig']))
saveas(gcf, fullfile(save_fold_path, [save_file_name '.png']))
close all;
end