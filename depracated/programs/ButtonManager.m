classdef ButtonManager
     properties
          File
          Save
          Seed
          Analyze

          PlayPause
     end

     methods
          % constructor
          function self = ButtonManager(uiFactory, parent)
               path = 'C:\Users\Max\Documents\Classes\Gonzales Lab\Two Photon\images';
               y = parent.Position(4) - 40;

               % top buttons
               self.File = uiFactory.createButton(...
                    parent, ...
                    [10, y, 30, 30], ...
                    fullfile(path, 'load_icon.png'), ...
                    @(~, ~) self.loadFcn);
               self.Save = uiFactory.createButton(...
                    parent, ...
                    [45, y, 30, 30], ...
                    fullfile(path, 'save_icon.png'), ...
                    @(~, ~) self.saveFcn);
               self.Seed = uiFactory.createButton(...
                    parent, ...
                    [80, y, 30, 30], ...
                    fullfile(path, 'seed_icon.png'), ...
                    @(~, ~) self.seedFcn);
               self.Analyze = uiFactory.createButton(...
                    parent, ...
                    [115, y, 30, 30], ...
                    fullfile(path, 'analyze_icon.png'), ...
                    @(~, ~) self.analyzeFcn);

               % bottom buttons
               self.PlayPause = uiFactory.createButton(...
                    parent, ...
                    [250, 27.5, 30, 30], ...
                    fullfile(path, 'play_icon.png'), ...
                    @(~, ~) self.playPauseFcn);
          end

          % load callback
          function self = loadFcn(self)
               disp('load')
          end

          % play/pause callback
          function self = playPauseFcn(self)
               disp('play/pause')
          end

          % save callback
          function self = saveFcn(self)
               disp('save')
          end

          % seed callback
          function self = seedFcn(self)
               disp('seed')
          end

          % analyze callback
          function self = analyzeFcn(self)
               disp('analyze')
          end
     end
end