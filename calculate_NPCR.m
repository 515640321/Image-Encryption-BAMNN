function npcr_val = calculate_NPCR(cipher1, cipher2)
    % cipher1, cipher2: 两幅密文图像矩阵（uint8 或 double 类型）
    
    C1 = double(cipher1);
    C2 = double(cipher2);
    
    [M, N] = size(C1);
    
    % 统计对应位置像素不相等的总点数
    diff_pixels = sum(C1(:) ~= C2(:));
    
    % 计算 NPCR 百分比
    npcr_val = (diff_pixels / (M * N)) ;
end