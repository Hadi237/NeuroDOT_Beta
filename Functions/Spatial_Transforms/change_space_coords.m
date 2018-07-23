function coord_out = change_space_coords(coord_in, space_info, input_type)

% CHANGE_SPACE_COORDS Applies a look up to change 3D coordinates into a new
% space.
% 
%   coord_out = CHANGE_SPACE_COORDS(coord_in, space_info, input_type) takes
%   a set of coordinates "coord_in" of the initial space "input_type", and
%   converts them into the new space defined by the structure "space_info",
%   which is then output as "coord_out".
% 
% See Also: AFFINE3D_IMG.

%% Parameters and initialization
if ~exist('input_type', 'var')
    input_type = 'coord';
end

% Define the voxel space.
nVxA = space_info.nVx;
nVyA = space_info.nVy;
nVzA = space_info.nVz;
drA = space_info.mmppix;
centerA = space_info.center; % i.e., center = coordinate of center of voxel with index [-1,-1,-1]
nV = size(coord_in, 1);

% Preallocate.
coord_out = zeros(size(coord_in));

%% Create coordinates for each voxel index.
X = ((-centerA(1) + nVxA * drA(1)):(-drA(1)):(-centerA(1) + drA(1)))';
Y = ((-centerA(2) + nVyA * drA(2)):(-drA(2)):(-centerA(2) + drA(2)))';
Z = ((-centerA(3) + nVzA * drA(3)):(-drA(3)):(-centerA(3) + drA(3)))';

%% Convert coordinates to new space.
switch input_type
    case 'coord' % ATLAS/4DFP/ETC COORDINATE SPACE
        for j = 1:nV
            x = coord_in(j, 1);
            if ((floor(x) > 0)  &&  (floor(x) <= nVxA))
                coord_out(j, 1) = X(floor(x)) - drA(1) * (x - floor(x));
            elseif floor(x) < 1
                coord_out(j, 1) = X(1) - drA(1) * (x - 1);
            elseif floor(x) > nVxA
                coord_out(j, 1) = X(nVxA) - drA(1) * (x - nVxA);
            end
            
            y = coord_in(j, 2);
            if ((floor(y) > 0)  &&  (floor(y) <= nVyA))
                coord_out(j, 2) = Y(floor(y)) - drA(2) * (y - floor(y));
            elseif floor(y) < 1
                coord_out(j, 2) = Y(1) - drA(2) * (y - 1);
            elseif floor(y) > nVyA
                coord_out(j, 2) = Y(nVyA) - drA(2) * (y - nVyA);
            end
            
            z = coord_in(j, 3);
            if ((floor(z) > 0)  &&  (floor(z) <= nVzA))
                coord_out(j, 3) = Z(floor(z)) - drA(3) * (z - floor(z));
            elseif floor(z) < 1
                coord_out(j, 3) = Z(1) - drA(3) * (z - 1);
            elseif floor(z) > nVzA
                coord_out(j, 3) = Z(nVzA) - drA(3) * (z - nVzA);
            end
        end
    case 'idx' % MATLAB INDEX SPACE
        for j = 1:nV
            [~, coord_out(j, 1)] = min(abs(coord_in(j, 1) - X));
            [~, coord_out(j, 2)] = min(abs(coord_in(j, 2) - Y));
            [~, coord_out(j, 3)] = min(abs(coord_in(j, 3) - Z));
        end
    case 'idxC'
        for j = 1:nV
            [~, foo] = min(abs(coord_in(j, 1) - X));
            coord_out(j, 1) = foo + (X(foo) - coord_in(j, 1)) / drA(1);
            [~, foo] = min(abs(coord_in(j, 2) - Y));
            coord_out(j, 2) = foo + (Y(foo) - coord_in(j, 2)) / drA(2);
            [~, foo] = min(abs(coord_in(j, 3) - Z));
            coord_out(j, 3) = foo + (Z(foo) - coord_in(j, 3)) / drA(3);
        end
end



%
