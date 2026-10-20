function [corr_h, corr_v, corr_d] = calculate_correlations_fast(image)
% 更高效的相关系数计算版本
% 使用向量化操作提高计算速度

    % 转换为double类型
    img = double(image);
    [rows, cols] = size(img);
    
    % 水平方向相关系数
    horizontal_x = img(:, 1:end-1);
    horizontal_y = img(:, 2:end);
    corr_h = corr2(horizontal_x(:), horizontal_y(:));
    
    % 垂直方向相关系数
    vertical_x = img(1:end-1, :);
    vertical_y = img(2:end, :);
    corr_v = corr2(vertical_x(:), vertical_y(:));
    
    % 对角方向相关系数（主对角线）
    diagonal_x = img(1:end-1, 1:end-1);
    diagonal_y = img(2:end, 2:end);
    corr_d = corr2(diagonal_x(:), diagonal_y(:));
end