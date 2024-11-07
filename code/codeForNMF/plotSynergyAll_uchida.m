
%{
explanation of this func:
This function is used in 'SYNERGYPLOT.m'.
Plot the results of the synergy analysis (temporal pattern, spatial pattern, VAF, etc.), focusing on the number of synergies in 'pcNum' for the date specified in 'fold_name'.

input arguments:
fold_name: [char], prefix & date (ex.) 'F170516'
pcNum: [double], number of synergies to focus on
nmf_fold_name: [char], 
each_plot: [0 or 1], Parameter for changing the layout of diagram.
save_setting:[struct], structure containing parameters for whether the output diagram should be saved or not.
base_dir: [char], base path for specifying folder path. (basically, this is correspond to monkeyname folder)

output arguments:

[Improvement point]
全体的に冗長
・stackの図とstdの図のplotの被っているところ
・セーブセクションの被っているところ
loadした時にtestが上書きされてしまうので、構造体に保存して区別するべき
%}

function plotSynergyAll_uchida(fold_name, pcNum,nmf_fold_name, each_plot, save_setting, base_dir, plot_clustering, synergy_num_type)
%% set para & get nmf result
task = 'standard';
fold_path = fullfile(base_dir, nmf_fold_name, [fold_name '_' task]);

% get the file details which is related to synergy analysis
synergy_files = get_synergy_files_name(fold_path, fold_name) ;

% load file
if isempty(synergy_files)
    error('synergy_files are not found. Please run "makeEMFNMF_btcOya.m" first');
else
    % load both of NMF result file
    for ii = 1:length(synergy_files)
        synergy_file_name = synergy_files(ii).name;
        if contains(synergy_file_name, 't_')
            % synergy Data
            load(fullfile(fold_path, synergy_file_name), 'test');
        else
            % VAF & name list of EMG
            synergy_detail_struct = load(fullfile(fold_path, synergy_file_name));
            test = synergy_detail_struct.test;
            TargetName = synergy_detail_struct.TargetName;
            if isfield(synergy_detail_struct, 'use_EMG_type')
                use_EMG_type = synergy_detail_struct.use_EMG_type; 
            else
                use_EMG_type = 'full';
            end
        end
    end
end

% get the number of EMG and muscle name
EMG_num = length(TargetName);
EMGs = get_EMG_name(TargetName);

% get parameters
[~, kf] = size(test.W);
save_fig_W = save_setting.save_fig_W;
save_fig_H = save_setting.save_fig_H;
save_fig_r2 = save_setting.save_fig_r2; 
save_data = save_setting.save_data;

%% sort synergies extracted from each test data and group them by synergies of similar characteristics
W_data = test.W(pcNum, :);
if plot_clustering == 1
    save_fold_path = fullfile(base_dir, 'new_nmf_result', [fold_name '_' task], [fold_name, '_syn_result_' num2str(EMG_num)], [fold_name '_clustering']);
    [Wt, k_arr] = OrderSynergy(EMG_num, pcNum, W_data, [], kf, base_dir, 1, fold_name, save_fold_path);
else
    [Wt, k_arr] = OrderSynergy(EMG_num, pcNum, W_data);
end

% if difference are found between segments
if isempty(k_arr)
    warning(['The ' num2str(kf) ' segments in the "' fold_name '" data were inconsistent when the number of synergies is ' num2str(pcNum) '.'])
    return;
end

%% plot W (spatial pattern)
figure('Position',[0,1000,800,1300]);
x = categorical(EMGs');
zeroBar = zeros(EMG_num,1);
aveW = zeros(EMG_num,pcNum);
std_value = cell(1, pcNum);

% make coefficient matrix for normalizing W(making it a unit vector)
Wt_coefficient_matrix = cell(size(Wt));
normalized_Wt = cell(size(Wt));
for session_id = 1:length(Wt)
    ref_session_Wt = Wt{session_id};
    [~, synergy_num] = size(ref_session_Wt);
    normalized_Wt{session_id} = zeros(size(ref_session_Wt));
    Wt_coefficient_matrix{session_id} = zeros(1, synergy_num);
    for synergy_id = 1:synergy_num
        ref_W = ref_session_Wt(:, synergy_id);
        W_coefficient = norm(ref_W);
        Wt_coefficient_matrix{session_id}(synergy_id) = W_coefficient;
        normalized_Wt{session_id}(:, synergy_id) = ref_W / W_coefficient;
    end
end


% subplot for each synergy
for i = 1:pcNum
    % organize value to be plotted
    plotted_W = nan(EMG_num, kf);
    for jj = 1:kf
        plotted_W(:, jj) = normalized_Wt{jj}(:, i);
    end
    
    % calc the mean value of test data
    temp = mean(plotted_W, 2);
    ave_normalized_W = temp / norm(temp);
    aveW(:, i) = ave_normalized_W;
    std_value{1,i} = std(plotted_W, 0, 2);

    % barplot
    subplot(pcNum,1,i); 
    bar(x,[zeroBar plotted_W]);

    % decoration
    ylim([0 1]);
    title([fold_name ' W pcNum = ' sprintf('%d',pcNum)]);
end

%% save figure & data about W (temporal pattern of synergy)
% set the path to save data & figure
save_fold = fullfile(fold_path, [fold_name '_syn_result_' sprintf('%02d',EMG_num)]);
makefold(save_fold);

% save_data
if save_data == 1
    save_fold_W = fullfile(save_fold, [fold_name '_W']);
    makefold(save_fold_W);
    comment = 'this data will be used for dispW';
    switch synergy_num_type
        case 'manual'
            save(fullfile(save_fold_W, [fold_name '_aveW_' sprintf('%d',pcNum) '.mat']), 'Wt_coefficient_matrix', 'aveW','k_arr','pcNum','fold_name','comment');
        case 'auto'
            save(fullfile(save_fold_W, [fold_name '_aveW_appropriateNum.mat']), 'Wt_coefficient_matrix', 'aveW','k_arr','pcNum','fold_name','comment');
    end
end

% save figure
if save_fig_W ==1
    saveas(gcf,fullfile(save_fold_W, [fold_name ' W pcNum = ' sprintf('%d',pcNum) '.png']));
end
close all;

%% plot aveW
figure('Position',[0,1000,800,1700]);
for i = 1:pcNum
    subplot(pcNum,1,i); 

    % barplot
    bar(x,aveW(:,i))
    hold on

    % add error bar
    er = errorbar(x,aveW(:,i),std_value{i},std_value{i});
    er.Color = [0 0 0];
    er.LineStyle = 'none';

    % decoration
    ylim([0 1]);
    title([fold_name ' aveW pcNum = ' sprintf('%d',pcNum)]);
end

% save figure
if save_fig_W ==1
    saveas(gcf, fullfile(save_fold_W, [fold_name ' aveW pcNum = ' sprintf('%d',pcNum) '.png']));
end
close all;

if each_plot == 1
    for i = 1:pcNum
        figure('Position',[0,1000,600,400]);

        % bar plot
        bar(x,aveW(:,i))
        hold on

        % add error bar
        er = errorbar(x,aveW(:,i),std_value{i},std_value{i});
        er.Color = [0 0 0];
        er.LineStyle = 'none';

        % decoration
        ylim([0 1]);
        title([fold_name ' aveW pcNum = ' sprintf('%d',pcNum) ' synergy' num2str(i)]);

        % save figure
        if save_fig_W ==1
            saveas(gcf,fullfile(save_fold_W, [fold_name ' aveW pcNum = ' sprintf('%d',pcNum) '_synergy' num2str(i) '.png']));
        end
        close all;
    end
end

%% plot H (temporal pattern of synergy)
% load timing data (which is created by )
switch use_EMG_type
    case 'full'
        easyData_path = fullfile(base_dir, 'easyData', [fold_name '_' task]);
        easyData_file_name = [fold_name '_EasyData.mat'];
        easyData_file_path = fullfile(easyData_path, easyData_file_name);
        try
            load(easyData_file_path, 'Tp', 'SampleRate');
        catch
            stack = dbstack;
            disp(['(Error occured: line ' num2str(stack(1).line + 1) ') EasyData(' easyData_file_path ') is not found. Please run "runnningEasyfunc.m" first!']);
            return;
        end
        SUC_Timing_A = floor(Tp.*(100/SampleRate));

    case 'trimmed'
        load(fullfile(fold_path, synergy_file_name), 'event_timings_after_trimmed');
        SUC_Timing_A = event_timings_after_trimmed;
end
SUC_num = length(SUC_Timing_A(:, 1)) - 1;

% concatenate all test data to create a temporal pattern of synergy in the entire recording interval (as All_H)
H_data = test.H(pcNum, :);
All_H = cell(1, kf);
for ii = 1:kf
    sort_order = k_arr(:, ii);
    for jj = 1:length(sort_order)
        sort_id = sort_order(jj);
        All_H{ii}(jj, :) = H_data{ii}(sort_id, :) * Wt_coefficient_matrix{ii}(jj);
    end
% All_H{ii} = H_data{ii}(sort_order, :);
end
All_H = cell2mat(All_H);

TIMEr = [-100 100]; %range of cutting out
TIMEl = abs(TIMEr(1))+abs(TIMEr(2))+1; % number of samples to be cut out
aveH = zeros(pcNum, TIMEl);
pullData = zeros(SUC_num, TIMEl);

% plot temporal pattern for each trial by cutting out each trial
figure('Position',[900,1000,800,1300]);
% each synergy
for ii=1:pcNum
    % each trial
   for jj=2:SUC_num
      subplot(pcNum,1,ii);

      % cut out temporal data for 'lever1 off' timng +-1 [sec] for each trial
      cutout_start_timing = SUC_Timing_A(jj, 3) + TIMEr(1);
      cutout_end_timing = SUC_Timing_A(jj, 3)+TIMEr(2);
      
      pullData(jj, :) = All_H(ii,  cutout_start_timing: cutout_end_timing);

       % plot each trial temporal data (around 'lever1 off' timing)
      plot(pullData(jj,:));
        
      % update averarge value up to the current trial
      aveH(ii, :) = ((aveH(ii, :) .* (jj-1)) + pullData(jj,:)) ./ jj ;

      % decoration
      ylim([0 8]);
      hold on;
   end
end

%% save figure & data about H (temporal pattern of synergy)
if save_data == 1
    save_fold_H = fullfile(save_fold, [fold_name '_H']);
    makefold(save_fold_H);
    comment = 'this data will be used for dispH';
    switch synergy_num_type
        case 'manual'
            save(fullfile(save_fold_H, [fold_name '_aveH3_' sprintf('%d',pcNum) '.mat']), 'Wt_coefficient_matrix', 'aveH','k_arr','pcNum','fold_name','comment');
        case 'auto'
            save(fullfile(save_fold_H, [fold_name '_aveH3_appropriateNum.mat']), 'Wt_coefficient_matrix', 'aveH','k_arr','pcNum','fold_name','comment');
    end
end

% save figure
if save_fig_H ==1
    saveas(gcf, fullfile(save_fold_H, [fold_name ' HS_2 pcNum = ' sprintf('%d',pcNum) '.fig']));
    saveas(gcf, fullfile(save_fold_H, [fold_name ' HS_2 pcNum = ' sprintf('%d',pcNum) '.png']));
end
close all;

% plot trial average value of temporal pattern for each synergy &
 figure('Position',[900,1000,800,1300]);
 for j=1:pcNum
     subplot(pcNum,1,j);
     plot(aveH(j,:), 'r');
     ylim([0 8]);
     hold on;
 end

 % save figure (averarge of temporal pattern)
 if save_fig_H ==1
     saveas(gcf,fullfile(save_fold_H  , [fold_name ' H3_ave pcNum = ' sprintf('%d',pcNum) '.fig']));
     saveas(gcf,fullfile(save_fold_H  , [fold_name ' H3_ave pcNum = ' sprintf('%d',pcNum) '.png']));
 end
 close all;

%% plot & save VAF figure
figure;
% load synergy file (for the one containing r2 information)
file_sizes = [synergy_files.bytes];
[~, min_idx] = min(file_sizes);
load(fullfile(fold_path, fullfile(synergy_files(min_idx).name)));

% plot VAF
for i= 1:kf
    plot(test.r2(:,i));
    ylim([0 1]);
    hold on;
    plot(shuffle.r2(:,i),'Color',[0,0,0]);
    hold on
end

% draw a line indicating the threshold
plot([0 EMG_num + 1],[0.8 0.8]);
title([fold_name ' R^2']);

% save VAF figure
if save_fig_r2 ==1
    save_fold_VAF = fullfile(save_fold, [fold_name '_r2']);
    makefold(save_fold_VAF)
    saveas(gcf, fullfile(save_fold_VAF, [fold_name ' R2 pcNum = ' sprintf('%d',pcNum) '.png']));
    close all;
end
end

