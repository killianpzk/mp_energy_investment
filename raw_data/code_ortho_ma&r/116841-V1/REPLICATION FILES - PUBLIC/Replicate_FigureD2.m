
clear 
clc

addpath([pwd '/subroutines/']) %mac


run Input_FigureD2_1
run Input_FigureD2_2
run Input_FigureD2_3
run Input_FigureD2_4


%%
clear 
clc

addpath([pwd '/MATfiles/']) %mac

%-------PLOT SELECTION OF IRFs--------------------------------------------%

%global set of charts: list in order of desired appearance in chart
runIdentifier  ='FigureD2';

selectV       ={'INDPRO';...             1.  Industrial Production
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
                'BUSLOANS';...           14. Business Loans
                'DTCTHFNM';...           15. Consumer Loans
                'OECDEXP';...            16. Exports of Goods
                'OECDIMP';...            17. Imports of Goods
                'M2SL';...               18. M2 Money Stock
                'GS1';...                19. 1 Year Rate
                'YCSLOPE';...            20. Term (10-1 Year Rate) Spread
                'S&P 500';...            21. S&P 500
                'CSHPI';...              22. House Price Index (1975)
                'BISREER';...            23. BIS Real Effective Exchange Rate
                'EBP';...                24. Excess Bond Premium (1973)
                'BASPREAD';...           25. BAA-AAA Spread
                'MORTG_SPREAD'};%        26. Mortgage Spread


            
selectV1 ={'INDPRO';'BUSINVx';'CAPUTLB00004S';'UNRATE';'AWHMAN';...
           'CES3000000008';'M2SL';'GS1';'EBP'}; %(1)

selectV2 ={'CPIAUCSL';'HOUST';'PERMIT';'OECDEXP';'OECDIMP';'S&P 500';...
           'CSHPI';'BISREER'}; %(2)

selectV3 ={'PCEPI';'DDURRA3M086SBEA';'DNDGRA3M086SBEA';'RPI';'BUSLOANS';...
           'DTCTHFNM';'YCSLOPE';'BASPREAD'}; %(3)
            
selectV4 ={'MORTG_SPREAD'}; %(4)


% . load IRFs .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %

%first set
load('Input_D2_1','IRF_BLP','IRF_LP','IRF_VAR','dataSetSpec','modelSpec');   %(1)

[~,selectV1]=ismember(selectV1,dataSetSpec.dataList);


varname =modelSpec.dataStructure.varLongName(selectV1);
varcode =modelSpec.dataStructure.varname(selectV1);

IRF_BLP_V.irfs    =IRF_BLP.irfs(:,selectV1);
IRF_BLP_V.irfs_u  =IRF_BLP.irfs_u(:,selectV1);
IRF_BLP_V.irfs_l  =IRF_BLP.irfs_l(:,selectV1);    

IRF_LP_V.irfs     =IRF_LP.irfs(:,selectV1);
IRF_LP_V.irfs_u   =IRF_LP.irfs_u(:,selectV1);
IRF_LP_V.irfs_l   =IRF_LP.irfs_l(:,selectV1);    

IRF_VAR_V.irfs    =IRF_VAR.irfs(:,selectV1);
IRF_VAR_V.irfs_u  =IRF_VAR.irfs_u(:,selectV1);
IRF_VAR_V.irfs_l  =IRF_VAR.irfs_l(:,selectV1);   
% .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  %


%second set
load('Input_D2_2','IRF_BLP','IRF_LP','IRF_VAR','dataSetSpec','modelSpec');   %(2)

[~,selectV2]=ismember(selectV2,dataSetSpec.dataList);


    
varname =[varname modelSpec.dataStructure.varLongName(selectV2)];
varcode =[varcode modelSpec.dataStructure.varname(selectV2)];

IRF_BLP_V.irfs    =[IRF_BLP_V.irfs   IRF_BLP.irfs(:,selectV2)];
IRF_BLP_V.irfs_u  =[IRF_BLP_V.irfs_u IRF_BLP.irfs_u(:,selectV2)];
IRF_BLP_V.irfs_l  =[IRF_BLP_V.irfs_l IRF_BLP.irfs_l(:,selectV2)];    

IRF_LP_V.irfs     =[IRF_LP_V.irfs   IRF_LP.irfs(:,selectV2)];
IRF_LP_V.irfs_u   =[IRF_LP_V.irfs_u IRF_LP.irfs_u(:,selectV2)];
IRF_LP_V.irfs_l   =[IRF_LP_V.irfs_l IRF_LP.irfs_l(:,selectV2)];    

IRF_VAR_V.irfs    =[IRF_VAR_V.irfs   IRF_VAR.irfs(:,selectV2)];
IRF_VAR_V.irfs_u  =[IRF_VAR_V.irfs_u IRF_VAR.irfs_u(:,selectV2)];
IRF_VAR_V.irfs_l  =[IRF_VAR_V.irfs_l IRF_VAR.irfs_l(:,selectV2)];   
% .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  %


%third set
load('Input_D2_3','IRF_BLP','IRF_LP','IRF_VAR','dataSetSpec','modelSpec');   %(3)

[~,selectV3]=ismember(selectV3,dataSetSpec.dataList);


    
varname =[varname modelSpec.dataStructure.varLongName(selectV3)];
varcode =[varcode modelSpec.dataStructure.varname(selectV3)];

IRF_BLP_V.irfs    =[IRF_BLP_V.irfs   IRF_BLP.irfs(:,selectV3)];
IRF_BLP_V.irfs_u  =[IRF_BLP_V.irfs_u IRF_BLP.irfs_u(:,selectV3)];
IRF_BLP_V.irfs_l  =[IRF_BLP_V.irfs_l IRF_BLP.irfs_l(:,selectV3)];    

IRF_LP_V.irfs     =[IRF_LP_V.irfs   IRF_LP.irfs(:,selectV3)];
IRF_LP_V.irfs_u   =[IRF_LP_V.irfs_u IRF_LP.irfs_u(:,selectV3)];
IRF_LP_V.irfs_l   =[IRF_LP_V.irfs_l IRF_LP.irfs_l(:,selectV3)];    

IRF_VAR_V.irfs    =[IRF_VAR_V.irfs   IRF_VAR.irfs(:,selectV3)];
IRF_VAR_V.irfs_u  =[IRF_VAR_V.irfs_u IRF_VAR.irfs_u(:,selectV3)];
IRF_VAR_V.irfs_l  =[IRF_VAR_V.irfs_l IRF_VAR.irfs_l(:,selectV3)];   
% .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  %


%fourth set
load('Input_D2_4','IRF_BLP','IRF_LP','IRF_VAR','dataSetSpec','modelSpec');   %(4)

[~,selectV4]=ismember(selectV4,dataSetSpec.dataList);


    
varname =[varname modelSpec.dataStructure.varLongName(selectV4)];
varcode =[varcode modelSpec.dataStructure.varname(selectV4)];

IRF_BLP_V.irfs    =[IRF_BLP_V.irfs   IRF_BLP.irfs(:,selectV4)];
IRF_BLP_V.irfs_u  =[IRF_BLP_V.irfs_u IRF_BLP.irfs_u(:,selectV4)];
IRF_BLP_V.irfs_l  =[IRF_BLP_V.irfs_l IRF_BLP.irfs_l(:,selectV4)];    

IRF_LP_V.irfs     =[IRF_LP_V.irfs   IRF_LP.irfs(:,selectV4)];
IRF_LP_V.irfs_u   =[IRF_LP_V.irfs_u IRF_LP.irfs_u(:,selectV4)];
IRF_LP_V.irfs_l   =[IRF_LP_V.irfs_l IRF_LP.irfs_l(:,selectV4)];    

IRF_VAR_V.irfs      =[IRF_VAR_V.irfs   IRF_VAR.irfs(:,selectV4)];
IRF_VAR_V.irfs_u    =[IRF_VAR_V.irfs_u IRF_VAR.irfs_u(:,selectV4)];
IRF_VAR_V.irfs_l    =[IRF_VAR_V.irfs_l IRF_VAR.irfs_l(:,selectV4)];   
% .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  %


%rearrange
[~,order] = ismember(selectV,varcode);

varname          =varname(order);

IRF_BLP_V.irfs    =IRF_BLP_V.irfs(:,order);
IRF_BLP_V.irfs_u  =IRF_BLP_V.irfs_u(:,order);
IRF_BLP_V.irfs_l  =IRF_BLP_V.irfs_l(:,order);    

IRF_LP_V.irfs     =IRF_LP_V.irfs(:,order);
IRF_LP_V.irfs_u   =IRF_LP_V.irfs_u(:,order);
IRF_LP_V.irfs_l   =IRF_LP_V.irfs_l(:,order);    

IRF_VAR_V.irfs    =IRF_VAR_V.irfs(:,order);
IRF_VAR_V.irfs_u  =IRF_VAR_V.irfs_u(:,order);
IRF_VAR_V.irfs_l  =IRF_VAR_V.irfs_l(:,order);  


%-------------------------------------------------------------------------&




%-PLOT IRFs: SAME IDENTIFICATION SCHEME-----------------------------------%

Bcolor   =[.0 .4 .6]; BbandFillColor   =[.85 .85 .85];
LPcolor  =[1. .4 .0]; LPbandFillColor  =[.9 .9 .9];
BLPcolor =[.0 .0 .4]; BLPbandFillColor =[.7 .7 .7];

%plot labels
shockSize =modelSpec.shockSize(modelSpec.shockVar)*100;

xPlotLength=21; %cm
yPlotLength=30; %cm
plotColumns=4;






    
%-------LP vs BLP vs BVAR---------------------------------------------%    

figure; pln=1; nHorizon=modelSpec.nHorizons; n=length(varname);
for j=1:n
    pl=subplot(ceil(n/plotColumns),plotColumns,pln);

    hold on

    %bands
    fill([0:1:nHorizon, fliplr(0:1:nHorizon)],...
        [IRF_VAR_V.irfs_l(1:nHorizon+1,j)' fliplr(IRF_VAR_V.irfs_u(1:nHorizon+1,j)')],...
        BbandFillColor,'EdgeColor','none');

    fill([0:1:nHorizon, fliplr(0:1:nHorizon)],...
        [IRF_BLP_V.irfs_l(1:nHorizon+1,j)' fliplr(IRF_BLP_V.irfs_u(1:nHorizon+1,j)')],...
        BLPbandFillColor,'EdgeColor','none');


    %irfs
    p0=plot(0:nHorizon,IRF_LP_V.irfs(1:nHorizon+1,j), '-.','LineWidth',1.5,'color',LPcolor);
    p1=plot(0:nHorizon,IRF_VAR_V.irfs(1:nHorizon+1,j),  '--','LineWidth',1.5,'color',Bcolor);
    p2=plot(0:nHorizon,IRF_BLP_V.irfs(1:nHorizon+1,j),'-', 'LineWidth',1.5,'color',BLPcolor);

    %zero line
    plot(0:nHorizon,zeros(size(1:nHorizon+1)),'k')

    hold off; axis tight

    xlim([0 nHorizon]);
    set(gca,'XTick',0:6:nHorizon,'XTickLabel',cellstr(num2str((0:6:nHorizon)')),'Layer','top')
    title(varname{j},'FontSize',9,'FontWeight','normal')

    if j==1
        ylabel('% points')
     end

    if j==n

        xlabel('horizon')

                lh=legend([p0 p1 p2],{['LP(' num2str(modelSpec.nLPlags) ')'];...
                                    ['BVAR(' num2str(modelSpec.nVARlags) ')'];...
                                     ['BLP(' num2str(modelSpec.nBLPlags) ')']},'FontSize',10,'Location','EastOutside');
        lp=get(lh,'Position'); lp(1)=.7; set(lh,'Position',lp)
        set(lh,'box','off')
    end

    pln=pln+1;
end



set(gcf,'PaperUnits','centimeters','PaperSize',[xPlotLength yPlotLength]) %[x y]
set(gcf,'PaperPosition',[-1 0 xPlotLength+2 yPlotLength]) %[left bottom width height]
print(gcf,'-dpdf',[pwd '/CHARTS/' runIdentifier '.pdf']);            

