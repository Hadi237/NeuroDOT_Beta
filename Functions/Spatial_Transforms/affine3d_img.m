function imgB = affine3d_img(imgA, infoA, infoB, affine, interp_type)

% AFFINE3D_IMG Transforms a 3D data set to a new space.
% 
%   imgB = AFFINE3D_IMG(imgA, infoA, infoB, affine) takes a reconstructed,
%   VOX x TIME image "imgA" and transforms it from its initial voxel space
%   defined by the structure "infoA" into a target voxel space defined by
%   the structure "infoB" and using the transform matrix "affine". The
%   output is a VOX x TIME matrix "imgB" in the target voxel space.
% 
%   imgB = AFFINE3D_IMG(imgA, infoA, infoB, affine, interp_type) allows the
%   user to specify an interpolation method for the INTERP3 function that
%   AFFINE3D_IMG uses. Other methods that can be used (input as strings)
%   are 'nearest', 'spline', and 'cubic'. The default value is 'linear'.
% 
% See Also: SPECTROSCOPY_IMG, CHANGE_SPACE_COORDS, INTERP3.

%% Parameters and Initialization.
[~, ~, ~, Nt] = size(imgA);
extrapval = 0;

if ~exist('interp_type', 'var')  ||  isempty(interp_type)
    interp_type = 'linear';
end
if ~exist('affine', 'var')  ||  isempty(affine)
    affine = eye(4);
end

%% Determine initial and target space coordinate ranges.
% Initial space.
centerA = infoA.center;
nVxA = infoA.nVx;
nVyA = infoA.nVy;
nVzA = infoA.nVz;
drA = infoA.mmppix;

X = ((-centerA(1) + nVxA * drA(1)):-drA(1):(-centerA(1) + drA(1)))';
Y = ((-centerA(2) + nVyA * drA(2)):-drA(2):(-centerA(2) + drA(2)))';
Z = ((-centerA(3) + nVzA * drA(3)):-drA(3):(-centerA(3) + drA(3)))';

% Target space.
centerB = infoB.center;
nVxB = infoB.nVx;
nVyB = infoB.nVy;
nVzB = infoB.nVz;
drB = infoB.mmppix;

x = ((-centerB(1) + nVxB * drB(1)):-drB(1):(-centerB(1) + drB(1)))';
y = ((-centerB(2) + nVyB * drB(2)):-drB(2):(-centerB(2) + drB(2)))';
z = ((-centerB(3) + nVzB * drB(3)):-drB(3):(-centerB(3) + drB(3)))';

%% Get all points in destination to sample
[ygv, xgv, zgv] = meshgrid(y, x, z);
xyz = [reshape(xgv, [], 1)'; reshape(ygv, [], 1)'; reshape(zgv, [], 1)'];
xyz = [xyz; ones(1, size(xyz, 2))];

%% Transform into source coordinates and remove extra column
uvw = affine * xyz;
uvw = uvw(1:3, :)';

%% Sample
xi = reshape(uvw(:, 1), length(x), length(y), length(z));
yi = reshape(uvw(:, 2), length(x), length(y), length(z));
zi = reshape(uvw(:, 3), length(x), length(y), length(z));

%% Interpolate
for k = 1:Nt
    imgB(:, :, :, k) = interp3(Y, X, Z, squeeze(imgA(:, :, :, k)),...
        yi, xi, zi, interp_type, extrapval);
end



%
