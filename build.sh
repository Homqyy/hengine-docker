#!/bin/bash -e

######################################################### Global Variable

G_ROOT_DIR=`cd $(dirname $0); pwd`
G_PREFIX=/usr/local/hengine
G_TENGINE_SRC=$G_ROOT_DIR/hengine
G_PREDEF=
G_CC_OPT=
G_LD_OPT=
G_NGX_OPT=
G_OPENSSL=
G_OPENSSL_OPT=

######################################################### Function

function append_predef
{
    G_PREDEF="$G_PREDEF $@"

    echo "predef << $G_PREDEF"
}

function append_cc
{
    G_CC_OPT="$G_CC_OPT $@"

    echo "ngx_cc << $G_CC_OPT"
}

function append_ld
{
    G_LD_OPT="$G_LD_OPT $@"

    echo "ngx_ld << $G_CC_OPT"
}

function append_ngx_opt
{
    G_NGX_OPT+=" $@"

    echo "ngx_opt << $G_NGX_OPT"
}


function build_with_tassl
{
    OPENSSL_LIB="${G_PREFIX}/.openssl"

    ./configure --with-http_ssl_module \
                    --prefix=${G_PREFIX} \
                    --with-cc-opt="-I$OPENSSL_LIB/include" \
                    --with-ld-opt="-Wl,-rpath=$OPENSSL_LIB/lib -L$OPENSSL_LIB/lib"
}

function add_tongsuo
{
    append_ngx_opt  --add-module=modules/ngx_tongsuo_ntls
    append_ngx_opt  --with-http_ssl_module --with-stream
    append_ngx_opt  --with-stream_ssl_module --with-stream_sni

    G_OPENSSL+="$G_ROOT_DIR/Tongsuo"
    G_OPENSSL_OPT+="--strict-warnings enable-ntls"
}

function add_lua
{
    [ ! -d luajit2-2.1-agentzh ] && unzip luajit2-2.1-agentzh.zip \
        && make -C luajit2-2.1-agentzh install

    make -C $G_ROOT_DIR/lua-resty-core install PREFIX=${G_PREFIX}
    make -C $G_ROOT_DIR/lua-resty-lrucache install PREFIX=${G_PREFIX}

    append_predef   LUAJIT_LIB=/usr/local/lib \
                    LUAJIT_INC=/usr/local/include/luajit-2.1

    append_ld       "-Wl,-rpath,/usr/local/lib"

    append_ngx_opt  --add-module=${G_ROOT_DIR}/ngx_devel_kit
    append_ngx_opt  --add-module=${G_ROOT_DIR}/lua-nginx-module
}


######################################################### Main

add_tongsuo
add_lua

cd $G_TENGINE_SRC

for def in $G_PREDEF
do
    export $def
done

pwd

./configure --prefix=$G_PREFIX \
            --with-ld-opt="$G_LD_OPT" $G_NGX_OPT \
            --with-openssl="$G_OPENSSL" \
            --with-openssl-opt="$G_OPENSSL_OPT" \
    && make && make install

cd 
