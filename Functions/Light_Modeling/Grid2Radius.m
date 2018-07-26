function Rad=Grid2Radius(grid,dr)
%
% This function populates a radius structure with topological 
% information for a cap.
% grid must have fields that list the spatial locations of sources and
% detectors in 3D: spos3, dpos3. dr provides a minimum separation for
% sources and detectors to be grouped into different neighbors.
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
if ~isfield(grid,'spos3')
    grid.spos3=cat(2,grid.spos,zeros(size(grid.spos,1),1));
end
if ~isfield(grid,'dpos3')
    grid.dpos3=cat(2,grid.dpos,zeros(size(grid.dpos,1),1));
end
if ~exist('dr','var'),dr=10;end

Rad.srcnum=size(grid.spos3,1);
Rad.detnum=size(grid.dpos3,1);
measnum=Rad.srcnum*Rad.detnum;
Rad.r=zeros(measnum,1);
Rad.meas=zeros(measnum,2);

%% Make Measlist and r
m=0;
for d=1:Rad.detnum
    for s=1:Rad.srcnum
        m=m+1;
        Rad.meas(m,1)=s;
        Rad.meas(m,2)=d;
        Rad.r(m)=round(10*norm(grid.spos3(s,:)-grid.dpos3(d,:)))/10;
    end
end


%% Make Measlist and r2d and rU2d fields
if isfield(grid,'dpos')
m=0;
for d=1:Rad.detnum
    for s=1:Rad.srcnum
        m=m+1;
        Rad.r2d(m)=round(10*norm(grid.spos(s,:)-grid.dpos(d,:)))/10;
    end
end
Rad.rU2d=unique(Rad.r2d);
r=Rad.r2d;
else
    Rad.rU2d=unique(Rad.r);
    r=Rad.r;
end


%% Populate nn's 
RadMaxR=ceil(max(r));%/10 inputs should be in mm
names{1}='nn1';
for n=2:RadMaxR
    names{n}=strcat(names{n-1},num2str(n));    
end
d=0; % s-d distance
c=0; % which nn are we on?
while any(r>d) % as long as there are still s-d pairs left to group
    if ((d==0) && (dr>9)), nnkeep=find(r>=d & r<(d+(2*dr)));d=d+dr;
    else nnkeep=find(r>=d & r<(d+dr));
    end 
     % find pairs within 1 mm range
    if isempty(nnkeep) % if there are none
    else % if we find pairs
        c=c+1; % increment nn count
        if c<12 
            Rad.(['nn',num2str(c)])=nnkeep;
            if (c>1),Rad.(names{c})=union(Rad.(names{c-1}),nnkeep);end    
        end    
        if c>RadMaxR; break; end % stop at nn9
    end
    d=d+dr; % incremement search distance
end
