FROM  alpine
LABEL Author=wxdlong \
      Email=wxdlong@qq.com \
      WHAT="Include k8s basic images"

COPY ok8s.tar.gz /home

ENTRYPOINT ["tar","-xzvf","/home/ok8s.tar.gz","-C","/ok8s"]

