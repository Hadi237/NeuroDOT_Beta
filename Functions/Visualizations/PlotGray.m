function PlotGray(data, info, params)%, pulse)

% PLOTGRAY A visualization of data as a scaled image.
%
%   PLOTGRAY(data, info) takes a light-level array "data" of the MEAS x
%   TIME format, and generates a grayscale plot of all the measurements in
%   the specified groupings.
%
%   PLOTGRAY(data, info, params) allows the user to specify parameters for
%   plot creation.
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
%       climits     [-0.03, 0.03]           Limits of color axis.
%
% Dependencies: PLOTGRAYDATA, ISTABLEVAR.

%% Parameters and initialization.
BkgdColor = 'k';
LineColor = 'w';
cs = unique(info.pairs.WL); % WLs.
use_NNx_RxD = 'RxD';

dims = size(data);
Nt = dims(end);
NDtf = (ndims(data) > 2);
Nm = prod(dims(1:end-1));

WL_img = [];
ys = []; xs = [];

if ~exist('params', 'var')
    params = [];
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
if ~isfield(params, 'climits')  ||  isempty(params.climits)
    params.climits = [-0.03, 0.03];
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

% THIS STUFF COMES LAST BECAUSE IT NEEDS params.Nwls TO BE SET FIRST.
if ~isfield(params, 'fig_size')  ||  isempty(params.fig_size)
    params.fig_size = [200, 200, 100+440*numel(params.Nwls), 420];
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

xspacing = round(Nt * numel(params.Nwls) * 1e-2);
yspacing = 20;

%%% Pulse functionality deprecated for now.
% % if ~isfield(params, 'show_pulses')  ||  isempty(params.show_pulses)
% %     params.show_pulses = 0;
% % end
% % if ~exist('pulse', 'var')
% %     pulse = 'Pulse_1';
% % end
% % if isnumeric(pulse)
% %     pulse = ['Pulse_', num2str(pulse)];
% % elseif ischar(pulse)  &&  isempty(strfind(pulse, 'Pulse_'))
% %     pulse = ['Pulse_', pulse];
% % end

%% N-D Input.
if NDtf
    data = reshape(data, [], Nt);
end

%% Plot Data.
% Concatenate images vertically by NN, horizontally by WL, then plot them
% all.
hold on
for k = params.Nwls
    l_img = [];
    for l = lvar
        switch use_NNx_RxD
            case 'NNx'
                keep = (info.pairs.WL == k)...
                    &  (info.pairs.NN == l)...
                    &  GM;
                % Omitting keepr here because if rlimits present, will
                % never use this branch.
            case 'RxD'
                keep = (info.pairs.WL == k)...
                    &  (info.pairs.(['r' lower(params.dimension)]) >= params.rlimits(l, 1))...
                    &  (info.pairs.(['r' lower(params.dimension)]) <= params.rlimits(l, 2))...
                    &  GM;
            case 'all'
                keep = (info.pairs.WL == k)  &  GM;
        end
        
        l_img = [l_img; params.climits(1) * ones(yspacing, Nt); data(keep, :)];
        
        ys(end+1, :) = size(l_img);
    end
    WL_img = [WL_img, params.climits(1) * ones(size(l_img, 1) - yspacing, xspacing), l_img(yspacing + 1:end, :)];
    xs(end+1, :) = size(WL_img);
end
final_img = WL_img(:, xspacing + 1:end);

if ~isempty(final_img)  &&  (nnz(final_img) > 0)
    PlotGrayData(final_img, params)%, pulse)
end

%% Plot synchs and start and stop pulses. (if directed to)
%%% Pulse functionality deprecated for now. Not essential to release.
% % if params.show_pulses
% %     if isfield(info.paradigm, 'synchpts')
% %         for m = 1:length(info.paradigm.synchpts)
% %             plot([1, 1] * info.paradigm.synchpts(m),...
% %                 [1, size(final_image, 1)], 'c', 'LineWidth', 2)
% %         end
% %     end
% %     if isfield(info.paradigm, 'Pulse_1')
% %         for m = 1:length(info.paradigm.(pulse))
% %             plot([1, 1] * info.paradigm.synchpts(info.paradigm.(pulse)(m)),...
% %                 [1, size(final_image, 1)], 'm', 'LineWidth', 2)
% %         end
% %     end
% % end

%% Formatting.
axis tight
colorbar(gca, 'Color', LineColor)

%% Labels.
tcell{1} = 'Gray Plot';
if strcmp(use_NNx_RxD, 'all')
    tcell{1} = [tcell{1}, ', All r', lower(params.dimension), ' and NN'];
end
if params.useGM
    tcell{1} = [tcell{1}, ', GM'];
end
tcell{end+1} = '';
title(tcell, 'Color', LineColor)

xlabel('Time (data points)')

% Special tick marks.
a = gca;
ys(:, 2) = [];
ys = unique(ys);
a.YTick = mean([ys, [0; ys(1:end - 1) + yspacing]], 2);
switch use_NNx_RxD
    case 'NNx'
        a.YTickLabel = cellstr(num2str(params.Nnns(:), '\\bf NN%d\r'));
    case 'RxD'
        a.YTickLabel = cellstr(num2str(params.rlimits,...
            ['\\bf %d \\leq r', lower(params.dimension), ' \\leq %d\r']));
        a.YTickLabelRotation = 90;
    case 'both'
        a.YTickLabel = cellstr([num2str(params.rlimits,...
            ['\\bf %d \\leq r', lower(params.dimension), ' \\leq %d\r']),...
            repmat(', ', lvar(end), 1), num2str(params.Nnns(:), 'NN%d\r')]);
        a.YTickLabelRotation = 90;
    case 'all'
        a.YTickLabel = 'All r and NN';
        a.YTickLabelRotation = 90;
end

xs(:, 1) = [];
xs = mean([xs - xspacing, [0; xs(1:end-1)]], 2);
for k = 1:numel(params.Nwls)
    d = text(xs(k), size(final_img, 1),...
        ['\bf', lambda_unit1, num2str(lambdas(params.Nwls(k))), lambda_unit2],...
        'Color', LineColor);
    d.Units = 'normalized';
    d.Position = d.Position + [0, 0.03, 0];
end

b = a.XTick(a.XTick <= Nt);
c = a.XTickLabel(a.XTick <= Nt);
a.XTick = [];
a.XTickLabel = [];
for k = 1:numel(params.Nwls)
    a.XTick = [a.XTick, b + (k - 1) * Nt + xspacing];
    a.XTickLabel = [a.XTickLabel, c];
end



%
