FROM  alpine
LABEL Author=wxdlong \
      Email=wxdlong@qq.com
      
COPY k8s.tar.gz /home
ENTRYPOINT ["cp","-rf","/home/k8s.tar.gz","/data"]

