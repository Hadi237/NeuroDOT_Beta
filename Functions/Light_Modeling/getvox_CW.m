function [vox,dim]=getvox_CW(nodes,G,flags)

% Find voxel grid and limits.  Voxel grid is defined as a subset of the
% volume voxellated space.
%
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


%% Determine Threshold and nodes within the threshold range
nodelevel=max(squeeze(sum(abs(G),1)),[],1);
m=max(nodelevel);
nkeep=find(nodelevel>=flags.gthresh*m);

xkeep=nodes(nkeep,1);
xmin=floor(min(xkeep));
xmax=ceil(max(xkeep));
while mod(xmax-xmin,flags.voxmm)
    xmax=xmax+1;
end
xmax=xmax-1;

ykeep=nodes(nkeep,2);
ymin=floor(min(ykeep));
ymax=ceil(max(ykeep));
while mod(ymax-ymin,flags.voxmm)
    ymax=ymax+1;
end
ymax=ymax-1;

zkeep=nodes(nkeep,3);
zmin=floor(min(zkeep));
zmax=ceil(max(zkeep));
while mod(zmax-zmin,flags.voxmm)
    zmax=zmax+1;
end
zmax=zmax-1;


%% Construct dim structure
dim=struct('xmin',xmin,'xmax',xmax,...
    'ymin',ymin,'ymax',ymax,'zmin',zmin,'zmax',zmax);

dim.xv=dim.xmin:flags.voxmm:dim.xmax;
dim.yv=dim.ymin:flags.voxmm:dim.ymax;
dim.zv=dim.zmin:flags.voxmm:dim.zmax;

dim.nVx=numel(dim.xv);
dim.nVy=numel(dim.yv);
dim.nVz=numel(dim.zv);
dim.nVt=dim.nVx*dim.nVy*dim.nVz;

dim.sV=flags.voxmm;

dim.mmppix=[flags.voxmm,-flags.voxmm,-flags.voxmm];
MPRsize=[flags.info.nVx,flags.info.nVy,flags.info.nVz];
centerMPR=flags.info.center;
dim.mmppix=flags.voxmm.*flags.info.mmppix;
dr=[MPRsize(1)-(dim.xmax+1),MPRsize(2)-(dim.ymax+1),...
    MPRsize(3)-(dim.zmax+1)];
dim.center=centerMPR-(dr.*flags.info.mmppix);


%% Construct vox
vox=zeros(dim.nVx,dim.nVy,dim.nVz,3);
for x=1:dim.nVx
    for y=1:dim.nVy
        for z=1:dim.nVz
            vox(x,y,z,:)=[dim.xv(x),dim.yv(y),dim.zv(z)];
        end
    end
end