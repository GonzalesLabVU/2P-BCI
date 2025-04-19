classdef ROIManager
     properties
          ROI
          ROIPanel
          ROIPlots
          ROIAxes
          ROISize
          Map
     end

     methods
          % constructor
          function self = ROIManager(panel, ax, map)
               self.ROI = [];
               self.ROIPlots = gobjects(0);
               self.ROISize = 18;

               self.ROIPanel = panel;
               self.ROIAxes = ax;
               self.Map = map;
          end

          % create new ROI from input position
          function self = createROI(self, pos)
               roi = rectangle(...
                    'Parent', self.ROIAxes, ...
                    'Position', pos);
               self.ROI(end+1) = roi;
          end

          % update displayed ROIs
          function self = updateROI(self)
               for i = 1:numel(self.ROI)
                    set(self.ROIPlots(i), 'CData', self.Map(self.ROI(i).Position));
               end
          end

          % plot display cleanup
          function self = cleanup(self)
               delete(self.ROIPlots)
               delete(self.ROI)

               self.ROIPlots = gobjects(0);
               self.ROI = [];
          end
     end
end