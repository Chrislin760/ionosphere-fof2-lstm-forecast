unzip_folder = 'C:\Users\Administrator\Desktop\毕设数据\foF2_Unzipped'; 

% 2. 搜索该文件夹下所有的电离层数据文件
disp('正在扫描解压文件夹中的数据文件，请稍候...');
file_list = dir(fullfile(unzip_folder, '*.*i')); 
num_files = length(file_list);

if num_files == 0
    temp_list = dir(fullfile(unzip_folder, '*.*'));
    file_list = temp_list(~[temp_list.isdir]); % 只保留文件
    num_files = length(file_list);
end

if num_files == 0
    error('在目标文件夹中没有找到任何文件，请检查解压步骤是否真的成功生成了文件！');
end

fprintf('共扫描到 %d 个数据文件。开始提取 12 年的时序信号...\n', num_files);

% 3. 内存预分配 
% 12年大约有 10.5 万个小时(数据点)
estimated_points = num_files * 24;
raw_foF2 = zeros(estimated_points, 1);
raw_time = NaT(estimated_points, 1); % NaT = Not-a-Time 空时间

% 设定第一阶段确定的低纬度目标坐标
target_lat = 20.0;
target_lon = 120.0;
lon_index = round((target_lon - (-180)) / 5) + 1; 
global_idx = 1; 

% 4. 遍历所有文件提取信号
for i = 1:num_files
    filename = fullfile(file_list(i).folder, file_list(i).name);
    fileID = fopen(filename, 'r');
    
    if fileID == -1
        continue;
    end
    
    current_year = 0; current_month = 0; current_day = 0;
    
    while ~feof(fileID)
        tline = fgetl(fileID);
        if ~ischar(tline), break, end
        
        % 提取时间帧头
        if contains(tline, 'EPOCH OF CURRENT MAP')
            time_data = sscanf(tline, '%d');
            % 修复千禧年年份缩写问题
            y = time_data(1);
            if y < 100, y = y + 2000; end 
            
            current_year = y; 
            current_month = time_data(2); 
            current_day = time_data(3);
            current_hour = time_data(4); 
            
            % 将提取出的时间戳转化为 MATLAB 标准时间格式
            raw_time(global_idx) = datetime(current_year, current_month, current_day, current_hour, 0, 0);
        end
        
        % 提取有效数据载荷
        if contains(tline, 'LAT/LON1/LON2/DLON')
            lat_data = sscanf(tline, '%f');
            if abs(lat_data(1) - target_lat) < 0.01 
                temp_array = fscanf(fileID, '%d', 73);
                val = temp_array(lon_index);
                
                % 过滤异常值 
                if val < 900 
                    raw_foF2(global_idx) = val * 0.1; % 乘以 0.1 换算回 MHz
                else
                    raw_foF2(global_idx) = NaN; 
                end
                global_idx = global_idx + 1; 
            end
        end
    end
    fclose(fileID);
    
    % 进度监控
    if mod(i, 300) == 0
        fprintf('数据组装中... 已处理 %d / %d 个文件\n', i, num_files);
    end
end

% 截断尾部冗余内存 (因为有些文件可能不满 24 小时)
raw_foF2 = raw_foF2(1:global_idx-1);
raw_time = raw_time(1:global_idx-1);

% 5. 核心步骤：严格按绝对时间轴重新排序
% 操作系统读取文件的顺序往往是乱的，这一步能将12年的数据按时间线严丝合缝地对接起来
disp('提取完成！正在按绝对时间线重组时间序列 (Sorting)...');
[sorted_time, sort_idx] = sort(raw_time);
all_foF2 = raw_foF2(sort_idx);
time_axis = sorted_time;

% 6. 保存
save('foF2_12years_data.mat', 'time_axis', 'all_foF2');
disp('12年的数据已存入当前文件夹下的 foF2_12years_data.mat');

% =========================================================
% 修改处：绘制 12 年图像，强制纯白底色，并优化横纵比
% =========================================================
figure('Name', 'foF2 12年全景演变趋势', 'Position', [100, 150, 900, 350], 'Color', 'w');
plot(time_axis, all_foF2, 'b-', 'LineWidth', 0.5);
title('2014-2025 低纬电离层 foF2 长期演变趋势 (12年全景)');
xlabel('年份');
ylabel('临界频率 foF2 (MHz)');
grid on;
set(gca, 'FontSize', 11);