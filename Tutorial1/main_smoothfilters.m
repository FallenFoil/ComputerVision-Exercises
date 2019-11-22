
% params:
% imgFileName - nome do ficheiro de imagem greyscale
function [noisy,smoothed] = main_smoothfilters(I,noiseType,noiseParams,filteringDomain,smoothingType,filterParams)

%%%%% noise
nargs = size(noiseParams,2);
switch noiseType
    case 'salt & pepper' 
         d = 0.05;      % default noise density, 
         if nargs > 0 
           d = noiseParams(1);
         end
         % adds salt and pepper noise, where d is the noise density. This affects approximately d*numel(I) pixels.
         noisy = imnoise(I,'salt & pepper',d);

    case 'gaussian'
         m = 0;                % default mean
         var_gauss = 0.01;     % default variance
         if nargs > 0
           m = noiseParams(1);
         end
         if nargs > 1
           var_gauss = noiseParams(2);
         end
         % adds Gaussian white noise with mean m and variance var_gauss.
         noisy = imnoise(I,'gaussian',m,var_gauss);

    otherwise
        error('Unknown noise type');
end


%%%%% smooth
nargs = size(filterParams,2);
switch filteringDomain
    case 'spatial'
        
        hsize = 10;     % kernel size
        if nargs > 0
            hsize = filterParams(1);
        end
        
        switch smoothingType
            case 'average'
                h = fspecial('average', hsize);
                smoothed = imfilter(noisy,h);

            case 'gaussian'
                sigma = 5;      % standard deviation
                if nargs > 1
                    sigma = filterParams(2);
                end
                h = fspecial('gaussian', hsize, sigma);
                smoothed = imfilter(noisy,h);
                
            case 'median'
                smoothed = medfilt2(noisy, [hsize hsize]);

            otherwise
                error('Unknown smoothing type (spatial filtering domain), options: average, gaussian, median');
        end

    case 'frequency'
        
        I = double(I)/255;
        
        s = size(I);
        % Padding
        P = padarray(I, s, 0,'post');
        
        % Centrar, multiplicar a imagem por (-1)^(x+y)
        C = center(P);
        
        % Calcular DFT
        F = fft2(C);
        
        hsize = 10;     % kernel size
        if nargs > 0
            hsize = filterParams(1);
        end
        
        % Gerar o filtro
        switch smoothingType
            case 'butterworth'
                n = 2;          % order
                d0 = 15;        % variance
                
                if nargs > 1
                    n = filterParams(2);
                end
                
                if nargs > 2
                    d0 = filterParams(3);
                end
                
                H = butterworthFilter(hsize, n, d0);

            case 'gaussian'
                sigma = 5;              % standard deviation
                
                if nargs > 1
                    sigma = filterParams(2);
                end
                
                H = fspecial('gaussian', hsize, sigma);
               
            otherwise
                error('Unknown smoothing type (frequency filtering domain), options: butterworth, gaussian');
        end
        
        % Padding, centrar e DFT do filtro
        H = padarray(H, 2*s - size(H),'post');
        H = center(H);
        H = fft2(H);
        
        % G(u,v) = H(u,v)F(u,v)
        G = H .* F;

        % gp(x,y) = {real{inverse DFT[G(u,v)]}(-1)^(x+y)
        G = real(ifft2(G));
        
        % Descentrar
        G = center(G);
        
        % Resultado final g(x,y) ao extrair a regi�o M X N
        smoothed = G(1:s(1),1:s(2));
       
    otherwise
        error('Unknown filtering domain, options: spatial, frequency');
end

end


function B = center(A)
    [l,c] = size(A);
    B = zeros(l,c);
    for i = 1:l
        for j = 1:c
            B(i,j) = A(i,j).*(-1).^(i + j);
        end
    end
end

function h = butterworthFilter(hsize, n, d0)
    h = zeros(hsize, hsize);
    for u = 1:hsize
        for v = 1:hsize
            b = sqrt(2) - 1;
            d = sqrt(u.^2 + v^2);
            x = b * (d0 / d); 
            h(u, v) = 1./(1 + x)^(2 * n);
        end
    end
end