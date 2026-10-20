% 读取原始图片
R0 = imread('cameraman.jpg');

% 如果需要转换为 256x256 尺寸
R0 = imresize(R0, [256, 256]);