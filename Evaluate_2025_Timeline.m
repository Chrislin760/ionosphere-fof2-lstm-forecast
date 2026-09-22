% =========================================================================
% 第6阶段：最终完整版——从全年全景到微观时刻的多尺度对比图 (三图独立版)
% =========================================================================
% 1. 核心修正：对齐时间轴
window_size = 24;
time_plot = time_test(window_size+1:end); 
% 确保长度一致（防御性检查）
min_len = min(length(time_plot), length(YPred_real));
time_plot = time_plot(1:min_len);
YTest_real = YTest_real(1:min_len);
YPred_real = YPred_real(1:min_len);

disp('正在生成多尺度预测对比图...');

% -------------------------------------------------------------------------
% Figure 1: 宏观尺度 —— 2025全年全景概览 (单独一幅图)
% -------------------------------------------------------------------------
figure('Name', '2025年全年预测全景对比', 'Color', 'w', 'Position', [50, 50, 1200, 400]);
plot(time_plot, YTest_real, 'b-', 'LineWidth', 1); 
hold on;
plot(time_plot, YPred_real, 'r--', 'LineWidth', 1); 
title('2025年全年低纬电离层 foF2 预测全景对比 (宏观连续趋势)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('foF2 (MHz)');
legend('雷达观测值', 'LSTM预测值', 'Location', 'best');
grid on;
xtickformat('yyyy-MM'); % 全年图显示到月份

% -------------------------------------------------------------------------
% Figure 2: 中观尺度 —— 春夏秋冬（3, 6, 9, 12月）各月细节对比 (2x2布局)
% -------------------------------------------------------------------------
figure('Name', '2025年季节与月份预测对比', 'Color', 'w', 'Position', [100, 100, 1200, 700]);
target_months = [3, 6, 9, 12];
season_names = {'春季 (3月) - 春分期', '夏季 (6月) - 夏至期', '秋季 (9月) - 秋分期', '冬季 (12月) - 冬至期'};

for i = 1:4
    subplot(2, 2, i); % 改为 2x2 排列
    mask = month(time_plot) == target_months(i);
    
    if any(mask)
        plot(time_plot(mask), YTest_real(mask), 'b-', 'LineWidth', 1.2); 
        hold on;
        plot(time_plot(mask), YPred_real(mask), 'r--', 'LineWidth', 1.2);
        
        title(sprintf('不同季节/月份：%s', season_names{i}), 'FontSize', 11);
        ylabel('foF2 (MHz)');
        if i == 1 % 仅在第一个子图显示图例，保持画面干净
            legend('观测值', '预测值', 'Location', 'best');
        end
        xtickformat('MM-dd');
        grid on;
    else
        text(0.5, 0.5, sprintf('测试集中未包含 %d 月份数据', target_months(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 11);
        axis off;
    end
end

% -------------------------------------------------------------------------
% Figure 3: 微观尺度 —— 连续一周 (7天) 昼夜演化及峰值变化 (独立一幅图)
% -------------------------------------------------------------------------
figure('Name', '不同天对比：连续一周预测', 'Color', 'w', 'Position', [150, 150, 1200, 400]);

first_day = dateshift(time_plot(1), 'start', 'day');
mask_week = (time_plot >= first_day) & (time_plot < first_day + days(7));

if any(mask_week)
    plot(time_plot(mask_week), YTest_real(mask_week), 'b-', 'LineWidth', 1.5); 
    hold on;
    plot(time_plot(mask_week), YPred_real(mask_week), 'r--', 'LineWidth', 1.5);
    
    title('不同天对比：连续一周 (7天) 昼夜演化及峰值变化', 'FontSize', 12);
    ylabel('foF2 (MHz)');
    legend('观测值', '预测值', 'Location', 'best');
    xtickformat('MM-dd HH:mm'); 
    grid on;
else
    text(0.5, 0.5, '数据不足7天，无法绘制周趋势', 'HorizontalAlignment', 'center');
end

% -------------------------------------------------------------------------
% Figure 4: 微观尺度 —— 连续 48 小时精细结构 (独立一幅图)
% -------------------------------------------------------------------------
figure('Name', '不同时刻对比：连续48小时精细结构', 'Color', 'w', 'Position', [200, 200, 1200, 400]);

start_48h = first_day + days(10); 
mask_48h = (time_plot >= start_48h) & (time_plot < start_48h + days(2));

if ~any(mask_48h)
    start_48h = first_day;
    mask_48h = (time_plot >= start_48h) & (time_plot < start_48h + days(2));
end

if any(mask_48h)
    plot(time_plot(mask_48h), YTest_real(mask_48h), 'b.-', 'MarkerSize', 10, 'LineWidth', 1.5); 
    hold on;
    plot(time_plot(mask_48h), YPred_real(mask_48h), 'ro--', 'MarkerSize', 5, 'LineWidth', 1.5);
    
    title('不同时刻对比：连续 48 小时精细结构 (清晨增长/正午极值/夜间衰减)', 'FontSize', 12);
    ylabel('foF2 (MHz)');
    legend('观测值', '预测值', 'Location', 'best');
    xtickformat('HH:mm'); 
    grid minor; 
else
    text(0.5, 0.5, '数据不足48小时，无法绘制时序精细图', 'HorizontalAlignment', 'center');
end

disp('绘图完成！请检查弹出的独立 Figure 窗口。');

% =========================================================================
% 第7阶段：【新增】深度物理分析 —— 误差的时空分布特性
% =========================================================================
disp('正在绘制一天内不同时刻的误差分布特性...');

% 注意：为了防止第6阶段的长度对齐操作影响维度，这里重新计算一次对齐后的误差
aligned_errors = YPred_real - YTest_real; 

% 提取测试集时间对应的每一个小时 (0-23)
hours_of_day = hour(time_plot);
avg_error_per_hour = zeros(24, 1);

for h = 0:23
    mask_h = (hours_of_day == h);
    if any(mask_h)
        % 计算每个小时段的平均绝对误差 (MAE)
        avg_error_per_hour(h+1) = mean(abs(aligned_errors(mask_h))); 
    end
end

% 绘制逐时误差柱状图
figure('Name', '误差的逐时分布', 'Color', 'w', 'Position', [250, 250, 800, 400]);
bar(0:23, avg_error_per_hour, 'FaceColor', [0.3010 0.7450 0.9330], 'EdgeColor', 'k');
hold on;

% 添加整体平均误差参考线 (使用之前算好的 mae_val)
yline(MAE, 'r--', 'LineWidth', 2, 'Label', '全天平均误差水平');

title('LSTM预测误差的一天内逐时分布 (捕捉晨昏交替波动)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('本地时间 (Local Time / Hour)', 'FontSize', 11);
ylabel('平均绝对误差 Δ (MHz)', 'FontSize', 11);
xticks(0:23);
grid on;
set(gca, 'FontSize', 10);

disp('所有毕设高级图表生成完毕！');