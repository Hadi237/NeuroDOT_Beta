function data_out = BlockAverage(data_in, pulse, dt)

% BLOCKAVERAGE Averages data by stimulus blocks.
%
%   data_out = BLOCKAVERAGE(data_in, pulse, dt) takes a data array
%   "data_in" and uses the pulse and dt information to cut that data 
%   timewise into blocks of equal length (dt), which are then averaged 
%   together and output as "data_out".
%
%
% See Also: NORMALIZE2RANGE_TTS.

%% Parameters and Initialization.
dims = size(data_in);
Nt = dims(end); % Assumes time is always the last dimension.
NDtf = (ndims(data_in) > 2); %#ok<ISMAT>
Nbl = length(pulse);


% Check to make sure that the block after the last synch point for this
% pulse does not exceed the data's time dimension. 
if (dt + pulse(end)) > Nt
    Nbl = Nbl - 1;
end

%% N-D Input (for 3-D or N-D voxel spaces).
if NDtf
    data_in = reshape(data_in, [], Nt);
end

%% Cut data into blocks.
Nm=size(data_in,1);
blocks=zeros(Nm,dt,Nbl);
for k = 1:Nbl
    blocks(:, :, k) = data_in(:, pulse(k):(pulse(k) + dt - 1));
end

%% Average blocks and return.
data_out = mean(blocks, 3);

%% N-D Output.
if NDtf
    data_out = reshape(data_out, [dims(1:end-1), dt]);
end