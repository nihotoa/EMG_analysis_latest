function [] = SaveAnovaResult(save_fold_path, save_file_name, tbl)
makefold(save_fold_path);
writetable(tbl, fullfile(save_fold_path, save_file_name), "WriteRowNames",true);
end