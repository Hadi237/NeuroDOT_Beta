function [M,info,I,Q,clipping]=Decode_Acqdecode_Raw(subj,dateA,suf,params)
%
% This function loads and decodes raw data from Acqdecode
% The function must be run in the folder containing the data files.
% The function first reads the Acqdecode-out info file.
% Then the function reads the *.cfg file for the encoding pattern. This
% file should be in the .../Support_files/ folder, possibly under a 
% .../cfg files/ folder.
% params is a structure that can contain the following parameters:
%   decode_type     {'IQ','FFT'} decoding strategies. 'FFT' is default
%   fftNh           if 'FFT' is decode type, fftNh selects how many
%                   harmonics are used in decoding. (1 or 2)
%   nfft            {'np2','spts'} Selects mode for the number of time points 
%                   to use in the fft of each time step. 'spts' is default
%   Wtype           window type. 'Hann' is default
%   adcT.i          ADC transient kill start point. default=10
%   adcT.f          ADS transient kill end point. default=4
%   noMatFile       Dsiable saving .mat files at end
%   fftIntPeriods   Sets FFT length to approximately an integer number of
%                   periods for each frequency
% Infrastructure for all systems utilizes the maximum allowed A/D channel
% per computer is the frame synch and the 2nd-to-last channel is the stim
% synch.



%% Parameters and Initialization
sr=96e3;
% FSchan=96; % This needs to be determined from the info files
mPHeight=0.1;
mPDist=1000;
ext='.raw';
if ~exist('params','var'),params=[];end
if ~isfield(params,'overwrite'),params.overwrite=0;end
if ~isfield(params,'tag')
    datafile2save=[dateA,'-',subj,'-',suf]; % Data file name
else
    datafile2save=[dateA,'-',subj,'-',suf,'_',params.tag]; % Data file name
end
    datafile=[dateA,'-',subj,'-',suf]; % Data file name

if exist([datafile2save,'.mat'],'file') && ~params.overwrite
    load([datafile2save,'.mat'])
else % do all of this
    
if~isfield(params,'decode_type') % options: 'IQ','FFT'
    params.decode_type='FFT'; % Changed default to FFT 180131
end 
if~isfield(params,'fftNh'),params.fftNh=1;end % options: 1,2
if~isfield(params,'nfft') % options: 'IQ','FFT'
    params.nfft='spts'; % Changed default to FFT 180131
end 
if~isfield(params,'Wtype') % options: 'np2','spts'
    params.Wtype='Hann'; % Changed default to spts 180213
end 
if~isfield(params,'adcT') % Enforce adc transient 180213
    params.adcT.i=12; % initial dead window
    params.adcT.f=5; % ending dead window
    t0=params.adcT.i;
else
    t0=0;
end 
if~isfield(params,'clipM') % clipping max
    params.clipM=1; 
    params.clipMu=0.5; 
end 
if~isfield(params,'noMatFile') % disable mat file saving
    params.noMatFile = 0 ;
end
if~isfield(params,'fftIntPeriods') % enforce integer fft periods
    params.fftIntPeriods = 0 ;
end


%% Load info file
info=readkeyfile([datafile,'-info.txt']);
Ns=info.srcnum;
Nd=info.detnum;
Nwl=info.cnum;
Nts=info.nts;
switch length(num2str(info.run))
    case 1
fn_base=[dateA,'-run00',num2str(info.run),'-ch'];
    case 2
fn_base=[dateA,'-run0',num2str(info.run),'-ch'];
end

switch info.pad % These must show the max A/D channel for each system
    case 'Adult_96x92a'
        FSchan=48; % info.nmotu * #chan in Motu (12)
    case 'Adult_96x92b'
        FSchan=48; % info.nmotu * #chan in Motu (12)
    case 'Baby32x34'
        FSchan=36; % info.nmotu * #chan in Motu (12)
    case 'AdultClinical2_48x34'
        FSchan=48; % info.nmotu * #chan in RME (32)
    case 'Matador_84x91'
        FSchan=96; % info.nmotu * #chan in FocusRite (16)
    case 'UHD126x126'
        FSchan=128; % Max focusrite channels as of 180705
end
SSchan=FSchan-1; % stim synch
info.DecodingParams=params;


%% Load encoding pattern cfg file
EncCfg=readkeyfile([info.enc,'.cfg']);
Nreg=EncCfg.nreg;
info.EncCfg=EncCfg;
flashPerc=EncCfg.nisamp/(EncCfg.nisamp+EncCfg.niblank);
periodSamp=sr./EncCfg.freq; % Number of samples per period for ea freq
Nfreq=length(EncCfg.freq);


%% Get frame synch raw file and Calculate empirical sampling info
disp('<<< Finding frame synch points')
[rawFilename,rawFilenameError] = fnbase2rawFileName( fn_base, FSchan, ext ) ;
fid=fopen(rawFilename) ;

Fsynch=fread(fid,'float32');fclose(fid);

% Find frame synchs
if abs(min(Fsynch))>abs(max(Fsynch)) % Adjust for possible neg synch pulse
    Fsynch=-Fsynch;
end

DtFsynch=-([Fsynch(1);Fsynch]-[Fsynch;Fsynch(end)]);
DtFsynch(end)=[];
[~,fs]=findpeaks(DtFsynch,'MinPeakHeight',mPHeight,'MinPeakDistance',mPDist);
Nf=length(fs)-1;
clear DtFsynch Fsynch

% Establish ON sampling time for each frequency
if length(unique(diff(fs)))>2
    disp(['Warning, variable frame sizes; ',num2str(unique(diff(fs(:)))'),...
        'frames may have been dropped'])
    figure;histogram((diff(fs)),[min(diff(fs))-1:max(diff(fs))+1]);
    set(gca,'YScale','log');
    xlabel('Samples per frame');ylabel('Number frames')
    pause(2)
%     return
end
% Flength=round(mean(diff(fs)));  % Assuming no frame synchs were missed
Flength=mode(diff(fs));  % Assuming no frame synchs were missed
disp(['<<< Frame rate ~ ',num2str(sr/Flength),' Hz'])

info.nframe=length(fs)-1; % number of full acquired frames
info.framesize=Flength; % mean frame length
info.framerate=sr/Flength; % calculate empirical frame rate (MOTU @ 96kHz)

SamplesPerTimeStepMax=floor((Flength/(EncCfg.nts))*flashPerc)-...
    params.adcT.i-params.adcT.f ;
numPeriods=floor(SamplesPerTimeStepMax./periodSamp);
SamplesPerTimeStepIntPeriods=floor(numPeriods.*periodSamp); 
if ( params.fftIntPeriods == 1 )
    SamplesPerTimeStep = SamplesPerTimeStepIntPeriods ;
else
    SamplesPerTimeStep = ones(size(EncCfg.freq)).*SamplesPerTimeStepMax ;
end

% prep for fft-based decoding
switch params.nfft
    case 'np2' % Changed default to FFT 180131
        Ndft = pow2(nextpow2(SamplesPerTimeStep));   
    case 'spts'
    Ndft = SamplesPerTimeStep;   % DO NOT Zero pack to a power of 2. (ER)
end
for j=1:Nfreq % indices associated w mod freqs
    freqs=sr*(0:(Ndft(j)/2))./Ndft(j);    % domain of FFT
    [mF,idxf]=min(abs(freqs-EncCfg.freq(j))); % Find FFT bin closest to EncCfg.freq(i)
    switch params.fftNh
        case 1
            idxF{j}=[idxf-1,idxf,idxf+1];
        case 2
            [mF,idxfh]=min(abs(freqs-2*EncCfg.freq(j)));
            idxF{j}=[idxf-1,idxf,idxf+1,idxfh-1,idxfh,idxfh+1];
    end
end


%% Set up Hamm window and sin/cos basic functions for ea freq
[HammF,sinF,cosF]=Generate_Decoding_Bases(...
    SamplesPerTimeStep,sr,EncCfg.freq,params);


%% Decode from raw data
disp('<<< Decoding raw data')
M=zeros(Ns,Nd,Nwl,Nf);
clipping=zeros(Ns,Nd,Nf);
if strcmp(params.decode_type,'IQ')
I=zeros(Ns,Nd,Nwl,Nf);
Q=zeros(Ns,Nd,Nwl,Nf);
else
   I=[];
   Q=[]; 
end

for d=1:Nd
    % Load data
    fprintf('d%s ',num2str(d))
    [rawFilename,rawFilenameError]=fnbase2rawFileName( fn_base, d, ext );
    fid=fopen(rawFilename);
    APDdata=fread(fid,'float32');fclose(fid);
    
    % Choose strategy here
    switch params.decode_type
        case 'IQ'
    
    % Decode all frames at once: IQ
    for ts=1:Nts 
        % For a given time step, find start times for ea frame
        ti=round(fs+(ts-1)*diff([fs;fs(end)])./Nts);ti(end)=[];
        
        tIdx=bsxfun(@plus,ti,[t0:(t0+SamplesPerTimeStep(1)-1)])';
        d1=reshape(APDdata(tIdx(:)),SamplesPerTimeStep(1),[])';
        clipping(ts,d,:)=((sum(abs(d1)>=params.clipM,2))+...
            (abs(mean(d1,2))>params.clipMu)+...
            ((max(d1,[],2)-min(d1,[],2))>1))>0; 
        [M(ts,d,1,:),I(ts,d,1,:),Q(ts,d,1,:)]=MIQ_Decode_Raw_Acqdecode(...
            d1,sinF{1},cosF{1},HammF{1},EncCfg.div(1));% REGION 1, WL 1
        
        tIdx=bsxfun(@plus,ti,[t0:(t0+SamplesPerTimeStep(2)-1)])';
        d1=reshape(APDdata(tIdx(:)),SamplesPerTimeStep(2),[])';
        [M(ts,d,2,:),I(ts,d,2,:),Q(ts,d,2,:)]=MIQ_Decode_Raw_Acqdecode(...
            d1,sinF{2},cosF{2},HammF{2},EncCfg.div(2));% REGION 1, WL 2
        
        if Nreg>1
        tIdx=bsxfun(@plus,ti,[t0:(t0+SamplesPerTimeStep(3)-1)])';
        d1=reshape(APDdata(tIdx(:)),SamplesPerTimeStep(3),[])';
        clipping(ts+Nts,d,:)=((sum(abs(d1)>=params.clipM,2))+...
            (abs(mean(d1,2))>=params.clipMu)+...
            ((max(d1,[],2)-min(d1,[],2))>1))>0; 
        [M(ts+Nts,d,1,:),I(ts+Nts,d,1,:),Q(ts+Nts,d,1,:)]=...
            MIQ_Decode_Raw_Acqdecode(...
            d1,sinF{3},cosF{3},HammF{3},EncCfg.div(3));% REGION 2, WL 1
        
        tIdx=bsxfun(@plus,ti,[t0:(t0+SamplesPerTimeStep(4)-1)])';
        d1=reshape(APDdata(tIdx(:)),SamplesPerTimeStep(4),[])';
        [M(ts+Nts,d,2,:),I(ts+Nts,d,2,:),Q(ts+Nts,d,2,:)]=...
            MIQ_Decode_Raw_Acqdecode_U87(...
            d1,sinF{4},cosF{4},HammF{4},EncCfg.div(4));% REGION 2, WL 2
        end
    end
    
    
        case 'FFT'
    % Decode all frames at once: Full FFT
    for ts=1:Nts 
        % For a given time step, find start times for ea frame
        ti=round(fs+(ts-1)*diff([fs;fs(end)])./Nts);ti(end)=[];
        
        tIdx=bsxfun(@plus,ti,[t0:(t0+SamplesPerTimeStep(1)-1)])';
        d1=reshape(APDdata(tIdx(:)),SamplesPerTimeStep(1),[])';

        if ( params.fftIntPeriods == 1 )
            % Number of samples in FFT different for each frequency
            %%%%%%%
            % This clipping is for 1 region only
            clipping(ts,d,:)=((sum(abs(d1)>=params.clipM,2))+...
                (abs(mean(d1,2))>=params.clipMu)+...
                ((max(d1,[],2)-min(d1,[],2))>1))>0; 
            %%%%%%%
            M(ts,d,1,:)=FFT_Decode_Raw_Acqdecode(...
                d1,HammF{1},Ndft(1),idxF{1},EncCfg.div(1));

            tIdx=bsxfun(@plus,ti,[t0:(t0+SamplesPerTimeStep(2)-1)])';
            d1=reshape(APDdata(tIdx(:)),SamplesPerTimeStep(2),[])';
            M(ts,d,2,:)=FFT_Decode_Raw_Acqdecode(d1,HammF{2},...
                Ndft(2),idxF{2},EncCfg.div(2));

            if Nreg>1
                tIdx=bsxfun(@plus,ti,[t0:(t0+SamplesPerTimeStep(3)-1)])';
                d1=reshape(APDdata(tIdx(:)),SamplesPerTimeStep(3),[])';
                clipping(ts+Nts,d,:)=((sum(abs(d1)>=params.clipM,2))+...
                    (abs(mean(d1,2))>=params.clipMu)+...
                    ((max(d1,[],2)-min(d1,[],2))>1))>0; 
                M(ts+Nts,d,1,:)=FFT_Decode_Raw_Acqdecode(...
                    d1,HammF{3},Ndft(3),idxF{3},EncCfg.div(3));

                tIdx=bsxfun(@plus,ti,[t0:(t0+SamplesPerTimeStep(4)-1)])';
                d1=reshape(APDdata(tIdx(:)),SamplesPerTimeStep(4),[])';
                M(ts+Nts,d,2,:)=FFT_Decode_Raw_Acqdecode(...
                    d1,HammF{4},Ndft(4),idxF{4},EncCfg.div(4));
            end
        else
            % Number of samples in FFT same for each frequency
            % 1 - 320sec/467sec = 32% faster on 1409 180320 AC001 with same
            % results
            mags = FFT_Decode_Raw_Acqdecode(...
                d1,HammF{1},Ndft(1),idxF,EncCfg.div);
            % Hacked in Vpp threshold for detecting MOTU clipped channels
            tsClipped = ((sum(abs(d1)>=params.clipM,2))+...
                (abs(mean(d1,2))>=params.clipMu)+...
                ((max(d1,[],2)-min(d1,[],2))>1))>0;
            if ( Nreg == 1) 
                M(ts,d,1:2,:) = mags(1:2,:) ;
                clipping(ts,d,:) = tsClipped ;
            else % Nreg>1
                for j=0:floor(info.srcnum/Nts)
                    if ( mod(j,2) == 0 )
                        currRegMagsIdx = [1:2] ;
                    else
                        currRegMagsIdx = [3:4] ;
                    end
                    if ( ts+j*Nts <= info.srcnum )
                        M(ts+j*Nts,d,1:2,:) = mags(currRegMagsIdx,:) ;
                        clipping(ts+j*Nts,d,:) = tsClipped ;
                    end
                end
            end
        end
        
        
    end
    
    end
end


%% If 2-pass, fix data and frames before synch
if strfind(info.enc,'2pass')
    for j = 0:Nreg-1
        % Get M, clipping for each region
        RegSrcStartIdx = j*Nts + 1 ;
        RegSrcEndIdx = (j+1)*Nts ; 
        if ( RegSrcEndIdx > info.srcnum )
            RegSrcEndIdx = info.srcnum ;
        end
        Nf_new=floor(size(M,4)/2); % Number of frames after merging hot and cool
        % Throw out last frame if there is an odd number so that 
        % dHot and dCool are the same size
        MRegion = M(RegSrcStartIdx:RegSrcEndIdx,:,:,1:Nf_new*2); 
        clippingRegion = clipping(RegSrcStartIdx:RegSrcEndIdx,:,1:Nf_new*2) ;
        
        DimScale(1)=sin(pi*info.EncCfg.dc(1+4*j))/sin(pi*info.EncCfg.dc(3+4*j));
        DimScale(2)=sin(pi*info.EncCfg.dc(2+4*j))/sin(pi*info.EncCfg.dc(4+4*j));

        % We want the large ratio because we are going to scale up the
        % lower duty cycle signal but we don't know which is which yet
        DimScale(1)=max(DimScale(1),1/DimScale(1)) ;
        DimScale(2)=max(DimScale(2),1/DimScale(2)) ;

        
        % Only look for clipping for S/D dist < 4 cm to determine which 
        % pass is clipped because it could be
        % caused by bright sources in another region
        load(['radius_',info.pad])
        radR2dSrcByDet = reshape(Rad.r2d,Rad.srcnum,Rad.detnum) ;
        radR2dRegionSrcByDet = radR2dSrcByDet(RegSrcStartIdx:RegSrcEndIdx,:) ;
        radR2dRegionSrcXDet = reshape(radR2dRegionSrcByDet,...
            size(radR2dRegionSrcByDet,1)*size(radR2dRegionSrcByDet,2),1) ;
        IdxRadR2dRegionSrcXDetClose = find(radR2dRegionSrcXDet < 40) ;

        clippingRegionSrcXDetByTimeSteps = reshape(clippingRegion,...
            size(clippingRegion,1)*size(clippingRegion,2),size(clippingRegion,3)) ;

        clippingRegionSrcXDetByTimeStepsClose = ...
            zeros(size(clippingRegion,1)*size(clippingRegion,2),...
            size(clippingRegion,3)) ;
        clippingRegionSrcXDetByTimeStepsClose(...
            IdxRadR2dRegionSrcXDetClose,:) = ...
            clippingRegionSrcXDetByTimeSteps(IdxRadR2dRegionSrcXDetClose,:);
        clippingRegionClose = reshape(...
            clippingRegionSrcXDetByTimeStepsClose,size(clippingRegion,1),...
            size(clippingRegion,2),size(clippingRegion,3)) ;

        oFClose=sum(clippingRegionClose(:,:,1:2:end),3);
        eFClose=sum(clippingRegionClose(:,:,2:2:end),3);
        NclipEClose=sum(eFClose(:));
        NclipOClose=sum(oFClose(:));
        

        oF=sum(clippingRegion(:,:,1:2:end),3);
        eF=sum(clippingRegion(:,:,2:2:end),3);
        % figure;subplot(1,2,1);imagesc(oF);title('odd F clipping')
        % xlabel('detectors');ylabel('sources')
        % subplot(1,2,2);imagesc(eF);
        % xlabel('detectors');ylabel('sources');title('even F clipping')

        NclipE=sum(eF(:));
        NclipO=sum(oF(:));

        if NclipEClose~=NclipOClose % cool to replace clipped hot
            if NclipOClose>NclipEClose % 1 is odd is hot, 0 if even is hot
                dHot=MRegion(:,:,:,1:2:end);
                dCool=MRegion(:,:,:,2:2:end);
                fsKeep=fs(2:2:end);
                repM=oF(:)>1;
                clippingRegion=eF>0;
                disp(['<<<Interpolating odd/even bright/dim data'])
                info.system.framerate=info.framerate;
                dHrs=resample_tts(dHot,info,2*info.framerate);
                dHot=dHrs(:,:,:,2:2:end);
                dHot(dHot<0)=eps;
                clear dHrs
            else
                dHot=MRegion(:,:,:,2:2:end);
                dCool=MRegion(:,:,:,1:2:end);
                fsKeep=fs(2:2:end);
                repM=eF(:)>1;
                clippingRegion=oF>0;
                disp(['<<<Interpolating even/odd bright/dim data'])
                info.system.framerate=info.framerate;
                dCrs=resample_tts(dCool,info,2*info.framerate);
                dCool=dCrs(:,:,:,2:2:end);
                dCool(dCool<0)=eps;
                clear dCrs
            end

            % scale dark data
            dCool(:,:,1,:)=dCool(:,:,1,:).*DimScale(1);
            dCool(:,:,2,:)=dCool(:,:,2,:).*DimScale(2);

            % put dark data in with bright data
            dHot=reshape(dHot,size(dHot,1)*size(dHot,2),2,[]);
            dCool=reshape(dCool,size(dCool,1)*size(dCool,2),2,[]);
            dHot(repM,:,1:Nf_new)=dCool(repM,:,1:Nf_new);


        else % no need for replacement
            M1=reshape(MRegion,Ns*Nd,2,[]);
            oNN2=mean(mean(mean(M1(Rad.nn2,:,1:2:end),3),2),1); % odd
            eNN2=mean(mean(mean(M1(Rad.nn2,:,2:2:end),3),2),1); % even
            if oNN2>eNN2
                dHot=MRegion(:,:,:,1:2:end);
                fsKeep=fs(1:2:end);
            else
                dHot=MRegion(:,:,:,2:2:end);
                fsKeep=fs(2:2:end);
            end
        end
        MRegion=reshape(dHot,size(MRegion,1),size(MRegion,2),2,[]);
        if ( j == 0 )
            MBestPassAllRegions = zeros(size(M,1),size(M,2),size(M,3),size(MRegion,4)) ;
        end
        MBestPassAllRegions(RegSrcStartIdx:RegSrcEndIdx,:,:,:) = MRegion ;
    end
    M = MBestPassAllRegions ;
    info.framerate=info.framerate/2; % % OR UP-SAMPLE????
    info.nframe=size(M,4);
    fs=fsKeep;
end


%% Load in aux channels and stim synch
sprintf(['\n <<< Loading Stim Synch data\n'])
if info.naux
    aux_chan=[(FSchan-1):-1:(FSchan-info.naux)];
    
    % Load aux channels
    for n=1:length(aux_chan)
        % aux file will be named DATE-run###-ch##.raw
        [rawFilename,rawFilenameError] = fnbase2rawFileName(...
            [dateA,'-run',num2str(info.run,'%03g'),'-ch'],...
            aux_chan(n), ext ) ;
        fid=fopen(rawFilename) ;
        
        if fid==-1
            error(['** loaddata: No .raw file was found for aux ',...
                num2str(n),' (channel ',num2str(num2str(aux_chan(n) )),') **'])
        end
        
        aux.(['aux',num2str(n)])=fread(fid,'float32');
        fclose(fid);
    end
    
    % Stim synch, specifically
    synch=zeros(2,info.nframe-1);
    ti=fs(1:info.nframe-1);
    tIdx=bsxfun(@plus,ti,[0:floor(info.framesize)-1])';
    s1=reshape(aux.aux1(tIdx(:)),floor(info.framesize),[])';
    synch(1,:)=squeeze(std(s1,[],2));
    fsynch=abs(fft(s1,info.framesize,2));
    [~,synch(2,:)]=max(fsynch(:,1:floor(info.framesize/2)),[],2);
    
    [info.synchpts,info.synchtype]=findsynch(synch);
    PulseTypes=unique(info.synchtype,'stable');
    for j=1:numel(PulseTypes)
        info.(['Pulse_',num2str(j)])=find(info.synchtype==PulseTypes(j));
    end
    info.synch=synch;
else
    synch=[];
end


%% Adjust outputs if not IQ decoding
if ~nnz(I)
    I=[];
    Q=[];
end

%% Get grid and radius files into structure

foo=load(['grid_',info.pad]);
info.grid=foo.grid;
foo=load(['radius_',info.pad]);
info.Rad=foo.Rad;

if ( ~params.noMatFile )
save([datafile2save,'.mat'],'M','info','I','Q','clipping','-v7.3')
end
end




