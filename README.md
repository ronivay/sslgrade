# sslgrade


This simple bash script will initiate [SSL Labs](https://www.ssllabs.com/ssltest/) test through API.

Test will print following results:

- Grade
- Warnings boolean (true/false)
- Possible issues in certificate chain 
- Supported protocols

Test will ignore certificate mismatch and fetch results anyway. T/M grade will indicate this happened.

SSL Labs API info: https://github.com/ssllabs/ssllabs-scan/blob/stable/ssllabs-api-docs.md 

Tests ran through API are not published in SSL Labs website by default.


### Usage

``` ./sslgrade.sh domain.tld ```


### Requirements


``` 
curl
jq 
```


### Notes

This isn't official SSL Labs tool.
Official CLI tool can be found: https://github.com/ssllabs/ssllabs-scan/

Take care that you follow terms of use: https://www.ssllabs.com/downloads/Qualys_SSL_Labs_Terms_of_Use.pdf
