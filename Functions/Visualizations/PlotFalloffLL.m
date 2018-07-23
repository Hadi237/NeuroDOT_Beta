function PlotFalloffLL(data, info, params)

% PLOTFALLOFFLL A light-level falloff visualization.
%
%   PLOTFALLOFFLL(data, info) takes a light-level array "data" of the MEAS
%   x TIME format, and generates a plot of each channel's temporal mean
%   against its source-detector distance, in the specified groupings.
%
%   PLOTFALLOFFLL(data, info, params) allows the user to specify parameters
%   for plot creation.
%
%   "params" fields that apply to this function (and their defaults):
%       fig_size    [200, 200, 560, 420]    Default figure position vector.
%       fig_handle  (none)                  Specifies a figure to target.
%                                           If empty, spawns a new figure.
%       dimension   '2D'                    Dimension of pair radii used.
%       rlimits     (all R2D)               Limits of pair radii displayed.
%       Nnns        (all NNs)               Number of NNs displayed.
%       Nwls        (all WLs)               Number of WLs displayed.
%       useGM       0                       Use Good Measurements.
%       xlimits     [0, 60]                 Limits of x-axis.
%       xscale      'linear'                Scaling of x-axis.
%       ylimits     [1e-6, 1e1]             Limits of y-axis.
%       yscale      'log'                   Scaling of y-axis.
%
% Dependencies: PLOTFALLOFFDATA, ISTABLEVAR.

%% Parameters and Initialization.
LineColor = 'w';
BkgdColor = 'k';
FieldColor = [0.1, 0.1, 0.1];
cs = unique(info.pairs.WL); % WLs.
use_NNx_RxD = 'RxD';

dims = size(data);
Nt = dims(end);
NDtf = (ndims(data) > 2);
Nm = prod(dims(1:end-1));

lcell = {};
h = [];

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
if ~isfield(params, 'dimension')  ||  isempty(params.dimension)
    params.dimension = '2D';
end
if (~isfield(params, 'rlimits')  ||  isempty(params.rlimits))  &&...
        (~isfield(params, 'Nnns')  ||  isempty(params.Nnns))
    % If both empty, use ALL.
    use_NNx_RxD = 'all';
    lvar = 1;
else % Otherwise, set defaults if one or the other is missing.
    if ~isfield(params, 'rlimits')  ||  isempty(params.rlimits)
        use_NNx_RxD = 'NNx';
        lvar = params.Nnns;
    end
    if ~isfield(params, 'Nnns')  ||  isempty(params.Nnns)
        lvar = 1:size(params.rlimits, 1);
    end
end
if ~isfield(params, 'Nwls')  ||  isempty(params.Nwls)
    params.Nwls = cs';
end
if ~isfield(params, 'useGM')  ||  isempty(params.useGM)
    params.useGM = 0;
end
if ~params.useGM  ||  ~isfield(info, 'MEAS')  ||  (isfield(info, 'MEAS')  &&  ~istablevar(info.MEAS, 'GI'))
    GM = ones(Nm, 1);
else
    GM = info.MEAS.GI;
end
if ~isfield(params, 'xlimits')  ||  isempty(params.xlimits)
    params.xlimits = [0, 60];
end
if ~isfield(params, 'xscale')  ||  isempty(params.xscale)
    params.xscale = 'linear';
end
if ~isfield(params, 'ylimits')  ||  isempty(params.ylimits)
    params.ylimits = [1e-6, 1e1];
end
if ~isfield(params, 'yscale')  ||  isempty(params.yscale)
    params.yscale = 'log';
end

if istablevar(info.pairs, 'lambda')
    lambdas = unique(info.pairs.lambda);
    lambda_unit1 = '';
    lambda_unit2 = ' nm';
else
    lambdas = cs;
    lambda_unit1 = '\lambda';
    lambda_unit2 = '';
end

%% N-D Input.
if NDtf
    data = reshape(data, [], Nt);
end

%% Plot Data.
set(gca, 'ColorOrder', [0, 0, 1;... %Blue
    1, 0, 0;... %Red
    1, 1, 1;... %White
    0, 1, 0;... %Green
    1, .5, 0;... %Orange
    1, 0, 1]); % Purple
hold on
for k = params.Nwls
    for l = lvar
        switch use_NNx_RxD
            case 'NNx'
                keep = (info.pairs.WL == k)...
                    &  (info.pairs.NN == l)...
                    &  GM;
                % Omitting keepr here because if rlimits present, will
                % never use this branch.
                lcell{end+1} = ['NN', num2str(l), ', ', lambda_unit1,...
                    num2str(lambdas(k)), lambda_unit2];
            case 'RxD'
                keep = (info.pairs.WL == k)...
                    &  (info.pairs.(['r', lower(params.dimension)]) >= params.rlimits(l, 1))...
                    &  (info.pairs.(['r', lower(params.dimension)]) <= params.rlimits(l, 2))...
                    &  GM;
                lcell{end+1} = ['r', lower(params.dimension), ' \in [',...
                    num2str(params.rlimits(l, 1)), ', ',...
                    num2str(params.rlimits(l, 2)), '] mm, ',...
                    lambda_unit1, num2str(lambdas(k)), lambda_unit2];
            case 'all'
                keep = (info.pairs.WL == k)  &  GM;
                lcell{end+1} = ['All r', lower(params.dimension),...
                    ' and NN, ', lambda_unit1, num2str(lambdas(k)), lambda_unit2];
        end
        
        ydata = data(keep, :);
        xdata = info.pairs.(['r', lower(params.dimension)])(keep);
        
        if ~isempty(ydata)  &&  ~isempty(xdata)
            h(end+1) = PlotFalloffData(ydata, xdata, params);
        else
            lcell{end} = [];
        end
    end
end

%% Label.
tcell{1} = 'All Measurements Falloff';
if strcmp(use_NNx_RxD, 'all')
    tcell{1} = [tcell{1}, ', All r', lower(params.dimension), ' and NN'];
end
if params.useGM
    tcell{1} = [tcell{1}, ', GM'];
end
title(tcell, 'Color', LineColor)

xlabel('S-D Separation (mm)', 'Color', LineColor)
ylabel('Light Levels', 'Color', LineColor)

legend(h, lcell, 'Color', FieldColor, 'TextColor', LineColor,...
    'Location', 'southwest')



%
