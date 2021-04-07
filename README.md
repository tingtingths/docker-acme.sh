# docker wrapped acme.sh

A Docker image to issue, renew, and deploy Let's Encrypt certificate with DNS-01 challenge.


## Example
Cloudflare DNS and Synology DSM deployment.
```sh
docker run -td \
    -e CERT_DOMAIN="<domain>" \
    -e CERT_DNS="dns_cf" \
    -e CF_Key="<cloudflare_key>" \
    -e CF_Email="cloudflare_email" \
    -e LE_ACC_EMAIL="<lets_encrypt_email" \
    -e DEPLOY_HOOK="synology_dsm" \
    -e SYNO_Username="<dsm_username>" \
    -e SYNO_Password="<dsm_password>" \
    -e SYNO_Scheme="https" \
    -e SYNO_Hostname="<dsm_host>" \
    -e SYNO_Port="443" \
    -e SYNO_DID="<dsm_2fa_device_id>" \
    -v <acme_home>:/home/acme/acme.sh \
    acme.sh
```

## Limitations
Only [dnsapi](https://github.com/acmesh-official/acme.sh/wiki/dnsapi) mode and [deployhooks](https://github.com/acmesh-official/acme.sh/wiki/deployhooks) are supported.


Check [acme.sh](http://acme.sh/) for more info.
