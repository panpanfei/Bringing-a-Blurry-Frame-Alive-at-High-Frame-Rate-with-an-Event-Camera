function x=fibosearch(fhandle,a,b,npoints)
% fibonacci search for minimum of unknown unimodal function in one variable
%     x = fibosearch(fhandle,a,b,npoints)
% a,b define the search interval with resolution 1/npoints
%create fibonacci sequence of length nfibo
nfibo=22;
fibo=[1,1,zeros(1,nfibo-2)];
for k=1:nfibo-2
    fibo(k+2)=fibo(k+1)+fibo(k);
end
%find number of required iterations
fiboindex=3;
while fibo(fiboindex)<npoints
        fiboindex=fiboindex+1;
end
for k=1:fiboindex-2
    if k==1
        x1 = a+fibo(fiboindex-k-1)/fibo(fiboindex-k+1)*(b-a);
        x2 = b-fibo(fiboindex-k-1)/fibo(fiboindex-k+1)*(b-a);
        fx1 = fhandle(x1);
        fx2 = fhandle(x2);
    end
    if fx1<fx2
        b=x2;
        x2=x1; fx2=fx1;
        x1=a+fibo(fiboindex-k-1)/fibo(fiboindex-k+1)*(b-a);
        fx1=fhandle(x1);
    else
        a=x1;
        x1=x2; fx1=fx2;
        x2=b-fibo(fiboindex-k-1)/fibo(fiboindex-k+1)*(b-a);
        fx2=fhandle(x2);
    end
end
if fx1<fx2
    x=x1;
else
    x=x2;
end
% disp(fiboindex-2)