function varargout = maindalta(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @untitled1_OpeningFcn, ...
                   'gui_OutputFcn',  @untitled1_OutputFcn, ...
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


% --- Executes just before untitled1 is made visible.
function untitled1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to untitled1 (see VARARGIN)

% Choose default command line output for untitled1
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes untitled1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = untitled1_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
global a;
handles.text7.String = 'Frame t';
handles.text6.String = 'Threshold c';
handles.text2.String = 'image f';
set(handles.edit1,'string',num2str(get(hObject,'value')));

dalta = get(handles.slider1,'Value');

[I,blur,et,newEt] = generalclean(dalta);
imshow(blur,'Parent',handles.axes1)
imshow(mat2gray(newEt),'Parent',handles.axes2)
imshow((I),'Parent',handles.axes3)

ts = get(handles.slider3,'Value');
[It,et] = reconstructAvideo(dalta,ts);
%  
imshow((It),'Parent',handles.axes4) 
guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit1_Callback(hObject, eventdata, handles)

global a;
handles.text7.String = 'Frame t';
handles.text6.String = 'Threshold c';
handles.text2.String = 'image f';
set(handles.slider1,'value',str2double(get(hObject,'string')));
sliderValue = get(handles.edit1,'String');
ang = str2double(sliderValue);
set(handles.slider1,'Value',ang);

dalta = get(handles.slider1,'Value');

[I,blur,et,newEt] = generalclean(dalta);
imshow(blur,'Parent',handles.axes1)
imshow(mat2gray(newEt),'Parent',handles.axes2)
imshow((I),'Parent',handles.axes3)


ts = get(handles.slider3,'Value');
[It,et] = reconstructAvideo(dalta,ts);
%  
imshow((It),'Parent',handles.axes4) 
guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% 
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on slider movement.
function slider3_Callback(hObject, eventdata, handles)
global b;
handles.text7.String = 'Frame t';
handles.text6.String = 'Threshold c';
handles.text2.String = 'image f';
set(handles.edit2,'string',num2str(get(hObject,'value')));
dalta = get(handles.slider1,'Value');
ts = get(handles.slider3,'Value');
[It,Et] = reconstructAvideo(dalta,ts);%_old

imshow(mat2gray((Et)),'Parent',handles.axes2)
imshow(((It)),'Parent',handles.axes4)



% --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit2_Callback(hObject, eventdata, handles)
global b;
handles.text7.String = 'Frame t';
handles.text6.String = 'Threshold c';
handles.text2.String = 'image f';
set(handles.slider3,'value',str2double(get(hObject,'string')));
sliderValue = get(handles.edit2,'String');
ang = str2double(sliderValue);
set(handles.slider3,'Value',ang);

dalta = get(handles.slider1,'Value');
ts = get(handles.slider3,'Value');
[It,Et] = reconstructAvideo(dalta,ts);%_old

imshow(mat2gray((Et)),'Parent',handles.axes2)
imshow(((It)),'Parent',handles.axes4)



% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
 
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
