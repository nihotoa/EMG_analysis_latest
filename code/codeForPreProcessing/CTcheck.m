%{
[explanation of this func]:
this function is used in 'prepareEMGAndTimingData.m'
Check for cross-talk between measured EMGs

[input arguments]:
monkey_prefix: [char], prefix of data
xpdate_num: [double], date of experiment
save_fold: [char], 'easyData', you dont need to change
task: [char], 'standard', you dont need to change
full_monkey_name: [char], full name of monkey

[output arguments]:
Yave: [double array], Array containing the values of the cross-correlation coefficients between EMG.
Y3ave: [double array], Array containing the values of the cross-correlation coefficients between EMG.

[points of improvement(Japanese)]   
�ؓd�ɂ��Ă��A3�K�����l�ɂ��Ă����ݑ��֊֐��̐�Βl�̍ő�l���Ƃ��Ă��邪����ł����̂�?
(���̎��Ԃ̈ʑ��͕ۑ�����ĂȂ�? & ��Βl��������-1�̉\��������̂ł�?)
pwd���g��Ȃ���������(bsse_dir��import���Ďg��)
%}

function [Yave,Y3ave] = CTcheck(monkey_prefix, xpdate_num, save_fold, full_monkey_name)
xpdate = sprintf('%d',xpdate_num);
disp(['START TO MAKE & SAVE ' monkey_prefix xpdate 'CTcheck ref_trial_EMG']);

% load EMG data & tget trial number
S = load(fullfile(save_fold, 'CT_check_data_list', [monkey_prefix xpdate '_CT_check_data.mat']),'CTcheck');
trial_num = length(S.CTcheck.raw_trial_EMG);
[EMG_num, ~] = size(S.CTcheck.raw_trial_EMG{1});

% To speed up processing, set the maximum value of iteration to 20.
if trial_num > 20
    trial_num = 20;
end

for trial_id = 1:trial_num
    % load each trial data
    ref_trial_EMG = S.CTcheck.raw_trial_EMG{:, trial_id};
    ref_trial_EMG_diff3 = S.CTcheck.diff3_trial_EMG{:, trial_id};

    % make empty array for storing data
    if trial_id == 1
        Yave = zeros(EMG_num,EMG_num);
        Y3ave = zeros(EMG_num,EMG_num);
    end

    Y = cell(EMG_num);
    X = cell(EMG_num);
    Ysum = zeros(EMG_num,EMG_num);

    Y3 = cell(EMG_num);
    X3 = cell(EMG_num);
    Y3sum = zeros(EMG_num,EMG_num);

    % Find the cross-correlation function between the i-th EMG and the j-th EMG
    for i = 1:EMG_num
        for j = 1:EMG_num
            % Y: cross-correlation function, X: Phase difference between 2 signals
            [Y{i,j},X{i,j}] = xcorr(ref_trial_EMG(i,:) - mean(ref_trial_EMG(i,:)), ref_trial_EMG(j,:) - mean(ref_trial_EMG(j,:)),'coeff');

            % Find the maximum absolute value of the cross-correlation
            Ysum(i,j) = max(abs(Y{i,j}));
            
            % Find the cross-correlation function of the 3rd-order differential value
            [Y3{i,j},X3{i,j}] = xcorr(ref_trial_EMG_diff3(i,:)-mean(ref_trial_EMG_diff3(i,:)), ref_trial_EMG_diff3(j,:)-mean(ref_trial_EMG_diff3(j,:)),'coeff');

            % Find the maximum absolute value of the cross-correlation
            Y3sum(i,j) = max(abs(Y3{i,j}));
        end
    end

    % find the average 'Yave' & 'Y3ave' for all trials 
    Yave = (Yave .* (trial_id-1) + Ysum) ./ trial_id;
    Y3ave = (Y3ave .* (trial_id-1) + Y3sum) ./ trial_id;
end

% save data
makefold(fullfile(save_fold, 'CTR_list'));
save(fullfile(save_fold, 'CTR_list', [monkey_prefix xpdate '_CTR.mat']), 'monkey_prefix', 'xpdate', 'Yave', 'Y3ave');
disp(['FINISH TO MAKE & SAVE ' monkey_prefix xpdate 'CTcheck ref_trial_EMG']);
end