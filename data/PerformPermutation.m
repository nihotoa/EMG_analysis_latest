%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]
・verify the change in spatial synergy by statistical test

[Saved data location]

[procedure]
pre: dispNMF_W.m
post: nothing

[Improvement points(Japanaese)]
3種類のanovaでswitchして処理を行なっているが、かぶっている部分があるので、共通部分は共通して書くように改善する
ローカル関数をファイルごとに分けてcodeの中に保存
mergeFiguresは汎用性高めたいので、書き換える
ヒートマップの中に数字書くやつも、commonCodeとして実装する

[caution!!]
・明らかにpostのデータの方が多いから、今のやり方はおそらく良くない
・上の問題をうまく改善したとしても、pre, post間の変動よりもpost内変動の方が大きいから有意差が出なかった可能性を否定できない。
   => これだと「一貫して変化してない」とは言えない
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
monkeyname = 'F';  % Name prefix of the folder containing the synergy data for each date
nmf_fold_name = 'new_nmf_result'; % name of nmf folder
session_group_name_list = {'pre', 'post'};
numPermutations = 10000; % パーミュテーションの回数(少なくとも100は必要、多ければ多いほどp値の信憑性が高まる)

%% code section
realname = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, nmf_fold_name);
Wdata_dir = fullfile(base_dir, 'W_synergy_data');
W_figure_dir = fullfile(base_dir, 'syn_figures');
common_save_dir = fullfile(base_dir, 'anova_result');
makefold(common_save_dir);
candidate_file_list = dirEx(Wdata_dir);
session_group_num = length(session_group_name_list);

% make structure object(structure array) for permutation for each session_group & store it in 'main_structure'
main_structure = struct();
for session_group_id = 1:session_group_num
    ref_session_group = session_group_name_list{session_group_id};
    ref_file_name = candidate_file_list(contains({candidate_file_list.name}, ref_session_group)).name;
    ref_structure = load(ref_file_name);
    ref_structure.session_group = ref_session_group;
    [~, session_num] = size(ref_structure.WDaySynergy{1});
    ref_structure.session_num = session_num;
    main_structure.(session_group_name_list{session_group_id}) = ref_structure;
end
synergy_num = length(ref_structure.WDaySynergy);


%% conduct permutation
% データの行数（サンプル数）=> 船戸先生にこれでいいか相談
numSamples = main_structure.pre.session_num * main_structure.post.session_num;
% コサイン類似度を計算する関数を作成
cosineSimilarity = @(x, y) dot(x, y) / (norm(x) * norm(y));
% 図の作成
figure('position', [100, 100, 800, 800])

% 各シナジーのpre,postで以下の操作を行う
for synergy_id = 1:synergy_num
    % 群ごとにシナジーのデータをまとめる
    synergy1 = main_structure.pre.WDaySynergy{synergy_id}';
    synergy2 = main_structure.post.WDaySynergy{synergy_id}';
    
    % pre,postからシナジーを一つずつ選び、コサイン距離を総当たりで計算 => 平均値を返す(船戸先生にこれでいいか相談)
    observedMeanDist = calcObservedMeanDist(numSamples, synergy1, synergy2, cosineSimilarity);
    
    % パーミュテーションによる(1 - コサイン類似度)の分布
    permutedDist = zeros(numPermutations, 1);
    
    % パーミュテーションテストの実行
    combinedData = [synergy1; synergy2];
    pre_session_num = main_structure.pre.session_num;
    post_session_num = main_structure.post.session_num;
    all_session_num =  pre_session_num + post_session_num;
    for i = 1:numPermutations
        % ランダム置換した後に2群に分ける
        permutedIndices = randperm(all_session_num);
        permutedSynergy1 = combinedData(permutedIndices(1:pre_session_num), :);
        permutedSynergy2 = combinedData(permutedIndices(pre_session_num + 1:end), :);
        
        % パーミュテーション1,2からシナジーを一つずつ選び、コサイン距離を総当たりで計算 => 平均値を返す(船戸先生にこれでいいか相談)
        permutedDistTemp = calcObservedMeanDist(numSamples, permutedSynergy1, permutedSynergy2, cosineSimilarity);
        permutedDist(i) = mean(permutedDistTemp);
    end
    
    % p値の計算: 観察された非類似度が、ノイズによってばらついた非類似度分布に対してどのくらいまれなのか？
    % 明らかにまれな現象(pが小さい)→ 有意な差を表す
    pValue = (sum(permutedDist >= observedMeanDist) + 1) / (numPermutations + 1);
    
    % 結果のプロットと装飾
    subplot(synergy_num, 1, synergy_id)
    histogram(permutedDist, 30);
    hold on;
    xline(observedMeanDist, 'r', 'LineWidth', 2); % 実データの(1 - コサイン類似度)の平均を表示
    title(sprintf(['(synergy' num2str(synergy_id) ', numPermutations=' num2str(numPermutations) ', p-value=' num2str(pValue, '%.3f') ')']), fontsize=15);
    if synergy_id == synergy_num
        xlabel('コサイン距離の平均','FontSize',15);
        ylabel('頻度', 'FontSize',15);
    end
end
sgtitle('パーミュテーションによるコサイン距離の分布', fontsize=20);

%図の保存
save_fold_path = fullfile(common_save_dir, 'Permutation');
save_file_name = 'permutation_result';
makefold(save_fold_path);
saveas(gcf, fullfile(save_fold_path, [save_file_name '.png']));
saveas(gcf, fullfile(save_fold_path, [save_file_name '.fig']));
close all;

%% define local function
function [observedMeanDist] = calcObservedMeanDist(numSamples, synergy1, synergy2, cosineSimilarity)
% 観測された(1 - コサイン類似度)の計算
observedDist = zeros(numSamples, 1);
pre_session_num = size(synergy1, 1);
post_session_num = size(synergy2, 1);

for pre_session_id = 1:pre_session_num
    for post_session_id = 1:post_session_num
        stored_idx = post_session_num * (pre_session_id - 1) + post_session_id;
        observedDist(stored_idx) = 1 - cosineSimilarity(synergy1(pre_session_id, :), synergy2(post_session_id, :));
    end
end
observedMeanDist = mean(observedDist);
end



