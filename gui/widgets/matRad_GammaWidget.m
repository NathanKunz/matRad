classdef matRad_GammaWidget < matRad_Widget
% matRad_GammaWidget : GUI widget for gamma index based comparisons of  
% dose cubes stored within resultGUI struct.
%
% References
%   -
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2020 the matRad development team. 
% 
% This file is part of the matRad project. It is subject to the license 
% terms in the LICENSE file found in the top-level directory of this 
% distribution and at https://github.com/e0404/matRad/LICENSES.txt. No part 
% of the matRad project, including this file, may be copied, modified, 
% propagated, or distributed except according to the terms contained in the 
% LICENSE file.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    


    properties
        SelectedDisplayOption1 = 'physicalDose' ;
        SelectedDisplayOption2 = 'physicalDose' ;
        SelectedDisplayAllOptions = strings;
        criteria = [3 3];
        n = 0;
        localglobal = 'global';
        resolution;
        lockUpdate = false;
        maxSlice;
        slice;
        gammaCube;
        gammaPassRateCell;
        updated = false;
        
    end 
    properties (Constant)
      normalization = {'local','global'}  ;
    end 

    events

    end 

    methods
        function this  = matRad_GammaWidget(handleParent)
%MANAGE ARGUMENTS 


            matRad_cfg = MatRad_Config.instance();
            if nargin < 2
                handleParent = figure(...
                    'Units','normalized',...
                    'Position',[0.1 0.1 0.7 0.7],...
                    'Visible','on',...
                    'Color',matRad_cfg.gui.backgroundColor,...  'CloseRequestFcn',@(hObject,eventdata) figure1_CloseRequestFcn(this,hObject,eventdata),...
                    'IntegerHandle','off',...
                    'Colormap',[0 0 0.5625;0 0 0.625;0 0 0.6875;0 0 0.75;0 0 0.8125;0 0 0.875;0 0 0.9375;0 0 1;0 0.0625 1;0 0.125 1;0 0.1875 1;0 0.25 1;0 0.3125 1;0 0.375 1;0 0.4375 1;0 0.5 1;0 0.5625 1;0 0.625 1;0 0.6875 1;0 0.75 1;0 0.8125 1;0 0.875 1;0 0.9375 1;0 1 1;0.0625 1 1;0.125 1 0.9375;0.1875 1 0.875;0.25 1 0.8125;0.3125 1 0.75;0.375 1 0.6875;0.4375 1 0.625;0.5 1 0.5625;0.5625 1 0.5;0.625 1 0.4375;0.6875 1 0.375;0.75 1 0.3125;0.8125 1 0.25;0.875 1 0.1875;0.9375 1 0.125;1 1 0.0625;1 1 0;1 0.9375 0;1 0.875 0;1 0.8125 0;1 0.75 0;1 0.6875 0;1 0.625 0;1 0.5625 0;1 0.5 0;1 0.4375 0;1 0.375 0;1 0.3125 0;1 0.25 0;1 0.1875 0;1 0.125 0;1 0.0625 0;1 0 0;0.9375 0 0;0.875 0 0;0.8125 0 0;0.75 0 0;0.6875 0 0;0.625 0 0;0.5625 0 0],...
                    'MenuBar','none',...
                    'Name','MatRad Gamma Analysis',...
                    'NumberTitle','off',...
                    'HandleVisibility','callback',...
                    'Tag','GammaWidget');
                
            end
            this = this@matRad_Widget(handleParent);
           
           this.initialize();
           this.update();
        end

        function this = initialize(this)
            if evalin( 'base', 'exist(''resultGUI'')' )
                resultGUI = evalin('base','resultGUI');
                resultnames = fieldnames(resultGUI) ;
                j = 1;
               for i = 1:numel(resultnames)
                   if ndims(resultGUI.(resultnames{i}))==3
                       this.SelectedDisplayAllOptions(j) = resultnames{i};
                       j=j+1;
                   end 
               end 
               % get and set display options 
                this.SelectedDisplayAllOptions = pad(this.SelectedDisplayAllOptions);
                set(this.handles.popupSelectedDisplayOption1,'String',this.SelectedDisplayAllOptions);
                set(this.handles.popupSelectedDisplayOption2,'String',this.SelectedDisplayAllOptions);
                this.maxSlice = size(resultGUI.physicalDose,3); 
                this.slice = round(this.maxSlice/2);
            end
            if evalin( 'base', 'exist(''ct'')' )
                ct = evalin('base','ct');
                this.resolution = [ct.resolution.x, ct.resolution.y, ct.resolution.z];
                set(this.handles.editResolution,'String', regexprep(num2str(this.resolution),'\s+',' '));
            end

            set(this.handles.editGammaCrit,'String', regexprep(num2str(this.criteria),'\s+',' '));
            
            

        end

        function this = update (this,~)
           
            if evalin( 'base', 'exist(''resultGUI'')' ) && this.lockUpdate
                resultGUI = evalin('base','resultGUI');
                resultnames = fieldnames(resultGUI) ;
                j = 1;
               for i = 1:numel(resultnames)
                   if ndims(resultGUI.(resultnames{i}))==3
                       this.SelectedDisplayAllOptions(j) = resultnames{i};
                       j=j+1;
                   end 
               end 
               % get and set display options 
                this.SelectedDisplayAllOptions = pad(this.SelectedDisplayAllOptions);
                set(this.handles.popupSelectedDisplayOption1,'String',this.SelectedDisplayAllOptions);
                set(this.handles.popupSelectedDisplayOption2,'String',this.SelectedDisplayAllOptions);

                %slider options %CAN ALSO SET MIN AND MAX TO NONZERO SLICES
                
                if size(resultGUI.(this.SelectedDisplayOption1),3) == size(resultGUI.(this.SelectedDisplayOption2),3)
                    this.maxSlice = size(resultGUI.(this.SelectedDisplayOption1),3);
                    this.slice = round(this.maxSlice/2);
                    set(this.handles.sliderSlice,'Min',1,'Max',this.maxSlice,...
                        'Value', this.slice, ...
                        'SliderStep',[1 1]);
                else
                    error('Mismatch in dimensions of selected cubes')
                end
            
            
                this.calcGamma();
                this.plotGamma();
                this.lockUpdate = false;
            end 

        end 
        % METHOD FOR WHEN WORKSPACE IS CHANGED 

        function set.SelectedDisplayOption1(this, value)
            this.SelectedDisplayOption1 = value;
            this.lockUpdate = true;
            this.update();
        end
        
        function set.SelectedDisplayOption2(this, value)
            this.SelectedDisplayOption2 = value;
            this.lockUpdate = true;
            this.update();
        end
        
        function set.resolution(this,value)
            this.resolution = value;
            this.lockUpdate = true;
            this.update();
        end
        
        function set.criteria(this,value)
            this.criteria = value;
            this.lockUpdate = true;
            this.update();
        end

        function set.localglobal(this,value)
            this.localglobal = value;
            this.lockUpdate = true;
            this.update();
        end
        function set.n(this,value)
            this.n = value;
            this.lockUpdate = true;
            this.update();
        end 
        
        
    end 

    methods (Access = protected)
        
        function this  = createLayout(this) 
            h20 = this.widgetHandle;

            matRad_cfg = MatRad_Config.instance();

            %Create Main Grid layout
            gridSize = [6 20];
            elSize = [0.9 0.6];
            [i,j] = ndgrid(1:gridSize(1),1:gridSize(2));
            gridPos = arrayfun(@(i,j) computeGridPos(this,[i j],gridSize,elSize),i,j,'UniformOutput',false);

             txt = sprintf('Choose Reference Cube from ResultGUI');
            h21 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','Reference cube 1:',...
                'Tooltip',txt,...
                'Style','text',...
                'Position',gridPos{3,1},...
                'BackgroundColor',matRad_cfg.gui.backgroundColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Tag','txtCube1',...                
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);

            h22 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','Please select ...',...
                'Tooltip',txt,...
                'Style','popupmenu',...
                'Value',1,...
                'Position',gridPos{4,1},...
                'BackgroundColor',matRad_cfg.gui.elementColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Callback',@(hObject,eventdata)popupSelectedDisplayOption1_Callback(this,hObject,eventdata),...
                'Tag','popupSelectedDisplayOption1',...
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);
            
             txt = sprintf('Choose Reference Cube from ResultGUI');
            h23 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','Reference cube 2:',...
                'Tooltip',txt,...
                'Style','text',...
                'Position',gridPos{5,1},...
                'BackgroundColor',matRad_cfg.gui.backgroundColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Tag','txtCube2',...                
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);

            h24 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','Please select ...',...
                'Tooltip',txt,...
                'Style','popupmenu',...
                'Value',1,...
                'Position',gridPos{6,1},...
                'BackgroundColor',matRad_cfg.gui.elementColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Callback',@(hObject,eventdata)popupSelectedDisplayOption2_Callback(this,hObject,eventdata),...
                'Tag','popupSelectedDisplayOption2',...
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);

            txt = sprintf('Gamma Criteria [mm %%]');
            h25 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','Gamma Criteria [mm %]:',...
                'Tooltip',txt,...
                'Style','text',...
                'Position',gridPos{1,3},...
                'BackgroundColor',matRad_cfg.gui.backgroundColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Tag','txtGammaCrit',...                
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);

            h26 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','0  0',...
                'Tooltip',txt,...
                'Style','edit',...
                'Position',gridPos{1,4},...
                'BackgroundColor',matRad_cfg.gui.elementColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Callback',@(hObject,eventdata)editGammaCrit_Callback(this,hObject,eventdata),...
                'Tag','editGammaCrit',...
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);

            txt = sprintf('Resolution of cube [mm/voxel]');
            h27 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','Resolution of cube [mm/voxel]:',...
                'Tooltip',txt,...
                'Style','text',...
                'Position',gridPos{1,5},...
                'BackgroundColor',matRad_cfg.gui.backgroundColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Tag','txtResolution',...                
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);

             h28 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','0 0 0',...
                'Tooltip',txt,...
                'Style','edit',...
                'Position',gridPos{1,6},...
                'BackgroundColor',matRad_cfg.gui.elementColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Callback',@(hObject,eventdata)editResolution_Callback(this,hObject,eventdata),...
                'Tag','editResolution',...
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);

            txt = sprintf('Number of interpolations, max suggested value is 3');
            h29 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','Number of interpolations n:',...
                'Tooltip',txt,...
                'Style','text',...
                'Position',gridPos{1,7},...
                'BackgroundColor',matRad_cfg.gui.backgroundColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Tag','txtInterpolations',...                
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);

              h30 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','0',...
                'Tooltip',txt,...
                'Style','edit',...
                'Position',gridPos{1,8},...
                'BackgroundColor',matRad_cfg.gui.elementColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Callback',@(hObject,eventdata)editInterpolations_Callback(this,hObject,eventdata),...
                'Tag','editInterpolations',...
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);

            txt = sprintf('local and global normalizations');
            h31 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','Type of normalization:',...
                'Tooltip',txt,...
                'Style','text',...
                'Position',gridPos{1,9},...
                'BackgroundColor',matRad_cfg.gui.backgroundColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Tag','txtInterpolations',...                
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);

            h32 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String',this.normalization,...
                'Tooltip',txt,...
                'Style','popupmenu',...
                'Value',1,...
                'Position',gridPos{1,10},...
                'BackgroundColor',matRad_cfg.gui.elementColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Callback',@(hObject,eventdata)popupNormalization_Callback(this,hObject,eventdata),...
                'Tag','popupRadMode',...
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);

             txt = sprintf('Choose which slice should be displayed in intensity plots');
            h33 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','Slice',...
                'Tooltip',txt,...
                'Style','text',...
                'Position',gridPos{1,11},...
                'BackgroundColor',matRad_cfg.gui.backgroundColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'Tag','txtInterpolations',...                
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight);

            h34 = uicontrol(...
                'Parent',h20,...
                'Units','normalized',...
                'String','Slider',...
                'Tooltip','Choose which slice should be displayed in intensity plots',...
                'Style','slider',...
                'Callback',@(hObject,eventdata) sliderSlice_Callback(this,hObject,eventdata),...
                'BusyAction','cancel',...
                'Interruptible','off',...
                'Position',gridPos{1,12},...
                'BackgroundColor',matRad_cfg.gui.elementColor,...
                'ForegroundColor',matRad_cfg.gui.textColor,...
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontName',matRad_cfg.gui.fontName,...
                'FontWeight',matRad_cfg.gui.fontWeight,...
                'Tag','sliderSlice');

             p1 = uipanel(...
                'Parent',h20,...   
                'Units','normalized',...
                'BackgroundColor',matRad_cfg.gui.backgroundColor,...
                'Tag','panelGammaIdx',...
                'Clipping','off',...
                'Position',[0.22 0.01 0.7 0.9],...
                'FontName',matRad_cfg.gui.fontName,...
                'FontSize',matRad_cfg.gui.fontSize,...
                'FontWeight',matRad_cfg.gui.fontWeight,...
                'Title','Gamma Analysis');

%               h35 = uicontrol(...
%                 'Parent',p1,...
%                 'Units','normalized',...
%                 'String','Gamma Pass Rate : ',...
%                 'Tooltip',txt,...
%                 'Style','text',...
%                 'Position',[0.05 0.05 0.5 0.95],...
%                 'BackgroundColor',matRad_cfg.gui.backgroundColor,...
%                 'ForegroundColor',matRad_cfg.gui.textColor,...
%                 'Tag','txtGammaPass',...                
%                 'FontSize',matRad_cfg.gui.fontSize,...
%                 'FontName',matRad_cfg.gui.fontName,...
%                 'FontWeight',matRad_cfg.gui.fontWeight);
%                
%               h36 = uifigure(...
%                 'Parent',p1,...   
%                 'Units','normalized',...
%                 'BackgroundColor',matRad_cfg.gui.backgroundColor,...
%                 'Tag','figGammaMap',...
%                 'Clipping','off',...
%                 'Position',[0.05 0.05 1 1],...
%                 'FontName',matRad_cfg.gui.fontName,...
%                 'FontSize',matRad_cfg.gui.fontSize,...
%                 'FontWeight',matRad_cfg.gui.fontWeight);

            this.createHandles();
        end
        
    end
    methods (Access = private)
    
        function popupNormalization_Callback(this, hObject, eventdata)
            contents      = cellstr(get(hObject,'String'));
            this.localglobal = contents{get(hObject,'Value')};

        end
        function popupSelectedDisplayOption1_Callback(this,hObject,eventdata)
            contents      = cellstr(get(hObject,'String'));
            this.SelectedDisplayOption1 = strtrim(contents{get(hObject,'Value')});
            
        end 
        function popupSelectedDisplayOption2_Callback(this,hObject,eventdata)
            contents      = cellstr(get(hObject,'String'));
            this.SelectedDisplayOption2 = strtrim(contents{get(hObject,'Value')});
            
        end 

        function editResolution_Callback(this, hObject, ~)
            t = sscanf (get(hObject,'String'), '%f');
            if numel(t) ~=3
                error('Resolution value error')
            else
                this.resolution = t;
            end 
            
        end 
        function editGammaCrit_Callback(this, hObject, ~)
            t = sscanf (get(hObject,'String'), '%f');
            if numel(t) ~=2
                error('Gamma Criterion value error')
            else
                this.criteria = t;
            end 
            
        end 

        function editInterpolations_Callback(this, hObject, ~)
            t = str2double(get(hObject,'String'));
            if ~isnumeric(t)
                error('Number of Interpolations value error')
            else
                this.n = t;
            end 
            
        end 
        function sliderSlice_Callback(this,hObject, ~)
           % hObject    handle to sliderSlice (see GCBO)
           % eventdata  reserved - to be defined in a future version of MATLAB
           % handles    structure with handles and user data (see GUIDATA)
           
           % Hints: get(hObject,'Value') returns position of slider
           %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
           %UpdatePlot(handles)
           
           this.slice = round(get(hObject,'Value'));

           this.plotGamma();
        end

        
    end
    

    methods
        function calcGamma(this)
            if evalin( 'base', 'exist(''resultGUI'')' )
                resultGUI = evalin('base','resultGUI');
            else
                % no result cube
            end
            if evalin( 'base', 'exist(''cst'')' )
                cst = evalin('base','cst');
            else 
                %no cst
            end 

            

            [this.gammaCube,this.gammaPassRateCell] = matRad_gammaIndex(resultGUI.(this.SelectedDisplayOption1) ,resultGUI.(this.SelectedDisplayOption2),...
                                                                            this.resolution,this.criteria,[],this.n,this.localglobal,cst);

        end 
        function plotGamma(this)
          this.widgetHandle;  
            
          
          % visualize if applicable

            if  ~isempty(this.slice) && ~isempty(this.gammaCube) 
                if isempty(this.handles.panelGammaIdx(1).Children)
                ax = axes('Parent',this.handles.panelGammaIdx);
                else
%                     delete(this.handles.panelGammaIdx(1).Children(2));
                    ax = this.handles.panelGammaIdx(1).Children(2);
                    
                end
%                 ax = figure('Parent',this.handles.panelGammaIdx);
%                 set(ax,'Color',[1 1 1]);  
                imagesc(ax, this.gammaCube(:,:,this.slice))
                myColormap = matRad_getColormap('gammaIndex');

                set(ax,'colormap',myColormap);
                
                colorbar(ax);
                titletxt = {[num2str(this.gammaPassRateCell{1,2},5) '% of points > ' num2str(this.criteria(1))  ...
                    '% pass gamma criterion (' num2str(this.criteria(1))  '% / ' ...
                    num2str(this.criteria(2))  'mm)']; ['with ' num2str(2^this.n-1) ' interpolation points']};
                title(ax, titletxt);
%                 set(this.handles.panelGammaIdx(1).Children(2),'Title',titletxt);

                
            
%             this.createHandles();
            end
        end

    end

end 
