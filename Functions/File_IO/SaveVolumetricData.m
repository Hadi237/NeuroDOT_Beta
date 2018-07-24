function SaveVolumetricData(volume, header, filename, pn, file_type)

% SAVEVOLUMETRICDATA Saves a volumetric data file.
%
%   SAVEVOLUMETRICDATA(volume, header, filename, pn, file_type) saves
%   volumetric data defined by "volume" and "header" into a file specified
%   by "filename", path "pn", and "file_type".
%
%   SAVEVOLUMETRICDATA(volume, header, filename) supports a full
%   filename input, as long as the extension is included in the file name
%   and matches a supported file type.
%
%   Supported File Types/Extensions: '.4dfp' 4dfp, '.nii' NIFTI.
%
%   NOTE: This function uses the NIFTI_Reader toolbox available on MATLAB
%   Central. This toolbox has been included with NeuroDOT 2.
%
% Dependencies: WRITE_4DFP_HEADER, WRITE_NIFTI.
%
% See Also: LOADVOLUMETRICDATA, MAKE_NATIVESPACE_4DFP.
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
if ~exist('file_type', 'var')  &&  ~exist('pn', 'var')
    [pn, filename, file_type] = fileparts(filename);
    file_type = file_type(2:end);
end

switch lower(file_type)
    case '4dfp'
        %% Write 4dfp header.
        switch header.acq
            case 'transverse'
                volume = flip(volume, 2);
            case 'coronal'
                volume = flip(volume, 2);
                volume = flip(volume, 3);
            case 'sagittal'
                volume = flip(volume, 1);
                volume = flip(volume, 2);
                volume = flip(volume, 3);
        end
        
        Write_4dfp_Header(header, fullfile(pn, filename))
        
        %% Write 4dfp image file.
        volume = squeeze(reshape(volume, header.nVx * header.nVy * header.nVz * header.nVt, 1));
        fid = fopen([fullfile(pn, filename), '.4dfp.img'], 'w', 'l');
        fwrite(fid, volume, header.format);
        fclose(fid);
        
    case {'nifti', 'nii'}
        %% Call NIFTI_Reader functions.
        volume = flip(volume, 1); % Convert back from LAS to RAS for NIFTI.
        
        nii = Write_NIFTI(volume, header, fullfile(pn, filename));
        
        save_nii(nii, [fullfile(pn, filename), '.nii']);
        
end



%
