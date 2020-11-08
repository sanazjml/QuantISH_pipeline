function varargout = Spot_Cut_Gui(varargin)
% SPOT_CUT_GUI MATLAB code for Spot_Cut_Gui.fig
%      SPOT_CUT_GUI, by itself, creates a new SPOT_CUT_GUI or raises the existing
%      singleton*.
%
%      H = SPOT_CUT_GUI returns the handle to a new SPOT_CUT_GUI or the handle to
%      the existing singleton*.
%
%      SPOT_CUT_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPOT_CUT_GUI.M with the given input arguments.
%
%      SPOT_CUT_GUI('Property','Value',...) creates a new SPOT_CUT_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Spot_Cut_Gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Spot_Cut_Gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Spot_Cut_Gui

% Last Modified by GUIDE v2.5 12-Aug-2019 10:06:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Spot_Cut_Gui_OpeningFcn, ...
    'gui_OutputFcn',  @Spot_Cut_Gui_OutputFcn, ...
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


% --- Executes just before Spot_Cut_Gui is made visible.
function Spot_Cut_Gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Spot_Cut_Gui (see VARARGIN)

% Choose default command line output for Spot_Cut_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
% UIWAIT makes Spot_Cut_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);
setappdata(0  , 'GUI_IM', gcf);
setappdata(gcf, 'i'      , 1);


% --- Outputs from this function are returned to the command line.
function varargout = Spot_Cut_Gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Create the initial image to plot.
%Initial image
path=pwd;
I=imread([path filesep 'Cover.png']);
imshow(I)

%Variable initialization
handles.add_rect_bound_info={};
handles.rem_rect_bound_info={};
handles.add_Img_num=[];
handles.rem_Img_num=[];

guidata(hObject,handles);
% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in Start.
function LoadDir_Callback(hObject, eventdata, handles)
% hObject    handle to LoadDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%Import GUI_IM data
GUI_IM = getappdata(0, 'GUI_IM');
%Load the variable from workspace regarding the thumbnails spots
File=load('tmp_summaries');
 mat_coord = File.mat_coord;
File = File.all_summaries;

%Control for the "Next" and "Prev" button
if  iscell(File)
    k = max(size(File));
else
    k = 1;
    FileName={File};%Change String to string Array if select single file
end
%Set of data
setappdata(GUI_IM, 'File', File);
setappdata(GUI_IM, 'k', k);
setappdata(GUI_IM, 'mat_coord', mat_coord ) ;

%Clock pointer during the loading
set(handles.figure1, 'pointer', 'watch')
drawnow;
UpdateAxes; %function used to visualize the images  in the GUI
set(handles.figure1, 'pointer', 'arrow')

%Function for visualize the image
function UpdateAxes
%Import values
GUI_IM = getappdata(0, 'GUI_IM');
File = getappdata(GUI_IM, 'File');
i = getappdata(GUI_IM, 'i');

%Read of the thumbnails image
IM = File{i};

%Reset axes dimensions
cla reset
%Show the image
imshow(IM);
mat_coord = getappdata(GUI_IM, 'mat_coord');
%set( gca, 'XLim', mat_coord([1,2]), 'YLim', mat_coord([3,4]));


% --- Executes on button press in StartRect.
function StartRect_Callback(hObject, eventdata, handles)
% hObject    handle to StartRect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Import values
GUI_IM = getappdata(0, 'GUI_IM');
i = getappdata(GUI_IM, 'i');

pos=[];

handles = guidata(hObject);
h = drawrectangle(gca,'StripeColor','r'); %Allow to draw a rectangle in the image
%Part of code made for modifing the rectangle until a keyboard key is
%pressed
w=0;
while w~=1
    try
        w = waitforbuttonpress;
    catch
        break
    end
    if w == 1
        pos=[pos; h.Position];
    end
end
pause(0.1); %pause
%save the rectangle coordinates
handles.add_rect_bound_info{end+1}=pos(:,:);
handles.add_Img_num = [handles.add_Img_num i];
guidata(hObject,handles)
pause(0.001);

% --- Executes on button press in Remove.
function Remove_Callback(hObject, eventdata, handles)
% hObject    handle to Remove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Import values
GUI_IM = getappdata(0, 'GUI_IM');
i = getappdata(GUI_IM, 'i');

pos=[];

handles = guidata(hObject);
h = drawrectangle(gca,'StripeColor','r'); %Rectangle draw
%Part of code made for modifing the rectangle until a keyboard key is
%pressed
w=0;
while w~=1
    try
        w = waitforbuttonpress;
    catch
        break
    end
    if w == 1
        pos=[pos; h.Position];
    end
end
pause(0.1); %pause
%save the rectangle coordinates
handles.rem_rect_bound_info{end+1}=pos(:,:);
handles.rem_Img_num = [handles.rem_Img_num i];
guidata(hObject,handles)
pause(0.001);

% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
% hObject    handle to Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA

%Saving of the rectangle coordinates for the selected Spots of each ROI
handles = guidata(hObject);
add_rect_data=handles.add_rect_bound_info;
rem_rect_data=handles.rem_rect_bound_info;
add_Img_num=handles.add_Img_num;
rem_Img_num=handles.rem_Img_num;
save('List_Rect','add_rect_data','rem_rect_data','add_Img_num', 'rem_Img_num');

%Dialog box of success operation
tex_struct.Interpreter = 'tex';
tex_struct.WindowStyle = 'modal';
uiwait(msgbox('\fontsize{15}Operation Complete! Summary images are in the spots folder.',tex_struct));

%Clean and close everything
clear all
close all


% --- Executes on button press in Next.
function Next_Callback(hObject, eventdata, handles)
% hObject    handle to Next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Code to visualize the next image

%Load variables
GUI_IM = getappdata(0, 'GUI_IM');
i = getappdata(GUI_IM, 'i');
k = getappdata(GUI_IM, 'k');
if i < k
    i = i + 1;
    setappdata(GUI_IM, 'i', i);
    %Clock pointer during the loading
    set(handles.figure1, 'pointer', 'watch')
    drawnow;
    UpdateAxes; %Function for visualize the image
    set(handles.figure1, 'pointer', 'arrow')
else
    tex_struct.Interpreter = 'tex';
    tex_struct.WindowStyle = 'modal';
    uiwait(msgbox('\fontsize{15} This is the last picture!','Warning','warn',tex_struct));
end

% --- Executes on button press in Previous.
function Previous_Callback(hObject, eventdata, handles)
% hObject    handle to Previous (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Code to visualize the previous image

%Load variables
GUI_IM = getappdata(0, 'GUI_IM');
i = getappdata(GUI_IM, 'i');
if i > 1
    i = i - 1;
    %Clock pointer during the loading
    set(handles.figure1, 'pointer', 'watch')
    drawnow;
    setappdata(GUI_IM, 'i', i);
    UpdateAxes; %Function for visualize the image
    set(handles.figure1, 'pointer', 'arrow')
else
    tex_struct.Interpreter = 'tex';
    tex_struct.WindowStyle = 'modal';
    uiwait(msgbox('\fontsize{15} This is the first picture!','Warning','warn',tex_struct));
end
