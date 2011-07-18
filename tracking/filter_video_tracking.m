function outs = filter_video_tracking(data, filt)
% FILTER_VIDEO_TRACKING    Filters video tracking datasets
% CISMM function
% video
% 
% This function reads in a Video Tracking dataset, saved in the 
% matlab workspace file (*.mat) format and filters it using filter types
% defined below.
% 
% function filter_video_tracking(data, filt)
%
% where 
%       "data" 
%       "filt"
%	    "minFrames" 
%       "minPixels" 
%       "maxPixelRange" 
%       "tcrop" 
%       "xycrop" 
%       "minFrames"
%       "minPixelRange"
%       "tCrop" 
%       "xyCrop" 
%      
%       
%
% Notes:
% - This function is designed to work under default conditions with
%   only the filename as an input argument.
%
%Filters data from trackers that have few than minFrames datapoints
%less than minPixelRange in either x OR y.
%from the edge of each tracker in time by tCrop
%from the edge of the field of view by xyCrop
%
%USAGE:
%   function data = prune_data_table(data, minFrames, minPixelRange, units, calib_um, tCrop, xyCrop)
%
%   where:
%   'data' is the video table
%   'min_PixelRange' is the minimum range a tracker must move in either x OR Y if it is to be kept
%   'units' is either 'pixel' or 'um', refering to the position columns in 'data'
%   'calib_um' is the microns per pixel calibration of the image.
%
%   Note that x and y ranges are converted to pixels if and only if 'units'
%   is 'um'. In this case, then 'calib_um' must be supplied.
   
video_tracking_constants;

%  Handle inputs
if (nargin < 2) || isempty(filt)
    filt.min_frames = 0;
    filt.min_pixels = 0;
    filt.tcrop      = 0;
    filt.xycrop     = 0;
    filt.xyzunits   = 'pixels';
    filt.calib_um   = 1;
end

if (nargin < 1) || isempty(data); 
    logentry('No data inputs set. Exiting filter_video_tracking now.');
    outs = [];
    return;
end


    %  Handle filters

    % 'minframes' the minimum number of frames required to keep a tracker
    if isfield(filt, 'min_frames')
        data = filter_min_frames(data, filt.min_frames);
    end

    if isfield(filt, 'min_pixels');
        % going to assume pixels
        data = filter_min_pixel_range(data, filt.min_pixels);
    end

    if isfield(filt, 'tcrop');
        data = filter_tcrop(data, filt.tcrop);    
    end

    if isfield(filt, 'xycrop');
        data = filter_xycrop(data, filt.xycrop);
    end


    % Relabel trackers to have consecutive IDs
    beadlist = unique(data(:,ID));
    if length(beadlist) == max(beadlist)+1
    %     logentry('No empty trackers, so no need to redefine tracker IDs.');
    else
        logentry('Removing empty trackers, tracker IDs are redefined.');
        for k = 1:length(beadlist)
            idx = find(data(:,ID) == beadlist(k));
            data(idx,ID) = k-1;
        end
    end

    outs = data;

return;




% %%%%%%
% FILTER FUNCTIONS BELOW
% %%%%%%

   
function data = filter_min_frames(data, minFrames)
%   'minFrames' is the minimum number of frames required to keep a tracker

    video_tracking_constants;
    beadlist = unique(data(:,ID));

    for i = 1:length(beadlist)                  %Loop over all beadIDs.
        idx = find(data(:, ID) == beadlist(i)); %Get all data rows for this bead
        numFrames = length(idx);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
        % Remove trackers that are too short in time
        if(numFrames < minFrames)             %If this bead has too few datapoints
            idx = find(data(:, ID) ~= beadlist(i)); %Get the rest of the data
            data = data(idx, :);                    %Recreate data without this bead
            continue                                %Move on to next bead now
        end
    end
    
    return;


function data = filter_min_pixel_range(data, minPixelRange, xyzunits, calib_um)
    video_tracking_constants;
    beadlist = unique(data(:,ID));
    
    if nargin < 4 || isempty(calib_um)
        xyzunits = 'pixels';
        calib_um = 1;
    end
    
    xyzunits = 'pixels';

    for i = 1:length(beadlist)                  %Loop over all beadIDs.
        idx = find(data(:, ID) == beadlist(i)); %Get all data rows for this bead
        numFrames = length(idx);    

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Remove trackers with too short a range in x OR y
        xrange = max(data(idx, X)) - min(data(idx, X)); %Calculate xrange
        yrange = max(data(idx, Y)) - min(data(idx, Y)); %Calculate yrange
        %Handle unit conversion, if necessary.
        if(nargin > 3)
            if strcmp(xyzunits,'m')
                calib = calib_um * 1e-6;  % convert calibration from um to meters
            elseif strcmp(xyzunits,'um')
                calib = calib_um;         % define calib as calib_um
            elseif strcmp(xyzunits,'nm')
                calib =  calib_um * 1e3;  % convert calib from um to nm
            else 
                calib = 1;
            end  
                xrange = xrange / calib;
                yrange = yrange / calib;
        end
        
        %Delete this bead iff necesary
        if(xrange<minPixelRange && yrange<minPixelRange) %If this bead has too few datapoints
            idx  = find(data(:, ID) ~= beadlist(i));     %Get all data rows for this bead
            data = data(idx, :);                         %Recreate data without this bead
           continue                                     %Move on to next bead now
        end
    end    
    
    return;


function data = filter_tcrop(data, tCrop)
    video_tracking_constants;    
    beadlist = unique(data(:,ID));
    
    for i = 1:length(beadlist)                  %Loop over all beadIDs.
        idx = find(data(:, ID) == beadlist(i)); %Get all data rows for this bead
        numFrames = length(idx);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Remove the frames before and after tCrop
        if(numFrames <= 2*tCrop)
            data(idx,:) = [];
            continue
        elseif(tCrop >= 1)
            firstFrames = 1:tCrop;
            lastFrames  = ceil(1+numFrames-tCrop):numFrames;
            data(idx([firstFrames lastFrames]),:) = [];         %Delete these rows
            % Update rows index
            idx = find(data(:, ID) == beadlist(i)); %Get all data rows for this bead
            numFrames = length(idx);
        end
    end
    
    return;


%Perform xyCrop
function data = filter_xycrop(data, xycrop)
    video_tracking_constants;
    
    minX = min(data(:,X)); maxX = max(data(:,X));
    minY = min(data(:,Y)); maxY = max(data(:,Y));

    xIDXmin = find(data(:,X) < (minX+xycrop)); xIDXmax = find(data(:,X) > (maxX-xycrop));
    yIDXmin = find(data(:,Y) < (minY+xycrop)); yIDXmax = find(data(:,Y) > (maxY-xycrop));

    DeleteRowsIDX = unique([xIDXmin; yIDXmin; xIDXmax; yIDXmax]);

    data(DeleteRowsIDX,:) = [];

    return;


% function for writing out stderr log messages
function logentry(txt)
    logtime = clock;
    logtimetext = [ '(' num2str(logtime(1),  '%04i') '.' ...
                   num2str(logtime(2),        '%02i') '.' ...
                   num2str(logtime(3),        '%02i') ', ' ...
                   num2str(logtime(4),        '%02i') ':' ...
                   num2str(logtime(5),        '%02i') ':' ...
                   num2str(round(logtime(6)), '%02i') ') '];
     headertext = [logtimetext 'filter_video_tracking: '];
     
     fprintf('%s%s\n', headertext, txt);
     
     return;