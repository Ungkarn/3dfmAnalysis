function varargout = sim_video_diff_expt(filename, in_struct)
% SIM_VIDEO_DIFF_EXPT simulates a bead diffusion experiment for a Newtonian fluid
%
% 3DFM function
% specific/modeling
% last modified 2013.08.29 (yingzhou)
%
% This function simulates a bead diffusion experiment for a Newtonian
% fluid.  
%
% [sim, out_struct] = sim_video_diff_expt(filename, in_struct)
%
% where "filename" is the filename where the simulation will be saved 
%                  (uses evt_GUI 'evt' format) 
%       "in_struct" is a structure that specifies the paramters for the
%                   simulation.  Its fields include:
%
%         in_struct.seed = seed value to give to random number generator.
%                          If this value is absent, the generator uses the 
%                          system time as the seed.
%         in_struct.numpaths = number of bead paths.  Default: 10.
%         in_struct.viscosity = solution viscosity in [Pa s].  Default: 0.023 (2 M sucrose).
%         in_struct.bead_radius = bead radius in [m].  Default: 0.5e-6. 
%         in_struct.frame_rate = frame rate of camera in [fps].  Default: 30.
%         in_struct.duration = duration of video in [s].  Default: 60.
%         in_struct.tempK = temperature of fluid in [K].  Default: 300.
%         in_struct.field_width = width of video frame in [px].  Default: 648.
%         in_struct.field_height = height of video frame in [px].  Default: 484.
%         in_struct.calib_um = conversion unit in [microns/pixel].  Default: 0.152.
%         in_struct.xdrift_vel = x-drift in [meters/frame].  Default: 0.
%         in_struct.ydrift_vel = y-drift in [meters/frame].  Default: 0.
%         in_struct.rad_confined = the particle's radius of confinement in [m]. Default: Inf.
%         in_struct.alpha = anomalous diffusion constant. Default: 1.
%         in_struct.dim = dimension of the diffusion (usually 1D, 2D, or
%         3D)
%         in_struct.modulus = modulus of the fluid [Pa]. Default: 2.2e9 (bulk modulus of water).
 
% Determine the type of model needed for the simulation based on the input
% structure
if isfield(in_struct, 'viscosity')&&isfield(in_struct, 'alpha')&&isfield(in_struct, 'xdrift_vel')&&isfield(in_struct, 'ydrift_vel')
    model_type = 'DAV';
elseif isfield(in_struct, 'viscosity')&&isfield(in_struct, 'alpha')
    model_type = 'DA';
elseif isfield(in_struct, 'viscosity')&&isfield (in_struct, 'rad_confined')
    model_type = 'DR';
elseif isfield(in_struct, 'viscosity')&&isfield(in_struct, 'xdrift_vel')&&isfield(in_struct, 'ydrift_vel')
    model_type = 'DV';
elseif isfield(in_struct, 'xdrift_vel')&&isfield(in_struct, 'ydrift_vel')
    model_type = 'V';
elseif isfield(in_struct, 'viscosity')
    model_type = 'D';
elseif isfield(in_struct, 'modulus')
    model_type = 'N';
end

logentry(['Parameters indicate a ' model_type ' model type.']);    

video_tracking_constants; 


if nargin < 2 || isempty(in_struct)
    logentry('Model parameters are not set.  Will create the default simulation.');
    in_struct = [];
end

if ~exist('filename', 'var') || isempty(filename)
    logentry('Not saving data to file.');
end

in_struct = param_check(in_struct);

    seed         = in_struct.seed;           %#ok<NASGU>
    numpaths     = in_struct.numpaths;
    viscosity    = in_struct.viscosity;      % [Pa s]
    bead_radius  = in_struct.bead_radius;    % [m]
    frame_rate   = in_struct.frame_rate;     % [frames/sec]
    duration     = in_struct.duration;       % [sec]
    tempK        = in_struct.tempK;          % [K]
    field_width  = in_struct.field_width;    % [pixels]
    field_height = in_struct.field_height;   % [pixels]
    calib_um     = in_struct.calib_um;       % [um/pixel]
    xdrift_vel   = in_struct.xdrift_vel;     % [m/frame]
    ydrift_vel   = in_struct.ydrift_vel;     % [m/frame]
    rad_confined = in_struct.rad_confined;   % [m]
    alpha        = in_struct.alpha;          % slope of loglog(MSD) plot
    modulus      = in_struct.modulus;        % [Pa]


    % simulation test
    simout = [];

    % time vector
    t = (1/frame_rate) * [1:(frame_rate*duration)]' - (1/frame_rate);  %#ok<NBRAK>

    % vector of frame ID's
    fr = [1:(frame_rate*duration)]'; %#ok<NBRAK>
       
    % xy tracker locations with zero offset        
    switch model_type  % to select the model functions to run
        case 'N'
            xy = sim_boltzmann_solid(modulus, bead_radius, frame_rate, duration, tempK, 2, numpaths);
        case 'D'
            xy = sim_newt_fluid(viscosity, bead_radius, frame_rate, duration, tempK, 2, numpaths);
        case 'V'
            in_struct.viscosity = 1e9;
            viscosity=in_struct.viscosity;
            xy = sim_newt_fluid(viscosity, bead_radius, frame_rate, duration, tempK, 2, numpaths);
        case 'DV'
            xy = sim_newt_fluid(viscosity, bead_radius, frame_rate, duration, tempK, 2, numpaths);
        case 'DR'
            xy = confined_diffusion (viscosity, bead_radius, frame_rate, duration, tempK, 2, numpaths, rad_confined); 
        case 'DA'
            xy = fBmXY_HD(viscosity, bead_radius, frame_rate, duration, tempK, numpaths, alpha);
        case 'DAV'
            xy = fBmXY_HD(viscosity, bead_radius, frame_rate, duration, tempK, numpaths, alpha); 
        otherwise
            error('Cannot select model type from the parameters given in the input structure.');
    end
    
    
        % create random starting locations (offsets) within the prescribed field
    position_offsets = repmat(rand(1,2,numpaths), [frame_rate*duration,1,1]).* ...
                       repmat([field_width field_height],[frame_rate*duration,1,numpaths]) .* ...
                       (calib_um / 1e6);

    % apply the random starting location 
    xy = xy + position_offsets;
    
    % drift vector for independent drift velocities in x and y
    accumulated_drift = cumsum( repmat([xdrift_vel ydrift_vel], ...
                                       [frame_rate*duration, 1, ...
                                       numpaths] ) );
    % apply the drift-drift is already applied for all cases in 
    xy = xy + accumulated_drift;
    
    % extraneous columns in the vrpn.mat format
    zrpy = zeros(frame_rate*duration,4);

% Clip data to "camera" field
% idx = find( simout(:,X) >=            0  & ...
%             simout(:,X) <=  field_width  & ...
%             simout(:,Y) >=            0  & ...
%             simout(:,Y) <= field_height  );
% simout = simout(idx,:);

for k = 1:numpaths;     
    % vector of tracker ID's
    id = ones(frame_rate*duration,1)*k; 
    

    % add this tracker's data to the output table
    simout = [simout; t, id,  fr,  xy(:,:,k), zrpy];
    
end;

% convert physical locations to pixel locations to simulate expt
simout(:,X:Y) = simout(:,X:Y) / (calib_um/1e6);  % puts into pixels

if exist('filename', 'var') && ~isempty(filename)
    save_vrpnmatfile(filename, simout, 'pixels', 1);
%     csvwrite([filename '.csv'], simout);
    logentry(['Saved data to file: ' filename]);
end



switch nargout
    case 1
        varargout{1} = simout;
    case 2
        varargout{1} = simout;
        varargout{2} = in_struct;            
end;

return;


function out = param_check(in)

    if ~isfield(in, 'seed') || isempty(in.seed)
        in.seed = sum(100000*clock);
    end
    
    if ~isfield(in, 'numpaths') || isempty(in.numpaths)
        in.numpaths = 10;
    end
    
    if ~isfield(in, 'viscosity') || isempty(in.viscosity)
        in.viscosity = 0.023;     % [Pa s]
    end
    
    if ~isfield(in, 'bead_radius') || isempty(in.bead_radius)
        in.bead_radius = 0.5e-6;  % [m]
    end

    if ~isfield(in, 'frame_rate') || isempty(in.frame_rate)
        in.frame_rate = 30;       % [frames/sec]
    end

    if ~isfield(in, 'duration') || isempty(in.duration)
        in.duration = 60;        % [sec]
    end
    
    if ~isfield(in, 'tempK') || isempty(in.tempK)
        in.tempK = 300;        % [K]
    end

    if ~isfield(in, 'field_width') || isempty(in.field_width)
        in.field_width = 648;     % [pixels]
    end

    if ~isfield(in, 'field_height') || isempty(in.field_height)
        in.field_height = 484;    % [pixels]
    end

    if ~isfield(in, 'calib_um') || isempty(in.calib_um)
        in.calib_um = 0.152;      % [um/pixel]
    end

    if ~isfield(in, 'xdrift_vel') || isempty(in.xdrift_vel)
        in.xdrift_vel = 0;   % [m/frame]
    end

    if ~isfield(in, 'ydrift_vel') || isempty(in.ydrift_vel)
        in.ydrift_vel = 0;   % [m/frame]
    end
    
    if ~isfield(in, 'rad_confined') || isempty(in.rad_confined)
        in.rad_confined = Inf;   % [m]
    end
    
    if ~isfield(in, 'alpha') || isempty(in.alpha)
        in.alpha = 1;   % [unitless]
    end

    if ~isfield(in, 'modulus') || isempty(in.modulus)
        in.modulus = 2.2e9;   % [Pa]
    end
    
    out = in;
    
return;

function logentry(txt)
    logtime = clock;
    logtimetext = [ '(' num2str(logtime(1),  '%04i') '.' ...
                   num2str(logtime(2),        '%02i') '.' ...
                   num2str(logtime(3),        '%02i') ', ' ...
                   num2str(logtime(4),        '%02i') ':' ...
                   num2str(logtime(5),        '%02i') ':' ...
                   num2str(round(logtime(6)), '%02i') ') '];
     headertext = [logtimetext 'sim_video_diff_expt: '];
     
     fprintf('%s%s\n', headertext, txt);
