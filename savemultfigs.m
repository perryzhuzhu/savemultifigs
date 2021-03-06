function varargout = savemultfigs(varargin)
% SAVEMULTFIGS is a simple GUI that allows to easily and quickly save 
% multiple figures in several formats in just a few clicks!
%
%  Original Version Author: Nicolas Beuchat, EPFL/HMS
%         nicolas.beuchat [at] gmail.com
% Creation date: 2-14-2012
% Last update:   2-17-2012
%
% Modified Version Authour: Yang Liu, Xi'an Jiaotong Univeristy
% Creation date: 12-16-2017
% Last update: 06-11-2018
%      
% TO-DO:
%   - Ask user if erase existing figures
%   - Default filename = title
%   - Clean code (remove unnecessary callbacks)
%   - Options to saveas (another window. Ex: resolution, etc.)
%   - Load figures directly from gui (to save in different formats)
%   - Problematic display in Mac OS X
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help savemultfigs

% Last Modified by GUIDE v2.5 12-Jun-2018 01:23:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @savemultfigs_OpeningFcn, ...
                   'gui_OutputFcn',  @savemultfigs_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before savemultfigs is made visible.
function savemultfigs_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to savemultfigs (see VARARGIN)

% Choose default command line output for savemultfigs
handles.output = hObject;

% UIWAIT makes savemultfigs wait for user response (see UIRESUME)
% uiwait(handles.figureSavemultifigs);

% Create checkbox and edit object for each opened figure
parentPanel = findobj(hObject,'Tag','uipanelFiles');
figlist = findall(0,'Type','fig');
figlist(figlist == hObject) = [];
%
% work for version<Matlab2014b
% figlist = sort(figlist,'ascend');
%
% https://ww2.mathworks.cn/matlabcentral/fileexchange/49718-sort-figure-handles
% work for version>=Matlab2014b
figlist = sortfighandlearray(figlist,'ascend');
if length(figlist)==0
    figlistnumber=[];
else
    figlistnumber=[figlist.Number];
end

% Read Config file
cfg_filename = 'multifigs.ini';
cfg_filepath = fullfile(getSavemultifigsPath(),cfg_filename);
handles.cfg_filepath = cfg_filepath;
ini = IniConfig();
if exist(cfg_filepath,'file')
    ini.ReadFile(cfg_filepath);
    % obtain attributes from ini file
    filetype = strsplit(ini.GetValues('basic','filetype'));
    pn = ini.GetValues('basic','outdir');
    saveinsubdir = ini.GetValues('basic','subdir'); 
    saveConfig = ini.GetValues('basic','savecfg'); 
    % set uicontrols' attributes accordingly
    child = get(findobj('Tag','uipanelFigType'),'children');
    for i=1:length(child)
        set(child(i),'Value',0)
        for j=1:length(filetype)
            if strcmp(get(child(i),'String'), filetype{j})
                set(child(i),'Value',1)
%                 sprintf(['matched ' get(child(i),'String') '&' filetype{j}])
            elseif strcmp(get(child(i),'String'),'eps') && strcmp(filetype{j},'epsc')
                set(child(i),'Value',1)
%                 sprintf(['matched ' get(child(i),'String') '&' filetype{j}])
            else
%                 sprintf(['unmatched ' get(child(i),'String') '&' filetype{j}])
            end
        end
    end
    set(findobj(hObject,'Tag','editOutputDir'),'String',pn);
    set(findobj(hObject,'Tag','checkboxDirType'),'Value',saveinsubdir);
    set(findobj(hObject,'Tag','checkboxSaveConfig'),'Value',saveConfig);
    
    
end



% Default value of parameters
defaultfilename = 'filename';
handles.defaultfilename = defaultfilename;
handles.figlist = figlist;
handles.figlistnumber = figlistnumber;
handles.parentPanel = parentPanel;
handles.rootFig = hObject;
handles.numberFig   = length(figlist);
handles.maxFigPerPage = 12;
handles.currentPage = 1;
handles.numberPage  = ceil(handles.numberFig / handles.maxFigPerPage);

% Set some of the objects properties/values
handles.visibleFig = ones(1,handles.numberFig);
if handles.numberFig > handles.maxFigPerPage + 1
    set(findobj('Tag','sliderPageNumber'),'Value',handles.currentPage,...
        'Max',handles.numberPage,'SliderStep', [1/(handles.numberPage-1) , 1/(handles.numberPage-1)],...
        'Visible','on')
    set(findobj('Tag','textPageNumber'),'Visible','on',...
        'String',[num2str(handles.currentPage) '/' num2str(handles.numberPage)])
    
    handles.visibleFig((handles.maxFigPerPage+1):handles.numberFig) = 0;
else
    set(findobj('Tag','sliderPageNumber'),'Visible','off')
    set(findobj('Tag','textPageNumber'),'Visible','off')
end

% Chose a default filename based on name of figure
defaultfilenames=cell(length(figlist),1); 
for i=1:length(figlist) 
    if isempty(get(figlist(i),'Name')) 
        defaultfilenames{i} = [defaultfilename num2str(figlist(i).Number)]; 
    else 
        defaultfilenames{i} = get(figlist(i),'Name'); 
    end 
end

% Display panel with figures name
for i=1:length(figlist)
    if handles.numberFig > handles.maxFigPerPage + 1
        j = mod(i-1,handles.maxFigPerPage) + 1;
    else
        j = i;
    end
    
    visible = {'off','on'};
    % position origin:left bottom.
    % position: [towardsright towardstop width height]
    PosTopMax=330;
    uicontrol('parent',parentPanel,'Style','checkbox',...
        'String',['Figure ' num2str(figlist(i).Number)],...
        'Position',[12 PosTopMax-25*(j-1) 100 20],...
        'Value',1.0,...
        'Tag',['checkboxFigure' num2str(figlist(i).Number)],...
        'Callback',@checkboxFigure_Callback,...
        'Visible',visible{1+handles.visibleFig(i)})
    uicontrol('parent',parentPanel,'Style','edit',...
        'String',[defaultfilenames{i}],...
        'Position',[88 PosTopMax-25*(j-1) 300 20],...
        'Tag',['editFigure' num2str(figlist(i).Number)],...
        'Callback',@editFigure_Callback,...
        'Visible',visible{1+handles.visibleFig(i)})
end

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = savemultfigs_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes during object creation, after setting all properties.
function editOutputDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOutputDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonBrowse.
function pushbuttonBrowse_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonBrowse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pathname = uigetdir;
if pathname ~= 0
    set(findobj('Tag','editOutputDir'),'String',pathname);
end



% --- Executes on button press in pushbuttonSave.
function pushbuttonSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

filetype = {};
j = 0;
child = get(findobj('Tag','uipanelFigType'),'children');
for i=1:length(child)
    if get(child(i),'Value')
        j = j + 1;
        filetype{j} = get(child(i),'String');
        if strcmp(filetype{j},'eps')
            filetype{j}='epsc';
        end
        
    end
end

if isempty(filetype)
    errordlg('No format selected! Aborted.')
    return
end

pn = get(findobj('Tag','editOutputDir'),'String');
saveinsubdir = get(findobj('Tag','checkboxDirType'),'Value');
if ~isdir(pn)
    opt = questdlg('Specified directory is not a directory! Create new directory here?');
    if strcmp(opt, 'Yes')
        status = mkdir(pn);
        if ~status
            errordlg('Creating new directory failed!')
            return
        end
    else
        errordlg('Specified directory is not a directory!\nSave operation failed!')
        return
    end
end
if saveinsubdir
    for j=1:length(filetype)
        if ~isdir(fullfile(pn,filetype{j}))
            mkdir(fullfile(pn,filetype{j}))
        end
    end
end

% Check for double names
n = 0;
strname = cell(0);
% errstr = cell(0);
for i=1:handles.numberFig
    dosave = get(findobj('Tag',['checkboxFigure' num2str(handles.figlist(i).Number)]),'Value');
    if dosave
        n = n+1;
        fn = get(findobj('Tag',['editFigure' num2str(handles.figlist(i).Number)]),'String');
        strname{n} = fn;
        ind(n) = i;
%         if ~isempty(ind)
%             errstr{k} = [fn ' is already used (Fig. )'];
%         end
    end
end

errstr{1} = '';
k = 1;
for i=1:n
    indrep = find(strcmp(strname{i},strname));
    if length(indrep) > 1
        k = k+1;
        errstr{k} = [strname{i} ' was used ' num2str(length(indrep)) ' times. Renamed to ' strname{i} '_#'];
        for j=1:length(indrep)
            strname{indrep(j)} = strcat(strname{indrep(j)},'_',num2str(j));
        end
    end
end


% Save figures
for i=1:n
    for j=1:length(filetype)
        fn = strname{i};
        if saveinsubdir
            saveas(handles.figlist(ind(i)),fullfile(pn,filetype{j},fn),filetype{j})
        else
            saveas(handles.figlist(ind(i)),fullfile(pn,fn),filetype{j})
        end
    end
end
nfigsave = n;

% nfigsave = 0;
% for i=1:handles.numberFig
%     dosave = get(findobj('Tag',['checkboxFigure' num2str(handles.figlist(i).Number)]),'Value');
%     if dosave
%         for j=1:length(filetype)
%             fn = get(findobj('Tag',['editFigure' num2str(handles.figlist(i).Number)]),'String');
%             if saveinsubdir
%                 saveas(handles.figlist(i),fullfile(pn,filetype{j},fn),filetype{j})
%             else
%                 saveas(handles.figlist(i),fullfile(pn,fn),filetype{j})
%             end
%         end
%         nfigsave = nfigsave + 1;
%     end
% end

msgbox([{[num2str(nfigsave) ' figures saved in ' num2str(length(filetype)) ' different formats'],...
    '','(Pressing ok will not close the GUI)'},errstr]);

% --- Executes on button press in pushbuttonAbout.
function pushbuttonAbout_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAbout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({'Save Multiple Figure','','Created by:','Nicolas Beuchat',...
    'EPFL/HMS','','February 14th 2012','Version 1.0',...
    '','Modified by:','Yang Liu','XJTU','','2018','Version 2.0'},'About','help')


% --- Executes on slider movement.
function sliderPageNumber_Callback(hObject, eventdata, handles)
% hObject    handle to sliderPageNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% round slider value
Value = round(get(hObject, 'Value'));
set(hObject, 'Value', Value);

handles.currentPage = Value;



handles.visibleFig = zeros(1,handles.numberFig);
handles.visibleFig(((handles.currentPage-1)*handles.maxFigPerPage+1):min(handles.currentPage*handles.maxFigPerPage,handles.numberFig)) = 1;

for i=1:handles.numberFig
    j = mod(i-1,handles.maxFigPerPage) + 1;
    
    visible = {'off','on'};
    Tag1 = ['checkboxFigure' num2str(handles.figlistnumber(i))];
    Tag2 = ['editFigure' num2str(handles.figlistnumber(i))];
    set(findobj('Tag',Tag1),'Visible',visible{1+handles.visibleFig(i)})
    set(findobj('Tag',Tag2),'Visible',visible{1+handles.visibleFig(i)})
end

set(findobj('Tag','textPageNumber'),...
    'String',[num2str(handles.currentPage) '/' num2str(handles.numberPage)])

% Update handles structure
guidata(hObject, handles);

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function sliderPageNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderPageNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



% --- Executes on button press in pushbuttonSelectAll.
function pushbuttonSelectAll_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSelectAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
for i=1:length(handles.figlist) 
	set(findobj('Tag',['checkboxFigure' num2str(handles.figlist(i).Number)]),...
		'Value',1)
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in pushbuttonUnselectAll.
function pushbuttonUnselectAll_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUnselectAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
for i=1:length(handles.figlist) 
	set(findobj('Tag',['checkboxFigure' num2str(handles.figlist(i).Number)]),...
		'Value',0)
end
% Update handles structure
guidata(hObject, handles);

function editFigure_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxFig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOutputDir as text
%        str2double(get(hObject,'String')) returns contents of editOutputDir as a double


% --- Executes on button press in pushbuttonRefreshFigs.
function pushbuttonRefreshFigs_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRefreshFigs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% clear old checkboxFigure and editFigure
for i=1:length(handles.figlistnumber)
    Tag1 = ['checkboxFigure' num2str(handles.figlistnumber(i))];
    Tag2 = ['editFigure' num2str(handles.figlistnumber(i))];
    delete(findobj('Tag',Tag1))
    delete(findobj('Tag',Tag2))
end

% refind all figs
figlist = findall(0,'Type','fig');
figlist(figlist == handles.rootFig) = [];
figlist = sortfighandlearray(figlist,'ascend');
if length(figlist)==0
    figlistnumber=[];
else
    figlistnumber=[figlist.Number];
end

% Reset default value of parameters
% handles.defaultfilename = get(findobj('Tag','editFilename'),'String');
handles.figlist = figlist;
handles.figlistnumber = figlistnumber;
handles.numberFig   = length(figlist);
handles.maxFigPerPage = 13;
handles.currentPage = 1;
handles.numberPage  = ceil(handles.numberFig / handles.maxFigPerPage);

% Set some of the objects properties/values
handles.visibleFig = ones(1,handles.numberFig);
if handles.numberFig > handles.maxFigPerPage + 1
    set(findobj('Tag','sliderPageNumber'),'Value',handles.currentPage,...
        'Max',handles.numberPage,'SliderStep', [1/(handles.numberPage-1) , 1/(handles.numberPage-1)],...
        'Visible','on')
    set(findobj('Tag','textPageNumber'),'Visible','on',...
        'String',[num2str(handles.currentPage) '/' num2str(handles.numberPage)])
    
    handles.visibleFig((handles.maxFigPerPage+1):handles.numberFig) = 0;
else
    set(findobj('Tag','sliderPageNumber'),'Visible','off')
    set(findobj('Tag','textPageNumber'),'Visible','off')
end

% Chose a default filename based on name of figure
defaultfilenames=cell(length(figlist),1); 
for i=1:length(figlist) 
    if isempty(get(figlist(i),'Name')) 
        defaultfilenames{i} = [handles.defaultfilename num2str(figlist(i).Number)]; 
    else 
        defaultfilenames{i} = get(figlist(i),'Name'); 
    end 
end

% Display panel with figures name
for i=1:length(figlist)
    if handles.numberFig > handles.maxFigPerPage + 1
        j = mod(i-1,handles.maxFigPerPage) + 1;
    else
        j = i;
    end
    
    visible = {'off','on'};
    
    % position origin:left bottom.
    % position: [towardsright towardstop width height]  
    uicontrol('Parent', handles.parentPanel,'Style','checkbox',...
        'String',['Figure ' num2str(figlist(i).Number)],...
        'Position',[12 370-25*(j-1) 100 20],...
        'Value',1.0,...
        'Tag',['checkboxFigure' num2str(figlist(i).Number)],...
        'Callback',@checkboxFigure_Callback,...
        'Visible',visible{1+handles.visibleFig(i)})
    uicontrol('Parent', handles.parentPanel,'Style','edit',...
        'String',[defaultfilenames{i}],...
        'Position',[88 370-25*(j-1) 300 20],...
        'Tag',['editFigure' num2str(figlist(i).Number)],...
        'Callback',@editFigure_Callback,...
        'Visible',visible{1+handles.visibleFig(i)})
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in checkboxFigureX.
function checkboxFigure_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxFig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxFig


function editFilename_Callback(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFilename as text
%        str2double(get(hObject,'String')) returns contents of editFilename as a double
handles.defaultfilename=get(hObject,'String');
% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editFilename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonUpdateSelected.
function pushbuttonUpdateSelected_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUpdateSelected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% handles.defaultfilename = get(findobj('Tag','editFilename'),'String');
for i=1:length(handles.figlistnumber)
    Tag1 = ['checkboxFigure' num2str(handles.figlistnumber(i))];
    Tag2 = ['editFigure' num2str(handles.figlistnumber(i))];
    if get(findobj('Tag',Tag1),'Value')==1
        set(findobj('Tag',Tag2),'String',[handles.defaultfilename num2str(handles.figlistnumber(i))])
    end
end

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in pushbuttonUpdateAll.
function pushbuttonUpdateAll_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUpdateAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% handles.defaultfilename = get(findobj('Tag','editFilename'),'String');
for i=1:length(handles.figlistnumber)
    Tag1 = ['checkboxFigure' num2str(handles.figlistnumber(i))];
    Tag2 = ['editFigure' num2str(handles.figlistnumber(i))];
%     if(findobj('Tag',Tag1))
    set(findobj('Tag',Tag2),'String',[handles.defaultfilename num2str(handles.figlistnumber(i))])
end

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in checkboxSaveConfig.
function checkboxSaveConfig_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSaveConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSaveConfig
handles.saveConfig = get(hObject,'Value');
% Update handles structure
guidata(hObject, handles);

% --- Executes when user attempts to close figureSavemultifigs.
function figureSavemultifigs_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figureSavemultifigs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% file format to save
filetype = {};
j = 0;
child = get(findobj('Tag','uipanelFigType'),'children');
for i=1:length(child)
    if get(child(i),'Value')
        j = j + 1;
        filetype{j} = get(child(i),'String');
        if strcmp(filetype{j},'eps')
            filetype{j}='epsc';
        end
        
    end
end
% output directory
pn = get(findobj('Tag','editOutputDir'),'String');
% save in sub directory
saveinsubdir = get(findobj('Tag','checkboxDirType'),'Value');
% save figs
saveConfig = get(findobj(hObject,'Tag','checkboxSaveConfig'),'Value');



% Hint: delete(hObject) closes the figure
delete(hObject);

if saveConfig
    % save config to file
    ini = IniConfig();
    ini.AddSections('basic');
    ini.AddKeys('basic','filetype',strjoin(filetype));
    ini.AddKeys('basic','outdir',pn);
    ini.AddKeys('basic','subdir',saveinsubdir); 
    ini.AddKeys('basic','savecfg',saveConfig); 
    ini.WriteFile(handles.cfg_filepath);
end
