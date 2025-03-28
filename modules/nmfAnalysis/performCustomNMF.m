%{
[Function Description]
This function performs Non-Negative Matrix Factorization (NMF) to extract muscle synergies.
It creates the necessary parameters, performs cross-validation by dividing data into segments,
and evaluates the quality of extracted synergies. The process is computationally intensive
and can be time-consuming.

[Input Arguments]
EMG_data_matrix: [double array] Matrix of EMG data with dimensions [num_muscles x num_samples]
num_segments: [integer] Number of parts to divide data for cross-validation
num_iterations: [integer] Number of repetitions for synergy search
shuffle_enabled: [bool] Flag to indicate whether to perform analysis on shuffled data (false: use only original data, true: also analyze with randomized time-series)
NMF_algorithm: [char] Algorithm to be used for NMF ('mult': Multiplicative Update rules, 'als': Alternating Least Squares)

[Output Arguments]
synergy_details: [struct] Structure containing metrics about extracted synergies (r2, explained variance, etc.)
extracted_synergies: [struct] Structure containing spatial pattern (W) and temporal pattern (H) of synergies

[Caution]
'nnmf2' is a function created by Takei and has not been refactored because it is complicated
%}

function [synergy_details, extracted_synergies] = performCustomNMF(EMG_data_matrix, num_segments, num_iterations, shuffle_enabled, NMF_algorithm)
% Create empty structures for storing results
[num_muscles, num_samples] = size(EMG_data_matrix);

extracted_synergies.train.W = cell(num_muscles, num_segments);
extracted_synergies.train.H = cell(num_muscles, num_segments);
extracted_synergies.test.W = cell(num_muscles, num_segments);
extracted_synergies.test.H = cell(num_muscles, num_segments);

synergy_details.num_iterations = num_iterations;
synergy_details.shuffle_enabled = shuffle_enabled;
synergy_details.algorithm = NMF_algorithm;
synergy_details.train.latent = nan(num_muscles, num_segments);
synergy_details.train.explained = nan(num_muscles, num_segments);
synergy_details.train.r2 = nan(num_muscles, num_segments);
synergy_details.train.r2slope = nan(num_muscles, num_segments);
synergy_details.test.latent = nan(num_muscles, num_segments);
synergy_details.test.explained = nan(num_muscles, num_segments);
synergy_details.test.r2 = nan(num_muscles, num_segments);
synergy_details.test.r2slope = nan(num_muscles, num_segments);

EMG_data_matrix = normalize(EMG_data_matrix, 'mean');

%% Perform NNMF to extract muscle synergies
for synergy_num = 1:num_muscles
    disp([num2str(synergy_num), '/', num2str(num_muscles), ' number of NMF'])

    % Initialize logical matrix for segment assignment
    segment_assignment = false(num_segments, num_samples);
    segment_length = floor(num_samples / num_segments);

    % Assign samples to each segment
    for segment_id = 1:num_segments
        start_idx = (segment_id - 1) * segment_length + 1;
        end_idx = segment_id * segment_length;
        segment_assignment(segment_id, start_idx:end_idx) = true;
    end
    
    % Perform k-fold cross-validation
    for segment_id = 1:num_segments
        disp([num2str(segment_id), '/', num2str(num_segments), ' k-fold cross-validation'])
        
        % Perform NNMF on train data
        train_data = EMG_data_matrix(:, ~segment_assignment(segment_id, :));
        train_data = normalize(train_data, 'mean');

        % Perform NNMF
        [train_W_data, train_H_data] = nnmf2(train_data, synergy_num, [], [], num_iterations, NMF_algorithm, 'wh', 'mean');

        % Reconstruct EMG from W & H
        reconstructed_train_data = train_W_data * train_H_data;

        extracted_synergies.train.W{synergy_num, segment_id} = train_W_data;
        extracted_synergies.train.H{synergy_num, segment_id} = train_H_data;

        % Calculate error between measured and reconstructed EMG
        error_matrix = reconstructed_train_data - train_data;

        % Calculate SSE and SST
        SSE = sum(reshape(error_matrix, numel(error_matrix), 1).^2);
        SST = sum((reshape(train_data, numel(train_data), 1) - mean(mean(train_data))).^2);
        sum_variance_between_EMG = sum(var(train_data, 1, 2));

        synergy_details.train.r2(synergy_num, segment_id) = 1 - SSE / SST;
        synergy_details.train.latent(synergy_num, segment_id) = sum(var(reconstructed_train_data, 1, 2));
        synergy_details.train.explained(synergy_num, segment_id) = synergy_details.train.latent(synergy_num, segment_id) / sum_variance_between_EMG;
      
        % Perform NNMF on test data
        test_data = EMG_data_matrix(:, segment_assignment(segment_id, :));
        test_data = normalize(test_data, 'mean');

        % Perform NNMF
        [test_W_data, test_H_data] = nnmf2(test_data, synergy_num, train_W_data, [], num_iterations, NMF_algorithm, 'wh', 'none');
        reconstructed_test_data = test_W_data * test_H_data;

        extracted_synergies.test.W{synergy_num, segment_id} = test_W_data;
        extracted_synergies.test.H{synergy_num, segment_id} = test_H_data;

        error_matrix = reconstructed_test_data - test_data;

        SSE = sum(reshape(error_matrix, numel(error_matrix), 1).^2);
        SST = sum((reshape(test_data, numel(test_data), 1) - mean(mean(test_data))).^2);
        sum_variance_between_EMG = sum(var(test_data, 1, 2));

        synergy_details.test.r2(synergy_num, segment_id) = 1 - SSE / SST;
        synergy_details.test.latent(synergy_num, segment_id) = sum(var(reconstructed_test_data, 1, 2));
        synergy_details.test.explained(synergy_num, segment_id) = synergy_details.test.latent(synergy_num, segment_id) / sum_variance_between_EMG;
    end
end
synergy_details.train.r2slope = [synergy_details.train.r2(1, :); diff(synergy_details.train.r2, 1, 1)];
synergy_details.test.r2slope = [synergy_details.test.r2(1, :); diff(synergy_details.test.r2, 1, 1)];
 
%% Perform the same process on shuffled data
if shuffle_enabled > 0
    synergy_details.shuffle.latent = nan(num_muscles, num_segments, shuffle_enabled);  
    synergy_details.shuffle.explained = nan(num_muscles, num_segments, shuffle_enabled);
    synergy_details.shuffle.r2 = nan(num_muscles, num_segments, shuffle_enabled);
    synergy_details.shuffle.r2slope = nan(num_muscles, num_segments, shuffle_enabled);
    
    for shuffle_idx = 1:shuffle_enabled
        disp(['shuffle: ', num2str(shuffle_idx), '/', num2str(shuffle_enabled)])
        shuffled_data = EMG_data_matrix;
        
        % Shuffle each EMG data
        for muscle_idx = 1:num_muscles
            shuffled_data(muscle_idx, :) = EMG_data_matrix(muscle_idx, randperm(num_samples));
        end
    
        for synergy_num = 1:num_muscles
            disp(['shuffle: ', num2str(synergy_num), '/', num2str(num_muscles)])
            
            % k-fold cross-validation
            segment_assignment = false(num_segments, num_samples);
            segment_length = floor(num_samples / num_segments);
            for segment_id = 1:num_segments
                start_idx = (segment_id - 1) * segment_length + 1;
                end_idx = segment_id * segment_length;
                segment_assignment(segment_id, start_idx:end_idx) = true;
            end
            
            for segment_id = 1:num_segments
                disp([num2str(segment_id), '/', num2str(num_segments), ' k-fold cross-validation'])
                
                % Train
                train_data = shuffled_data(:, ~segment_assignment(segment_id, :));
                train_data = normalize(train_data, 'mean');
                [shuffle_train_W_data] = nnmf2(train_data, synergy_num, [], [], num_iterations, NMF_algorithm, 'wh', 'mean');
                
                % Test
                test_data = shuffled_data(:, segment_assignment(segment_id, :));
                test_data = normalize(test_data, 'mean');
                [shuffle_test_W_data, shuffle_test_H_data] = nnmf2(test_data, synergy_num, shuffle_train_W_data, [], num_iterations, NMF_algorithm, 'h', 'none');
                reconstructed_test_data = shuffle_test_W_data * shuffle_test_H_data;
                error_matrix = reconstructed_test_data - test_data;
                SSE = sum(reshape(error_matrix, numel(error_matrix), 1).^2);
                SST = sum((reshape(test_data, numel(test_data), 1) - mean(mean(test_data))).^2);
                sum_variance_between_EMG = sum(var(test_data, 1, 2));

                synergy_details.shuffle.r2(synergy_num, segment_id, shuffle_idx) = 1 - SSE / SST;
                synergy_details.shuffle.latent(synergy_num, segment_id, shuffle_idx) = sum(var(reconstructed_test_data, 1, 2));
                synergy_details.shuffle.explained(synergy_num, segment_id, shuffle_idx) = synergy_details.shuffle.latent(synergy_num, segment_id, shuffle_idx) / sum_variance_between_EMG;
            end
        end
        synergy_details.shuffle.r2slope(:, :, shuffle_idx) = [synergy_details.shuffle.r2(1, :, shuffle_idx); diff(synergy_details.shuffle.r2(:, :, shuffle_idx), 1, 1)];
    end
end
