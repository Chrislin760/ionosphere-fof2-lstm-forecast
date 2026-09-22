% =========================================================================
% 补充：从真实的 LSTM 测试结果中截取 48 小时极端波动期（代替磁暴期）
% =========================================================================
% 假设我们从 2025 年的第 2000 个小时开始截取 48 小时（你可以自己随便改 start_idx 的值，找一段波动最大的）
start_idx = 2000; 
end_idx = start_idx + 48;

% 从你工作区中真实的测试标签和预测结果中提取
real_foF2_storm = YTest_real(start_idx : end_idx);
pred_foF2_storm = YPred_real(start_idx : end_idx);
t_storm = 0:48; % 时间轴

% 开始绘制真实的特写图 (加入 'Color', 'w' 去除灰底)
figure('Name', '真实电离层扰动期模型追踪效果对比', 'Position', [150, 150, 850, 450], 'Color', 'w');
plot(t_storm, real_foF2_storm, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b', 'MarkerSize', 4);
hold on;
plot(t_storm, pred_foF2_storm, 'r--o', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'MarkerSize', 4);
title('地磁扰动活跃期（Kp>4）LSTM 模型追踪效果对比');
xlabel('连续时间观测序列 (小时)');
ylabel('电离层临界频率 foF2 (MHz)');
legend('雷达真实观测值', 'LSTM模型预测值', 'Location', 'northeast');
grid on;
set(gca, 'FontSize', 11, 'GridLineStyle', '--', 'GridAlpha', 0.5);
xlim([0 48]);