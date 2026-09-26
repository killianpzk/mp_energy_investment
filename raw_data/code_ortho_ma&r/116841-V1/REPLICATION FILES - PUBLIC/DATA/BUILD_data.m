
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
% ----------------------------------------------------------------------- %



clear 
clc


%  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %
%  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %

%main data

[tempData,tempText]         =xlsread('Miranda-Agrippino&Ricco_ALLDATA.xlsx','FRED-MD_2015SM');

data                        =tempData(2:end,2:end);
dates                       =x2mdate(tempData(2:end,1));
dataName                    =tempText(2,2:end);
dataDescription             =tempText(3,2:end);
logTransform                =logical(tempData(1,2:end));


clear tempData tempText


save FRED-MD_2015SM.mat
clear



%  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %
%  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %

%end of month 1year rate

[tempData,~]                =xlsread('Miranda-Agrippino&Ricco_ALLDATA.xlsx','endOfMonthGS1data');

eomGS1.data                 =tempData(:,2);
eomGS1.dates                =x2mdate(tempData(:,1));


clear tempData tempText


save endOfMonthGS1data.mat
clear



%  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %
%  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %

%Miranda-Agrippino & Ricco instruments

[tempData,tempText]         =xlsread('Miranda-Agrippino&Ricco_ALLDATA.xlsx','MM_IVinstruments');

externalInstrument.data     =tempData(:,2:end);
externalInstrument.dates    =x2mdate(tempData(:,1));
externalInstrument.labels   =tempText(1,:);

clear tempData tempText


save MM_IVinstruments.mat
clear



%  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %
%  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %

%FF4-based High-Frequency instruments

[tempData,tempText]         =xlsread('Miranda-Agrippino&Ricco_ALLDATA.xlsx','FF4_IV_variants');

externalInstrument.data     =tempData(:,2:end);
externalInstrument.dates    =x2mdate(tempData(:,1));
externalInstrument.labels   =tempText(1,:);

clear tempData tempText


save FF4_IV_variants.mat
clear



%  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %
%  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %

%narrative monetary policy instrument

[tempData,tempText]         =xlsread('Miranda-Agrippino&Ricco_ALLDATA.xlsx','RRnarrative');

externalInstrument.data     =tempData(:,2:end);
externalInstrument.dates    =x2mdate(tempData(:,1));
externalInstrument.labels   =tempText(1,:);

clear tempData tempText


save RRnarrative.mat
clear



%  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %
%  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . %

%narrative monetary policy instrument

[tempData,tempText]         =xlsread('Miranda-Agrippino&Ricco_ALLDATA.xlsx','ConsensusForecastsUS');

CFUS1Y.median               =tempData(:,2:end);
CFUS1Y.dates                =x2mdate(tempData(:,1));
CFUS1Y.labels               =tempText(1,:);

clear tempData tempText


save ConsensusForecastsUS.mat
clear
