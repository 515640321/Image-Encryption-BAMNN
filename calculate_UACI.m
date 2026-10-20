function uaci_val = calculate_UACI(cipher1, cipher2)
    % cipher1, cipher2: 两幅密文图像矩阵（可为 uint8 或 double 类型）
    
    % 转换为双精度浮点数以防计算溢出
    C1 = double(cipher1);
    C2 = double(cipher2);
    
    % 获取图像尺寸
    [M, N] = size(C1);
    
    % 计算 UACI 公式
    diff_sum = sum(abs(C1(:) - C2(:)));
    uaci_val = (diff_sum / (M * N * 255)) ;
end