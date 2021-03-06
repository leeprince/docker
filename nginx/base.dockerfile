# 指定基础镜像
FROM centos:8

MAINTAINER leeprince@foxmail.com

# 修改时区,并设置硬件时钟为上海时间. 本人宿主机操作系统为 macOS，时区的文件信息路径为(其他操作系统应该一样)：/usr/share/zoneinfo/Asia/Shanghai
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone

# 设备环境变量
ENV NGINX_VERSION=nginx-1.17.8
# 构建参数
# ARG NGINX_VERSION=nginx-1.17.8

# 创建系统用户组及系统用户
RUN groupadd -r nginx && useradd -r -g nginx nginx

# 备份镜像源; 已经测试没问题这里就直接覆盖了。
# RUN mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup

# 复制文件：COPY <源路径>... <目标路径> ｜ COPY ["<源路径1>",... "<目标路径>"]
# 更新 centos 源为阿里云镜像源;实例中已下载到 dockerfile 的同级目录下.也可以直接下载到指定目录下
COPY ./centos-repo/Centos-8.repo /etc/yum.repos.d/CentOS-Base.repo
# RUN wget -O wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo

# RUN 执行命令行的命令
# 更新 yum 源；清除缓存; 并下载编译安装需要的软件; 再次清理缓存
RUN yum update -y \
    && yum clean all \
    && yum makecache \
    && yum install -y gcc gcc-c++ autoconf automake make zlib zlib-devel net-tools openssl* pcre* wget \
    && yum clean all && rm -rf /var/cache/yum/*

# 下载 nginx 源文件并编译安装, 再清除临时文件
RUN mkdir -p /tmp/nginx && cd /tmp/nginx \
    && wget http://nginx.org/download/$NGINX_VERSION.tar.gz \
    && tar -zxvf $NGINX_VERSION.tar.gz \
    && cd $NGINX_VERSION \
    && ./configure --prefix=/usr/local/nginx --group=nginx --user=nginx \
    && make && make install \
    && rm -rf /tmp/nginx

# 设置工作目录
WORKDIR /usr/local/nginx

# 设置 nginx 命令为全局可使用
RUN ln -s /usr/local/nginx/sbin/* /usr/local/sbin

# 定义匿名卷
# 定义匿名卷时特别需要注意的地方是 nginx 不同版本或者不同安装方式其文件的路径可能不一样的情况。如：nginx.conf、log、html、sbin 这些主要文件
VOLUME ["/usr/local/nginx/conf/conf.d/", "/usr/local/nginx/logs/", "/usr/local/nginx/html/"]

COPY ./conf/nginx.conf /usr/local/nginx/conf/
COPY ./conf/conf.d/default.conf /usr/local/nginx/conf/conf.d/

# 声明运行时容器提供服务端口。
# ！不要在暴露端口的时候映射端口(EXPOSE 8000:80),这是会影响容器的可移植性和扩展性的！
EXPOSE 80 433

# 容器启动命令:CMD ["可执行文件", "参数1", "参数2"...]
# CMD 命令在 {docker run ...} 过程当中是会被其他指令替代, 比如 sh、bash
CMD ["/usr/local/nginx/sbin/nginx",  "-c", "/usr/local/nginx/conf/nginx.conf", "-g", "daemon off;"]

# ENTRYPOINT 入口点: 当指定了 ENTRYPOINT 后， CMD 的含义就发生了改变，不再是直接的运行其命令，而是将 CMD 的内容作为参数传给 ENTRYPOINT 指令
# ENTRYPOINT ["/usr/local/nginx/sbin/nginx",  "-c", "/usr/local/nginx/nginx.conf", "-g", "daemon off;"]