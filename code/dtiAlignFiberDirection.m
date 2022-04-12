function [fg] = dtiAlignFiberDirection(fg,direction)
% We have to correct the direction of each fg.fiber in your fascicle before
% calculate diffusivities along tract
% 
% Input
% fg = fgRead(fgfile)
% direction = 'LR','AP','SI' 
%
% Example 
% fg = fgRead(fgfile)
% direction = 'LR'
% [fg] = dtiAlignFiberDirection(fg,direction)
%
% SO 2013

% %% argument check
% if isempty(fg.fibers);sprintf('error check the number of fibers');
% end;
% 
%% correct fiber direction
% fg.fibers contains x,y,z coordinates

switch direction
    case 'AP'
        for jj = 1:length(fg.fibers)
            if fg.fibers{jj}(2,1) < fg.fibers{jj}(2,end)
                fg.fibers{jj}= fliplr(fg.fibers{jj});
            end
        end
    case 'PA'
        for jj = 1:length(fg.fibers)
            if fg.fibers{jj}(2,1) > fg.fibers{jj}(2,end)
                fg.fibers{jj}= fliplr(fg.fibers{jj});
            end
        end        
    case 'LR'
        for jj = 1:length(fg.fibers)
            if fg.fibers{jj}(1,1) > fg.fibers{jj}(1,end)
                fg.fibers{jj}= fliplr(fg.fibers{jj});
            end
        end
    case 'SI'
        for jj = 1:length(fg.fibers)
            if fg.fibers{jj}(3,1) > fg.fibers{jj}(1,end)
                fg.fibers{jj}= fliplr(fg.fibers{jj});
            end
        end
end