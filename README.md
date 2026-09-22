# 基于 LSTM 的低纬电离层 foF2 长期预测

> 本科毕业设计 · 使用 LSTM 深度神经网络对低纬电离层临界频率(foF2)进行逐小时预测
> 数据集:全球测高仪网络 2014–2025 共 **12 年** 时序(约 105,000 小时)· 目标站位 **20°N, 120°E**

---

## 一、项目背景

电离层 F2 层临界频率(foF2)是描述电离层状态最核心的参数之一,直接决定高频(HF)通信可用的
最高频率、影响 GNSS 导航的延迟修正,具有显著的 **昼夜变化、季节变化与 11 年太阳活动周期**。

本项目从 IGY 格式的公开测高仪原始文件出发,完成 **原始数据解析 → 时序重建 → 深度学习建模
→ 多尺度评估** 的全流程,验证 LSTM 网络在低纬电离层短时预报中的可行性。

---

## 二、核心结果

测试集:2025 年全年 8,760 小时(完全独立于训练集)

| 评价指标 | LSTM 模型 | 基准模型(Persistence) |
|:---|:---:|:---:|
| RMSE (MHz) | **【填你的数】** | **【填你的数】** |
| MAE (MHz) | **【填你的数】** | **【填你的数】** |
| 平均误差 (MHz) | **【填你的数】** | — |
| 相关系数 R | **【填你的数】** | — |
| 决定系数 R² | **【填你的数】** | — |

> 基准模型 Persistence 假设「下一时刻的值 = 当前时刻的真实值」,是时序预测中最常用的
> 朴素对照,用以证明 LSTM 相比「不做预测」的实际增益。

---

## 三、代码结构

```
.
├── UnZipped.m                      # ① 批量解压:递归扫描所有年份的 zip 包并统一解压
├── DataExtract.m                   # ② 数据提取:解析 IGY 文件,提取 foF2 时序并严格按时间排序
├── Data_Prepare.m                  # ③ 数据预处理:缺失值填补 → 年份切分 → Z-score → 滑动窗口
├── Train_LSTM.m                    # ④ 模型训练:构建 LSTM 网络、训练、测试并保存模型
├── Evaluate_Model_Performance.m    # ⑤ 量化评估:RMSE/MAE/R² + 基准模型对比 + 误差分布
├── Evaluate_2025_Timeline.m        # ⑥ 多尺度可视化:全年 / 季节 / 一周 / 48小时 / 逐时误差
├── new.m                           # ⑦ 补充:扰动活跃期模型追踪效果特写
├── untitled.m                      # ⑧ 补充:误差「月份 × 小时」时空分布热力图
│
├── foF2_12years_data.mat           # 12 年时序原始数据(代码读这个,624 KB)
├── My_Trained_LSTM.mat             # 训练完成的 LSTM 网络模型(68 KB)
└── norm_params.mat                 # 训练集标准化参数 μ / σ(反归一化必需)
```

---

## 四、技术实现要点

### 4.1 原始文件解析(DataExtract.m)
- 定位 `EPOCH OF CURRENT MAP` 帧头,提取 年/月/日/时 时间戳,并修复千禧年两位年份写法
- 解析 `LAT/LON1/LON2/DLON` 数据块,按经纬度网格索引定位目标站位(20°N, 120°E)
- 测高仪压缩编码为整数存储,×0.1 还原为 MHz;`≥900` 视为传感器无效填充码,置 NaN
- **时间对齐**:文件系统返回的文件顺序并非时间顺序,采用后置 `sort` 按绝对时间戳重组

### 4.2 数据预处理(Data_Prepare.m)
- 12 年长序列中的传感器缺失用 `fillmissing(...,'linear')` 线性插值
- 按真实年份切分:**2014–2024 训练(11 年)/ 2025 测试(1 年)**,避免随机切分造成的时序泄露
- Z-score 标准化,**μ、σ 仅由训练集计算**并落盘供反归一化复用,杜绝测试集信息泄露
- 构造 24 小时滑动窗口样本,`X = [t-23 … t]`,`Y = t+1`(监督学习格式)

### 4.3 网络结构(Train_LSTM.m)
```
sequenceInputLayer(1)
lstmLayer(64, 'OutputMode','last')
fullyConnectedLayer(1)
regressionLayer
```
训练配置:Adam 优化器 · MaxEpochs 20 · MiniBatchSize 256 · 梯度阈值 1 ·
初始学习率 0.005(分段衰减,每 10 epoch ×0.2)

### 4.4 评估体系(Evaluate_Model_Performance.m)
RMSE / MAE / 平均误差 / 皮尔逊相关系数 R / 决定系数 R²
\+ **Persistence 基准对照** + 误差概率密度分布 + 误差逐时(0–23 h)分布
\+ 误差「月份 × 小时」二维热力图

---

## 五、复现步骤

1. 从 NOAA / 全球测高仪公开数据库下载各年份 IGY 数据包,按年份放入 `2014/` … `2025/` 目录
2. 运行 `UnZipped.m` → 全部解压至 `foF2_Unzipped/`
3. 运行 `DataExtract.m` → 生成 `foF2_12years_data.mat` + 12 年全景趋势图
4. 运行 `Data_Prepare.m` → 生成 `LSTM_Prepared_Data.mat` 与 `norm_params.mat`
5. 运行 `Train_LSTM.m` → 训练网络,输出训练曲线并保存 `My_Trained_LSTM.mat`
6. 运行 `Evaluate_Model_Performance.m` → 得到精度指标与评估图
7. 运行 `Evaluate_2025_Timeline.m` → 生成多尺度对比图

**运行环境**:MATLAB R2021a 或更高 · Deep Learning Toolbox

> ⚠️ 注意:`UnZipped.m` 与 `DataExtract.m` 中的输入/输出路径为作者本地路径,
> 复现时请先修改为你的实际路径。

---

## 六、后续改进方向

- 引入 **太阳活动指数(F10.7)、地磁指数(Kp/Ap)** 作为外部协变量,提升扰动期预报能力
- 将单站模型扩展为 **多站/区域网格预测**,构建区域 foF2 时空预报场
- 对比 **Bi-LSTM / GRU / Transformer**,进一步分析不同结构在电离层这类准周期信号上的表现

---

## 七、License

本项目采用 [MIT License](LICENSE) 开源,欢迎交流。
