FROM  alpine
LABEL Author=wxdlong \
      Email=wxdlong@qq.com \
      WHAT="Include k8s basic images"

COPY k8s.tar.gz /home
ENTRYPOINT ["cp","-rf","/home/k8s.tar.gz","/data"]

