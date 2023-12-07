# Hengine Docker

## 版本说明

**3.1（latest）**：

- 参考：[hengine-docker](https://github.com/Homqyy/hengine-docker)
- 特性：
    - 支持用`NGX_HTTP_WEB <on|off>`控制是否激活基础的HTTP服务，默认值为`on`；
- Bug 列表：
    - `entrypoint.sh`语法错误
    - 缺少模块`ngx_http_sub_module`和`ngx_http_proxy_connect_module`

**3.0**：

- Bug 列表：
    - `NGX_HTTP_SNI` 设置 `off` 会报错（`latest`已解决）

**2.0（弃用）**：

- 启用选项：`--with-stream_sni`
- 支持协议转换：`tcp`、`udp`和`udp+kcp`三者间的任意转换
- 支持 KCP 代理

- 解决Bug：
    - PROXY CONNECT的时候，`realm`的值是错误的

**1.0（弃用）**：

- 支持 PROXY CONNECT 使用 Basic 认证

## 介绍

[homqyy/hengine](https://hub.docker.com/r/homqyy/hengine)是一个web全家桶镜像，将Nginx、国密、Lua合为一体，方便满足各种业务需求；同时支持环境变量配置，可用于快速部署Web服务；并且支持配置模板，增加扩展性，方便懂Nginx的人去配置自己的服务。

它支持以下特性：

- [x] 国密
- [x] Lua
- [x] 环境变量
- [x] 配置模板

## 使用

Web服务器是常见的需求，因此此镜像默认支持了Web服务器，只需要通过环境变量去控制即可。当然对于高级用户，可能想要定义自己的Web服务器，因此也支持通过`NGX_HTTP_WEB`环境变量去控制是否激活基础的Web服务器：

- `NGX_HTTP_WEB <on|off>`：是否激活基础的Web服务器，默认值为`on`；如果设置为`off`，则不会激活基础的Web服务器，这时候下文中提到的HTTP和HTTPS相关的环境变量都不会生效。

### 部署 HTTP服务器

假设要部署 `80` 的web服务器，那么只需要在你的`docker-compose.yml`中写入以下内容：

```yml
version: '3.8'

services:
  web:
    image: homqyy/hengine:3.0
    ports:
      - '80:80/tcp'
    environment:
      NGX_HTTP_LISTEN: '80'
```

`NGX_HTTP_LISTEN`用来定义服务器监听的端口，`ports`则指定主机与容器的映射关系，这里将主机的`80`端口映射到了我们监听的`80`端口上，如果你希望主机用别的端口，只需要修改映射值即可，比如：

```yml
ports:
    - '8080:80/tcp'
```

### 部署  HTTPS服务器

```yml
version: '3.8'

services:
  web:
    image: homqyy/hengine:3.0
    ports:
      - '443:443/tcp'
    environment:
      NGX_HTTP_LISTEN: '443 ssl'
      NGX_HTTP_SSL_CERT: certs/https.dev.example.com/rsa/chain.pem
      NGX_HTTP_SSL_KEY: certs/https.dev.example.com/rsa/privkey.pem
    volumes:
      - '${G_BASE_DIR}/certs:/usr/local/hengine/conf/certs:ro'
```

上述用`NGX_HTTP_LISTEN`指定监听的端口为`443`，同时表明了监听的端口协议为`ssl`。并且设置了证书和密钥：

- `NGX_HTTP_SSL_CERT`：指定证书的路径，支持非国密证书。这里的路径指的是在容器中的路径，因此证书应当通过`bind`挂载到容器中。支持绝对路径和相对路径，如果使用相对路径的话，那么它是相对于`/usr/local/hengine/conf`的，因此要实现上述的配置效果，则需要挂`chain.pem`到`/usr/local/hengine/conf/certs/https.dev.example.com/rsa/chain.pem`。
- `NGX_HTTP_SSL_KEY`：指定密钥的路径，支持非国密证书。这里的路径与`NGX_HTTP_SSL_CERT`一样。

示例中用`${G_BASE_DIR}`表示你在主机中的基本路径，因此实际使用的时候你应当替换它的值为你主机中的实际值。更好的实践是通过`.env`去定义`${G_BASE_DIR}`的值，这样对于未来移植`docker-compose.yml`会更方便。

上面只是部署一个HTTPS服务器的最基本参数，我们实际使用中还会涉及到一些高级需求，比如：

- 启用SNI验证：添加环境变量`NGX_HTTP_SNI: <on|off>`去启用该功能，该功能应该跟`NGX_HTTP_SERVER_NAME`配合使用

- 设置虚拟服务名称：添加环境变量`NGX_HTTP_SERVER_NAME <domain_name>`去设置虚拟服务名称，通常是设置成域名，主要用途是 “虚拟服务”和“SNI”，比如：

    ```yml
    NGX_HTTP_SNI: on
    NGX_HTTP_SERVER_NAME: https.dev.example.com
    ```

    - 上述打开了SNI并且配置了虚拟服务名称，如果客户端SNI没有携带 `https.dev.example.com` 的话会连接会被拒接。

- 认证客户端：支持以下环境变量
    - `NGX_HTTP_SSL_VERIFY_CLIENT <on | off | optional | optional_no_ca>`：
        - `on`：打开认证功能；客户端必须发送客户端证书，并且验证通过；
        - `off`：关闭认证功能，默认是`off`；
        - `optional`：客户端可发送也可不发送证书，但是如果发送的话就必须验证通过；
        - `optional_no_ca`：客户端可发送也可不发送，如果发送了也可以不验证通过。

    - `NGX_HTTP_SSL_VERIFY_DEPTH: <number>`：设置核实证书链的最大有效深度，比如深度为3的话：
    
        ```yml
        NGX_HTTP_SSL_VERIFY_DEPTH: 3
        ```

    - `NGX_HTTP_SSL_CA <path>`：设置CA证书，路径解释与`NGX_HTTP_SSL_CERT`一致。比如：
    
        ```yml
        NGX_HTTP_SSL_CA: certs/ca/ca-all.pem.crt
        ```

- 设置加密套件：添加环境变量`NGX_HTTP_SSL_CIPHERS: <openssl_ciphers_string>`，该套件的语法为`OPENSSL`的语法，详情可参考：[openssl-1.1.1_ciphers](https://www.openssl.org/docs/man1.1.1/man1/ciphers.html)，比如：

    ```yml
    NGX_HTTP_SSL_CIPHERS: ALL
    ```

### 部署 国密服务器

国密服务器也属于HTTPS，区别在于是否支持国密套件，差别就是以下环境变量：

```yml
NGX_HTTP_NTLS: on
NGX_HTTP_SSL_SIGN_CERT: certs/gm.dev.homqyy.cn/gm/chain.pem
NGX_HTTP_SSL_SIGN_KEY: certs/gm.dev.homqyy.cn/gm/privkey.pem
NGX_HTTP_SSL_ENC_CERT: certs/gm.dev.homqyy.cn/gm/enc-chain.pem
NGX_HTTP_SSL_ENC_KEY: certs/gm.dev.homqyy.cn/gm/enc-privkey.pem
```

- `NGX_HTTP_NTLS <on | off>`：是否启用国密功能，`on`为启用，`off`为禁用，默认是`off`；

- `NGX_HTTP_SSL_SIGN_CERT`: 设置签名证书，路径的解释与`NGX_HTTP_SSL_CERT`一致；

- `NGX_HTTP_SSL_SIGN_KEY`: 设置签名密钥，路径的解释与`NGX_HTTP_SSL_CERT`一致；

- `NGX_HTTP_SSL_ENC_CERT`: 设置加密证书，路径的解释与`NGX_HTTP_SSL_CERT`一致；

- `NGX_HTTP_SSL_ENC_KEY`: 设置加密密钥，路径的解释与`NGX_HTTP_SSL_CERT`一致；

配置大致如下所示：

```yml
version: '3.8'

services:
  web:
    image: homqyy/hengine:3.0
    ports:
      - '443:443/tcp'
    environment:
      NGX_LOG_LEVEL: info
      NGX_HTTP_LISTEN: '443 ssl'
      NGX_HTTP_SNI: on
      NGX_HTTP_SERVER_NAME: gm.dev.example.com
      NGX_HTTP_NTLS: on
      NGX_HTTP_SSL_SIGN_CERT: certs/gm.dev.homqyy.cn/gm/chain.pem
      NGX_HTTP_SSL_SIGN_KEY: certs/gm.dev.homqyy.cn/gm/privkey.pem
      NGX_HTTP_SSL_ENC_CERT: certs/gm.dev.homqyy.cn/gm/enc-chain.pem
      NGX_HTTP_SSL_ENC_KEY: certs/gm.dev.homqyy.cn/gm/enc-privkey.pem
      NGX_HTTP_SSL_CIPHERS: ECC-SM2-SM4-CBC-SM3:ECDHE-SM2-SM4-CBC-SM3;
      NGX_HTTP_SSL_VERIFY_CLIENT: on
      NGX_HTTP_SSL_VERIFY_DEPTH: 3
      NGX_HTTP_SSL_CA: certs/ca/ca-all.pem.crt
    volumes:
      - '${G_BASE_DIR}/web/certs/:${G_NGX_CONF}/certs/:ro'
```

当然，上述只开启了国密，其实国密跟标准的密码是可以共同使用的，只需要把`NGX_HTTP_SSL_CERT`和`NGX_HTTP_SSL_KEY`也设置上即可。

### 调试/日志

设置日志级别：`NGX_LOG_LEVEL <emerg | alert | crit | error | warn | notice | info | debug>`，默认是 `error`，可以根据需要自己调整级别

查看日志：直接查看docker的输出即可

如果出现了因为位置导致 hengine 容器运行不起来，可以通过以下方法进行调试：

1. 将`entrypoint`改为`/sbin/init`

    ```yml
    version: '3.8'

    services:
      web:
        image: homqyy/hengine:3.0
        entrypoint: /sbin/init
        ...
    ```

2. 运行容器

3. Attach（`docker exec`）到容器中

4. 手动运行 `entrypoint.sh`，然后根据报错信息去调整自己的配置

### 全配置概览

```yml
version: '3.8'

services:
  web:
    image: homqyy/hengine:3.0
    ports:
      - '443:443/tcp'
    environment:
      NGX_LOG_LEVEL: info
      NGX_HTTP_LISTEN: '443 ssl'
      NGX_HTTP_SNI: on
      NGX_HTTP_SERVER_NAME: gm.dev.example.com
      NGX_HTTP_NTLS: on
      NGX_HTTP_SSL_SIGN_CERT: certs/gm.dev.homqyy.cn/gm/chain.pem
      NGX_HTTP_SSL_SIGN_KEY: certs/gm.dev.homqyy.cn/gm/privkey.pem
      NGX_HTTP_SSL_ENC_CERT: certs/gm.dev.homqyy.cn/gm/enc-chain.pem
      NGX_HTTP_SSL_ENC_KEY: certs/gm.dev.homqyy.cn/gm/enc-privkey.pem
      NGX_HTTP_SSL_CERT: certs/gm.dev.homqyy.cn/rsa/chain.pem
      NGX_HTTP_SSL_KEY: certs/gm.dev.homqyy.cn/rsa/privkey.pem
      NGX_HTTP_SSL_CIPHERS: ECC-SM2-SM4-CBC-SM3:AES256-SHA
      NGX_HTTP_SSL_VERIFY_CLIENT: off
      NGX_HTTP_SSL_VERIFY_DEPTH: 3
      NGX_HTTP_SSL_CA: certs/ca/ca-all.pem.crt
    volumes:
      - '${G_BASE_DIR}/web/certs/:${G_NGX_CONF}/certs/:ro'
```

## 模板配置

模板配置是该镜像的一个特色，它可以方便懂`Nginx`的人去配置自己的服务，同时还原生支持了以`NGX_`为前缀环境变量，接下来我们对上述两点进行解释。

### HTTP模板配置

在该镜像中，指定`http`块`{}`下的配置被放置在`/usr/local/hengine/conf/http.conf.d/`目录中，只要是放置在该目录中并且以`.conf`结尾的配置文件都会被当成`http {}`下的配置去解析，因此我们如下做：

1. 在主机上创建自己的`server`配置文件，路径为`/home/admin/my_server.conf`

    ```nginx
    server {
        listen 8080;

        location / {
            root html;
            index index.html index.htm;
        }
    }
    ```

2. 挂载到容器中：

    ```yml
    services:
      web:
        image: homqyy/hengine:3.0
        ...
        volumes:
          - '/home/admin/my_server.conf:/usr/local/hengine/conf/http.conf.d/my_server.conf:ro'
    ```

3. 运行容器：会发现自己的配置将被解析

4. 用客户端访问 `8080` 端口

但是这怎么能称为模板呢？那就要跟环境变量结合了，也就是大家可以在配置文件中去使用环境变量，并把它作为模板，然后像前面部署HTTP服务器一样通过环境变量控制结果，比如：

1. 在主机上创建自己的`server`模板配置文件，路径为`/home/admin/my_server.conf.temp`：这里 **必须 `.temp` 结尾**，因为只有这样才会被当成模板配置文件。

    ```nginx
    server {
        listen ${NGX_MY_LISTEN};

        location / {
            root html;
            index index.html index.htm;
        }
    }
    ```

2. 挂载到容器中：

    ```yml
    services:
      web:
        image: homqyy/hengine:3.0
        ...
        environment:
          NGX_MY_LISTEN: 9090
        volumes:
          - '/home/admin/my_server.conf.temp:/usr/local/hengine/conf/http.conf.d/my_server.conf.temp:ro'
    ```

3. 运行容器：会发现自己的配置将被解析

4. 用客户端访问 `9090` 端口

### Stream模板配置

Stream配置模板同理，区别在于它的路径为`/usr/local/hengine/conf/stream.conf.d/`

## 加密套件列表

支持的加密套件列表如下（来自命令`tongsuo ciphers -v ALL | cut -d ' ' -f1`）：

```
TLS_AES_256_GCM_SHA384
TLS_CHACHA20_POLY1305_SHA256
TLS_AES_128_GCM_SHA256
TLS_SM4_GCM_SM3
TLS_SM4_CCM_SM3
ECDHE-ECDSA-AES256-GCM-SHA384
ECDHE-RSA-AES256-GCM-SHA384
DHE-DSS-AES256-GCM-SHA384
DHE-RSA-AES256-GCM-SHA384
ECDHE-ECDSA-CHACHA20-POLY1305
ECDHE-RSA-CHACHA20-POLY1305
DHE-RSA-CHACHA20-POLY1305
ECDHE-ECDSA-AES256-CCM8
ECDHE-ECDSA-AES256-CCM
DHE-RSA-AES256-CCM8
DHE-RSA-AES256-CCM
ADH-AES256-GCM-SHA384
ECDHE-ECDSA-AES128-GCM-SHA256
ECDHE-RSA-AES128-GCM-SHA256
DHE-DSS-AES128-GCM-SHA256
DHE-RSA-AES128-GCM-SHA256
ECDHE-ECDSA-AES128-CCM8
ECDHE-ECDSA-AES128-CCM
DHE-RSA-AES128-CCM8
DHE-RSA-AES128-CCM
ADH-AES128-GCM-SHA256
ECDHE-ECDSA-AES256-SHA384
ECDHE-RSA-AES256-SHA384
DHE-RSA-AES256-SHA256
DHE-DSS-AES256-SHA256
ADH-AES256-SHA256
ECDHE-ECDSA-AES128-SHA256
ECDHE-RSA-AES128-SHA256
DHE-RSA-AES128-SHA256
DHE-DSS-AES128-SHA256
ADH-AES128-SHA256
ECDHE-ECDSA-AES256-SHA
ECDHE-RSA-AES256-SHA
DHE-RSA-AES256-SHA
DHE-DSS-AES256-SHA
AECDH-AES256-SHA
ADH-AES256-SHA
ECDHE-ECDSA-AES128-SHA
ECDHE-RSA-AES128-SHA
DHE-RSA-AES128-SHA
DHE-DSS-AES128-SHA
AECDH-AES128-SHA
ADH-AES128-SHA
RSA-PSK-AES256-GCM-SHA384
DHE-PSK-AES256-GCM-SHA384
RSA-PSK-CHACHA20-POLY1305
DHE-PSK-CHACHA20-POLY1305
ECDHE-PSK-CHACHA20-POLY1305
DHE-PSK-AES256-CCM8
DHE-PSK-AES256-CCM
AES256-GCM-SHA384
AES256-CCM8
AES256-CCM
PSK-AES256-GCM-SHA384
PSK-CHACHA20-POLY1305
PSK-AES256-CCM8
PSK-AES256-CCM
RSA-PSK-AES128-GCM-SHA256
DHE-PSK-AES128-GCM-SHA256
DHE-PSK-AES128-CCM8
DHE-PSK-AES128-CCM
AES128-GCM-SHA256
AES128-CCM8
AES128-CCM
PSK-AES128-GCM-SHA256
PSK-AES128-CCM8
PSK-AES128-CCM
ECC-SM2-SM4-GCM-SM3
ECDHE-SM2-SM4-GCM-SM3
RSA-SM4-GCM-SHA256
RSA-SM4-GCM-SM3
AES256-SHA256
AES128-SHA256
ECDHE-PSK-AES256-CBC-SHA384
ECDHE-PSK-AES256-CBC-SHA
SRP-DSS-AES-256-CBC-SHA
SRP-RSA-AES-256-CBC-SHA
SRP-AES-256-CBC-SHA
RSA-PSK-AES256-CBC-SHA384
DHE-PSK-AES256-CBC-SHA384
RSA-PSK-AES256-CBC-SHA
DHE-PSK-AES256-CBC-SHA
AES256-SHA
PSK-AES256-CBC-SHA384
PSK-AES256-CBC-SHA
ECDHE-PSK-AES128-CBC-SHA256
ECDHE-PSK-AES128-CBC-SHA
SRP-DSS-AES-128-CBC-SHA
SRP-RSA-AES-128-CBC-SHA
SRP-AES-128-CBC-SHA
RSA-PSK-AES128-CBC-SHA256
DHE-PSK-AES128-CBC-SHA256
RSA-PSK-AES128-CBC-SHA
DHE-PSK-AES128-CBC-SHA
ECC-SM2-SM4-CBC-SM3
ECDHE-SM2-SM4-CBC-SM3
AES128-SHA
RSA-SM4-CBC-SHA256
RSA-SM4-CBC-SM3
PSK-AES128-CBC-SHA256
PSK-AES128-CBC-SHA
```