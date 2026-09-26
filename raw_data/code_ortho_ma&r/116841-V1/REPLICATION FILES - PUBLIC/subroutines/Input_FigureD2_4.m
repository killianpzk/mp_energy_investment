
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
%                                                                         %
% miranda (2016) silvia.miranda-agrippino@bankofengland.co.uk             %
%                g.ricco@warwick.ac.uk                                    %
% ----------------------------------------------------------------------- %


clear
clc

addpath([pwd '/subroutines/']) %mac
addpath([pwd '/DATA/'])





%run identifier
runIdentifier='Input_D2_4';


%-MODEL SPECIFICATION-----------------------------------------------------%

%choose VAR variables
dataSetSpec.dataList           ={'INDPRO','UNRATE','CPIAUCSL','HOUST','PERMIT',...
                                 'GS1','GS10','S&P 500','CSHPI','MORTG_SPREAD'};
                                  


%set estimation sample
dataSetSpec.beginSet           =datenum(1990,1,1);          
dataSetSpec.endSet             =datenum(2012,6,1);


%set pre-sample for BLP
dataSetSpec.beginPreSample     =datenum(1979,7,1); 
dataSetSpec.endPreSample       =datenum(1990,12,1);

%initialize BLP prior on presample
modelSpec.presample            =true;

%set BLP prior type
modelSpec.priorType            ='VAR'; %BLP only, alternatives: 'VAR', 'RW'; 



%set VAR specification, lags, IRFs horizon
modelSpec.nVARlags             =12; %number of lags in VAR (& prior)
modelSpec.nBLPlags             =6;  %number of lags in BLP
modelSpec.nLPlags              =6;  %number of lags in LP

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
%       ESTIMATE IMPULSE RESPONSE FUNCTIONS USING DIFFERENT MODELS        %
%-------------------------------------------------------------------------%

%declare external instrument
modelSpec.selectedInstrument  =IVList{1}; 


%assemble data
modelSpec =buildDataStructure(dataSetSpec,modelSpec);


%load shock variable and normalization in model structure 
modelSpec.shockSize     =shockSize*double(ismember(modelSpec.dataStructure.varname,shockVar))';
modelSpec.shockVar      =ismember(modelSpec.dataStructure.varname,shockVar);




%1. VAR
IRF_VAR =IRFbayesianNIW(modelSpec,hyperPriorsOptions);

%2. LP
IRF_LP  =IRFlocalProj(modelSpec);

%3. BLP
IRF_BLP =IRFbayesianLocalProj(modelSpec,hyperPriorsOptions);





%-SAVE OUTPUT-------------------------------------------------------------%

save([pwd '/MATfiles/' runIdentifier])

%-------------------------------------------------------------------------&









%%
%-PLOT IRFs---------------------------------------------------------------%

Bcolor   =[.2 .4 .6]; BbandFillColor   =[.85 .85 .85];
LPcolor  =[1. .4 .0]; LPbandFillColor  =[.9 .9 .9];
BLPcolor =[.0 .2 .4]; BLPbandFillColor =[.7 .7 .7];


         
%plot labels
varname     =modelSpec.dataStructure.varLongName;
shockSize   =modelSpec.shockSize(modelSpec.shockVar)*100;
nHorizon    =modelSpec.nHorizons; 

xPlotLength =20; %cm
yPlotLength =12; %cm
plotColumns =4;


%variables in plot
[~,selectN]  =ismember(modelSpec.dataStructure.varname,...
              modelSpec.dataStructure.varname);


n =numel(selectN);




figure; pln=1; 

%-------BLP vs BVAR---------------------------------------------%    
for j=selectN

    pl=subplot(ceil(n/plotColumns),plotColumns,pln);

    hold on

    %bands
    fill([0:1:nHorizon, fliplr(0:1:nHorizon)],...
        [IRF_VAR.irfs_l(1:nHorizon+1,j)' fliplr(IRF_VAR.irfs_u(1:nHorizon+1,j)')],...
        BbandFillColor,'EdgeColor','none');

    fill([0:1:nHorizon, fliplr(0:1:nHorizon)],...
        [IRF_BLP.irfs_l(1:nHorizon+1,j)' fliplr(IRF_BLP.irfs_u(1:nHorizon+1,j)')],...
        BLPbandFillColor,'EdgeColor','none');


    %irfs
    p0=plot(0:nHorizon,IRF_LP.irfs(1:nHorizon+1,j), '-.','LineWidth',1.5,'color',LPcolor);
    p1=plot(0:nHorizon,IRF_VAR.irfs(1:nHorizon+1,j),  '--','LineWidth',1.5,'color',Bcolor);
    p2=plot(0:nHorizon,IRF_BLP.irfs(1:nHorizon+1,j),'-','LineWidth',1.5,'color',BLPcolor);

    %zero line
    plot(0:nHorizon,zeros(size(1:nHorizon+1)),'k')

    hold off; axis tight

    xlim([0 nHorizon]);
    set(gca,'XTick',0:6:nHorizon,'XTickLabel',cellstr(num2str((0:6:nHorizon)')),'Layer','top')
    title(varname{j},'FontSize',9,'Fontweight','Normal')

    if j==1
        ylabel('% points')
    end

    if j==max(selectN)

        xlabel('horizon')

        lh=legend([p0 p1 p2],{['LP(' num2str(modelSpec.nLPlags) ')'];...
                              ['BVAR(' num2str(modelSpec.nLPlags) ')'];...
                              ['BLP(' num2str(modelSpec.nBLPlags) ')']},...
                              'FontSize',8,'Location','SouthEast');
        lp=get(lh,'Position'); lp(1)=.7; set(lh,'Position',lp)
        set(lh,'box','off')

    end
    
    pln=pln+1;
end

