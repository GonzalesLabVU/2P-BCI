classdef UIComponentFactory
     methods
          % constructor
          function self = UIComponentFactory()
               % pass
          end

          % create new button
          function button = createButton(self, parent, pos, icon, callback)
               button = uicontrol(...
                    'Parent', parent, ...
                    'Style', 'pushbutton', ...
                    'Position', pos, ...
                    'CData', self.loadIconData(icon), ...
                    'Callback', callback);
          end

          % create new label
          function label = createLabel(~, parent, pos, txt)
               label = uilabel(...
                    'Parent', parent, ...
                    'Position', pos, ...
                    'Text', txt, ...
                    'FontWeight', 'bold');
          end

          % load button CData from files
          function icon = loadIconData(~, filename)
               icon = imread(filename);
          end
     end
end