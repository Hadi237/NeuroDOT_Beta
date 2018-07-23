function h = PlotFalloffData(fall_data, separations, params)

% PLOTFALLOFFDATA A basic falloff plotting function.
%
%   PLOTFALLOFFDATA(data, info) takes one input array "fall_data" and plots
%   it against another "separations" to create a falloff plot.
%
%   PLOTFALLOFFDATA(data, info, params) allows the user to specify
%   parameters for plot creation.
% 
%   h = PLOTFALLOFFDATA(...) passes the handles of the plot line objects
%   created.
%
%   "params" fields that apply to this function (and their defaults):
%       fig_size    [200, 200, 560, 420]    Default figure position vector.
%       fig_handle  (none)                  Specifies a figure to target.
%                                           If empty, spawns a new figure.
%       xlimits     'auto'                  Limits of x-axis.
%       xscale      'linear'                Scaling of x-axis.
%       ylimits     'auto'                  Limits of y-axis.
%       yscale      'log'                   Scaling of y-axis.
%
% See Also: PLOTFALLOFFLL.

%% Parameters and Initialization.
LineColor = 'w';
BkgdColor = 'k';

ydims = size(fall_data);
Nt = ydims(end);
NDtf_fall = (ndims(fall_data) > 2);

xdims = size(separations);
Nsep = xdims(end);
NDtf_sep = (ndims(separations) > 2);

if ~exist('params', 'var')
    params = [];
end

if ~isfield(params, 'fig_size')  ||  isempty(params.fig_size)
    params.fig_size = [200, 200, 560, 420];
end
if ~isfield(params, 'fig_handle')  ||  isempty(params.fig_handle)
    params.fig_handle = figure('Color', BkgdColor, 'Position', params.fig_size);
    new_fig = 1;
else
    switch params.fig_handle.Type
        case 'figure'
            set(groot, 'CurrentFigure', params.fig_handle);
        case 'axes'
            set(gcf, 'CurrentAxes', params.fig_handle);
    end
end
if ~isfield(params, 'xlimits')  ||  isempty(params.xlimits)
    params.xlimits = 'auto';
end
if ~isfield(params, 'xscale')  ||  isempty(params.xscale)
    params.xscale = 'linear';
end
if ~isfield(params, 'ylimits')  ||  isempty(params.ylimits)
    params.ylimits = 'auto';
end
if ~isfield(params, 'yscale')  ||  isempty(params.yscale)
    params.yscale = 'log';
end

%% N-D Input.
if NDtf_fall
    fall_data = reshape(fall_data, [], Nt);
end

if NDtf_sep
    separations = separations(:);
end

if (size(fall_data, 1) ~= numel(separations))... % Not sure if this needed but whatever.
        (numel(fall_data) == numel(separations))
    error('*** Error: Falloff data and separation distances do not match. ***')
end

%% Calculate & Plot Data.
ydata = mean(fall_data, 2); % Take temporal mean.

h = plot(separations, ydata, '*');

%% Format Plot.
box on

a = gca;
a.Color = BkgdColor;
a.XColor = LineColor;
a.YColor = LineColor;
a.XGrid = 'on';
a.YGrid = 'on';

%% Resize.
xlim(params.xlimits)
ylim(params.ylimits)
a.XScale = params.xscale;
a.YScale = params.yscale;



%
