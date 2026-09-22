
% 1. 源路径：
zip_folder = 'C:\Users\Administrator\Desktop\毕设数据'; 

% 2. 目标路径
unzip_folder = 'C:\Users\Administrator\Desktop\毕设数据\foF2_Unzipped'; 

% 检查解压目标文件夹是否存在，不存在则自动创建
if ~exist(unzip_folder, 'dir')
    mkdir(unzip_folder);
end

% 获取所有的 zip 文件列表
disp('正在全盘扫描所有年份文件夹下的压缩包...');
zip_files = dir(fullfile(zip_folder, '**', '*.zip'));
num_zips = length(zip_files);

if num_zips == 0
    error('没有找到任何 zip 文件，请检查 C:\Users\Administrator\Desktop\毕设数据 路径是否正确！');
end

fprintf('扫描完毕！共发现 %d 个压缩包，准备开始集中解压...\n', num_zips);

% 开始循环解压
for i = 1:num_zips
    % 获取当前这个 zip 文件的完整绝对路径
    zip_path = fullfile(zip_files(i).folder, zip_files(i).name);
    
    try
        % 将它解压到我们统一建立的那个大文件夹里
        unzip(zip_path, unzip_folder);
    catch
        warning(['解压失败，跳过该文件: ', zip_files(i).name]);
    end
    
    % 每解压 100 个文件，打印一次进度
    if mod(i, 100) == 0
        fprintf('进度汇报：已成功解压 %d / %d 个文件...\n', i, num_zips);
    end
end

disp('太棒了！所有年份数据已全部穿透解压完毕！');
disp(['请前往 ', unzip_folder, ' 查看解压后的文件。']);