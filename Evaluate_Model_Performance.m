% =========================================================================
% 第5阶段：模型量化评估与可视化图表 (含基准模型对比)
% =========================================================================
disp('正在计算误差指标并绘制可视化图表...');

% 1. 计算核心评价指标：RMSE 和 MAE (Δ)
errors = YPred_real - YTest_real;
rmse_val = sqrt(mean(errors.^2)); 
mae_val = mean(abs(errors));      
mean_err = mean(errors);          

% 2. 【新增】极简基准模型 (Persistence Baseline) 对比
% 基准模型：假设下一时刻的预测值等于当前时刻的真实值
Y_baseline = [YTest_real(1); YTest_real(1:end-1)]; 
baseline_errors = Y_baseline - YTest_real;
baseline_rmse = sqrt(mean(baseline_errors.^2));
baseline_mae = mean(abs(baseline_errors));

% 打印对比结果到命令行 (方便你直接复制到论文表格)
disp('--------------------------------------------------');
disp('【论文核心数据表格：模型精度对比】');
disp(['LSTM模型 RMSE: ', num2str(rmse_val), ' MHz']);
disp(['基准模型 RMSE: ', num2str(baseline_rmse), ' MHz']);
disp(['LSTM模型 MAE (Δ): ', num2str(mae_val), ' MHz']);
disp(['基准模型 MAE (Δ): ', num2str(baseline_mae), ' MHz']);
disp('--------------------------------------------------');

% 3. 计算皮尔逊相关系数
R = corrcoef(YTest_real, YPred_real);
corr_value = R(1,2);
R_squared = corr_value^2;

% --- 图表 1：真实值 vs 预测值散点相关性拟合图 --- (加入 'Color', 'w' 去除灰底)
figure('Name', '预测相关性与误差分析', 'Position', [100, 100, 700, 600], 'Color', 'w');
scatter(YTest_real, YPred_real, 15, 'filled', 'MarkerFaceAlpha', 0.4, 'MarkerFaceColor', [0 0.4470 0.7410]);
hold on;
min_val = min([YTest_real; YPred_real]);
max_val = max([YTest_real; YPred_real]);
plot([min_val, max_val], [min_val, max_val], 'r--', 'LineWidth', 2);
title('LSTM模型对低纬电离层 foF2 预测的相关性分析');
xlabel('测高仪真实观测值 foF2 (MHz)');
ylabel('LSTM模型预测值 foF2 (MHz)');
legend('预测数据点', '理想拟合线 (y=x)', 'Location', 'northwest');

% 在图表上打上标签
metrics_text = sprintf('相关系数 R = %.4f\n决定系数 R^2 = %.4f\nRMSE = %.4f MHz\n平均绝对误差 (Δ) = %.4f MHz', ...
    corr_value, R_squared, rmse_val, mae_val);
text(min_val + 0.5, max_val - 2.0, metrics_text, 'FontSize', 11, 'FontWeight', 'bold', 'EdgeColor', 'k', 'BackgroundColor', 'w');
grid on;
set(gca, 'FontSize', 11);

% --- 图表 2：预测误差分布直方图 --- (加入 'Color', 'w' 去除灰底)
figure('Name', '预测误差分布', 'Position', [150, 150, 700, 500], 'Color', 'w');
h = histogram(errors, 'Normalization', 'pdf', 'EdgeColor', 'w', 'FaceColor', [0.8500 0.3250 0.0980]);
hold on;
pd = fitdist(errors, 'Normal');
x_values = linspace(min(errors), max(errors), 100);
y_values = pdf(pd, x_values);
plot(x_values, y_values, 'k-', 'LineWidth', 2);
xline(mean_err, 'b--', 'LineWidth', 1.5, 'Label', sprintf('误差均值: %.4f', mean_err));
title('LSTM模型预测误差 (Δ) 的概率密度分布');
xlabel('预测误差 Δ (模型预测值 - 真实观测值) / MHz');
ylabel('概率密度 (Probability Density)');
legend('误差分布直方图', '正态拟合曲线', '均值中心线', 'Location', 'northeast');
grid on;
set(gca, 'FontSize', 11);