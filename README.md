# Hengine Docker

For Chinese, please refer to [README-zh.md](https://github.com/Homqyy/hengine-docker/blob/main/README-zh.md)

## Version Notes

**3.2 (latest)**:

* Reference: hengine-docker: [https://github.com/Homqyy/hengine-docker](https://github.com/Homqyy/hengine-docker)
* Features: None
* Bug list：
    * stream template is invalid

**3.1**:

* Features:
    * Supports controlling whether to enable the basic HTTP service using the `NGX_HTTP_WEB <on|off>` environment variable, the default value is `on`.
* Bug list:
    * `entrypoint.sh` syntax error
    * Missing modules `ngx_http_sub_module` and `ngx_http_proxy_connect_module` 

**3.0**:

* Bug list:
    * An error occurs when `NGX_HTTP_SNI` is set to `off` (fixed in `latest`)

**2.0 (deprecated)**:

* Enable options: `--with-stream_sni`
* Supports protocol conversion: any conversion between `tcp`, `udp`, and `udp+kcp`
* Supports KCP proxy
* Bug fixes:
    * The value of `realm` is incorrect when using PROXY CONNECT

**1.0 (deprecated)**:

* Supports using Basic authentication for PROXY CONNECT

## Introduction

[homqyy/hengine](https://hub.docker.com/r/homqyy/hengine) is a web full-family image that combines Nginx, Guomi, and Lua into one, which is convenient to meet various business needs; it also supports environment variable configuration, which can be used to quickly deploy web services; and supports configuration templates to increase extensibility and facilitate people who know Nginx to configure their own services.

It supports the following features:

- [x] China Encryption Standards (Guomi)
- [x] Lua
- [x] Environment Variables
- [x] Configuration Templates

## Development

1. Download the source code: `git clone https://github.com/Homqyy/hengine-docker`
2. Download submodules: `git submodule update --init --recursive`

## Usage

Web servers are a common requirement, so this image supports a basic web server by default. This can be controlled using environment variables. Advanced users may want to define their own web server, so the image also supports controlling whether the basic web server is enabled using the `NGX_HTTP_WEB` environment variable.

* `NGX_HTTP_WEB <on|off>`: Whether to enable the basic web server. The default value is `on`. If set to `off`, the basic web server will not be enabled. In this case, the HTTP and HTTPS related environment variables mentioned below will not take effect.

### Deploying an HTTP Server

To deploy a web server on port `80`, you just need to add the following content in your `docker-compose.yml`:

```yml
version: '3.8'

services:
  web:
    image: homqyy/hengine
    ports:
      - '80:80/tcp'
    environment:
      NGX_HTTP_LISTEN: '80'
```

`NGX_HTTP_LISTEN` is used to define the port the server listens on, and `ports` specifies the mapping between the host and container. Here, the host's `80` port is mapped to our listened `80` port. If you wish to use a different port on the host, just modify the mapping value, for example:

```yml
ports:
    - '8080:80/tcp'
```

### Deploying an HTTPS Server

```yml
version: '3.8'

services:
  web:
    image: homqyy/hengine
    ports:
      - '443:443/tcp'
    environment:
      NGX_HTTP_LISTEN: '443 ssl'
      NGX_HTTP_SSL_CERT: certs/https.dev.example.com/rsa/chain.pem
      NGX_HTTP_SSL_KEY: certs/https.dev.example.com/rsa/privkey.pem
    volumes:
      - '${G_BASE_DIR}/certs:/usr/local/hengine/conf/certs:ro'
```

The above `NGX_HTTP_LISTEN` specifies listening on port `443` and indicates the ssl protocol. It also sets the certificate and key:

- `NGX_HTTP_SSL_CERT`: Specifies the path to the certificate, supporting non-China encryption standards. The path refers to the path inside the container, so the certificate should be bound-mounted into the container. It supports absolute and relative paths; if a relative path is used, it is relative to `/usr/local/hengine/conf`. Therefore, to achieve the above configuration, `chain.pem` should be mounted to `/usr/local/hengine/conf/certs/https.dev.example.com/rsa/chain.pem`.
- `NGX_HTTP_SSL_KEY`: Specifies the path to the key, supporting non-China encryption standards. The path interpretation is the same as `NGX_HTTP_SSL_CERT`.

In the example, `${G_BASE_DIR}` represents the base path in your host, so you should replace it with the actual value in your host when actually using it. A better practice is to define the value of `${G_BASE_DIR}` through a `.env` file, which makes it more convenient to port `docker-compose.yml` in the future.

The above is just the basic parameters for deploying an HTTPS server. In actual use, we might involve some advanced requirements, such as:

- Enabling SNI verification: Add the environment variable `NGX_HTTP_SNI: <on|off>` to enable this feature, which should be used in conjunction with `NGX_HTTP_SERVER_NAME`

- Setting virtual service name: Add the environment variable `NGX_HTTP_SERVER_NAME <domain_name>` to set the virtual service name, usually set to a domain name, mainly used for "virtual service" and "SNI", for example:

    ```yml
    NGX_HTTP_SNI: on
    NGX_HTTP_SERVER_NAME: https.dev.example.com
    ```

    - The above enables SNI and configures the virtual service name. If the client SNI does not carry `https.dev.example.com`, the connection will be refused.

- Client Authentication: Supports the following environment variables
    - `NGX_HTTP_SSL_VERIFY_CLIENT <on | off | optional | optional_no_ca>`:
        - `on`: Enables authentication; the client must send a client certificate and pass verification;
        - `off`: Disables authentication, default is `off`;
        - `optional`: The client can choose to send or not send a certificate, but if sent, it must pass verification;
        - `optional_no_ca`: The client can choose to send or not send

, and if sent, it does not need to pass verification.

    - `NGX_HTTP_SSL_VERIFY_DEPTH: <number>`: Sets the maximum valid depth for verifying the certificate chain, for example, a depth of 3:

        ```yml
        NGX_HTTP_SSL_VERIFY_DEPTH: 3
        ```

    - `NGX_HTTP_SSL_CA <path>`: Sets the CA certificate, path interpretation is consistent with `NGX_HTTP_SSL_CERT`. For example:
    
        ```yml
        NGX_HTTP_SSL_CA: certs/ca/ca-all.pem.crt
        ```

- Setting Encryption Suites: Add the environment variable `NGX_HTTP_SSL_CIPHERS: <openssl_ciphers_string>`, whose syntax is `OPENSSL` syntax, details can be referred to: [openssl-1.1.1_ciphers](https://www.openssl.org/docs/man1.1.1/man1/ciphers.html), for example:

    ```yml
    NGX_HTTP_SSL_CIPHERS: ALL
    ```

### Deploying a China Encryption Standard Server

A China Encryption Standard server also belongs to HTTPS, the difference is whether it supports China encryption suites, the difference is in the following environment variables:

```yml
NGX_HTTP_NTLS: on
NGX_HTTP_SSL_SIGN_CERT: certs/gm.dev.homqyy.cn/gm/chain.pem
NGX_HTTP_SSL_SIGN_KEY: certs/gm.dev.homqyy.cn/gm/privkey.pem
NGX_HTTP_SSL_ENC_CERT: certs/gm.dev.homqyy.cn/gm/enc-chain.pem
NGX_HTTP_SSL_ENC_KEY: certs/gm.dev.homqyy.cn/gm/enc-privkey.pem
```

- `NGX_HTTP_NTLS <on | off>`: Whether to enable China encryption standards, `on` for enabled, `off` for disabled, default is `off`;

- `NGX_HTTP_SSL_SIGN_CERT`: Sets the signature certificate, path interpretation is consistent with `NGX_HTTP_SSL_CERT`;

- `NGX_HTTP_SSL_SIGN_KEY`: Sets the signature key, path interpretation is consistent with `NGX_HTTP_SSL_CERT`;

- `NGX_HTTP_SSL_ENC_CERT`: Sets the encryption certificate, path interpretation is consistent with `NGX_HTTP_SSL_CERT`;

- `NGX_HTTP_SSL_ENC_KEY`: Sets the encryption key, path interpretation is consistent with `NGX_HTTP_SSL_CERT`;

The configuration is roughly as follows:

```yml
version: '3.8'

services:
  web:
    image: homqyy/hengine
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
      NGX_HTTP_SSL_CIPHERS: ECC-SM2-SM4-CBC-SM3:ECDHE-SM2-SM4-CBC-SM3
      NGX_HTTP_SSL_VERIFY_CLIENT: on
      NGX_HTTP_SSL_VERIFY_DEPTH: 3
      NGX_HTTP_SSL_CA: certs/ca/ca-all.pem.crt
    volumes:
      - '${G_BASE_DIR}/web/certs/:${G_NGX_CONF}/certs/:ro'
```

Of course, the above only enables China encryption, but in fact, China encryption and standard encryption can be used together, just set `NGX_HTTP_SSL_CERT` and `NGX_HTTP_SSL_KEY` as well.

### Debugging/Logs

Set log level: `NGX_LOG_LEVEL <emerg | alert | crit | error | warn | notice | info | debug>`, default is `error`, can be adjusted according to needs

View logs: Directly view the docker output

If there are issues causing the hengine container to not run properly, you can debug as follows:

1. Change `entrypoint` to `/sbin/init`

    ```yml
    version: '3.8'

    services:
      web:
        image: homqyy/hengine
        entrypoint: /sbin/init
        ...
    ```

2. Run the container

3. Attach (`docker exec`) to the container

4. Manually run `entrypoint.sh`, then adjust your configuration based on the error information

### Full Configuration Overview

```yml
version: '3.8'

services:
  web:
    image: homqyy/hengine
    ports:
      - '443:443/tcp'
    environment:
      NGX_LOG_LEVEL: info
      NGX_HTTP_WEB: on
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

## Template Configuration

Template configuration is a feature of this image. It facilitates people familiar with `Nginx` to configure their own services while natively supporting environment variables prefixed with `NGX_`. Let's explain the above two points.

### HTTP Template Configuration

In this image, the configuration specified under the `http` block `{}` is placed in the `/usr/local/hengine/conf/http.conf.d/` directory. Any configuration file placed in this directory and ending with `.conf` will be parsed as a configuration under `http {}`. Therefore, we do the following:

1. Create your own `server` configuration file on the host, located at `/home/admin/my_server.conf`

    ```nginx
    server {
        listen 8080;

        location / {
            root html;
            index index.html index.htm;
        }
    }
    ```

2. Mount it to the container:

    ```yml
    services:
      web:
        image: homqyy/hengine
        ...
        volumes:
          - '/home/admin/my_server.conf:/usr/local/hengine/conf/http.conf.d/my_server.conf:ro'
    ```

3. Run the container: Your configuration will be parsed.

4. Access the `8080` port using a client.

But how is this considered a template? This is where environment variables come into play. You can use environment variables in the configuration file and treat it as a template. Then, control the outcome through environment variables, just like deploying an HTTP server earlier, for example:

1. Create your own `server` template configuration file on the host, located at `/home/admin/my_server.conf.temp`: It **must end with `.temp`** as only then it will be treated as a template configuration file.

    ```nginx
    server {
        listen ${NGX_MY_LISTEN};

        location / {
            root html;
            index index.html index.htm;
        }
    }
    ```

2. Mount it to the container:

    ```yml
    services:
      web:
        image: homqyy/hengine
        ...
        environment:
          NGX_MY_LISTEN: 9090
        volumes:
          - '/home/admin/my_server.conf.temp:/usr/local/hengine/conf/http.conf.d/my_server.conf.temp:ro'
    ```

3. Run the container: Your configuration will be parsed.

4. Access the `9090` port using a client.

### Stream Tempalte Configuration

Stream template configuration is the same, the difference is that its path is `/usr/local/hengine/conf/stream.conf.d/`

## Supported Cipher Suites List

The list of supported cipher suites is as follows (from the command `tongsuo ciphers -v ALL | cut -d ' ' -f1`):

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
