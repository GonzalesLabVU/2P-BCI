classdef PrairieDisplay < handle
     properties
          Figure
          StatusLabel

          FrameManager
          ROIManager
          ButtonManager
          UIComponentFactory
     end

     methods
          % constructor
          function self = PrairieDisplay()
               format short, format compact
               close all force
               clc

               self.Figure = uifigure(...
                    'Name', 'CalciumTracer', ...
                    'Position', [75, 125, 1350, 650], ...
                    'Resize', 'on', ...
                    'AutoResizeChildren', 'on', ...
                    'Visible', 'off');

               self.UIComponentFactory = UIComponentFactory();
               self.FrameManager = FrameManager(self.Figure);
               self.ROIManager = ROIManager(self.Figure, gca, []);
               self.ButtonManager = ButtonManager(self.UIComponentFactory, self.Figure);

               self.initializeUI();
          end

          % UI initialization
          function self = initializeUI(self)
               disp('Initializing...')

               set(self.Figure, 'Visible', 'on')
          end
     end
end