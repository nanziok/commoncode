#!/bin/bash

# create_JWK.sh P-256
# create_JWK.sh P-384
# create_JWK.sh P-521

# 生成包含完整参数的 JWK
CURVE=${1:-"P-256"}
KEY_ID="ec-key-$(date +%s)"

case $CURVE in
    "P-256") openssl_curve="prime256v1"; alg="ES256" ;;
    "P-384") openssl_curve="secp384r1"; alg="ES384" ;;
    "P-521") openssl_curve="secp521r1"; alg="ES512" ;;
    *) openssl_curve="prime256v1"; alg="ES256" ;;
esac

# 生成PEM格式的密钥对
openssl ecparam -name $openssl_curve -genkey -noout -out ec-private.pem
openssl ec -in ec-private.pem -pubout -out ec-public.pem

echo "PEM格式密钥已生成: ec-private.pem, ec-public.pem"

# 提取私钥（移除前缀00如果存在）
PRIVATE_HEX=$(openssl ec -in ec-private.pem -text -noout | awk '/priv:/{getline; while(/^[[:space:]]/){gsub(/[:[:space:]]/,""); printf "%s", $0; getline}}' | sed 's/^00//')

# 提取公钥并分解为x,y坐标
PUBLIC_INFO=$(openssl ec -in ec-private.pem -text -noout -pubout | awk '/pub:/{getline; while(/^[[:space:]]/){gsub(/[:[:space:]]/,""); printf "%s", $0; getline}}')

# 移除04前缀（未压缩格式标识）
PUBLIC_HEX=$(echo "$PUBLIC_INFO" | sed 's/^04//')

# 对于不同曲线，公钥长度不同
case $CURVE in
    "P-256")
        key_length=64
        ;;
    "P-384")
        key_length=96
        ;;
    "P-521")
        key_length=132
        ;;
esac

# 提取X和Y坐标（根据曲线长度动态计算）
X_HEX=$(echo $PUBLIC_HEX | cut -c1-$key_length)
Y_HEX=$(echo $PUBLIC_HEX | cut -c$((key_length+1))-$((key_length*2)))

# 验证提取的密钥长度
if [ -z "$PRIVATE_HEX" ] || [ -z "$PUBLIC_HEX" ]; then
    echo "错误: 无法提取密钥信息"
    exit 1
fi

to_b64url() {
    echo -n "$1" | xxd -r -p | base64 -w 0 | tr '+/' '-_' | tr -d '=';
}

# 生成完整的 JWK
cat > ec-complete.jwk << EOF
{
  "kty": "EC",
  "crv": "$CURVE",
  "alg": "$alg",
  "x": "$(to_b64url $X_HEX)",
  "y": "$(to_b64url $Y_HEX)",
  "d": "$(to_b64url $PRIVATE_HEX)",
  "use": "sig",
  "kid": "$KEY_ID"
}
EOF

# 清理临时文件
# rm -f key_info.txt

echo "完整的 JWK 已生成: ec-complete.jwk"
echo "PEM格式密钥: ec-private.pem, ec-public.pem"
