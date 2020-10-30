%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MEAN SHIFT TRACKING
% ----------------------
% YOU HAVE TO MODIFY THIS FILE TO MAKE IT RUN!
% YOU CAN ADD ANY FUNCTION YOU FIND USEFUL!
% In particular, you have to create the different functions:
%	- cd = color_distribution(imagePatch, m)
%	- k = compute_bhattacharyya_coefficient(p,q)
%	- weights = compute_weights(imPatch, qTarget, pCurrent, Nbins)
% 	- z = compute_meanshift_vector(imPatch, prev_center, weights)
%
% the function to extract an image part is given.
% ----------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear all
close all

%% 载入图片
imPath = 'car'; imExt = 'jpg'; %定义文件路径
%检查图片文件路径是否存在
if isdir(imPath) == 0
    error('USER ERROR : The image directory does not exist');
end
%载入路径中的文件
filearray = dir([imPath filesep '*.' imExt]); % 获取目录下所有文件
NumImages = size(filearray,1); %图片数量
if NumImages < 0
    error('No image in the directory');
end
disp('Loading image files from the video sequence, please be patient...');
%获取图片参数
imgname = [imPath filesep filearray(1).name]; %获取图片名
I = imread(imgname);
VIDEO_WIDTH = size(I,2);
VIDEO_HEIGHT = size(I,1);
ImSeq = zeros(VIDEO_HEIGHT, VIDEO_WIDTH, NumImages);%读取目录下全部图片
for i=1:NumImages
    imgname = [imPath filesep filearray(i).name]; %获取图片名
    ImSeq(:,:,i) = imread(imgname); %放入所有图片
end
disp(' ... OK!');


%% 初始化跟踪器
%在第一帧图片中框出感兴趣区域作为跟踪目标
% 使用函数imcrop手动初始化,框出跟踪目标,该函数用于返回图像的一个裁剪区域。可把图像显示在一个图像窗口中， 并允许用户以交互方式使用鼠标选定要剪切的区域。
[patch, rect] = imcrop(ImSeq(:,:,1)./255);%rect输出左上角横纵坐标 宽度 高度
%获取ROI参数（中心点坐标/宽度/高度），ROI（region of interest），感兴趣区域
ROI_Center = round([rect(1)+rect(3)/2 , rect(2)+rect(4)/2]); 
ROI_Width = rect(3);
ROI_Height = rect(4);
rectangle('Position', rect, 'EdgeColor','r');%画矩阵框出初始目标位置

%**********MEANSHIFT跟踪算法**********
%%首先定义目标的颜色模型，计算颜色概率分布
% compute target object color probability distribution given the center and size of the ROI
imPatch = extract_image_patch_center_size(ImSeq(:,:,1), ROI_Center, ROI_Width, ROI_Height);
%该函数截取了感兴趣区域的颜色数据
%RGB颜色空间中的颜色分布
Nbins = 8;
TargetModel = color_distribution(imPatch, Nbins);%以上函数用来计算目标模型的qu概率密度
%
figure('name', 'Mean Shift Algorithm', 'units', 'normalized', 'outerposition', [0 0 1 1]);
prev_center = ROI_Center;
disp(prev_center);

for n = 2:NumImages
    %读取下一帧图片
    I = ImSeq(:,:,n);
    while(1)        
    	% STEP 1
    	% 计算上一帧目标中心位置的PDF，即候选模型
    	imPatch = extract_image_patch_center_size(I, prev_center, ROI_Width, ROI_Height);
    	ColorModel = color_distribution(imPatch, Nbins);
    	% 计算目标模型和候选模型之间的相似程度-bhattacharyya距离
     	rho = compute_bhattacharyya_coefficient(TargetModel, ColorModel);
    
    	% STEP 2, 3
    	% 计算候选模型区域每个像素点的权重
    	weights = compute_weights_NG(imPatch, TargetModel, ColorModel, Nbins);
    	% 计算mean-shift vector得到新的候选中心位置
        z = compute_meanshift_vector(imPatch, prev_center, weights);
    	new_center = round(z);
        
        % STEP 4, 5计算新的候选模型和相似度
        imPatch2 = extract_image_patch_center_size(I, new_center, ROI_Width, ROI_Height);
    	ColorModel2 = color_distribution(imPatch2, Nbins);
    	% 相似度
     	rho2 = compute_bhattacharyya_coefficient(TargetModel, ColorModel2);
        while(rho2<rho)%当移动后的候选位置相似度小于移动前的时候 进行以下迭代搜索 
            new_center = (prev_center+new_center)/2;            
            imPatch2 = extract_image_patch_center_size(I, new_center, ROI_Width, ROI_Height);
            ColorModel2 = color_distribution(imPatch2, Nbins);
            rho2 = compute_bhattacharyya_coefficient(TargetModel, ColorModel2);% 相似度
        end
        % STEP 6
        if norm(new_center-prev_center, 1) < 0.0001
            break
        end
        prev_center = new_center;
    end
    
    disp(new_center);
    subplot(1,1,1); imshow(I, []);
    hold on;
	plot(new_center(1), new_center(2) , '+', 'Color', 'r', 'MarkerSize',10);
    drawnow;
	
end