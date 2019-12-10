function [volume, header] = LoadVolumetricData(filename, pn, file_type)

% LOADVOLUMETRICDATA Loads a volumetric data file.
%
%   [volume, header] = LOADVOLUMETRICDATA(filename, pn, file_type) loads a
%   file specified by "filename", path "pn", and "file_type", and returns
%   it in two parts: the raw data file "volume", and the header "header",
%   containing a number of key-value pairs in 4dfp format.
%
%   [volume, header] = LOADVOLUMETRICDATA(filename) supports a full
%   filename input, as long as the extension is included in the file name
%   and matches a supported file type.
% 
%   Supported File Types/Extensions: '.4dfp' 4dfp, 'nii' NIFTI.
% 
%   NOTE: This function uses the NIFTI_Reader toolbox available on MATLAB
%   Central. This toolbox has been included with NeuroDOT 2.
% 
% Dependencies: READ_4DFP_HEADER, READ_NIFTI_HEADER, MAKE_NATIVESPACE_4DFP.
% 
% See Also: SAVEVOLUMETRICDATA.
% 
% Copyright (c) 2017 Washington University 
% Created By: Adam T. Eggebrecht
% Eggebrecht et al., 2014, Nature Photonics; Zeff et al., 2007, PNAS.
%
% Washington University hereby grants to you a non-transferable, 
% non-exclusive, royalty-free, non-commercial, research license to use 
% and copy the computer code that is provided here (the Software).  
% You agree to include this license and the above copyright notice in 
% all copies of the Software.  The Software may not be distributed, 
% shared, or transferred to any third party.  This license does not 
% grant any rights or licenses to any other patents, copyrights, or 
% other forms of intellectual property owned or controlled by Washington 
% University.
% 
% YOU AGREE THAT THE SOFTWARE PROVIDED HEREUNDER IS EXPERIMENTAL AND IS 
% PROVIDED AS IS, WITHOUT ANY WARRANTY OF ANY KIND, EXPRESSED OR 
% IMPLIED, INCLUDING WITHOUT LIMITATION WARRANTIES OF MERCHANTABILITY 
% OR FITNESS FOR ANY PARTICULAR PURPOSE, OR NON-INFRINGEMENT OF ANY 
% THIRD-PARTY PATENT, COPYRIGHT, OR ANY OTHER THIRD-PARTY RIGHT.  
% IN NO EVENT SHALL THE CREATORS OF THE SOFTWARE OR WASHINGTON 
% UNIVERSITY BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, OR 
% CONSEQUENTIAL DAMAGES ARISING OUT OF OR IN ANY WAY CONNECTED WITH 
% THE SOFTWARE, THE USE OF THE SOFTWARE, OR THIS AGREEMENT, WHETHER 
% IN BREACH OF CONTRACT, TORT OR OTHERWISE, EVEN IF SUCH PARTY IS 
% ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

%% Parameters and Initialization
volume = [];
header = [];
if ~exist('file_type', 'var')  &&  ~exist('pn', 'var')
    [pn, filename, file_type] = fileparts(filename);
    file_type = file_type(2:end);
end

switch lower(file_type)
    case '4dfp'
        %% Read 4dfp file.
        % Read .ifh header.
        header = Read_4dfp_Header(fullfile(pn, [filename, '.', file_type, '.ifh']));
        
        % Read .img file.
        fid = fopen(fullfile(pn, [filename, '.', file_type, '.img']), 'r', header.byte);
        volume = fread(fid, header.nVx * header.nVy * header.nVz * header.nVt, header.format);
        fclose(fid);
        
        %% Put header into native space if not already.
        header = Make_NativeSpace_4dfp(header);
        
        %% Format for output.
        volume = squeeze(reshape(volume, header.nVx, header.nVy, header.nVz, header.nVt));
        
        switch header.acq
            case 'transverse'
                volume = flip(volume, 2);
            case 'coronal'
                volume = flip(volume, 2);
                volume = flip(volume, 3);
            case 'sagittal'
                volume = flip(volume, 1);
                volume = flip(volume, 2);
                volume = flip(volume, 3);  % Is this wrong???
        end
    case {'nifti', 'nii'}
        %% Call NIFTI_Reader functions.
        %%% NOTE: When passing file types, if you have the ".nii" file
        %%% extension, you must use that as both the "ext" input AND add it
        %%% as an extension on the "filename" input.
        nii = load_nii(fullfile(pn, [filename, '.', file_type]));
        
        header = Read_NIFTI_Header(nii);
        
        volume = flip(nii.img, 1); % NIFTI loads in RAS orientation. We want LAS, so we flip first dim.
        
end
volume=double(volume);


%
