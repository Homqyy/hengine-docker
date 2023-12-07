#!/bin/bash -e

g_prefix=/usr/local/hengine
g_hengine=$g_prefix/sbin/nginx
g_conf=$g_prefix/conf
g_http_conf=$g_conf/http.conf.d
g_stream_conf=$g_conf/http.conf.d

export NGX_LOG_LEVEL=${NGX_LOG_LEVEL:-error}
export NGX_HTTP_LISTEN=${NGX_HTTP_LISTEN:-80}
export NGX_HTTP_SERVER_NAME=${NGX_HTTP_SERVER_NAME:-localhost}
export NGX_HTTP_WEB=${NGX_HTTP_WEB:-on}


################################## Function

function exit_hengine
{
    echo "exit hengine"

    $g_hengine -s stop

    exit 0
}

function subspec
{
    suffix=$1

    # 初始化一个空数组
    files=()
    
    # 为每个目录添加匹配的文件到数组
    for dir in "$g_conf" "$g_http_conf" "$g_stream_conf"; do
        # 检查目录下是否有 .temp 文件
        if compgen -G "${dir}/*.$suffix" > /dev/null; then
            # 将匹配的文件添加到数组
            files+=("${dir}"/*.$suffix)
        fi
    done

    # 遍历 temp_files 数组
    for f in "${files[@]}"; do
       # 确保 $temp 真实存在（避免无匹配的情况）
       [ -e "$f" ] || continue

       # 移除 .temp 后缀得到 conf 文件名
       conf=${f%.$suffix}

       # 使用 envsubst 处理模板
       envsubst "${ngx_vars}" < "$f" > "$conf"
    done
}

# 替换模板文件中的环境变量
function subenv
{
    # pass all variables with prefix of 'NGX_'
    ngx_vars=""
    for var in $(printenv | grep '^NGX_' | cut -d '=' -f1); do
        ngx_vars="${ngx_vars}\${${var}}"
    done

    subspec 'temp'
}

function active_internal
{
    name=$1
    flag=$2

    if [ "$flag" == 'on' ]; then
        cp $g_conf/internal/$name.conf.temp $g_http_conf
    elif [ "$flag" == 'off' ]; then
        # do nothing
        echo "do nothing" > /dev/null
    elif [ -n "$flag" ]; then
        echo "$name have a invalid value: $flag"
        return 1
    fi

    return 0
}

function init_ssl
{
    # set default value
    NGX_HTTP_SSL_CIPHERS=${NGX_HTTP_SSL_CIPHERS:-ECC-SM2-SM4-CBC-SM3:ECC-SM2-SM4-GCM-SM3:ECDHE-SM2-SM4-CBC-SM3:ECDHE-SM2-SM4-GCM-SM3:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA:AES128-GCM-SHA256:AES128-SHA256:AES128-SHA:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:AES256-GCM-SHA384:AES256-SHA256:AES256-SHA:ECDHE-RSA-AES128-SHA256:!aNULL:!eNULL:!RC4:!EXPORT:!DES:!3DES:!MD5:!DSS:!PKS}
    NGX_HTTP_SSL_CERT=${NGX_HTTP_SSL_CERT:-}
    NGX_HTTP_SSL_KEY=${NGX_HTTP_SSL_KEY:-}

    NGX_HTTP_NTLS=${NGX_HTTP_NTLS:-off}
    NGX_HTTP_SSL_SIGN_CERT=${NGX_HTTP_SSL_SIGN_CERT:-}
    NGX_HTTP_SSL_SIGN_KEY=${NGX_HTTP_SSL_SIGN_KEY:-}
    NGX_HTTP_SSL_ENC_CERT=${NGX_HTTP_SSL_ENC_CERT:-}
    NGX_HTTP_SSL_ENC_KEY=${NGX_HTTP_SSL_ENC_KEY:-}

    NGX_HTTP_SSL_VERIFY_CLIENT=${NGX_HTTP_SSL_VERIFY_CLIENT:-}
    NGX_HTTP_SSL_VERIFY_DEPTH=${NGX_HTTP_SSL_VERIFY_DEPTH:-}
    NGX_HTTP_SSL_CA=${NGX_HTTP_SSL_CA:-}

    NGX_HTTP_SNI=${NGX_HTTP_SNI:-}

    # trim value
    [ -n "$NGX_HTTP_SSL_CIPHERS" ] \
        && NGX_HTTP_SSL_CIPHERS="ssl_ciphers         $NGX_HTTP_SSL_CIPHERS;"
    [ -n "$NGX_HTTP_SSL_CERT" ] \
        &&    NGX_HTTP_SSL_CERT="ssl_certificate     $NGX_HTTP_SSL_CERT;"
    [ -n "$NGX_HTTP_SSL_KEY" ]  \
        &&     NGX_HTTP_SSL_KEY="ssl_certificate_key $NGX_HTTP_SSL_KEY;"

    [ -n "$NGX_HTTP_SSL_SIGN_CERT" ]  \
        &&     NGX_HTTP_SSL_SIGN_CERT="ssl_sign_certificate $NGX_HTTP_SSL_SIGN_CERT;"
    [ -n "$NGX_HTTP_SSL_SIGN_KEY" ]  \
        &&     NGX_HTTP_SSL_SIGN_KEY="ssl_sign_certificate_key $NGX_HTTP_SSL_SIGN_KEY;"
    [ -n "$NGX_HTTP_SSL_ENC_CERT" ]  \
        &&     NGX_HTTP_SSL_ENC_CERT="ssl_enc_certificate $NGX_HTTP_SSL_ENC_CERT;"
    [ -n "$NGX_HTTP_SSL_ENC_KEY" ]  \
        &&     NGX_HTTP_SSL_ENC_KEY="ssl_enc_certificate_key $NGX_HTTP_SSL_ENC_KEY;"

    [ -n "$NGX_HTTP_SSL_VERIFY_CLIENT" ] \
        && NGX_HTTP_SSL_VERIFY_CLIENT="ssl_verify_client $NGX_HTTP_SSL_VERIFY_CLIENT;"
    [ -n "$NGX_HTTP_SSL_VERIFY_DEPTH" ] \
        && NGX_HTTP_SSL_VERIFY_DEPTH="ssl_verify_depth $NGX_HTTP_SSL_VERIFY_DEPTH;"
    [ -n "$NGX_HTTP_SSL_CA" ] \
        && NGX_HTTP_SSL_CA="ssl_client_certificate $NGX_HTTP_SSL_CA;"

    active_internal "http_web" "$NGX_HTTP_WEB"
    active_internal "http_sni" "$NGX_HTTP_SNI"

    # export NGX_*
    export NGX_HTTP_SSL_CIPHERS
    export NGX_HTTP_SSL_CERT
    export NGX_HTTP_SSL_KEY

    export NGX_HTTP_NTLS
    export NGX_HTTP_SSL_SIGN_CERT
    export NGX_HTTP_SSL_SIGN_KEY
    export NGX_HTTP_SSL_ENC_CERT
    export NGX_HTTP_SSL_ENC_KEY

    export NGX_HTTP_SSL_VERIFY_CLIENT
    export NGX_HTTP_SSL_VERIFY_DEPTH
    export NGX_HTTP_SSL_CA

    export NGX_HTTP_WEB
    export NGX_HTTP_SNI
}

################################## Main

# 捕获docker退出的信号，用函数 exit_hengine 优雅退出
trap exit_hengine SIGTERM SIGINT

mkdir -p $g_http_conf $g_stream_conf

init_ssl

subenv

/usr/local/hengine/sbin/nginx -g 'daemon off;' &

ngx_pid=$!

if ps -p $ngx_pid > /dev/null
then
    touch /usr/local/hengine/logs/error.log
    tail -f /usr/local/hengine/logs/error.log &
    
    touch /usr/local/hengine/logs/access.log
    tail -f /usr/local/hengine/logs/access.log &
    
    if [ ${NGX_HTTP_WEB} == 'on' ]; then
        echo "running on ${NGX_HTTP_LISTEN} as $ngx_pid"
    else
        echo "running as $ngx_pid"
    fi
    
    wait $ngx_pid
else
    echo "fail to start"
    exit 1;
fi

