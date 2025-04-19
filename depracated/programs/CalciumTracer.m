classdef CalciumTracer < handle
     % Public Properties
     properties
          Figure
          FrameAxes
          ROIAxes
          ROIPlots
          TraceAxes
          TracePlots

          Timer

          Filename
          Frames
          CurrentFrame

          WarningLog
     end

     % Private Properties
     properties (Access = private)
          FrameIndex
          Status
          Time
          ColorMap

          ROIPanel
          ROI
          ROISize
          Map
          Signal
          TraceData

          Buttons
          StatusLabel
     end

     % Custom Events
     events
          newFrame
          newFile
          newStatus
          newMap
          newROI
     end

     % Public Methods
     methods
          % constructor
          function self = CalciumTracer()
               % formatting
               format short, format compact
               close all force
               clc

               % event listeners
               addlistener(self, 'newFrame', @self.onNewFrame);
               addlistener(self, 'newFile', @self.onNewFile);
               addlistener(self, 'newStatus', @self.onNewStatus);
               addlistener(self, 'newMap', @self.onNewMap);
               addlistener(self, 'newROI', @self.onNewROI);

               % Filename
               self.Filename = '<choose file>';

               % Figure
               self.Figure = uifigure(...
                    'Name', 'CalciumTracer', ...
                    'Position', [0, 0, 1045, 500], ...
                    'WindowStyle', 'normal', ...
                    'Resize', 'off', ...
                    'Color', [0.8824, 0.8824, 0.8824], ...
                    'Pointer', 'watch', ...
                    'HitTest', false, ...
                    'Visible', 'off', ...
                    'CreateFcn', @(~, ~) delete(timerfindall), ...
                    'DeleteFcn', @(~, ~) delete(timerfindall), ...
                    'WindowButtonDownFcn', @self.onClick, ...
                    'WindowButtonMotionFcn', @self.onCursorMotion, ...
                    'KeyPressFcn', @self.onKeyPress);
               movegui(self.Figure, 'center')

               % ROIPanel
               self.ROIPanel = gobjects(0);

               % FrameAxes, ROIAxes, TraceAxes
               self.FrameAxes = uiaxes(...
                    'Parent', self.Figure, ...
                    'Tag', 'Frame Axes', ...
                    'NextPlot', 'replacechildren', ...
                    'Position', [40, 57.5, 440, 440], ...
                    'Box', 'off', ...
                    'Visible', 'on', ...
                    'Color', [0, 0, 0], ...
                    'Toolbar', [], ...
                    'PickableParts', 'none', ...
                    'HitTest', false, ...
                    'XTick', [], ...
                    'XLim', [1, 512], ...
                    'XTickLabel', '', ...
                    'YTick', [], ...
                    'YLim', [1, 512], ...
                    'YTickLabel', '', ...
                    'TickDir', 'none');
               self.ROIAxes = gobjects(0);
               self.TraceAxes = gobjects(0);

               % ROIPlots, TracePlots
               self.ROIPlots = gobjects(0);
               self.TracePlots = gobjects(0);

               % Frames
               self.Frames = {self.loadIconData('default_frame.png')};

               % CurrentFrame
               self.CurrentFrame = imshow(self.loadIconData('default_frame.png'), ...
                    'Parent', self.FrameAxes, ...
                    'Colormap', gray(256));
               
               % ROI, ROISize, Map, Signal, TraceData
               self.ROI = gobjects(0);
               self.ROISize = 18;
               self.Map = [];
               self.Signal = [];
               self.TraceData = [];

               % ColorMap
               pos = [0; ... % black
                    0.5; ... % blue
                    0.65; ... % green
                    0.8; ... % yellow
                    1]; % red
               cdata = [0, 0, 0; ... % black
                    23, 53, 160; ... % blue
                    67, 147, 8; ... % green
                    231, 195, 0; ... % yellow
                    239, 62, 0] ... % red
                    / 255;
               self.ColorMap = interp1(pos, cdata, linspace(0, 1, 256));

               % Buttons
               self.Buttons.File = self.createButton(...
                    'Parent', self.Figure, ...
                    'Position', [8.5, 462.5, 30, 30], ...
                    'Icon', 'load_icon.png', ...
                    'Callback', @(~, ~) notify(self, 'newFile'));
               self.Buttons.Save = self.createButton(...
                    'Parent', self.Figure, ...
                    'Position', [8.5, 427.5, 30, 30], ...
                    'Icon', 'save_icon.png', ...
                    'Callback', @self.SaveFcn);
               self.Buttons.Seed = self.createButton(...
                    'Parent', self.Figure, ...
                    'Position', [8.5, 392.5, 30, 30], ...
                    'Icon', 'seed_icon.png', ...
                    'Callback', @(~, ~) notify(self, 'newMap'));
               self.Buttons.Analyze = self.createButton(...
                    'Parent', self.Figure, ...
                    'Position', [8.5, 357.5, 30, 30], ...
                    'Icon', 'analyze_icon.png', ...
                    'Callback', @self.AnalyzeFcn);
               self.Buttons.SkipB5 = self.createButton(...
                    'Parent', self.Figure, ...
                    'Position', [180, 27.5, 30, 30], ...
                    'Icon', 'skipBackward5_icon.png', ...
                    'Callback', @(~, ~) self.SkipFcn(-1, 5));
               self.Buttons.SkipB1 = self.createButton(...
                    'Parent', self.Figure, ...
                    'Position', [215, 27.5, 30, 30], ...
                    'Icon', 'skipBackward1_icon.png', ...
                    'Callback', @(~, ~) self.SkipFcn(-1, 1));
               self.Buttons.PlayPause = self.createButton(...
                    'Parent', self.Figure, ...
                    'Position', [250, 27.5, 30, 30], ...
                    'Icon', 'play_icon.png', ...
                    'Callback', @self.PlayPauseFcn);
               self.Buttons.SkipF1 = self.createButton(...
                    'Parent', self.Figure, ...
                    'Position', [285, 27.5, 30, 30], ...
                    'Icon', 'skipForward1_icon.png', ...
                    'Callback', @(~, ~) self.SkipFcn(1, 1));
               self.Buttons.SkipF5 = self.createButton(...
                    'Parent', self.Figure, ...
                    'Position', [320, 27.5, 30, 30], ...
                    'Icon', 'skipForward5_icon.png', ...
                    'Callback', @(~, ~) self.SkipFcn(1, 5));

               % StatusLabel
               self.StatusLabel = uilabel(...
                    'Parent', self.Figure, ...
                    'Position', [10, 1.5, 1045, 20], ...
                    'Text', ['File: <choose file>', repmat(' ', 1, 10), ...
                         'FOV Map: Missing', repmat(' ', 1, 10), ...
                         'Status: Paused', repmat(' ', 1, 10), ...
                         'Frame: 0', repmat(' ', 1, 10), ...
                         'Time: 0.00s'], ...
                    'FontName', 'Helvetica', ...
                    'FontSize', 13, ...
                    'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'left', ...
                    'VerticalAlignment', 'center');

               % FrameIndex, Time, Status
               self.FrameIndex = 1;
               self.Time = 0;
               self.Status = 'Paused';

               % Timer
               self.Timer = timer(...
                    'ExecutionMode', 'fixedSpacing', ...
                    'Period', 1/30, ...
                    'StartDelay', 1, ...
                    'BusyMode', 'queue', ...
                    'TimerFcn', @self.timerFcn);
               warning('off', 'all')

               % WarningLog
               self.WarningLog = {};

               % initialization
               self = self.begin();
          end
          
          % setup
          function self = begin(self)
               set(self.Figure, 'Visible', 'off')
               pause(0.33)

               self = self.loadMap();

               h = waitbar(0, 'Starting up...');
               steps = linspace(0, 1, 6);

               for i = 1:numel(steps)
                    waitbar(steps(i), h, 'Starting up...');
                    pause(randi(20, 1) / 100)
               end

               close(h)
               set(self.Figure, 'Visible', 'on')
               set(self.Figure, 'Pointer', 'arrow')

               set(self.Buttons.File, 'Enable', 'on')

               self = self.logWarning();
          end

          % set / get
          function set.FrameIndex(self, new_idx)
               self.FrameIndex = new_idx;
               notify(self, 'newFrame')
          end
          
          function set.Status(self, new_status)
               self.Status = new_status;
               notify(self, 'newStatus')
          end
     end

     % Private Methods
     methods (Access = private)
          % misc
          function self = logWarning(self)
               [msg, id] = lastwarn;
               
               if ~isempty(msg)
                    self.WarningLog{end+1} = struct('message', msg, 'id', id);
                    lastwarn('');
               end
          end

          function icon = loadIconData(~, filename)
               path = strsplit(cd, '\');
               path = path(1:end-1);
               path = char(join(path, '\'));

               file = fullfile(path, 'images\', filename);
               [rgb, ~, alpha] = imread(file);

               rgb = double(rgb);
               rgb = (rgb - min(rgb(:))) / max(rgb(:));

               %icon = struct('CData', rgb, 'AlphaData', alpha);
               icon = rgb;
          end

          function btn = createButton(self, varargin)
               p = inputParser;

               addParameter(p, 'Parent', 0)
               addParameter(p, 'Tag', '')
               addParameter(p, 'Position', [0, 0, 0, 0])
               addParameter(p, 'Icon', 'default_frame.png')
               addParameter(p, 'Callback', @(~, ~) disp('empty callback'))
               addParameter(p, 'Enable', 'off')

               parse(p, varargin{:})

               parent = p.Results.Parent;
               tag = p.Results.Tag;
               pos = p.Results.Position;
               img = p.Results.Icon;
               callback = p.Results.Callback;
               enable = p.Results.Enable;
               
               btn = uicontrol(...
                    'Parent', parent, ...
                    'Tag', tag, ...
                    'Style', 'pushbutton', ...
                    'Position', pos, ...
                    'HorizontalAlignment', 'center', ...
                    'BackgroundColor', 'none', ...
                    'CData', self.loadIconData(img), ...
                    'Enable', enable, ...
                    'Visible', 'on', ...
                    'Callback', callback);
          end

          function lbl = createLabel(self, varargin)
               p = inputParser;

               addParameter(p, 'Parent', self.Figure)
               addParameter(p, 'Tag', '')
               addParameter(p, 'Position', [0, 0, 30, 1045])
               addParameter(p, 'Text', '')
               addParameter(p, 'FontWeight', 'bold')
               addParameter(p, 'HorizontalAlignment', 'left')

               parse(p, varargin{:})

               parent = p.Results.Parent;
               tag = p.Results.Tag;
               pos = p.Results.Position;
               txt = p.Results.Text;
               weight = p.Results.FontWeight;
               h_align = p.Results.HorizontalAlignment;

               lbl = uilabel(...
                    'Parent', parent, ...
                    'Tag', tag, ...
                    'Position', pos, ...
                    'Text', txt, ...
                    'BackgroundColor', 'none', ...
                    'FontColor', [0, 0, 0], ...
                    'FontName', 'Helvetica', ...
                    'FontSize', 14, ...
                    'FontWeight', weight, ...
                    'HorizontalAlignment', h_align, ...
                    'VerticalAlignment', 'center');
          end

          function data = loadFile(~, filename)
               file = matfile(filename);

               vars = properties(file);
               vars = vars(~cellfun('isempty', regexp(vars, '^frames_')));

               start_frame = cellfun(@(x) str2double(regexp(x, '(?<=frames_)(\d+)', 'match')), ...
                    vars);
               [~, sorted_idx] = sort(start_frame);
               sorted_vars = vars(sorted_idx);

               data = [];
               for i = 1:numel(sorted_vars)
                    subset = file.(sorted_vars{i});
                    data = cat(3, data, subset);
               end

               data = mat2cell(data, 512, 512, ones(1, size(data, 3)));
          end

          function response = popup(~, msg, title, opts)
               f = uifigure(...
                    'Position', [0, 0, 350, 100], ...
                    'Name', title, ...
                    'Icon', repmat(0.9529 * ones(4), 1, 1, 3), ...
                    'ToolBar', 'none', ...
                    'WindowStyle', 'normal', ...
                    'Resize', 'off', ...
                    'Visible', 'off');
               uilabel(...
                    'Parent', f, ...
                    'Position', [15, 0, 320, 85], ...
                    'Text', msg, ...
                    'FontName', 'Helvetica', ...
                    'FontSize', 13, ...
                    'FontWeight', 'normal', ...
                    'FontColor', [0, 0, 0], ...
                    'WordWrap', 'on', ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'top', ...
                    'BackgroundColor', 'none');
               uicontrol(...
                    'Parent', f, ...
                    'Position', [90, 12.5, 60, 20], ...
                    'String', opts{1}, ...
                    'FontName', 'Helvetica', ...
                    'FontSize', 8, ...
                    'FontWeight', 'normal', ...
                    'BackgroundColor', [0.975, 0.975, 0.975], ...
                    'Callback', @(~, ~) buttonFcn(f, opts{1}));
               uicontrol(...
                    'Parent', f, ...
                    'Position', [220, 12.5, 60, 20], ...
                    'String', opts{2}, ...
                    'FontName', 'Helvetica', ...
                    'FontSize', 8, ...
                    'FontWeight', 'normal', ...
                    'BackgroundColor', [0.975, 0.975, 0.975], ...
                    'Callback', @(~, ~) buttonFcn(f, opts{1}));

               function buttonFcn(fig, val)
                    fig.UserData = val;
                    uiresume(fig)
               end

               movegui(f, 'center')
               uistack(f, 'top')
               set(f, 'Visible', 'on')

               uiwait(f)

               response = f.UserData;
               delete(f)
          end

          function self = loadMap(self)
               folder_path = 'C:\Users\Max\Documents\Classes\Gonzales Lab\Two Photon\data';
               file_path = fullfile(folder_path, 'FOVmap.mat');

               if exist(file_path, 'file') == 2
                    map_struct = load(file_path);
                    self.Map = map_struct.map;
               end
          end

          function self = updateTraces(self)
               if isempty(self.ROI)
                    return
               end

               for i = 1:numel(self.ROI)
                    bbox = self.ROI(i).Position;

                    r_min = floor(bbox(2));
                    r_max = ceil(r_min + bbox(4));
                    c_min = floor(bbox(1));
                    c_max = ceil(c_min + bbox(3));

                    img = self.Frames{self.FrameIndex};
                    img = img(r_min:r_max, c_min:c_max);
                    img = imresize(img, [128, 128]);

                    set(self.ROIPlots(i), 'CData', img);
               end
          end

          function value = deltaFoverF(self, old_F, new_F)
               if self.FrameIndex == 1
                    self.TraceData = repmat(zeros(1, 64), 1, numel(self.ROI));
               else
                    value = (new_F - old_F) / old_F;
                    value = rescale(value, 0, 1);
               end
          end

          % event callbacks
          function self = onNewFile(self, ~, ~)
               set(self.Figure, 'Pointer', 'watch')

               [filename, path] = uigetfile('*.mat', 'Select File', ...
                    'C:\Users\Max\Documents\Classes\Gonzales Lab\Two Photon\data');

               set(self.Figure, 'Visible', 'off')
               set(self.Figure, 'Visible', 'on')

               if ~ischar(filename)
                    return
               else
                    self.Filename = filename;
               end

               filename = sprintf('%s\\%s', path, filename);
               self.Frames = self.loadFile(filename);

               h = waitbar(0, 'Starting up...');
               steps = linspace(0, 1, 6);

               for k = 1:numel(steps)
                    waitbar(steps(k), h, 'Initializing...');
                    pause(randi(50, 1) / 100)
               end

               if ~isempty(self.Map)
                    set(self.Buttons.Analyze, 'Enable', 'on')
               end

               close(h)

               delete(self.ROIPlots)
               self.ROIPlots = gobjects(0);

               delete(self.TracePlots)
               self.TracePlots = gobjects(0);

               self.TraceData = [];

               self.FrameIndex = 1;

               self.CurrentFrame = imshow(self.Frames{1}, ...
                    'Parent', self.FrameAxes, ...
                    'Colormap', gray(256));

               set(self.Figure, 'Pointer', 'arrow')

               self.Status = 'Paused';

               set(self.Buttons.Seed, 'Enable', 'on')
               set(self.Buttons.SkipB5, 'Enable', 'on')
               set(self.Buttons.SkipB1, 'Enable', 'on')
               set(self.Buttons.PlayPause, 'Enable', 'on')
               set(self.Buttons.SkipF1, 'Enable', 'on')
               set(self.Buttons.SkipF5, 'Enable', 'on')

               if ~strcmp(self.Timer.Running, 'on')
                    start(self.Timer)
               end
          end
          
          function self = onNewFrame(self, ~, ~)
               self.Time = (self.FrameIndex - 1) * (1/30);

               set(self.CurrentFrame, 'CData', self.Frames{self.FrameIndex});
               self = self.updateTraces();
          end

          function self = onNewStatus(self, ~, ~)
               filename = self.Filename;

               if ~strcmp(filename, '<choose file>')
                    frame_num = self.FrameIndex;
               else
                    frame_num = 0;
               end

               time = self.Time;
               status = self.Status;

               if isempty(self.Map)
                    map_found = 'Missing';
               else
                    map_found = 'Found';
               end

               keys = {'File', 'FOV Map', 'Status', 'Frame', 'Time'};
               values = {filename, map_found, status, frame_num, time};
               spacer = repmat(' ', 1, 10);

               lbl = '';
               for i = 1:5
                    switch i
                         case 1
                              lbl = sprintf('%s%s: %s%s', ...
                                   lbl, keys{i}, values{i}, spacer);
                         case 2
                              lbl = sprintf('%s%s: %s%s', ...
                                   lbl, keys{i}, values{i}, spacer);
                         case 3
                              lbl = sprintf('%s%s: %s%s', ...
                                   lbl, keys{i}, values{i}, spacer);
                         case 4
                              lbl = sprintf('%s%s: %d%s', ...
                                   lbl, keys{i}, values{i}, spacer);
                         case 5
                              lbl = sprintf('%s%s: %.2fs', ...
                                   lbl, keys{i}, values{i});
                    end
               end
               
               set(self.StatusLabel, 'Text', lbl)
          end

          function self = onNewMap(self, ~, ~)
               self = self.cleanup();

               self.ROIPanel = uipanel(...
                    'Parent', self.Figure, ...
                    'Position', [637.5, 200, 250, 95], ...
                    'BackgroundColor', [0.85, 0.85, 0.85], ...
                    'BorderColor', [0, 0, 0], ...
                    'BorderWidth', 1.25);

               % roi count labels
               self.createLabel(...
                    'Parent', self.ROIPanel, ...
                    'Tag', 'count_label', ...
                    'Position', [24.5, 60, 180, 30], ...
                    'Text', 'Regions of Interest:', ...
                    'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'center');
               self.createLabel(...
                    'Parent', self.ROIPanel, ...
                    'Tag', 'count_value', ...
                    'Position', [129.5, 60, 135, 30], ...
                    'Text', '0', ...
                    'FontWeight', 'normal', ...
                    'HorizontalAlignment', 'center');

               % roi size labels
               self.createLabel(...
                    'Parent', self.ROIPanel, ...
                    'Tag', 'size_label', ...
                    'Position', [50, 37.5, 115, 30], ...
                    'Text', 'Average Size:', ...
                    'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'center');
               self.createLabel(...
                    'Parent', self.ROIPanel, ...
                    'Tag', 'size_value', ...
                    'Position', [122, 37.5, 115, 30], ...
                    'Text', '0px', ...
                    'FontWeight', 'normal', ...
                    'HorizontalAlignment', 'center');

               % panel buttons
               self.createButton(...
                    'Parent', self.ROIPanel, ...
                    'Tag', 'abandon', ...
                    'Position', [70, 10, 25, 25], ...
                    'Icon', 'abandon_icon.png', ...
                    'Callback', @(~, ~) abandonFcn(self), ...
                    'Enable', 'on');
               self.createButton(...
                    'Parent', self.ROIPanel, ...
                    'Tag', 'undo', ...
                    'Position', [110, 10, 25, 25], ...
                    'Icon', 'undo_icon.png', ...
                    'Callback', @(~, ~) undoFcn(self), ...
                    'Enable', 'off');
               self.createButton(...
                    'Parent', self.ROIPanel, ...
                    'Tag', 'confirm', ...
                    'Position', [150, 10, 25, 25], ...
                    'Icon', 'confirm_icon.png', ...
                    'Callback', @(~, ~) confirmFcn(self), ...
                    'Enable', 'off');

               % initialize Map, update status
               self.Map = uint8(zeros(512));
               self.Status = 'Mapping';

               function self = abandonFcn(self)
                    response = self.popup(...
                         'Abandon the current FOV map? This action cannot be undone.', ...
                         'Confirmation', ...
                         {'Yes', 'No'});

                    switch response
                         case 'Yes'
                              self = self.cleanup();
                         case 'No'
                              % do nothing
                    end
               end

               function self = undoFcn(self)
                    if ~isempty(self.ROI)
                         delete(self.ROI(end))
                         self.ROI(end) = [];
                    end

                    notify(self, 'newROI')
               end

               function self = confirmFcn(self)
                    response = self.popup(...
                         'Save current FOV map? This will overwrite existing maps if they exist.', ...
                         'Confirmation', ...
                         {'Yes', 'No'});

                    switch response
                         case 'Yes'
                              path = 'C:\Users\Max\Documents\Classes\Gonzales Lab\Two Photon\data';
                              filename = fullfile(path, 'FOVmap.mat');

                              map = self.Map;
                              save(filename, 'map', '-v7.3');

                              self = self.cleanup();
                         case 'No'
                              % do nothing
                    end
               end
          end

          function self = onNewROI(self, ~, ~)
               buttons = self.ROIPanel.Children;
               buttons = buttons(arrayfun(@(child) isa(child, 'matlab.ui.control.UIControl'), ...
                    buttons));

               undo_btn = buttons(arrayfun(@(btn) strcmp(btn.Tag, 'undo'), ...
                    buttons));
               confirm_btn = buttons(arrayfun(@(btn) strcmp(btn.Tag, 'confirm'), ...
                    buttons));

               if isempty(self.ROI)
                    set(undo_btn, 'Enable', 'off')
                    set(confirm_btn, 'Enable', 'off')
               else
                    set(undo_btn, 'Enable', 'on')
                    set(confirm_btn, 'Enable', 'on')
               end
          end

          function self = cleanup(self, ~, ~)
               roi = self.FrameAxes.Children;
               roi = roi(arrayfun(@(child) isa(child, 'matlab.graphics.primitive.Rectangle'), ...
                    roi));

               for n = 1:numel(roi)
                    delete(roi(n))
               end

               delete(self.ROIAxes)
               delete(self.ROIPlots)
               delete(self.ROI)
               delete(self.TraceAxes)
               delete(self.TracePlots)
               delete(self.TraceData)
               delete(self.Signal)

               self.ROIAxes = gobjects(0);
               self.ROIPlots = gobjects(0);
               self.ROI = gobjects(0);
               self.TraceAxes = gobjects(0);
               self.TracePlots = gobjects(0);
               self.Signal = [];

               self.Status = 'Paused';
          end

          % button callbacks
          function self = SkipFcn(self, direction, step)
               if strcmp(self.Status, 'Paused')
                    N_frames = numel(self.Frames);

                    new_idx = self.FrameIndex + (direction * step);
                    new_idx = mod(new_idx - 1, N_frames) + 1;

                    self.FrameIndex = new_idx;

                    notify(self, 'newFrame')
               end
          end

          function self = SaveFcn(self, ~, ~)
               disp('file saved')
          end

          function self = PlayPauseFcn(self, ~, ~)
               if strcmp(self.Status, 'Paused') || strcmp(self.Status, 'Mapping')
                    set(self.Buttons.PlayPause, 'CData', self.loadIconData('pause_icon.png'))
                    self.Status = 'Running';
               end
          end
     
          function self = AnalyzeFcn(self, ~, ~)
               self = self.cleanup();

               cc = bwconncomp(self.Map);
               stats = regionprops('table', cc, 'BoundingBox');

               bbox = stats.BoundingBox;
               y = 350;

               for i = 1:size(bbox, 1)
                    roi = rectangle(...
                         'Parent', self.FrameAxes, ...
                         'Position', bbox(i, :), ...
                         'FaceColor', 'none', ...
                         'EdgeColor', [1, 0, 0], ...
                         'LineWidth', 1);
                    roi_ax = uiaxes(...
                         'Parent', self.Figure, ...
                         'Position', [515, y, 128, 128], ...
                         'XLim', [1, 128], ...
                         'XTickLabel', {}, ...
                         'YLim', [1, 128], ...
                         'YTickLabel', {}, ...
                         'TickDir', 'none', ...
                         'TickLength', [0, 0], ...
                         'Box', 'off', ...
                         'HitTest', false, ...
                         'Toolbar', [], ...
                         'PickableParts', 'none', ...
                         'NextPlot', 'replacechildren');

                    trace = zeros(1, 64);
                    trace_ax = uiaxes(...
                         'Parent', self.Figure, ...
                         'Position', [665, y, 350, 128], ...
                         'TickDir', 'none', ...
                         'XLim', [0, 64], ...
                         'XTick', 0:8:64, ...
                         'XTickLabel', cellfun(@num2str, num2cell(0:8:64), ...
                              'UniformOutput', false), ...
                         'YLim', [0, 1], ...
                         'YTick', 0:0.5:1, ...
                         'YTickLabel', cellfun(@num2str, num2cell(0:0.5:1), ...
                              'UniformOutput', false), ...
                         'Box', 'off', ...
                         'HitTest', false, ...
                         'Toolbar', [], ...
                         'PickableParts', 'none', ...
                         'NextPlot', 'replacechildren');

                    r_min = floor(bbox(i, 2));
                    r_max = floor(r_min + bbox(i, 4));
                    c_min = floor(bbox(i, 1));
                    c_max = ceil(c_min + bbox(i, 3));

                    img = self.Frames{self.FrameIndex};
                    img = img(r_min:r_max, c_min:c_max);
                    img = imresize(img, [128, 128]);

                    self.ROIPlots(end+1) = imshow(img, ...
                         'Parent', roi_ax, ...
                         'Colormap', self.ColorMap);
                    self.ROIAxes(end+1) = roi_ax;
                    self.ROI(end+1) = roi;

                    self.TracePlots(end+1) = plot(trace, ...
                         'Parent', trace_ax, ...
                         'LineWidth', 1.25);
                    self.TraceAxes(end+1) = trace_ax;
                    self.TraceData(i, :) = trace;

                    y = y - 137.5;
               end
          end

          % figure callbacks
          function self = onKeyPress(self, ~, event)
               min_sz = 10;
               max_sz = 26;
               
               switch event.Key
                    case 'uparrow'
                         if (self.ROISize + 2) <= max_sz
                              self.ROISize = self.ROISize + 2;
                         end
                    case 'downarrow'
                         if (self.ROISize - 2) >= min_sz
                              self.ROISize = self.ROISize - 2;
                         end
                    case 'return'
                         panel_buttons = self.ROIPanel.Children;
                         panel_buttons = panel_buttons(arrayfun(@(child) isa(child, 'matlab.ui.control.UIControl'), ...
                              panel_buttons));

                         confirm_btn = panel_buttons(arrayfun(@(btn) strcmp(btn.Tag, 'confirm'), ...
                              panel_buttons));

                         confirm_btn.Callback([], []);
                    case 'escape'
                         response = self.popup(...
                              'Abandon the current FOV map? This action cannot be undone.', ...
                              'Confirmation', ...
                              {'Yes', 'No'});
     
                         switch response
                              case 'Yes'
                                   self = self.cleanup();
                              case 'No'
                                   % do nothing, return to mapping
                         end
               end

               self = self.onCursorMotion(self.Figure, []);
          end

          function self = onCursorMotion(self, src, ~)
               if ~strcmp(self.Status, 'Mapping')
                    return
               end

               persistent rect

               ax = src.Children(end);
               pointer_pos = round(ax.CurrentPoint(1, 1:2));

               valid_pos = (1 <= pointer_pos(1)) && (pointer_pos(1) <= 512) && ...
                    (1 <= pointer_pos(2)) && (pointer_pos(2) <= 512);

               if ~valid_pos
                    delete(rect)
                    return
               end

               sz = self.ROISize;

               x_pos = pointer_pos(1) - (sz/2);
               y_pos = pointer_pos(2) - (sz/2);

               if ~isempty(rect)
                    delete(rect)
               end

               rect = rectangle(...
                    'Parent', self.FrameAxes, ...
                    'Position', [x_pos, y_pos, sz, sz], ...
                    'FaceColor', 'none', ...
                    'EdgeColor', [1, 0, 0], ...
                    'LineWidth', 1);
          end

          function self = onClick(self, src, ~)
               if ~strcmp(self.Status, 'Mapping')
                    return
               end

               ax = src.Children(end);
               pos = round(ax.CurrentPoint(1, 1:2));

               valid_pos = (1 <= pos(1)) && (pos(1) <= 512) && ...
                    (1 <= pos(2)) && (pos(2) <= 512);

               if ~valid_pos
                    return
               end
               
               x_min = pos(1) - (self.ROISize / 2);
               x_max = pos(1) + (self.ROISize / 2);
               y_min = pos(2) - (self.ROISize / 2);
               y_max = pos(2) + (self.ROISize / 2);

               self.Map(y_min:y_max, x_min:x_max) = 1;

               self.ROI(end+1) = rectangle(...
                    'Parent', self.FrameAxes, ...
                    'Position', [x_min, y_min, self.ROISize, self.ROISize], ...
                    'FaceColor', 'none', ...
                    'EdgeColor', [1, 0, 0], ...
                    'LineWidth', 1);

               notify(self, 'newROI')
          end

          % timer callback
          function self = timerFcn(self, ~, ~)
               % only proceed if Status_ = 'Running'
               if ~strcmp(self.Status, 'Running')
                    return
               end

               % update status label
               notify(self, 'newStatus')

               % increment FrameIndex_ within valid bounds and
               % update displayed frame
               if (self.FrameIndex + 1) > numel(self.Frames)
                    self.FrameIndex = 1;
                    self.TraceData = zeros(size(self.TraceData));
               else
                    self.FrameIndex = self.FrameIndex + 1;
               end
          end
     end
end