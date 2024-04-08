function getspike_figure


fig = figure;
set(fig,'Pointer','fullcrosshair',...
    'Tag','gsdisplay',...
    'Toolbar','Figure');


h1  = subplot(6,1,1);
set(h1,'Tag','spike');

h2  = subplot(6,1,2:5);
set(h2,'Tag','unit');


linkaxes([h1,h2],'x');


h   = uicontrol('Unit','Normalized',...
    'Callback','getspike(''load'')',...
    'Position',[0.20 0.05 0.1 0.1],...
    'String','Load',...
    'Style','Pushbutton',...
    'Tag','loadbutton');

h   = uicontrol('Unit','Normalized',...
    'Callback','getspike(''save'')',...
    'Position',[0.35 0.05 0.1 0.1],...
    'String','Save',...
    'Style','Pushbutton',...
    'Tag','savebutton');

h   = uicontrol('Unit','Normalized',...
    'Callback','getspike(''scope'')',...
    'Position',[0.60 0.05 0.1 0.1],...
    'String','Scope',...
    'Style','Pushbutton',...
    'Tag','scopebutton');

h   = uicontrol('Unit','Normalized',...
    'Callback','',...
    'Position',[0.72 0.05 0.15 0.05],...
    'String','Threshold',...
    'Style','Edit',...
    'Tag','Threshold_value');

h   = uicontrol('Unit','Normalized',...
    'Callback','',...
    'Position',[0.72 0.1 0.07 0.05],...
    'String','A',...
    'Style','RadioButton',...
    'Tag','RB_Rising',...
    'Value',1);

h   = uicontrol('Unit','Normalized',...
    'Callback','',...
    'Position',[0.80 0.1 0.07 0.05],...
    'String','V',...
    'Style','RadioButton',...
    'Tag','RB_Falling',...
    'Value',0);


