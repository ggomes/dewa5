function plot_panels(N,mnth,xlimits)

% load dataSolar
load(fullfile('results',sprintf('N%d',N)),'sol')

X = sol{mnth};
time = 1:numel(X.g);

if nargin<3
    xlimits = [1 time(end)];
end


% Node 1
figure('Position',[1248        -309         550         856])
subplot(311)
plot(time,N*[X.s' X.b_in X.b_out],'LineWidth',2)
legend('s','bin','bout')
grid
set(gca,'XLim',xlimits)
subplot(312)
plot(time,N*X.B(1:end-1),'LineWidth',2)
legend('B')
grid
set(gca,'XLim',xlimits)
subplot(313)
plot(time,N*[X.g X.s'],'LineWidth',2)
legend('g','s')
grid
set(gca,'XLim',xlimits)

% Node 2 and 3
figure('Position',[1814        -308         560         859])
subplot(211)
plot(time,[N*X.g X.Xs],'LineWidth',2)
legend('N*g','Xs')
grid
set(gca,'XLim',xlimits)
subplot(212)
plot(time,[X.d' X.Xb],'LineWidth',2)
legend('d','Xb')
grid
set(gca,'XLim',xlimits)
