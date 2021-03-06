figure(1)
plot([0,1,2,3,4],[NaN,12,12,12,12],'m-',[1,2,3,4],[12.85,7.82,6.49,6.88],'b-',repmat(3,1,80),linspace(6,13,80),'r.','Linewidth',3)
legend('GPU OpenCL','Julia Par')
xlabel('No. Cores')
ylabel('Time(s)')
title('nx = 1500, ne = 15')
xlim([0.8 inf])
set(gca,'XTick',0:1:4);

figure(2)
plot([1,2,3,4],[51,51,51,51],'m-',[1,2,3,4],[97.2,66.5,57.57,55],'b-',repmat(4,1,80),linspace(45,100,80),'r.','LineWidth',3)
legend('GPU OpenCL','Julia Par')
xlabel('No. Cores')
ylabel('Seconds')
title('nx = 1500, ne = 50')
xlim([0.8 4.3])
ylim([45 inf])
set(gca,'XTick',0:1:4);

mean([98.1,96.3])
mean([64.5;
    67.9;
    67.2])
mean([57.8;
    64.4;
    53.7;
    54.4])
mean([56.8;
    52.8;
    57;
    ])