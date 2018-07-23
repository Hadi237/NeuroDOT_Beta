function PlotMeshSurface(mesh, params)

% PLOTMESHSURFACE Creates a 3D surface mesh visualization.
% 
%   PLOTMESHSURFACE(mesh) creates a 3D visualization of the surface mesh
%   "mesh". If no region data is provided in "mesh.region", all nodes will
%   be assumed to form a single region. If a field "data" is provided as
%   part of the "mesh" structure, that data will be used to color the
%   visualization. If both "data" and "region" are present, the "region"
%   values are used as an underlay for the colormapping.
%   
% 
%   PLOTMESHSURFACE(mesh, params) allows the user to specify parameters
%    for plot creation.
%
%   "params" fields that apply to this function (and their defaults):
%       fig_size    [20, 200, 1240, 420]        Default figure position
%                                               vector.
%       fig_handle  (none)                      Specifies a figure to
%                                               target.
%       Cmap.P      'jet'                       Colormap for positive data
%                                               values.
%       BG          [0.8, 0.8, 0.8]             Background color, as an RGB
%                                               triplet.
%       orientation 't'                         Select orientation of
%                                               volume. 't' for transverse,
%                                               's' for sagittal.
% 
%   Note: APPLYCMAP has further options for using "params" to specify
%   parameters for the fusion, scaling, and colormapping process.
% 
% Dependencies: APPLYCMAP
% 
% See Also: PLOTSLICES, PLOTCAP, CAP_FITTER.


%% Parameters and Initialization
LineColor = 'k';
new_fig = 0;

if ~exist('params', 'var')
    params = [];
end

if ~isfield(params, 'orientation')
    params.orientation = 's';
end

if ~isfield(params, 'BG')  ||  isempty(params.BG)
    params.BG = [0.8, 0.8, 0.8];%'w';%
end

if ~isfield(params, 'fig_size')  ||  isempty(params.fig_size)
    params.fig_size = [20, 200, 560, 560];
end
if ~isfield(params, 'fig_handle')  ||  isempty(params.fig_handle)
    params.fig_handle = figure('Color',  'w',...
        'Position', params.fig_size);
    new_fig = 1;
else
    switch params.fig_handle.Type
        case 'figure'
            set(groot, 'CurrentFigure', params.fig_handle);
        case 'axes'
            set(gcf, 'CurrentAxes', params.fig_handle);
    end
end

if ~isfield(params,'Cmap'), params.Cmap='jet';end
if ~isfield(params,'alpha'), params.alpha=1;end % Transparency
if ~isfield(params,'OL'), params.OL=0;end
if ~isfield(params,'reg'), params.reg=1;end
if ~isfield(params,'TC'),params.TC=0;end  
if ~isfield(params,'PD'), params.PD=0;end


%% Get face centers of elements for S/D pairs.
switch size(mesh.elements, 2)
    case 4  % extract surface mesh from volume mesh
        TR = triangulation(mesh.elements, mesh.nodes);
        [m.elements, m.nodes] = freeBoundary(TR);
        [~, Ib] = ismember(m.nodes, mesh.nodes, 'rows');
        Ib(Ib == 0) = []; % Clear zero indices.
        if isfield(mesh,'region'), m.region=mesh.region(Ib);end
        if isfield(mesh,'data'), m.data=mesh.data(Ib);end
    case 3
        m=mesh;
end


%% mesh.data and mesh.region together determine coloring rules

if isfield(m,'region') && ~params.reg
    m=rmfield(m,'region');
end
    
if ~isfield(m,'data')       % NO DATA
    if ~isfield(m,'region') % no data, no regions
        FaceColor = [0.25, 0.25, 0.25];
        EdgeColor = [0.25, 0.25, 0.25];%BkgdColor;
        FaceLighting = 'flat';
        AmbientStrength = 0.5;        
        h = patch('Faces', m.elements, 'Vertices',m.nodes,...
            'EdgeColor', EdgeColor, 'FaceColor', FaceColor,...
            'FaceLighting', FaceLighting,...
            'AmbientStrength', AmbientStrength);        
        
    else                      % data are regions               
        params.PD=1;
        params.TC=1;
        params.DR=max(m.region(:));
        tempCmap=params.Cmap;
        params.Cmap=eval([tempCmap, '(', num2str(params.DR), ');']);
        EdgeColor =  params.BG; % or 'none'
        FaceColor = 'flat';
        FaceLighting = 'gouraud';
        AmbientStrength = 0.25;
        DiffuseStrength = 0.75; % or 0.75
        SpecularStrength = 0.1;        
        FV_CData=params.Cmap(mode(reshape(m.region(m.elements(:)),[],3),2),:);        
        h = patch('Faces', m.elements, 'Vertices', m.nodes,...
            'EdgeColor', EdgeColor, 'FaceColor', FaceColor,...
            'FaceVertexCData', FV_CData, 'FaceLighting', FaceLighting,...
            'AmbientStrength', AmbientStrength, 'DiffuseStrength',... 
            DiffuseStrength,'SpecularStrength', SpecularStrength);        
    end
    
else                        % DATA
    if ~isfield(m,'region') % no regions
        FV_CData = applycmap(underlay, [], params);
    else                    % with regions
        FV_CData = applycmap(m.data, m.region, params);
    end
    EdgeColor =  params.BG; % or 'none'
    FaceColor = 'interp';
    FaceLighting = 'gouraud';
    AmbientStrength = 0.25;
    DiffuseStrength = 0.75; % or 0.75
    SpecularStrength = 0.1;
    h = patch('Faces', m.elements, 'Vertices', m.nodes,...
        'EdgeColor', EdgeColor, 'FaceColor', FaceColor,...
        'FaceVertexCData', FV_CData, 'FaceLighting', FaceLighting,...
        'AmbientStrength', AmbientStrength, 'DiffuseStrength',...
        DiffuseStrength,'SpecularStrength', SpecularStrength);
end
        
        
set(gca, 'Color', params.BG);%, 'XTick', [], 'YTick', [], 'ZTick', []);

switch params.orientation
    case 's'
        set(gca, 'ZDir', 'rev');
    case 't'
        set(gca, 'XDir', 'rev');
    case 'c'
        set(gca, 'YDir', 'rev');
end

axis image
% axis off
hold on
rotate3d on


%% Set additional lighting
% Lower lighting
light('Position', [-140, 90, -100], 'Style', 'local')
light('Position', [-140, -350, -100], 'Style', 'local')
light('Position', [300, 90, -100], 'Style', 'local')
light('Position', [300, -350, -100], 'Style', 'local')

% Higher lighting
light('Position', [-140, 90, 360], 'Style', 'local');
light('Position', [-140, -350, 360], 'Style', 'local');
light('Position', [300, 90, 360], 'Style', 'local');
light('Position', [300, -350, 360], 'Style', 'local');

xlabel('X', 'Color', LineColor)
ylabel('Y', 'Color', LineColor)
zlabel('Z', 'Color', LineColor)

if new_fig
    view(163, -86)
end

if isfield(params,'side')
    switch params.side
        case 'post'
            light('Position',[-500,-20,0],'Style','local');
            light('Position',[500,-20,0],'Style','local');
            light('Position',[0,-200,50],'Style','local');
        case 'dorsal'
            light('Position',[-500,-20,100],'Style','local');
            light('Position',[500,-20,100],'Style','local');
            light('Position',[100,-200,200],'Style','local');
            light('Position',[100,200,200],'Style','local');
            light('Position',[0,200,0],'Style','local');
            light('Position',[200,200,0],'Style','local');
            light('Position',[100,500,100],'Style','local');
        case 'coronal'
            if ~any(m.nodes(:)<0)
                light('Position',[-500,-20,100],'Style','local');
                light('Position',[500,-20,100],'Style','local');
                light('Position',[100,-200,200],'Style','local');
                light('Position',[100,200,200],'Style','local');
                light('Position',[0,200,0],'Style','local');
                light('Position',[200,200,0],'Style','local');
                light('Position',[100,500,100],'Style','local');
            else
                mm=mean(m.nodes);
                x=-mm(1);y=mm(2);z=-mm(3);
                light('Position',[-(x+400),y-150,z],'Style','local');
                light('Position',[x+400,y-150,z],'Style','local');
                light('Position',[x,-(y+50),z+100],'Style','local');
                light('Position',[x,y+50,z+100],'Style','local');
                % light('Position',[100,200,0],'Style','local');
                light('Position',[x-100,y+50,z-100],'Style','local');
                light('Position',[x+100,y+50,z-100],'Style','local');
                light('Position',[x,y+350,z],'Style','local');
            end
            
    end
end

%
