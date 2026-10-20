% clc
% clear all
% reading image's pixel in c

c1 = imread('cameraman.jpg');
c0 = imresize(c1, [256, 256], 'bilinear');
% c0 = squeeze(c0(:,:,3));
% get the dimensions of the image
[M,N] = size(c0);
cd = double(c0);
% R1=uint8((reshape(floor(mod(abs(10^12*((S(1,:)-floor(S(1,:))))),256)),256,256)));
% random value insertion
U1 = U(1:65536, 1);
V = zeros(256,1);  % 补充V的定义（假设为256×1零矩阵）
for i =1:256
    V(i,1)=randi(i);
end
U2 = [U1; V];
% 修复：重塑为256×257矩阵（65536+256=65792=256×257）
SR = reshape(U2(:,1) - floor(U2(:,1)), 256, 257);
R = zeros(M,N+1);%R代表图像的像素矩阵加了一列随机数，增加随机性
for i = 1:M
    for j = 1:N+1
        if j == 1
            R(i,j) = randi(i);
        else
            R(i,j) = cd(i,j-1);
        end
    end
end

% R2=zeros(M,1);
% for i =1:M
%     if j == 1
        % R(i,j)=randi(i)
%     end
% end
% R=[R1 R2];

B = zeros(M,N+1);% 创建M×(N+1)的零矩阵B，用于存储加密过程中的中间结果
s1 = zeros(M,N+1);% 创建M×(N+1)的零矩阵s1，用于存储由混沌映射生成的伪随机序列（密钥流）
s2 = zeros(N+1,M+1);
s3 = zeros(M+1,N+2);
s4 = zeros(N+2,M+2);

%设置混沌映射参数（加密密钥核心）
% user defined values  % 注释：用户自定义参数（加密的核心密钥参数）
% values of r should be between 0 and 4.  % 注释：r系列参数应在0~4之间（符合混沌映射特性）
% value of s0 should be between 0 and 1.  % 注释：s0应在0~1之间（混沌映射的初始状态范围）
% user defined values
% values of r should be between 0 and 4.
% value of s0 should be between 0 and 1.
s0 = 0.87;% 混沌映射的初始状态（种子值），微小变化会导致序列完全不同（加密安全性关键）
r0 = 1.5;% 混沌映射的控制参数（用于第一列s1的生成）
r1 = 1.3;% 混沌映射的控制参数（用于非第一列s1的生成）
r2 = 1.2;
r3 = 1.1;
r4 = 1.3;
k=0.12;
%核心作用：定义alt混沌映射的输入参数，这些参数是加密算法的 “密钥”—— 只有知道相同的参数，才能生成相同的混沌序列，进而解密。
%参数意义：s0是初始种子，r0/r1控制混沌映射的演化规律，k控制扰动强度，共同决定s1序列的随机性（直接影响加密安全性）。

% 1-D substitution 
% first round of the encryption
%这部分是加密的核心，通过双重循环生成混沌序列s1，并结合异或运算对R矩阵（含随机列的图像数据）进行加密，存储到B中。
for i = 1:M
    for j = 1:N+1
        if (i==1) && (j==1)% 第1行第1列（矩阵左上角第一个元素）
            s1(i,j) = alt(r0,SR(1,1),k);% 用初始参数r0、s0、k生成第一个混沌值
        elseif (i>1) && (j == 1)% 第1列（非首行，即i≥2，j=1）
            s1(i,j) = alt(r0,SR(i-1,1),k);% 依赖上一行第1列的s1值（列方向迭代）
        else    % 非第1列（j≥2，任意行i）
            s1(i,j) = alt(r1,SR(i,j-1),k);% 依赖同一行前一列的s1值（行方向迭代）
        end %已经对s1(i,j)设计完成，s1的生成是 “链式依赖” 的：第一个元素s1(1,1)由初始种子s0生成，第一列其他元素依赖上一行第一列的值（纵向传递），其他列元素依赖同一行前一列的值（横向传递）。
%这种 “依赖前序值” 的迭代方式，是混沌序列 “对初始条件敏感” 的体现 ——s0或r0/r1的微小变化，会导致整个s1矩阵完全不同，确保加密密钥的唯一性。
        if j > 1    % 跳过第1列（随机列），仅处理有效数据列（j≥2，对应原始图像数据）
            s = floor(mod(s1(i,j)* 10^10, 256));  % 将混沌值s1(i,j)转换为0~255的整数密钥
            B(i,j) = bitxor(bitxor(B(i,j-1),R(i,j),'uint8'),s,'uint8');     
        end
    end
end
E = rot90(B);%顺时针旋转90度，通过旋转，加密后的图像E中像素的空间分布与原始图像几乎无关联，攻击者无法利用 “相邻像素相关性” 进行破解。


% second round
% random value insertion
R = randi(255,N+1,1,'uint8');% 作用：在第二轮加密的输入中再次嵌入随机列，延续“随机扰动+原始数据”的加密思路。
B = [R E];
R = B;% 将拼接后的B赋值给R，用于后续循环中引用“原始输入数据”（避免B在加密过程中被修改后丢失原始值）
        % 注意：此时R与B完全相同，后续修改B时，R保持初始值不变，确保异或运算能正确引用原始数据。
for i = 1:N+1
    for j = 1:M+1
        if (i==1) && (j==1)
            s2(i,j) = alt(r0,s1(1,N),k);% 初始值来自第一轮s1的(1,N)位置（非重新用s0，增强序列关联性和复杂度）
        elseif (i>1) && (j == 1)
            s2(i,j) = alt(r0,s2(i-1,1),k);% 依赖上一行第1列的s2值（纵向迭代，与s1逻辑一致）
        else    
            s2(i,j) = alt(r2,s2(i,j-1),k);% 依赖同一行前一列的s2值（横向迭代，但用r2作为控制参数，与s1的r1不同）
        end  %%对单个的s2(i,j)设计完成，并且每个s2都在0到1之间
        if j > 1  % 跳过第1列（随机列），处理有效数据列（j≥2）
            s = floor(mod(s2(i,j)* 10^10, 256));%将每个s2放大，和256取模，实现0-255之间
            B(i,j) = bitxor(bitxor(B(i,j-1),R(i,j),'uint8'),s,'uint8');%双重异或运算
        else % j=1（第一列，随机列）
            B(i,j) = R(i,j);% 直接保留随机列的值（不加密，作为下一轮迭代的初始扰动）
        end
    end
end
E = rot90(B);%把B逆时针旋转90度，通过旋转，加密后的图像E中像素的空间分布与原始图像几乎无关联，攻击者无法利用 “相邻像素相关性” 进行破解。
%此时E是(M+1)*(N+1)

%third round 
% random value insertion
R = randi(255,M+1,1,'uint8');% 生成一个(M+1)×1的随机列向量R（元素为0~255的uint8类型）
B = [R E];
R = B;% 将拼接后的B赋值给R，保存第三轮加密的原始输入（避免B在加密过程中被修改后丢失原始数据）
        % 与前两轮逻辑一致：后续异或运算需要引用“未加密的原始值”，因此用R暂存初始B。
for i = 1:M+1
    for j = 1:N+2
        if (i==1) && (j==1)
            s3(i,j) = alt(r0,s2(N,1),k);% 初始值来自第二轮s2的(N,1)位置（非重新用s0或s1的初始值，强化多轮序列的关联性）
        elseif (i>1) && (j == 1)
            s3(i,j) = alt(r0,s3(i-1,1),k);% 依赖上一行第1列的s3值（纵向迭代，与前两轮逻辑一致）
        else    
            s3(i,j) = alt(r3,s3(i,j-1),k);% 依赖同一行前一列的s3值（横向迭代，使用新控制参数r3，与前两轮的r1、r2不同）
        end
        if j > 1  % 跳过第1列（随机列），处理有效数据列（j≥2）
            s = floor(mod(s3(i,j)* 10^10, 256));
            B(i,j) = bitxor(bitxor(B(i,j-1),R(i,j),'uint8'),s,'uint8');
        else
            B(i,j) = R(i,j);
        end
    end
end
E = rot90(B);
%旋转后E变为(N+2)×(M+1)

% fourth round
% random value insertion
R = randi(255,N+2,1,'uint8');% 生成一个(N+2)×1的随机列向量R（元素为0~255的uint8类型）
B = [R E];
R = B;
for i = 1:N+2
    for j = 1:M+2
        if (i==1) && (j==1)
            s4(i,j) = alt(r0,s3(1,N),k);% 初始值来自第三轮s3的(1,N)位置（强化四轮序列的关联性：s1→s2→s3→s4）
        elseif (i>1) && (j == 1)
            s4(i,j) = alt(r0,s4(i-1,1),k);% 依赖上一行第1列的s4值（纵向迭代，与前三轮逻辑一致）
        else    
            s4(i,j) = alt(r4,s4(i,j-1),k);% 依赖同一行前一列的s4值（横向迭代，使用新控制参数r4，与r1、r2、r3均不同）
        end
        if j > 1  % 跳过第1列（随机列），处理有效数据列（j≥2）
            s = floor(mod(s4(i,j)* 10^10, 256));
            B(i,j) = bitxor(bitxor(B(i,j-1),R(i,j),'uint8'),s,'uint8');     
        else
            B(i,j) = R(i,j);
        end
    end
end
E = rot90(B);
%旋转后E变为(M+2)×(N+2)

E = uint8(E); 
imwrite(E, 'encrypted_result.jpg');  
fprintf('加密图像已保存为 encrypted_result.jpg\n');
% 将最终加密结果E转换为uint8类型（8位无符号整数）
               % 原因：
               % - 图像数据的标准类型是uint8（像素值范围0~255），之前加密过程中可能因运算转为double类型；
               % - 转换为uint8才能被`imshow`正确显示，且与原始图像`c0`（通常是uint8）保持类型一致，便于后续对比分析。
subplot(2, 4, 1);
imshow(c0);
% title("Original image");
subplot(2,4,2);
imshow(E);
% title("Encrypted image");

glcm = graycomatrix(c0);
% 计算原始图像c0的灰度共生矩阵（GLCM）
% GLCM描述图像中相邻像素的灰度值组合频率，反映纹理的空间分布规律
contrast_original = graycoprops(glcm,'contrast');% 从原始图像的GLCM中提取“对比度”特征
                                                   % 对比度：描述相邻像素灰度值的差异程度（值越大，纹理越粗糙/边缘越清晰）

glcm = graycomatrix(E);% 计算加密图像E的灰度共生矩阵（GLCM）
contrast_cipher = graycoprops(glcm,'contrast');  % 从加密图像的GLCM中提取“对比度”特征
% histogram
subplot(2,4,5);
imhist(c0);
% set(h, 'FaceColor', 'r', 'EdgeColor', 'k');
subplot(2,4,6);
imhist(E);
% set(h, 'FaceColor', 'r', 'EdgeColor', 'k');
%%%%解密过程

E   = uint8(E);% 将加密后的图像E转换为uint8类型（与加密最后一步保持一致，确保数据类型匹配）
%[M,N] = size(E);
EE=E;
DD   = zeros(M+2,N+2);% 初始化解密结果矩阵D（尺寸与加密最后一轮的矩阵一致），用于存储解密中间结果
sd1 = zeros(M,N+1);% 初始化解密用混沌序列sd1（对应加密时的s1）
sd2 = zeros(M,N+1);% 初始化解密用混沌序列sd2（对应加密时的s2）
sd3 = zeros(M,N+1);% 初始化解密用混沌序列sd3（对应加密时的s3）
sd4 = zeros(M,N+1);% 初始化解密用混沌序列sd4（对应加密时的s4）

% user defined values% 注释：用户自定义参数（必须与加密时完全相同，否则无法解密）
s0 = 0.87;
r0 = 1.5;
r1 = 1.3;
r2 = 1.2;
r3 = 1.1;
r4 = 1.3;
k=0.12;

%1-D SUBSTITUTION

for rnd = 1:4  %% 遍历4轮，分别生成sd1-sd4（对应加密时的s1-s4）
    for i = 1:M+2 %% 行数范围与加密最后一轮的矩阵尺寸一致
        for j = 1:M+2  %% 列数范围与加密最后一轮的矩阵尺寸一致
            if (rnd==1) % 第1轮：生成sd1（对应加密时的s1）
                if (i==1) && (j==1)  % 第1行第1列（初始值）
                    sd1(i,j) = alt(r0,SR(1,1),k);  % 与加密s1(1,1)生成逻辑相同：用s0、r0、k
                elseif (M+1>=i>1) && (j == 1) % 第1列（非首行）
                    sd1(i,j) = alt(r0,SR(i-1,1),k); % 与加密s1一致：依赖上一行第1列的值
                elseif (j>1) && (i<=M)   
                    sd1(i,j) = alt(r1,SR(i,j-1),k);  % 与加密s1一致：用r1，依赖同一行前一列的值
                end
            elseif (rnd==2) % 第2轮：生成sd2（对应加密时的s2）
                if (i==1) && (j==1)
                    sd2(i,j) = alt(r0,sd1(1,N),k);  % 与加密s2(1,1)一致：用sd1(1,N)（即加密时的s1(1,N)）
                elseif (i>1) && (j == 1)
                    sd2(i,j) = alt(r0,sd2(i-1,1),k); % 与加密s2一致：依赖上一行第1列的值
                else    
                    sd2(i,j) = alt(r2,sd2(i,j-1),k);  % 与加密s2一致：用r2，依赖同一行前一列的值
                end 
            elseif (rnd==3)  % 第3轮：生成sd3（对应加密时的s3）
                if (i==1) && (j==1)
                    sd3(i,j) = alt(r0,sd2(N,1),k); % 与加密s3(1,1)一致：用sd2(N,1)（即加密时的s2(N,1)）
                elseif (i>1) && (j == 1)
                    sd3(i,j) = alt(r0,sd3(i-1,1),k); % 与加密s3一致：依赖上一行第1列的值
                else    
                    sd3(i,j) = alt(r3,sd3(i,j-1),k);   % 与加密s3一致：用r3，依赖同一行前一列的值
                end
            elseif (rnd==4)  % 第4轮：生成sd4（对应加密时的s4）
                if (i==1) && (j==1)
                    sd4(i,j) = alt(r0,sd3(1,N),k); % 与加密s4(1,1)一致：用sd3(1,N)（即加密时的s3(1,N)）
                elseif (i>1) && (j == 1)
                    sd4(i,j) = alt(r0,sd4(i-1,1),k);  % 与加密s4一致：依赖上一行第1列的值
                else      
                    sd4(i,j) = alt(r4,sd4(i,j-1),k);  % 与加密s4一致：用r4，依赖同一行前一列的值
                end
            end
        end
    end
end


EE = rot90(EE,3);  % 将加密图像E逆时针旋转90度（等价于顺时针旋转270度）
for i = 1:N+2  % 遍历行数（与第四轮加密时的矩阵行数一致）
    for j = 1:M+2  % 遍历列数（与第四轮加密时的矩阵列数一致）
        if j > 1  % 处理有效数据列（跳过第一列，对应加密时的非随机列）
            s = floor(mod(sd4(i,j)* 10^10, 256));  % 生成与第四轮加密时完全相同的整数密钥s
                                                  % sd4是解密时生成的对应加密s4的混沌序列，确保密钥与加密时一致
            DD(i,j) = bitxor(bitxor(EE(i,j-1),EE(i,j),'uint8'),s,'uint8');  % 逆向异或操作，还原加密前的数据     
        else
            DD(i,j) = EE(i,j);
        end
    end
end
DD(:,1) = []; % 删除矩阵D的第一列（对应第四轮加密时插入的随机列）
DD(N+3:M+2,:) = [];
% 删除矩阵D中从第N+3行到第M+2行的所有行（裁剪多余行）
% 对应加密过程：多轮加密中因插入随机列和旋转，矩阵尺寸可能膨胀（如逐步增加行数）
% 效果：通过裁剪移除加密过程中额外增加的行，使矩阵尺寸匹配前三轮解密所需的输入维度

EE = rot90(DD,3);
for i = 1:M+1
    for j = 1:N+2
        if j > 1 % 处理有效数据列（跳过第一列，对应加密时的非随机列）
            s = floor(mod(sd3(i,j)* 10^10, 256));
            % 生成与第三轮加密时完全相同的整数密钥s
            % sd3是解密时生成的对应加密s3的混沌序列，确保密钥与加密时一致
            DD(i,j) = bitxor(bitxor(EE(i,j-1),EE(i,j),'uint8'),s,'uint8');
        else
            DD(i,j) = EE(i,j);
        end
    end
end
if M==N
    DD(M+2,:) = [];  % 若为正方形，删除矩阵D的第M+2行（裁剪第三轮加密中可能因尺寸膨胀额外增加的行）
                    % 原因：正方形图像在多轮加密中尺寸变化更规律，需针对性裁剪以匹配原始维度
end
DD(:,1) = [];% 删除矩阵D的第一列（对应第三轮加密时插入的随机列R）
DD(:,N+2:M) = [];% 删除矩阵D中从第N+2列到第M列的所有列（裁剪第三轮加密中因拼接导致的多余列）


EE = rot90(DD,3);  % 将上一步解密得到的矩阵D逆时针旋转90度（等价于顺时针旋转270度）
for i = 1:N+1
    for j = 1:M+1
        if j > 1 % 处理有效数据列（跳过第一列，对应加密时的非随机列）
            s = floor(mod(sd2(i,j)* 10^10, 256));% 生成与第二轮加密时完全相同的整数密钥s
                                                  % sd2是解密时生成的对应加密s2的混沌序列，确保密钥与加密时一致
            DD(i,j) = bitxor(bitxor(EE(i,j-1),EE(i,j),'uint8'),s,'uint8');
        else
            DD(i,j) = EE(i,j);
        end
    end
end
DD(:,1) = [];% 删除矩阵D的第一列（对应第二轮加密时插入的随机列R）
DD(N+2:M+1,:) = [];% 删除矩阵D中从第N+2行到第M+1行的所有行（裁剪第二轮加密中因尺寸膨胀额外增加的行）


EE = rot90(DD,3);% 将上一步解密得到的矩阵D逆时针旋转90度（等价于顺时针旋转270度）
for i = 1:M
    for j = 1:N+1
        if j > 1    % 处理有效数据列（跳过第一列，对应第一轮加密时的非随机列，即原始图像数据列）
            s = floor(mod(sd1(i,j)* 10^10, 256));% 生成与第一轮加密时完全相同的整数密钥s
                                                  % sd1是解密时生成的对应加密s1的混沌序列，确保密钥与加密时完全一致
            DD(i,j) = bitxor(bitxor(EE(i,j-1),EE(i,j),'uint8'),s,'uint8');   % 逆向异或操作，还原原始图像数据 
        end
    end
end

%REMOVING INSERTED RANDOM PIXELS
DD(:,N+2:M) = [];% 删除矩阵D中从第N+2列到第M列的所有列（裁剪第一轮加密中因多轮拼接导致的多余列）
DD(:,1) = [];% 删除矩阵D的第一列（对应第一轮加密时插入的随机列R）
if M==N
    DD(M+1,:) = [];
end

DD = uint8(DD);
subplot(2, 4, 4);
imshow(DD);
% title("Decrypted image");


% function x1 =  alt(r,x0 )
% if x0 < 0.5
%     x1 = mod ((r*x0*(1-x0) + ((4-r)*x0/2)),1);
%  end
%  if x0 >=0.5
%     x1 = mod ((r*x0*(1-x0) + ((4-r)*(1-x0)/2)) ,1);
%  end	
% end

%% 原始灰度图像的水平像素对
x_original = c0(:, 1:end-1);  % 当前像素（所有行，第1列 ~ 倒数第2列）
x_original = x_original(:);             % 展平为列向量（便于散点图绘制）
y_original = c0(:, 2:end);    % 右侧相邻像素（所有行，第2列 ~ 最后1列）
y_original = y_original(:);             % 展平为列向量

%% 加密后灰度图像的水平像素对（假设img_encrypted是加密结果，需替换为真实数据）
% img_encrypted = uint8(randi([0, 255], size(img_original)));  % 用随机矩阵模拟“无相关性”的加密效果
x_encrypted = EE(:, 1:end-1);
x_encrypted = x_encrypted(:);
y_encrypted = EE(:, 2:end);
y_encrypted = y_encrypted(:);
% figure(2);  % 新建图形窗口

%% 子图1：原始灰度图像的水平相关性
subplot(2, 4, 7);
scatter(x_original, y_original, 1, 'b', 'filled');  % 点大小1，蓝色填充
% xlabel('Pixel grey value on coordinate (x,y)');
% ylabel('Pixel grey value on coordinate (x,y+1)');
xlabel('Pixel grey value','FontSize', 6);
ylabel('Pixel grey value','FontSize', 6);
title('Original Gray Image','FontSize', 6);
axis([0 255 0 255]);  % 限制坐标轴为灰度值范围
grid on;  % 可选：显示网格

%% 子图2：加密后图像的水平相关性
subplot(2, 4, 8);
scatter(x_encrypted, y_encrypted, 1, 'b', 'filled');
% xlabel('Pixel grey value on coordinate (x,y)');
% ylabel('Pixel grey value on coordinate (x,y+1)');
xlabel('Pixel grey value','FontSize', 6);
ylabel('Pixel grey value','FontSize', 6);
title('Encrypted Image','FontSize', 6);
axis([0 255 0 255]);
grid on;
%改进后的alt函数
function x1 = alt(r, x0, k)
    % 改进的分段混沌映射函数
    % 输入：
    %   r - 控制参数（建议范围：3.6~4.0，增强混沌特性）
    %   x0 - 当前状态值（范围：[0,1)）
    %   k - 扰动参数（建议范围：0.1~0.3，增加序列随机性）
    % 输出：
    %   x1 - 下一个状态值（范围：[0,1)）

    % 1. 增加分段数量（从2段改为3段），提升状态转移复杂度
    if x0 < 1/3
        % 第一段：Logistic映射 + 正弦扰动（利用正弦的非线性增强随机性）
        base = r * x0 * (1 - x0);
        perturb = k * sin(pi * x0 * 3);  % 与x0相关的扰动项
        x1 = mod(base + perturb, 1);

    elseif x0 < 2/3
        % 第二段：Tent映射变体 + 二次项（引入不同映射类型，增加多样性）
        base = 1 - 2 * abs(x0 - 0.5);  % Tent映射核心公式
        perturb = k * (x0 - 0.5)^2;    % 二次扰动项
        x1 = mod(r/4 * base + perturb, 1);  % 用r缩放增强参数敏感性

    else
        % 第三段：Logistic映射反向 + 指数扰动（进一步差异化）
        base = r * (1 - x0) * x0;  % 与第一段Logistic对称但顺序调整
        perturb = k * exp(-5 * (x0 - 1));  % 随x0变化的指数扰动
        x1 = mod(base + perturb, 1);
    end

    % 2. 增加微小概率的状态跳变（防止序列陷入周期过短的循环）
    % if rand < 0.001  % 1‰的概率触发随机跳变
    %     x1 = rand;  % 直接生成一个随机值，打破潜在周期
    % end
end


function x1 = alt2(r, x0, k)
    % 改进的分段混沌映射函数
    % 输入：
    %   r - 控制参数（建议范围：3.6~4.0，增强混沌特性）
    %   x0 - 当前状态值（范围：[0,1)）
    %   k - 扰动参数（建议范围：0.1~0.3，增加序列随机性）
    % 输出：
    %   x1 - 下一个状态值（范围：[0,1)）

    % 1. 增加分段数量（从2段改为3段），提升状态转移复杂度
    if x0 < 1/3
        % 第一段：Logistic映射 + 正弦扰动（利用正弦的非线性增强随机性）
        base = r * x0 * (1 - x0);
        perturb = k * sin(pi * x0 * 3);  % 与x0相关的扰动项
        x1 = mod(base + perturb, 1);

    elseif x0 < 2/3
        % 第二段：Tent映射变体 + 二次项（引入不同映射类型，增加多样性）
        base = 1 - 2 * abs(x0 - 0.5);  % Tent映射核心公式
        perturb = k * (x0 - 0.5)^2;    % 二次扰动项
        x1 = mod(r/4 * base + perturb, 1);  % 用r缩放增强参数敏感性

    else
        % 第三段：Logistic映射反向 + 指数扰动（进一步差异化）
        base = r * (1 - x0) * x0;  % 与第一段Logistic对称但顺序调整
        perturb = k * exp(-5 * (x0 - 1));  % 随x0变化的指数扰动
        x1 = mod(base + perturb, 1);
    end

    % 2. 增加微小概率的状态跳变（防止序列陷入周期过短的循环）
    if rand < 0.0025  % 1‰的概率触发随机跳变
        x1 = rand;  % 直接生成一个随机值，打破潜在周期
    end
end


%%%%解密过程2

E   = uint8(E);% 将加密后的图像E转换为uint8类型（与加密最后一步保持一致，确保数据类型匹配）
%[M,N] = size(E);
D   = zeros(M+2,N+2);% 初始化解密结果矩阵D（尺寸与加密最后一轮的矩阵一致），用于存储解密中间结果
sd1 = zeros(M,N+1);% 初始化解密用混沌序列sd1（对应加密时的s1）
sd2 = zeros(M,N+1);% 初始化解密用混沌序列sd2（对应加密时的s2）
sd3 = zeros(M,N+1);% 初始化解密用混沌序列sd3（对应加密时的s3）
sd4 = zeros(M,N+1);% 初始化解密用混沌序列sd4（对应加密时的s4）

% user defined values% 注释：用户自定义参数（必须与加密时完全相同，否则无法解密）
s0 = 0.87;
r0 = 1.5;
r1 = 1.3;
r2 = 1.2;
r3 = 1.1;
r4 = 1.3;
k=0.12;

%1-D SUBSTITUTION

for rnd = 1:4  %% 遍历4轮，分别生成sd1-sd4（对应加密时的s1-s4）
    for i = 1:M+2 %% 行数范围与加密最后一轮的矩阵尺寸一致
        for j = 1:M+2  %% 列数范围与加密最后一轮的矩阵尺寸一致
            if (rnd==1) % 第1轮：生成sd1（对应加密时的s1）
                if (i==1) && (j==1)  % 第1行第1列（初始值）
                    sd1(i,j) = alt2(r0,SR(1,1),k);  % 与加密s1(1,1)生成逻辑相同：用s0、r0、k
                elseif (M+1>=i>1) && (j == 1) % 第1列（非首行）
                    sd1(i,j) = alt2(r0,SR(i-1,1),k); % 与加密s1一致：依赖上一行第1列的值
                elseif (j>1) && (i<=M)   
                    sd1(i,j) = alt2(r1,SR(i,j-1),k);  % 与加密s1一致：用r1，依赖同一行前一列的值
                end
            elseif (rnd==2) % 第2轮：生成sd2（对应加密时的s2）
                if (i==1) && (j==1)
                    sd2(i,j) = alt2(r0,sd1(1,N),k);  % 与加密s2(1,1)一致：用sd1(1,N)（即加密时的s1(1,N)）
                elseif (i>1) && (j == 1)
                    sd2(i,j) = alt2(r0,sd2(i-1,1),k); % 与加密s2一致：依赖上一行第1列的值
                else    
                    sd2(i,j) = alt2(r2,sd2(i,j-1),k);  % 与加密s2一致：用r2，依赖同一行前一列的值
                end 
            elseif (rnd==3)  % 第3轮：生成sd3（对应加密时的s3）
                if (i==1) && (j==1)
                    sd3(i,j) = alt2(r0,sd2(N,1),k); % 与加密s3(1,1)一致：用sd2(N,1)（即加密时的s2(N,1)）
                elseif (i>1) && (j == 1)
                    sd3(i,j) = alt2(r0,sd3(i-1,1),k); % 与加密s3一致：依赖上一行第1列的值
                else    
                    sd3(i,j) = alt2(r3,sd3(i,j-1),k);   % 与加密s3一致：用r3，依赖同一行前一列的值
                end
            elseif (rnd==4)  % 第4轮：生成sd4（对应加密时的s4）
                if (i==1) && (j==1)
                    sd4(i,j) = alt2(r0,sd3(1,N),k); % 与加密s4(1,1)一致：用sd3(1,N)（即加密时的s3(1,N)）
                elseif (i>1) && (j == 1)
                    sd4(i,j) = alt2(r0,sd4(i-1,1),k);  % 与加密s4一致：依赖上一行第1列的值
                else      
                    sd4(i,j) = alt2(r4,sd4(i,j-1),k);  % 与加密s4一致：用r4，依赖同一行前一列的值
                end
            end
        end
    end
end


E = rot90(E,3);  % 将加密图像E逆时针旋转90度（等价于顺时针旋转270度）
for i = 1:N+2  % 遍历行数（与第四轮加密时的矩阵行数一致）
    for j = 1:M+2  % 遍历列数（与第四轮加密时的矩阵列数一致）
        if j > 1  % 处理有效数据列（跳过第一列，对应加密时的非随机列）
            s = floor(mod(sd4(i,j)* 10^10, 256));  % 生成与第四轮加密时完全相同的整数密钥s
                                                  % sd4是解密时生成的对应加密s4的混沌序列，确保密钥与加密时一致
            D(i,j) = bitxor(bitxor(E(i,j-1),E(i,j),'uint8'),s,'uint8');  % 逆向异或操作，还原加密前的数据     
        else
            D(i,j) = E(i,j);
        end
    end
end
D(:,1) = []; % 删除矩阵D的第一列（对应第四轮加密时插入的随机列）
D(N+3:M+2,:) = [];
% 删除矩阵D中从第N+3行到第M+2行的所有行（裁剪多余行）
% 对应加密过程：多轮加密中因插入随机列和旋转，矩阵尺寸可能膨胀（如逐步增加行数）
% 效果：通过裁剪移除加密过程中额外增加的行，使矩阵尺寸匹配前三轮解密所需的输入维度

E = rot90(D,3);
for i = 1:M+1
    for j = 1:N+2
        if j > 1 % 处理有效数据列（跳过第一列，对应加密时的非随机列）
            s = floor(mod(sd3(i,j)* 10^10, 256));
            % 生成与第三轮加密时完全相同的整数密钥s
            % sd3是解密时生成的对应加密s3的混沌序列，确保密钥与加密时一致
            D(i,j) = bitxor(bitxor(E(i,j-1),E(i,j),'uint8'),s,'uint8');
        else
            D(i,j) = E(i,j);
        end
    end
end
if M==N
    D(M+2,:) = [];  % 若为正方形，删除矩阵D的第M+2行（裁剪第三轮加密中可能因尺寸膨胀额外增加的行）
                    % 原因：正方形图像在多轮加密中尺寸变化更规律，需针对性裁剪以匹配原始维度
end
D(:,1) = [];% 删除矩阵D的第一列（对应第三轮加密时插入的随机列R）
D(:,N+2:M) = [];% 删除矩阵D中从第N+2列到第M列的所有列（裁剪第三轮加密中因拼接导致的多余列）


E = rot90(D,3);  % 将上一步解密得到的矩阵D逆时针旋转90度（等价于顺时针旋转270度）
for i = 1:N+1
    for j = 1:M+1
        if j > 1 % 处理有效数据列（跳过第一列，对应加密时的非随机列）
            s = floor(mod(sd2(i,j)* 10^10, 256));% 生成与第二轮加密时完全相同的整数密钥s
                                                  % sd2是解密时生成的对应加密s2的混沌序列，确保密钥与加密时一致
            D(i,j) = bitxor(bitxor(E(i,j-1),E(i,j),'uint8'),s,'uint8');
        else
            D(i,j) = E(i,j);
        end
    end
end
D(:,1) = [];% 删除矩阵D的第一列（对应第二轮加密时插入的随机列R）
D(N+2:M+1,:) = [];% 删除矩阵D中从第N+2行到第M+1行的所有行（裁剪第二轮加密中因尺寸膨胀额外增加的行）


E = rot90(D,3);% 将上一步解密得到的矩阵D逆时针旋转90度（等价于顺时针旋转270度）
for i = 1:M
    for j = 1:N+1
        if j > 1    % 处理有效数据列（跳过第一列，对应第一轮加密时的非随机列，即原始图像数据列）
            s = floor(mod(sd1(i,j)* 10^10, 256));% 生成与第一轮加密时完全相同的整数密钥s
                                                  % sd1是解密时生成的对应加密s1的混沌序列，确保密钥与加密时完全一致
            D(i,j) = bitxor(bitxor(E(i,j-1),E(i,j),'uint8'),s,'uint8');   % 逆向异或操作，还原原始图像数据 
        end
    end
end

%REMOVING INSERTED RANDOM PIXELS
D(:,N+2:M) = [];% 删除矩阵D中从第N+2列到第M列的所有列（裁剪第一轮加密中因多轮拼接导致的多余列）
D(:,1) = [];% 删除矩阵D的第一列（对应第一轮加密时插入的随机列R）
if M==N
    D(M+1,:) = [];
end

D = uint8(D);
subplot(2, 4, 3);
imshow(D);
% title("Decrypted image");