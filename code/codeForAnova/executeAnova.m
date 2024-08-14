function [tbl, p_value_array, stats_struct] = executeAnova(examined_data, label_array, test_type, synergy_id, test_type_for_comprehensive_test)
switch test_type
    case 'one-way-anova'
        [p, tbl] = anova1(examined_data, label_array, 'off');
    
        % create table from result(tbl)
        result_data_array = tbl(2:end, 2:end);
        rowNames = {'Group', 'Error', 'Total'};
        colNames = tbl (1, 2:end);
        colNames{end} = 'Prob>F';
        tbl = array2table(result_data_array, 'RowNames',rowNames, 'VariableNames',colNames);
        disp(['Synergy' num2str(synergy_id) ' p-value:' num2str(p)]);
    case 'muscle-one-way-anova'
        [~, muscle_num] = size(examined_data);
        p_value_array = zeros(1, muscle_num);
        for muscle_id = 1:muscle_num
            ref_examined_data = examined_data(:, muscle_id);
            [p, ~] = anova1(ref_examined_data, label_array, 'off');
            p_value_array(muscle_id) = p;
        end
        p = [];
        tbl = [];
    case  'two-way-anova'
        [p, tbl] = anovan(examined_data, {label_array.session_group, label_array.muscle_group}, "model","interaction","varnames",{'s_group', 'm_group'});
        tbl = array2table(tbl);
        disp(['Synergy' num2str(synergy_id) ' p-value(session_group main-effect):' num2str(p(1))]);
        disp(['Synergy' num2str(synergy_id) ' p-value(muscle_group main-effect):' num2str(p(2))]);
        disp(['Synergy' num2str(synergy_id) ' p-value(interaction):' num2str(p(3))]);
    case 'MANOVA'
        data_table = array2table(examined_data, 'VariableNames', label_array.muscle_group);
        data_table.Session = label_array.session_group;
        % Creating Strings for Formulating Dependent and Independent Variables
        formula_string = [data_table.Properties.VariableNames{1} '-' data_table.Properties.VariableNames{end-1} ' ~ Session'];
        
        % Creating an iterative measurement model
        rm = fitrm(data_table, formula_string);
        tbl = manova(rm);
        p = tbl.pValue(7);
        disp(['Synergy' num2str(synergy_id) ' p-value(Hotelling-test):' num2str(p)]);
    case 'comprehensive_test'
        %{
            交互作用は考慮していないことに注意
        %}
        switch test_type_for_comprehensive_test
            case 'friedman'
                testFunction = @friedman;
            case 'two-way-anova'
                testFunction = @anova2;
        end
        [p_session, session_tbl, session_stats] = testFunction(examined_data.session_effect, 1, 'off');
        [p_synergy, synergy_tbl, synergy_stats] = testFunction(examined_data.synergy_effect, 1, 'off');
        
        if strcmp(test_type_for_comprehensive_test, 'two-way-anova')
            p_synergy = p_session(2);
            p_session = p_session(1);
        end

        % make tables
        switch test_type_for_comprehensive_test
            case 'friedman'
                session_static_result = session_tbl(2:end, 2:end);
                synergy_static_result = synergy_tbl(2:end, 2:end);
                output_tbl = [session_static_result; synergy_static_result];
                rowNames = {'Sessions', 'Error(Sessions)', 'Total(Sessions)', 'Synergies', 'Error(Synergies)', 'Total(Synergies)' };
                colNames = session_tbl (1, 2:end);
                colNames{end-1} = 'chi square';
                colNames{end} = 'Prob>F';
            case 'two-way-anova'
                output_tbl = session_tbl(2:end, 2:end);
                rowNames = {'Sessions', 'Synergies', 'Error', 'Total' };
                colNames = session_tbl (1, 2:end);
                colNames{end} = 'Prob>F';
        end
        tbl = array2table(output_tbl, 'RowNames',rowNames, 'VariableNames',colNames);

        % display result
        disp(['Synergy' num2str(synergy_id) ' control p-value(between sessions, main-effect):' num2str(p_session)]);
        disp(['Synergy' num2str(synergy_id) ' control p-value(between synergies, main-effect):' num2str(p_synergy)]);

        % compile data of stats (ouput of friedman)
        hasSigDiff_session = 0;
        hasSigDiff_synergy = 0;
        if  p_session < 0.05
            hasSigDiff_session = 1;
        end
        if  p_synergy < 0.05
            hasSigDiff_synergy = 1;
        end
        stats_struct = struct();
        stats_struct.session.stats = session_stats;
        stats_struct.session.hasSigDiff = hasSigDiff_session;
        stats_struct.synergy.stats = synergy_stats;
        stats_struct.synergy.hasSigDiff = hasSigDiff_synergy;
end

if not(exist("p_value_array", "var"))
    p_value_array = [];
end
if not(exist("stats_struct", "var"))
    stats_struct = [];
end
end