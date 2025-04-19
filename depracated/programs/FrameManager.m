classdef FrameManager
     properties
          Parent
          Axes

          Frames
          FrameIndex
          CurrentFrame
     end

     methods
          % constructor
          function self = FrameManager(parent)
               self.FrameIndex = 1;
               self.Frames = {};
               self.CurrentFrame = [];

               self.Parent = parent;
               self.Axes = uiaxes(...
                    'Parent', self.Parent, ...
                    'Position', [50, 85, 512, 512], ...
                    'Toolbar', [], ...
                    'XTick', [], ...
                    'XLim', [1, 512], ...
                    'XTickLabel', '', ...
                    'YTick', [], ...
                    'YLim', [1, 512], ...
                    'YTickLabel', '', ...
                    'TickDir', 'none');
          end

          % assign frames from loaded file
          function self = loadFrames(self, filename)
               self.Frames = self.loadFile(filename);

               self.FrameIndex = 1;
               self.CurrentFrame = imshow(self.Frames{1}, ...
                    'Parent', self.Axes, ...
                    'Colormap', gray(256));
          end

          % update displayed frame with new FrameIndex
          function self = updateFrameDisplay(self)
               set(self.CurrentFrame, 'CData', self.Frames{self.FrameIndex})
          end

          % load data from files
          function self = loadFile(self, filename)
               file = matfile(filename);

               vars = properties(file);
               vars = vars(~cellfun('isempty', regexp(vars, '^frames_')));
               
               start_frame = cellfun(@(x) str2double(regexp(x, '(?<=frames_)(\d+)', 'match')), vars);
               [~, sorted_idx] = sort(start_frame);
               sorted_vars = vars(sorted_idx);

               data = [];
               for i = 1:numel(sorted_vars)
                    subset = file.(sorted_vars{i});
                    data = cat(3, data, subset);
               end

               data = mat2cell(data, 512, 512, ones(1, size(data, 3)));
               self.Frames = data;
          end
     end
end