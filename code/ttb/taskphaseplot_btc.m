function viewcohtrig_btc

tppobj.rootpath    = datapath;
% temp        = dir(tppobj.rootpath);
% 
% tppobj.parentpath  = {};
% jj          = 1;
% for ii=1:length(temp)
%     if(temp(ii).isdir==1)
%         tppobj.parentpath{jj}  = temp(ii).name;
%         jj=jj+1;
%     end
% end
% tppobj.parentpath  = tppobj.parentpath(3:length(tppobj.parentpath));
tppobj.parentpath    = tppobj.rootpath;
% tppobj.selecpath   = [];
tppobj.filenames     = [];
tppobj.selectedfile  = [];


fig   =figure('Name','T-controller',...
   'NumberTitle','off',...
   'MenuBar','none',...
   'PaperOrientation','portrait',...
   'PaperPosition',[-2 4.91751 26.4382 19.8287],...%[-2.72314 4.91751 26.4382 19.8287]
   'PaperPositionMode','manual',...
   'PaperType','A4',...
   'Pointer','arrow',...
   'Resize','on',...
   'Units','pixels',...
   'UserData',[],...
   'Position',[247    22   448   903]);%[-922 37 448 903]
% tppobj.viewerfig     = figure('Name','T-viwer',...
%         'Numbertitle','off',...
%         'PaperUnits' ,'centimeters',...
%         'PaperOrientation' , 'landscape',...
%         'PaperPosition' , [-2.08175 -1.12758 33.8409 23.2392],...
%         'PaperPositionMode' , 'manual',...
%         'Units' , 'pixels',...
%         'Position' , [812    45   749   765],...
%         'ToolBar' , 'figure');
% h1  = uicontrol('BackgroundColor',[1 1 1],...
%    'Style','listbox',...
%    'HorizontalAlignment','center',...
%    'Units','normalized',...
%    'Position',[0.04 0.16 0.4 0.8],...
%    'Tag','pathList',...
%    'Max',1,...
%    'Min',0,...
%    'String',tppobj.parentpath,...
%    'Callback','tppobj=get(gcf,''UserData'');ind = get(gco,''Value''); tppobj.selecpath   = tppobj.parentpath{ind}; temp    = what([tppobj.rootpath,''\\'',tppobj.selecpath]);tppobj.filenames   = temp.mat; set(tppobj.h.filelist,''String'',tppobj.filenames);set(gcf,''UserData'',tppobj)');

h1  = uicontrol(fig,'BackgroundColor',[1 1 1],...
   'Style','listbox',...
   'HorizontalAlignment','center',...
   'Units','normalized',...
   'Position',[0.05 0.05 0.92 0.77],...
   'Tag','fileList',...
   'Max',0,...
   'Min',1,...
   'String','',...
   'Callback','tppobj=get(gcf,''UserData'');ind = get(gco,''Value''); filenames   = get(gco,''String'');tppobj.selectedfile =filenames{ind}; triggerind = get(tppobj.h.settrigger,''Value''); triggernames   = get(tppobj.h.settrigger,''String'');tppobj.selectedtrigger =triggernames{triggerind};taskphaseplot([tppobj.parentpath,''\'',tppobj.selectedfile]);set(gcf,''UserData'',tppobj)');


uicontrol(fig,'BackgroundColor',get(fig,'Color'),...
   'Style','pushbutton',...
   'Callback','tppobj=get(gcf,''UserData'');tppobj.parentpath=uigetdir(tppobj.parentpath);temp    = what(tppobj.parentpath);tppobj.filenames   = sort(temp.mat);set(tppobj.h.filelist,''String'',tppobj.filenames,''Value'',1);set(tppobj.h.textbox,''String'',tppobj.parentpath);set(gcf,''UserData'',tppobj)',...
   'HorizontalAlignment','center',...
   'Units','normalized',...
   'Position',[0.05 0.93 0.2 0.04],...
   'String','OpenDir');
h2 = uicontrol(fig,'BackgroundColor',get(fig,'Color'),...
   'Style','text',...
   'HorizontalAlignment','left',...
   'Units','normalized',...
   'Position',[0.3 0.93 0.6 0.04],...
   'String','Open Directory.');
h3 = uicontrol(fig,'BackgroundColor',[1 1 1],...
   'Style','Popupmenu',...
   'HorizontalAlignment','left',...
   'Units','normalized',...
   'Position',[0.7 0.85 0.2 0.04],...
   'String',{'GripOn';'EndHold';'Control'});
h4 = uicontrol(fig,'BackgroundColor',[1 1 1],...
    'Callback','tppobj=get(gcf,''UserData'');filt=get(tppobj.h.filtbox,''String'');files=strfilt(tppobj.filenames,filt);set(tppobj.h.filelist,''String'',files,''Value'',1);',...
   'Max',1,...
   'Min',0,...
   'Style','Edit',...
   'HorizontalAlignment','left',...
   'Units','normalized',...
   'Position',[0.3 0.86 0.3 0.03],...
   'String',[]);
h5 = uicontrol(fig,'BackgroundColor',get(fig,'Color'),...
   'Style','checkbox',...
   'HorizontalAlignment','left',...
   'Units','normalized',...
   'Position',[0.2 0.86 0.1 0.03],...
   'String','Filter');


% tppobj.h.pathlist    = h1;
tppobj.h.filelist    = h1;
tppobj.h.textbox     = h2;
tppobj.h.settrigger  = h3;
tppobj.h.filtbox     = h4;
set(fig,'UserData',tppobj);