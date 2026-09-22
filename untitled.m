% ==========================================================
% 补充：绘制 2025 年 foF2 预测平均绝对误差的时空热力图
% ==========================================================

% 1. 获取全年的绝对误差数据
% 如果你工作区里有真实的预测结果，请取消下面这行的注释并使用它：
% errors_abs = abs(YTest_real - YPred_real);

% （为防止你当前没跑完数据，这里先用高仿真物理特征生成一段 8760 小时的占位误差数据，方便你预览图像效果）
if ~exist('errors_abs', 'var')
    % 模拟赤道异常（下午误差大）与春秋分异常（春秋误差大）
    t_sim = 1:8760;
    errors_abs = 0.25 + 0.15*sin(pi*t_sim'/4380) + 0.1*sin(pi*(mod(t_sim,24)-14)/12) + 0.1*rand(8760,1);
end

% 2. 截取 2025 全年的 8760 个小时 (365天 * 24小时)
if length(errors_abs) >= 8760
    errors_abs = errors_abs(1:8760);
end

% 3. 将一维误差重塑为 365天 x 24小时 的矩阵
daily_errors = reshape(errors_abs, 24, 365)';

% 4. 计算每个月 24 小时的平均绝对误差
days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
monthly_hourly_errors = zeros(12, 24);

start_day = 1;
for m = 1:12
    end_day = start_day + days_in_month(m) - 1;
    % 按月计算 24 个时次的均值
    monthly_hourly_errors(m, :) = mean(daily_errors(start_day:end_day, :), 1);
    start_day = end_day + 1;
end

% 5. 绘制专业级热力图 (加入 'Color', 'w' 去除灰底)
figure('Name', '预测误差时空热力图', 'Position', [150, 150, 900, 400], 'Color', 'w');

xvalues = string(0:23);
yvalues = {'1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'};

h = heatmap(xvalues, yvalues, monthly_hourly_errors);
h.Title = '2025年 LSTM 模型预测平均绝对误差 (MAE) 时空分布热力图';
h.XLabel = '本地时间 Local Time (时)';
h.YLabel = '月份 Month';
h.Colormap = parula; % 经典的科研热力图配色
h.ColorScaling = 'scaled';
h.GridVisible = 'off'; % 关闭内部网格线显得更高级
h.CellLabelFormat = '%.2f'; % 格子内保留两位小数（若嫌挤可将这行注释掉）