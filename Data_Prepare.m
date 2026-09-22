% =========================================================================
% 第2阶段：电离层时序数据预处理与特征构造
% =========================================================================

% 1. 加载 12 年全量数据
load('foF2_12years_data.mat'); 

disp('1. 正在排查并填补序列中的缺失值 (NaN)...');
all_foF2_clean = fillmissing(all_foF2, 'linear');

if any(isnan(all_foF2_clean))
    error('警告: 仍有未填补的 NaN 值');
end

% 2014 到 2024 年的数据给模型学习，2025 年的数据留作测试
disp('2. 正在按真实年份切分数据 (2014-2024: 训练集 | 2025: 测试集)...');
train_idx = year(time_axis) < 2025;
test_idx = year(time_axis) == 2025;

data_train = all_foF2_clean(train_idx);
data_test = all_foF2_clean(test_idx);

% 提取对应的测试集真实时间轴
time_test = time_axis(test_idx);

disp(['划分完成！训练集 (2014-2024): ', num2str(length(data_train)), '点, 测试集 (2025): ', num2str(length(data_test)), '点。']);

% 3. 数据标准化 (Z-score)
disp('3. 正在进行 Z-score 标准化...');
mu = mean(data_train);
sig = std(data_train);

data_train_norm = (data_train - mu) / sig;
data_test_norm = (data_test - mu) / sig;

save('norm_params.mat', 'mu', 'sig');

% 4. 构造 LSTM 滑动窗口
window_size = 24;
disp(['4. 正在构造滑动窗口特征 (窗口大小: ', num2str(window_size), ' 小时)...']);

[XTrain, YTrain] = create_sequences(data_train_norm, window_size);
[XTest, YTest] = create_sequences(data_test_norm, window_size);

disp('--------------------------------------------------');
disp('按年份划分的标准化矩阵已全部就绪。');
disp('--------------------------------------------------');

save('LSTM_Prepared_Data.mat', 'XTrain', 'YTrain', 'XTest', 'YTest', 'time_test', '-v7.3');

% --- 辅助函数：切分窗口 ---
function [X, Y] = create_sequences(data, window_size)
    num_samples = length(data) - window_size;
    X = cell(num_samples, 1);
    Y = zeros(num_samples, 1);
    
    for i = 1:num_samples
        X{i} = data(i : i + window_size - 1)'; 
        Y(i) = data(i + window_size);
    end
end