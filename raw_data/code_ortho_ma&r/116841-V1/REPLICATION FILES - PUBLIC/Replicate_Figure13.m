

% ----------------------------------------------------------------------- %
%                                                                         %
%             T H E    T R A N S M I S S I O N    O F                     %
%           M O N E T A R Y    P O L I C Y    S H O C K S                 %
%                                                                         %
%         Silvia Miranda-Agrippino and Giovanni Ricco (2016)              %
%                                                                         %
%                                                                         %
%                  r e p l i c a t i o n   c o d e                        %
%                                                                         %
% ----------------------------------------------------------------------- %


clear
clc

addpath([pwd '/subroutines/']) %mac
addpath([pwd '/DATA/'])





%run identifier
runIdentifier='Figure13';


%-MODEL SPECIFICATION-----------------------------------------------------%

%choose VAR variables
dataSetSpec.dataList           ={'INDPRO','UNRATE','CPIAUCSL','CRBPI','GS1'}; 


%set estimation sample
dataSetSpec.beginSet           =datenum(1982,1,1);          
dataSetSpec.endSet             =datenum(2006,12,1);


%set pre-sample for BLP
dataSetSpec.beginPreSample     =datenum(1972,1,1); 
dataSetSpec.endPreSample       =datenum(1982,12,1);

%initialize BLP prior on presample
modelSpec.presample            =true;

%set BLP prior type
modelSpec.priorType            ='VAR'; %BLP only, alternatives: 'VAR', 'RW'; 


modelSpec.nSubsamples          =9; %loops over rolling 24-years subsamples
%first run: 1982-2006
%last  run: 1990-2014




%set VAR specification, lags, IRFs horizon
modelSpec.nVARlags             =12; %number of lags in VAR (& prior)
modelSpec.nBLPlags             =12; %number of lags in BLP
modelSpec.nLPlags              =12; %number of lags in LP

modelSpec.nHorizons            =24;
modelSpec.bandsCoverage        =90;



%choose identification scheme
modelSpec.identification       ='PSVAR'; %alternatives: 'PSVAR', 'CHOL';


%instruments (IRFs are computed for all instruments listed)
IVList                         ={'MPI'};

% Instruments:
%      1. FF4      : HF surprises in 4th Fed Fund Future (FF4) at all HF dates
%      2. FF4SFOMC : FF4 at Scheduled FOMC only 
%      3. FF4GK    : Weighted FF4 as in Gertler and Karadi (2015)
%      4. MPN      : Narrative instrument as in Romer and Romer (2004)
%      5. MPI      : FF4 projection at all HF dates on all Greenbok types -- Miranda-Agrippino & Ricco 
%      6. CBINFO   : Instrument for CB info (fitted component of MPI regression) -- Miranda-Agrippino & Ricco 



%declare shock variable & shock size
shockVar                       ='GS1';       %1-year rate
shockSize                      =1;           %percentage points




%-HYPERPRIORS SETTINGS----------------------------------------------------%

%random walk prior
hyperPars.isrw                   =true(1,length(dataSetSpec.dataList)); %rw prior

%hyperpriors initial values
%
hyperPars.lambda                 =.4;    %tightness of VAR coeffs prior (the higher lambda the closer to OLS)
hyperPars.lambdaC                =1e5;   %intercept (you want this to be large)
hyperPars.lambdaP                =.4;    %tightness of projCoeffs prior (same role as above)
%
hyperPars.miu                    =1;     %sum of coefficients prior (constraint multiplier)
hyperPars.theta                  =2;     %cointegration prior (constraint multiplier) 
hyperPars.alpha                  =2;     %lag decaying coeff for NIW prior


%set hyperpriors options (matches GLP fields); if you want default values
%(when available) set to empty [];
hyperPriorsOptions.hyperpriors   =true;                  %find optimal hyperparameters: NO default option
hyperPriorsOptions.Vc            =1e5;                   %variance of the VAR constant (default=1e6)
hyperPriorsOptions.pos           =find(~hyperPars.isrw); %position of stationary variables
hyperPriorsOptions.MNalpha       =[];                    %lag decaying coeff of NIW prior (default=2)
hyperPriorsOptions.MNpsi         =false;                 %residual variance univariate AR(1) std (default=hyperprior)
hyperPriorsOptions.noc           =false;                 %sum of coefficients prior: NO default option
hyperPriorsOptions.sur           =false;                 %cointegration prior: NO default option
hyperPriorsOptions.Fcast         =false;                 %build forecasts: NO default option
hyperPriorsOptions.hz            =modelSpec.nHorizons;   %max forecast horizon: NO default option
hyperPriorsOptions.mcmc          =false;                 %run metropolis-hasting algorithm: NO default option
hyperPriorsOptions.Ndraws        =1200;                  %default=20k
hyperPriorsOptions.Ndrawsdiscard =200;                   %default=10k
hyperPriorsOptions.MCMCconst     =1;                     %default=1
hyperPriorsOptions.MCMCfcast     =false;                 %store forecast at each MCMC draw (default=true)
hyperPriorsOptions.MCMCstorecoeff=false;                 %store coefficients at each MCMC draw (default=true)
hyperPriorsOptions.initialValues =hyperPars;             %see above


%sampling from paramenters distribution
GibbsOptions.iterations          =1200;
GibbsOptions.burnin              =200;
GibbsOptions.jump                =1;

hyperPriorsOptions.GibbsOptions  =GibbsOptions;
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%








%-------------------------------------------------------------------------%
%   ESTIMATE IMPULSE RESPONSE FUNCTIONS OVER DIFFERENT ROLLING SAMPLES    %
%-------------------------------------------------------------------------%

%declare external instrument
modelSpec.selectedInstrument  =IVList{1}; 


%loop over samples
for t=1:modelSpec.nSubsamples

    if t>1
        
        %discard prior settings
        dataSetSpec = rmfield(dataSetSpec,'beginPreSample');
        dataSetSpec = rmfield(dataSetSpec,'endPreSample');
        dataSetSpec = rmfield(dataSetSpec,'beginSet');
        dataSetSpec = rmfield(dataSetSpec,'endSet');

        %populate subsamples
        dataSetSpec.beginPreSample     =datenum(1972+t,1,1);
        dataSetSpec.endPreSample       =datenum(1982+t,12,1);
        dataSetSpec.beginSet           =datenum(1982+t,1,1);
        dataSetSpec.endSet             =datenum(2006+t,12,1);    
    end    
    
    %assemble data
    modelSpec =buildDataStructure(dataSetSpec,modelSpec);

    
    %load shock variable and normalization in model structure 
    modelSpec.shockSize           =shockSize*double(ismember(modelSpec.dataStructure.varname,shockVar))';
    modelSpec.shockVar            =ismember(modelSpec.dataStructure.varname,shockVar);


    

    %  .     .     .     .     .     .     .     .     .     .     .     %

    %estimate & store IRFs over subsamples
    
    eval(['irfVAR', num2str(t),'=IRFbayesianNIW(modelSpec,hyperPriorsOptions);'])
    eval(['irfLP' , num2str(t),'=IRFlocalProj(modelSpec);'])
    eval(['irfBLP', num2str(t),'=IRFbayesianLocalProj(modelSpec,hyperPriorsOptions);'])
    %  .     .     .     .     .     .     .     .     .     .     .     %

    
end



% 
% %-SAVE OUTPUT-------------------------------------------------------------%
% 
% % modelString=[datestr(dataSetSpec.beginSet,'YY'),datestr(dataSetSpec.endSet,'YY')];
% modelString='7914';
% 
% outFileName=['IRFs',modelString,'_',runIdentifier];
% save([pwd '/MATfiles/' outFileName])
% 
% %-------------------------------------------------------------------------&
% 
% 
% 
% 





%%
%-PLOT IRFs---------------------------------------------------------------%

LineColors =[ .2  .4  .6;...
             1.   .4  .0;...
              .0  .2  .4];
          
BandColors =[.9  .9  .9;...
             .85 .85 .85;...
             .7  .7  .7];

LineTypes  ={'--','-.','-'};
         
%plot labels
varname     =modelSpec.dataStructure.varLongName;
shockSize   =modelSpec.shockSize(modelSpec.shockVar)*100;
nHorizon    =modelSpec.nHorizons; 

xPlotLength =16; %cm
yPlotLength =12; %cm
plotColumns =4;


%variables in plot
[~,selectN]  =ismember({'INDPRO','UNRATE','CPIAUCSL','GS1'},...
              modelSpec.dataStructure.varname);



figure; n=length(varname);

%-------BLP space----------------------------------------------------%
irfBLPareas=cell(n,1);
for j=selectN

    irfBLPall=nan(nHorizon+1,modelSpec.nSubsamples+1);
    
    %loop over subsamples
    for t=1:modelSpec.nSubsamples
        
        %load relevant IRF set
        eval(['irfBLPall(:,t)=irfBLP',num2str(t),'.irfs(:,j);'])
        
    end
    irfBLPareas{j}=[min(irfBLPall,[],2) max(irfBLPall,[],2)];
end        
          

pln=1;

%loop over variables
for j=selectN

    %  .     .     .     .     .     .     .     .     .     .     .     %
    %  .     .     .     .     .     .     .     .     .     .     .     %

    subplot(2,plotColumns,pln);

    hold on

    %BLP space
    p1=fill([0:1:nHorizon, fliplr(0:1:nHorizon)],...
        [irfBLPareas{j}(:,1)' fliplr(irfBLPareas{j}(:,2)')],...
        BandColors(3,:),'EdgeColor','none');
    
    
    %loop over subsamples (VAR)
    for t=1:modelSpec.nSubsamples
        
        %load relevant IRF set
        eval(['irfVAR=irfVAR',num2str(t),';'])

        %VAR irfs
        p2=plot(0:nHorizon,irfVAR.irfs(:,j),'-','LineWidth',1.5,'color',LineColors(3,:));

        if t==modelSpec.nSubsamples

            %add zero line
            plot(0:nHorizon,zeros(size(1:nHorizon+1)),'k')

            %axis
            xlim([0 nHorizon]);     axis tight
            set(gca,'XTick',0:6:nHorizon,'XTickLabel',cellstr(num2str((0:6:nHorizon)')),'FontSize',8,'layer','top')
            title(varname{j},'FontSize',9,'FontWeight','normal')

        end        
    end
    
    if j==1    
        
        ylabel('% points','FontSize',9)     
        legend([p1 p2],{'BLP';'VAR'},'FontSize',9,'Location','SouthWest')
    end

    

    %  .     .     .     .     .     .     .     .     .     .     .     %
    %  .     .     .     .     .     .     .     .     .     .     .     %
    
    subplot(2,plotColumns,pln+numel(selectN));

    hold on

    %BLP space
    p1=fill([0:1:nHorizon, fliplr(0:1:nHorizon)],...
        [irfBLPareas{j}(:,1)' fliplr(irfBLPareas{j}(:,2)')],...
        BandColors(3,:),'EdgeColor','none');
    
    
    %loop over subsamples (LP)
    for t=1:modelSpec.nSubsamples
        
        %load relevant IRF set
        eval(['irfLP=irfLP',num2str(t),';'])

        %LP irfs
        p2=plot(0:nHorizon,irfLP.irfs(:,j),'-','LineWidth',1.5,'color',LineColors(2,:));

        if t==modelSpec.nSubsamples

            %add zero line
            plot(0:nHorizon,zeros(size(1:nHorizon+1)),'k')

            %axis
            xlim([0 nHorizon]);     axis tight
            set(gca,'XTick',0:6:nHorizon,'XTickLabel',cellstr(num2str((0:6:nHorizon)')),'FontSize',8,'layer','top')
            title(varname{j},'FontSize',9,'FontWeight','normal')

        end        
    end
    
    
    if j==1    
        
        legend([p1 p2],{'BLP';'LP'},'FontSize',9,'Location','SouthWest')
    end
    
    
    if j==max(selectN);    
        
        xlabel('horizon','FontSize',9);      
    
    end       
    
    pln=pln+1;
    
end

set(gcf,'PaperUnits','centimeters','PaperSize',[20 11]) %[x y]
set(gcf,'PaperPosition',[-1 0 22 11]) %[left bottom width height]
print(gcf,'-dpdf',[pwd '/CHARTS/' runIdentifier '.pdf']);            

