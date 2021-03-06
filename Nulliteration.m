%Reading an image
  [X Y] = uigetfile('*.gif');
  Input = strcat(Y,X);
image=imread(Input);
  image=rgb2gray(image);
[a b]=size(image);

%Adding a noise
imagen = imnoise(image,'poisson'); 
imaget=double(imagen);

%Variable Stabilising Transformation

for i=0:a-1
    for j=0:b-1
        imaget(i+1,j+1)=2*sqrt(imaget(i+1,j+1)+(3/8));
    end
end

N = a;          
%Compute all thresholds

n = size(imaget,1);
F = ones(n);
X = fftshift(ifft2(F)) * sqrt(prod(size(F)));
tic, C = fdct_wrapping(X,0,1); toc;

% Compute norm of curvelets 

E = cell(size(C));
for s=1:length(C)
  E{s} = cell(size(C{s}));
  for w=1:length(C{s})
    A = C{s}{w};
    E{s}{w} = sqrt(sum(sum(A.*conj(A))) / prod(size(A)));
  end
end


C = fdct_wrapping(imaget,1);

% Null hypothesis
    
disp('Hypothesis');
   T= 10*log10(2*erfcinv(2*1e-3)^2);
   P=10^(T/10);%Decibel to power conversion
    Z =sqrt(P);%Formula 
    for i = 1:length(C)
       for j = 1:length(C{i})
        Z_changed = Z*E{i}{j};
                   realvalues = real(C{i}{j});     
                   imagvalues = imag(C{i}{j});
                   realvalues = realvalues .* (abs(realvalues) > Z_changed);
                   imagvalues = imagvalues .* (abs(imagvalues) > Z_changed);
                   C{i}{j} = realvalues + sqrt(-1)*imagvalues;   %sqrt(-1)=i;
      
       
       
       
       
       end
    end


tic,
temprestoredimg = real(ifdct_wrapping(C,1));toc;

 u=double(temprestoredimg);
 u0=u;

%----------------------------------------------- 
%       iteration 
%-----------------------------------------------

% coefficient of the TV norm (needs to be adapted for each image) 
lambda=1.5; 

%  space discretization 
h=1.;

%  number of iterations (depends on the image) 
IterMax=2;

%  needed to regularize TV at the origin 
eps=.0000001;


%-----------------------------------------------------------
%     BEGIN ITERATIONS IN ITER 
%-----------------------------------------------------------

for Iter=1:IterMax, 

	Iter

    for i=2:a-1,
      for j=2:b-1,

    %-----------computation of coefficients co1,co2,co3,co4---------

	ux=(u(i+1,j)-u(i,j))/h;
	uy=(u(i,j+1)-u(i,j))/h;
        Gradu=sqrt(eps*eps+ux*ux+uy*uy);% Gradient
        co1=1./Gradu;

    ux=(u(i,j)-u(i-1,j))/h;
	uy=(u(i-1,j+1)-u(i-1,j))/h;
        Gradu=sqrt(eps*eps+ux*ux+uy*uy);
        co2=1./Gradu;

    ux=(u(i+1,j)-u(i,j))/h;
	uy=(u(i,j+1)-u(i,j))/h;
        Gradu=sqrt(eps*eps+ux*ux+uy*uy);
        co3=1./Gradu;

	ux=(u(i+1,j-1)-u(i,j-1))/h;
    uy=(u(i,j)-u(i,j-1))/h;
        Gradu=sqrt(eps*eps+ux*ux+uy*uy);
        co4=1./Gradu;

        co=1.+(1/(2*lambda*h*h))*(co1+co2+co3+co4);

	div=co1*u(i+1,j)+co2*u(i-1,j)+co3*u(i,j+1)+co4*u(i,j-1); %Divergence

	u(i,j)=(1./co)*(u0(i,j)+(1/(2*lambda*h*h))*div);%Formula for each pixel

      end
    end
end

 %  Inverse Variable Stabilisation
restoredimage=double(u);

for i=0:a-1
    for j=0:b-1
        restoredimage(i+1,j+1)=(( restoredimage(i+1,j+1)/2).^2) - (3/8);
    end
end
subplot(1,3,1); imagesc(image); colormap gray; axis off;axis image;title('Original image');
subplot(1,3,2); imagesc(imagen); colormap gray; axis off;axis image;title('Noisy image');
subplot(1,3,3); imagesc(restoredimage); colormap gray; axis off;axis image;title('Restored image');
ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
text(0.5,0.9,'Curvelet Transform - Null hypothesis with an iterative reconstruction','HorizontalAlignment','center','VerticalAlignment', 'top')



%Making the scales equal

image=double(image);
u=double(u);
%Compute the PSNR of the original image with respect to noisy image

rms=0;
imagen=double(imagen);
for i=1:a-1
    for j=1:b-1
 rms=rms+((imagen(i,j)-image(i,j))*(imagen(i,j)-image(i,j))/(256*256));
    end
end

psnr_noisy=(10*log10((255*255)/rms));
psnr_noisy


%Compute the PSNR of the original image with respect to filtered image

rms=0;
for i=1:a-1
    for j=1:b-1
 rms=rms+((image(i,j)-restoredimage(i,j))*(image(i,j)-restoredimage(i,j))/(256*256));
    end
end

psnr_restored=(10*log10((255*255)/rms));
psnr_restored


%Quality Index measument

xy=0;
xvar=0;
xbar=0;
ybar=0;
yvar=0;
% xbar=mean2(image);
% ybar=mean2(restoredimage);
% xstd=std2(image);
% xvar=xstd*xstd;
% ystd=std2(restoredimage);
% yvar=ystd*ystd;
%xy=corr2(image,restoredimage);
 
for i=1:a-1
     for j=1:b-1
         xbar=xbar+(image(i,j)/(256*256));%Finding mean of an original image
          ybar=ybar+(restoredimage(i,j)/(256*256));%Finding mean of restored image
     end
end

for i=1:a-1
     for j=1:b-1
         xvar=xvar+((image(i,j)-xbar).^2)/(256*256);%Variance of the original image
         yvar=yvar+((restoredimage(i,j)-ybar).^2)/(256*256);%Variance of the restored image
       xy=xy+((image(i,j)-xbar)*(restoredimage(i,j)-ybar))/(256*256);% Correlation co-eff b/w original & restored image
     end
end

  Q=(4*xy*xbar*ybar)/((xvar+yvar)*((xbar.^2)+(ybar.^2)));         %Formula for UQI
  Q
 
