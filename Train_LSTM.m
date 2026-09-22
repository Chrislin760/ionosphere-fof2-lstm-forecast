disp('正在加载准备好的时序数据与还原密码本...');
load('LSTM_Prepared_Data.mat'); 
load('norm_params.mat'); 

disp('开始构建 LSTM 深度学习网络架构...');
numFeatures = 1;      
numResponses = 1;     
numHiddenUnits = 64;  

layers = [ ...
    sequenceInputLayer(numFeatures)
    lstmLayer(numHiddenUnits, 'OutputMode', 'last') 
    fullyConnectedLayer(numResponses)
    regressionLayer];

disp('配置网络训练参数...');
options = trainingOptions('adam', ...
    'MaxEpochs', 20, ...                 
    'MiniBatchSize', 256, ...            
    'GradientThreshold', 1, ...          
    'InitialLearnRate', 0.005, ...       
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropPeriod', 10, ...
    'LearnRateDropFactor', 0.2, ...
    'Verbose', 0, ...
    'Plots', 'none');       

disp(' 模型开始训练');
[net, info] = trainNetwork(XTrain, YTrain, layers, options);
disp('✅ 模型训练完成');

figure('Name', '训练进度曲线', 'Color', 'w', 'Position', [150, 150, 800, 600]);

subplot(2,1,1);
plot(info.TrainingRMSE, 'Color', [0 0.4470 0.7410], 'LineWidth', 1.5);
title('训练过程均方根误差 (RMSE)', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('迭代次数 (Iterations)', 'FontSize', 12);
ylabel('RMSE', 'FontSize', 12);
grid on;
set(gca, 'FontSize', 11, 'GridAlpha', 0.3);

subplot(2,1,2);
plot(info.TrainingLoss, 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.5);
title('训练过程损失 (Loss)', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('迭代次数 (Iterations)', 'FontSize', 12);
ylabel('Loss', 'FontSize', 12);
grid on;
set(gca, 'FontSize', 11, 'GridAlpha', 0.3);

disp('正在测试');
YPred_norm = predict(net, XTest, 'MiniBatchSize', 256);
YPred_real = YPred_norm * sig + mu;
YTest_real = YTest * sig + mu;

RMSE = sqrt(mean((YPred_real - YTest_real).^2));
MAE = mean(abs(YPred_real - YTest_real));

fprintf('\n================ 最终结果 ================\n');
fprintf('均方根误差 (RMSE): %.4f MHz\n', RMSE);
fprintf('平均绝对误差 (MAE) : %.4f MHz\n', MAE);
fprintf('============================================\n');

figure('Color', 'w');
plot_length = 400; 
plot(YTest_real(1:plot_length), 'b-', 'LineWidth', 1.5);
hold on;
plot(YPred_real(1:plot_length), 'r--', 'LineWidth', 1.5);
title('LSTM预测对比 (真实值 vs 预测值)');
xlabel('时间 (小时)');
ylabel('电离层临界频率 foF2 (MHz)');
legend('真实观测值 (Actual)', '模型预测值 (Predicted)');
grid on;

save('My_Trained_LSTM.mat', 'net');
disp('神经网络模型已存入 My_Trained_LSTM.mat');