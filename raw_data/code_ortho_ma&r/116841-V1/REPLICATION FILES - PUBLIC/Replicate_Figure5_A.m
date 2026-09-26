

% ----------------------------------------------------------------------- %
%               The Transmission of Monetary Policy Shocks                %
%                   Miranda-Agrippino and Ricco (2018)
% ----------------------------------------------------------------------- %
%
% Identification of Monetary Policy Shocks: comparison across instruments
%
% Models:
%       1. VAR(12) in IP, UNRATE, CPI, CRBPI, GS1
%       2. Misspecification: VAR(2) in IP, CPI, GS1
%
% ----------------------------------------------------------------------- %


clear
clc

addpath([pwd '/subroutines/']) %mac
addpath([pwd '/DATA/'])

%plot utils
plotIRFs=true; saveCharts=true;


%optional run identifier
runIdentifier='Figure5_A';



%-MODEL SPECIFICATION-----------------------------------------------------%

%choose VAR variables
dataSetSpec.dataList           ={'INDPRO','UNRATE','CPIAUCSL','CRBPI','EBP','GS1'}; 


%set estimation sample
dataSetSpec.beginSet           =datenum(1979,1,1);
dataSetSpec.endSet             =datenum(2014,12,1);

%choose identification scheme
modelSpec.identification       ='PSVAR'; %alternatives: PSVAR CHOL

%declare shock variable & shock size
shockVar                       ='GS1';
shockSize                      =1; %points

%set VAR specification, IRFs horizon, 
modelSpec.nVARlags             =12; %number of lags in VAR
modelSpec.nHorizons            =2; %max horizon for IRFs
modelSpec.bandsCoverage        =90;


IVList                         ={'FF4GK','FF4','FF4SFOMC','MPN','MPI'};

%-HYPERPRIORS SETTINGS----------------------------------------------------%

%random walk prior
hyperPars.isrw      =true(1,length(dataSetSpec.dataList)); %rw prior

%if not hyperpriors: set hyperparameters manually (prior tightness) 
%
hyperPars.lambda    =.4;    %tightness of VAR coeffs prior (the higher \lambda the closer to OLS)
hyperPars.lambdaC   =1e5;   %intercept (you want this to be large)
hyperPars.lambdaP   =.4;    %tightness of projCoeffs prior (same role as above)
%
hyperPars.miu       =1;     %sum of coefficients prior (constraint multiplier)
hyperPars.theta     =2;     %cointegration prior (constraint multiplier) 
hyperPars.alpha     =2;     %lag decaying coeff for NIW prior


%set hyperpriors options (matches GLP fields); if you want default values
%(when available) set to empty [];
hyperPriorsOptions.hyperpriors   = false;                 %find optimal hyperparameters: NO default option
hyperPriorsOptions.Vc            = 1e5;                   %variance of the VAR constant (default=1e6)
hyperPriorsOptions.pos           = find(~hyperPars.isrw); %position of stationary variables
hyperPriorsOptions.MNalpha       = [];                    %lag decaying coeff of NIW prior (default=2)
hyperPriorsOptions.MNpsi         = false;                 %residual variance univariate AR(1) std (default=hyperprior)
hyperPriorsOptions.noc           = false;                 %sum of coefficients prior: NO default option
hyperPriorsOptions.sur           = false;                 %cointegration prior: NO default option
hyperPriorsOptions.Fcast         = false;                 %build forecasts: NO default option
hyperPriorsOptions.hz            = modelSpec.nHorizons;   %max forecast horizon: NO default option
hyperPriorsOptions.mcmc          = false;                 %run metropolis-hasting algorithm: NO default option
hyperPriorsOptions.Ndraws        = 1000;                  %default=20k
hyperPriorsOptions.Ndrawsdiscard = 200;                   %default=10k
hyperPriorsOptions.MCMCconst     = 1;                     %default=1
hyperPriorsOptions.MCMCfcast     = false;                 %store forecast at each MCMC draw (default=true)
hyperPriorsOptions.MCMCstorecoeff= false;                 %store coefficients at each MCMC draw (default=true)
hyperPriorsOptions.initialValues = hyperPars;             %see above


%sampling from paramenters distribution
GibbsOptions.iterations          = 1200;
GibbsOptions.burnin              = 200;
GibbsOptions.jump                = 1;

hyperPriorsOptions.GibbsOptions  = GibbsOptions;
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%











%-------------------------------------------------------------------------%
%   ESTIMATE IMPULSE RESPONSE FUNCTIONS UNDER DIFFERENT IDENTIFICATIONS   %
%-------------------------------------------------------------------------%

%loop over instruments
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

    
    %estimate VAR & compute IRFs
    IRF_=IRFbayesianNIW(modelSpec,hyperPriorsOptions);
    
    
    %store
    eval(['IRF' num2str(j) '=IRF_;'])
    eval(['IRF' num2str(j) '.instrument =modelSpec.selectedInstrument;'])

    
end


% 
% %-SAVE OUTPUT-------------------------------------------------------------%
% 
% modelString=[datestr(dataSetSpec.beginSet,'YY'),datestr(dataSetSpec.endSet,'YY')];
% 
% outFileName=[runIdentifier '_' modelString];
% save([pwd '/' outFileName])
% 
% %-------------------------------------------------------------------------&
% 



%%
%   PLOT IRFs

VAR3color =[0.8500    0.3250    0.0980]; 
VAR2color =[0.4660  0.6740  0.1880]; 
VAR1color =[.0 .2 .4]; 

%plot labels
varname   =modelSpec.dataStructure.varname;
shockSize =modelSpec.shockSize(modelSpec.shockVar)*100;

%rename into shorter strings
varname{ismember(varname,'INDPRO')}='IP';
varname{ismember(varname,'CPIAUCSL')}='CPI';


[~,selectN]  =ismember({'IP','CPI','GS1'},varname);
[~,selectIV] =ismember(IVList,IVList);



figure; plotColumns=numel(selectIV); n=length(selectN);

pln=1;

for j=selectIV
    
%     pl=subplot(ceil(numel(IVList)/plotColumns),plotColumns,j);    
    pl=subplot(1,plotColumns,pln);    
   
    %select relevant IRFs
    eval(['IRF=IRF' num2str(j) ';'])
    
    
    hold on    
    
    %zero line
    plot(0:n+1,zeros(n+2,1),'k','LineWidth',.7)
    
    %bands 
    errorbar(1:n,squeeze(IRF.irfs(1,selectN)),squeeze(IRF.irfs(1,selectN))-squeeze(IRF.irfs_l(1,selectN)),...
            squeeze(IRF.irfs_u(1,selectN))-squeeze(IRF.irfs(1,selectN)),...
            '.','LineWidth',1.5,'color',[.7 .7 .7])
    
    %impacts
    plot(1:n,squeeze(IRF.irfs(1,selectN)),'o','MarkerSize',5,'LineWidth',1,'color',VAR1color,'MarkerFaceColor',VAR1color)
    
    
    %axis
    set(gca,'Xtick',1:n,'XTickLabel',varname(selectN),'FontSize',9)    
    
    title(IVList{j},'FontSize',10,'FontWeight','normal','Interpreter','none')
    
    if j==selectIV(1)
       
        ylabel('% points','FontSize',9)
    end
    
    pln=pln+1;
    
end


set(gcf,'PaperUnits','centimeters','PaperSize',[23 6]) %[x y]
set(gcf,'PaperPosition',[-2.5 0 28 6]) %[left bottom width height]
print(gcf,'-dpdf',[pwd '/CHARTS/' runIdentifier '.pdf']);            



