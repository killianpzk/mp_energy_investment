

clear
clc

addpath([pwd '/subroutines/']) %mac
addpath([pwd '/DATA/'])



%load FF4 data
load FF4_IV_variants

data1  =externalInstrument.data(:,ismember(externalInstrument.labels,'FF4'),:);
dates1 =externalInstrument.dates;


%laod instrument
load MM_IVinstruments

data2  =externalInstrument.data(:,ismember(externalInstrument.labels,'MPI'),:);
dates2 =externalInstrument.dates;



%chart
minT    =max(dates1(1),dates2(1));
maxT    =min(dates1(end),dates2(end));

commonT =dates1(dates1>=minT & dates1<=maxT); %common sample



figure;

hold on
NBERrecessionplot('dates',commonT,'ymin',-.4,'ymax',.3);

p1=plot(commonT,data1(ismember(dates1,commonT)),'color',[1.0 .4 .0],'LineStyle','-','LineWidth',1.5);
p4=plot(commonT,data2(ismember(dates2,commonT)),'color',[.0 .0 .4],'LineWidth',1.5);

% line([datenum('01-Feb-2006') datenum('01-Feb-2006')], ylim,'LineStyle','--','color','k','LineWidth',1);
% text(datenum('01-Feb-2006'),-.1,'Chair Bernanke','VerticalAlignment','Top',...
%    'HorizontalAlignment','Right','FontSize',11,'Color','k','Rotation',90)

set(gca,'FontSize',10,'Xtick',commonT(12:24:end),'box','on'); dateaxis('x',10); datetick('keepticks')

xlim([commonT(1) commonT(end)]);
ylim([-.4 .2]);

set(gca,'layer','top')

% title('Monetary Policy Shock','FontSize',12)
legend([p1 p4],{'Market-Based Surprise';'Monetary Policy Instrument'},'FontSize',9,'Location','SouthWest','box','on')
ylabel('percentage points','FontSize',10)

set(gcf,'PaperUnits','centimeters','PaperSize',[20 9]) %[x y]
set(gcf,'PaperPosition',[-1 -.0 22 9]) %[left bottom width height]
print(gcf,'-dpdf','CHARTS/Figure2.pdf')

