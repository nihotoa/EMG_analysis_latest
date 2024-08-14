function [examined_data, label_array, cosine_distance_list] = AnovaPreparation(main_structure, synergy_id, test_type)
% common processes
session_group_num = length(fieldnames(main_structure));
examined_data = cell(session_group_num, 1);

% devide processes for each test_type
switch test_type
    case 'one-way-anova'
        label_array = {};
        for session_group_id = 1:session_group_num
            group_name = ['group' num2str(session_group_id)];
            ref_group_structure = main_structure.(group_name);
            ref_data = ref_group_structure.WDaySynergy{synergy_id};
            [EMG_num, session_num] = size(ref_data);
            label_num = EMG_num * session_num;
            examined_data{session_group_id} = reshape(ref_data, [], 1); 
            label_array = [label_array; repmat({ref_group_structure.session_group}, label_num, 1)];
        end
        examined_data = cell2mat(examined_data);
    case 'muscle-one-way-anova'
        label_array = {};
        for session_group_id = 1:session_group_num
            group_name = ['group' num2str(session_group_id)];
            ref_group_structure = main_structure.(group_name);
            ref_data = ref_group_structure.WDaySynergy{synergy_id};
            examined_data{session_group_id} = transpose(ref_data);
            label_array = [label_array; repmat({ref_group_structure.session_group}, ref_group_structure.session_num, 1)];
        end
        examined_data = cell2mat(examined_data);
    case 'two-way-anova'
        label_array = struct();
        label_array.session_group = [];
        label_array.muscle_group = [];
        for session_group_id = 1:session_group_num
            group_name = ['group' num2str(session_group_id)];
            ref_group_structure = main_structure.(group_name);
            ref_data = ref_group_structure.WDaySynergy{synergy_id};
            [EMG_num, session_num] = size(ref_data);
            label_num = EMG_num * session_num;
            examined_data{session_group_id} = reshape(ref_data, [], 1); 
            label_array.session_group = [label_array.session_group; repmat({ref_group_structure.session_group}, label_num, 1)];
            label_array.muscle_group = [label_array.muscle_group, repmat(ref_group_structure.x, 1, session_num)];
        end
        examined_data = cell2mat(examined_data);
        label_array.muscle_group = cellstr(transpose(label_array.muscle_group));
    case 'MANOVA'
        label_array = struct();
        label_array.session_group = [];
        label_array.muscle_group = [];
        for session_group_id = 1:session_group_num
            group_name = ['group' num2str(session_group_id)];
            ref_group_structure = main_structure.(group_name);
            ref_data = ref_group_structure.WDaySynergy{synergy_id};            
            examined_data{session_group_id} = transpose(ref_data);
            label_array.session_group = [label_array.session_group; repmat({ref_group_structure.session_group}, ref_group_structure.session_num, 1)];
        end
        examined_data = cell2mat(examined_data);
        label_array.muscle_group = cellstr(ref_group_structure.x);
    case 'comprehensive_test'
        %{
        注意: pre, postの2セッショングループのみしか考慮していないので、セッションをもっと増やしたい場合は改善が必要
        %}
        label_array = {};
        field_name_list = fieldnames(main_structure);

        % Extract synergies
        synergy_data_list = cell(1, session_group_num);
        for session_group_id = 1:session_group_num
            ref_group_structure = main_structure.(field_name_list{session_group_id});
            ref_synergy_data = ref_group_structure.WDaySynergy;

            % if ref_sssessiong is correspond to 'pre' session, average value of the synergy which is correspod to 'synergy_id' is adopted (as reference)
            if session_group_id == 1
                ref_synergy_data = mean(ref_synergy_data{synergy_id}, 2);
            end
            synergy_data_list{session_group_id} = ref_synergy_data;
        end

        % calcurate cosine distance between 'control_synergy' vs all other synergy combinations
        control_synergy = synergy_data_list{1};
        all_cosine_distance_list = cell(1, session_group_num-1) ;
        for session_group_id = 2:session_group_num
            % pick up necessary data
            ref_group_params = struct();
            ref_group_structure = main_structure.(field_name_list{session_group_id});
            ref_group_params.session_num = ref_group_structure.session_num;
            ref_synergy_data = synergy_data_list{session_group_id};
            ref_group_params.synergy_num = length(ref_synergy_data);

            % create  empty list to store the result
            cosine_distance_list = zeros(ref_group_params.synergy_num, ref_group_params.session_num);
            
            % calcurate cosine distance for all combination
            for compare_synergy_id = 1:ref_group_params.synergy_num
                for compare_session_id = 1:ref_group_params.session_num
                    ref_synergy = ref_synergy_data{compare_synergy_id}(:, compare_session_id);
                    cosine_distance_value = 1 - ((dot(control_synergy, ref_synergy)) / (norm(control_synergy) * norm(ref_synergy)));
                    cosine_distance_list(compare_synergy_id, compare_session_id) = cosine_distance_value;
                end
            end
            all_cosine_distance_list{session_group_id-1} = cosine_distance_list;
        end
        
        % create examined, data & label_id
        examined_data = struct();
        examined_data.session_effect = cell(1,session_group_num-1);
        examined_data.synergy_effect = cell(1,session_group_num-1);
        for session_group_id = 2:session_group_num
            examined_data.session_effect = all_cosine_distance_list{session_group_id-1};
            examined_data.synergy_effect = transpose(all_cosine_distance_list{session_group_id-1});
        end
end
if not(exist("cosine_distance_list", "var"))
    cosine_distance_list = [];
end
end