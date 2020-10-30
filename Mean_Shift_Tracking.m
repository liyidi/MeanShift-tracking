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

%% ����ͼƬ
imPath = 'car'; imExt = 'jpg'; %�����ļ�·��
%���ͼƬ�ļ�·���Ƿ����
if isdir(imPath) == 0
    error('USER ERROR : The image directory does not exist');
end
%����·���е��ļ�
filearray = dir([imPath filesep '*.' imExt]); % ��ȡĿ¼�������ļ�
NumImages = size(filearray,1); %ͼƬ����
if NumImages < 0
    error('No image in the directory');
end
disp('Loading image files from the video sequence, please be patient...');
%��ȡͼƬ����
imgname = [imPath filesep filearray(1).name]; %��ȡͼƬ��
I = imread(imgname);
VIDEO_WIDTH = size(I,2);
VIDEO_HEIGHT = size(I,1);
ImSeq = zeros(VIDEO_HEIGHT, VIDEO_WIDTH, NumImages);%��ȡĿ¼��ȫ��ͼƬ
for i=1:NumImages
    imgname = [imPath filesep filearray(i).name]; %��ȡͼƬ��
    ImSeq(:,:,i) = imread(imgname); %��������ͼƬ
end
disp(' ... OK!');


%% ��ʼ��������
%�ڵ�һ֡ͼƬ�п������Ȥ������Ϊ����Ŀ��
% ʹ�ú���imcrop�ֶ���ʼ��,�������Ŀ��,�ú������ڷ���ͼ���һ���ü����򡣿ɰ�ͼ����ʾ��һ��ͼ�񴰿��У� �������û��Խ�����ʽʹ�����ѡ��Ҫ���е�����
[patch, rect] = imcrop(ImSeq(:,:,1)./255);%rect������ϽǺ������� ��� �߶�
%��ȡROI���������ĵ�����/���/�߶ȣ���ROI��region of interest��������Ȥ����
ROI_Center = round([rect(1)+rect(3)/2 , rect(2)+rect(4)/2]); 
ROI_Width = rect(3);
ROI_Height = rect(4);
rectangle('Position', rect, 'EdgeColor','r');%����������ʼĿ��λ��

%**********MEANSHIFT�����㷨**********
%%���ȶ���Ŀ�����ɫģ�ͣ�������ɫ���ʷֲ�
% compute target object color probability distribution given the center and size of the ROI
imPatch = extract_image_patch_center_size(ImSeq(:,:,1), ROI_Center, ROI_Width, ROI_Height);
%�ú�����ȡ�˸���Ȥ�������ɫ����
%RGB��ɫ�ռ��е���ɫ�ֲ�
Nbins = 8;
TargetModel = color_distribution(imPatch, Nbins);%���Ϻ�����������Ŀ��ģ�͵�qu�����ܶ�
%
figure('name', 'Mean Shift Algorithm', 'units', 'normalized', 'outerposition', [0 0 1 1]);
prev_center = ROI_Center;
disp(prev_center);

for n = 2:NumImages
    %��ȡ��һ֡ͼƬ
    I = ImSeq(:,:,n);
    while(1)        
    	% STEP 1
    	% ������һ֡Ŀ������λ�õ�PDF������ѡģ��
    	imPatch = extract_image_patch_center_size(I, prev_center, ROI_Width, ROI_Height);
    	ColorModel = color_distribution(imPatch, Nbins);
    	% ����Ŀ��ģ�ͺͺ�ѡģ��֮������Ƴ̶�-bhattacharyya����
     	rho = compute_bhattacharyya_coefficient(TargetModel, ColorModel);
    
    	% STEP 2, 3
    	% �����ѡģ������ÿ�����ص��Ȩ��
    	weights = compute_weights_NG(imPatch, TargetModel, ColorModel, Nbins);
    	% ����mean-shift vector�õ��µĺ�ѡ����λ��
        z = compute_meanshift_vector(imPatch, prev_center, weights);
    	new_center = round(z);
        
        % STEP 4, 5�����µĺ�ѡģ�ͺ����ƶ�
        imPatch2 = extract_image_patch_center_size(I, new_center, ROI_Width, ROI_Height);
    	ColorModel2 = color_distribution(imPatch2, Nbins);
    	% ���ƶ�
     	rho2 = compute_bhattacharyya_coefficient(TargetModel, ColorModel2);
        while(rho2<rho)%���ƶ���ĺ�ѡλ�����ƶ�С���ƶ�ǰ��ʱ�� �������µ������� 
            new_center = (prev_center+new_center)/2;            
            imPatch2 = extract_image_patch_center_size(I, new_center, ROI_Width, ROI_Height);
            ColorModel2 = color_distribution(imPatch2, Nbins);
            rho2 = compute_bhattacharyya_coefficient(TargetModel, ColorModel2);% ���ƶ�
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