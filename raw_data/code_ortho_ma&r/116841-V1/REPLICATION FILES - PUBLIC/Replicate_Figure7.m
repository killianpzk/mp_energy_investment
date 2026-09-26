
% ----------------------------------------------------------------------- %
%                            
%
%             T H E    T R A N S M I S S I O N    O F                     %
%           M O N E T A R Y    P O L I C Y    S H O C K S                 %
%                                                                         %
%         Silvia Miranda-Agrippino and Giovanni Ricco (2019)              %
%                                                                         %
%                                                                         %
%                  r e p l i c a t i o n   c o d e                        %
%                                                                         %
%                                                                         %
% Main script:                                                            %
% ------------                                                            %
%                                                                         %
% The following code estimates dynamic responses to a monetary policy     %
% shock on monthly US data                                                % 
%                                                                         %
% TRANSMISSION:(options)                                                  %
%              - Local Projections                                        %
%              - Bayesian VAR                                             %
%              - Bayesian Local Projections (Miranda-Agrippino & Ricco)   %
%                                                                         %
% IDENTIFICATION:(options)                                                %
%              - Cholesky                                                 %
%              - External Instruments                                     %
%                                                                         %
% DATA:                                                                   %
%              - FRED-MD (McCracken & Ng) + extensions                    %
%              - extensions are listed in mainDataFolder/READMEdata.txt   %
%                                                                         %
%                                                                         %
%                silvia.miranda-agrippino@bankofengland.co.uk             %
%                g.ricco@warwick.ac.uk                                    %
% ----------------------------------------------------------------------- %


clear
clc

addpath([pwd '/subroutines/']) %mac
addpath([pwd '/DATA/'])





%run identifier
runIdentifier='Figure7';


%-MODEL SPECIFICATION-----------------------------------------------------%

%choose VAR variables
dataSetSpec.dataList ={'INDPRO';...             1.  Industrial Production
                       'BUSINVx';...            2.  Business Inventories 
                       'CAPUTLB00004S';...      3.  Capacity Utilization
                       'UNRATE';...             4.  Unemployment Rate
                       'AWHMAN';...             5.  Average Weekly Hours Mfg
                       'CPIAUCSL';...           6.  CPI All Items
                       'PCEPI';...              7.  PCE Deflator
                       'CES3000000008';...      8.  Average Earnings Mfg
                       'DDURRA3M086SBEA';...    9.  Real Consumption Durable Goods
                       'DNDGRA3M086SBEA';...    10. Real Consumption Nondurable Goods
                       'HOUST';...              11. Housing Starts 
                       'PERMIT';...             12. Building Permits
                       'RPI';...                13. Real Personal Income
                       'UMCSENTx';...           14. Consumer Sentiment
                       'BUSLOANS';...           15. Business Loans
                       'DTCTHFNM';...           16. Consumer Loans
                       'OECDEXP';...            17. Exports of Goods
                       'OECDIMP';...            18. Imports of Goods
                       'M2SL';...               19. M2 Money Stock
                       'GS1';...                20. 1 Year Rate
                       'YCSLOPE';...            21. Term (10Y-1Y) Spread
                       'S&P 500';...            22. S&P 500
                       'CSHPI';...              23. House Price Index
                       'BISREER';...            24. BIS Real Effective Exchange Rate
                       'EBP';...                25. Excess Bond Premium
                       'BASPREAD';...           26. BAA-AAA Spread
                       'MORTG_SPREAD'};%        27. Mortgage Spread



%set estimation sample
dataSetSpec.beginSet           =datenum(1979,7,1);          
dataSetSpec.endSet             =datenum(2014,12,1);


%set pre-sample for BLP
dataSetSpec.beginPreSample     =datenum(1973,1,1); 
dataSetSpec.endPreSample       =datenum(1979,12,1);

%initialize BLP prior on presample
modelSpec.presample            =true;

%set BLP prior type
modelSpec.priorType            ='VAR'; %BLP only, alternatives: 'VAR', 'RW'; 



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
%   ESTIMATE IMPULSE RESPONSE FUNCTIONS UNDER DIFFERENT IDENTIFICATIONS   %
%-------------------------------------------------------------------------%


%loop over instruments (VAR only)
for j=1:numel(IVList)

   
    %discard prior settings
    if isfield(modelSpec,'selectedInstrument')
       
        modelSpec = rmfield(modelSpec,'selectedInstrument');        
    end
    
    %declare external instrument
    modelSpec.selectedInstrument  =IVList{j}; 
    
    
    %assemble data
    modelSpec =buildDataStructure(dataSetSpec,modelSpec);

    
    %load shock variable and normalization in model structure 
    modelSpec.shockSize     =shockSize*double(ismember(modelSpec.dataStructure.varname,shockVar))';
    modelSpec.shockVar      =ismember(modelSpec.dataStructure.varname,shockVar);

    

    
    %  .     .     .     .     .     .     .     .     .     .     .     %

    %estimate VAR & compute IRFs
    IRF_=IRFbayesianNIW(modelSpec,hyperPriorsOptions);              %for Bayesian VAR
%     IRF_=IRFbayesianLocalProj(modelSpec,hyperPriorsOptions);        %for Bayesian LP
    
    
    %store
    eval(['IRF_VAR_' num2str(j) '=IRF_;'])
    eval(['IRF_VAR_' num2str(j) '.instrument =modelSpec.selectedInstrument;'])
    
    %  .     .     .     .     .     .     .     .     .     .     .     %

    
end


%-SAVE OUTPUT-------------------------------------------------------------%

save([pwd '/MATfiles/' runIdentifier])

%-------------------------------------------------------------------------&









%%
%-PLOT IRFs---------------------------------------------------------------%

LineColors =[ .0  .2  .4;...
              1.  .4  .0;...
              .2  .4  .6];
          
BandColors =[.7  .7  .7;...
             .85 .85 .85;...
             .9  .9  .9];

LineTypes  ={'-','-.','--'};
         
%plot labels
varname     =modelSpec.dataStructure.varLongName;
shockSize   =modelSpec.shockSize(modelSpec.shockVar)*100;
nHorizon    =modelSpec.nHorizons; 

xPlotLength =16; %cm
yPlotLength =12; %cm
plotColumns =4;


%variables in plot
selectN=1:numel(modelSpec.dataStructure.varname);
n=numel(selectN);





%-------VAR ONLY------------------------------------------------------%
%-------ACROSS IDENTIFICATIONS----------------------------------------%

    
figure; pln=1; 

for j=selectN 
        
    
    pl=subplot(ceil(n/plotColumns),plotColumns,pln);
    
    hold on

    
    for k=1:numel(IVList)

            
        %select relevant IRFs
        eval(['IRF=IRF_VAR_' num2str(k) ';'])

        %bands
        fill([0:1:nHorizon, fliplr(0:1:nHorizon)],...
            [IRF.irfs_l(1:nHorizon+1,j)' fliplr(IRF.irfs_u(1:nHorizon+1,j)')],...
            BandColors(k,:),'EdgeColor','none');
        
    end
    

    plines=nan(numel(IVList),1);
    for k=1:numel(IVList)

            
        %select relevant IRFs
        eval(['IRF=IRF_VAR_' num2str(k) ';'])

        %irfs
        plines(k)=plot(0:nHorizon,IRF.irfs(1:nHorizon+1,j),LineTypes{k},'LineWidth',1.2,'color',LineColors(k,:));
        
    end
        
    %zero line
    plot(0:nHorizon,zeros(size(1:nHorizon+1)),'k','LineWidth',.7)

        
    %axis
    xlim([0 nHorizon]); axis tight
    set(gca,'XTick',0:6:nHorizon,'XTickLabel',cellstr(num2str((0:6:nHorizon)')),...
        'FontSize',8,'Layer','top')
    title(varname{j},'FontSize',7,'FontWeight','Normal')
        
    if j==1
        ylabel('% points','FontSize',8)
    end

    if j==max(selectN)

        xlabel('months','FontSize',8)

    end

    pln=pln+1;
end
    
set(gcf,'PaperUnits','centimeters','PaperSize',[25 6*ceil(n/plotColumns)]) %[x y]
set(gcf,'PaperPosition',[-1.5 0 28 6*ceil(n/plotColumns)]) %[left bottom width height]

print(gcf,'-dpdf',[pwd '/CHARTS/' runIdentifier '.pdf']);            
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%

