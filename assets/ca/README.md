# Bundled root certificate

`isrg-root-x1.pem` — **ISRG Root X1**, the root that the events API's
certificate chain terminates at:

```
CN=rosemont.com
  └─ CN=YR2, O=Let's Encrypt, C=US
       └─ CN=Root YR, O=ISRG, C=US
            └─ CN=ISRG Root X1, O=Internet Security Research Group, C=US
```

## Why it's here

Dart verifies TLS with its own BoringSSL against the host's trust store.
Windows populates that store lazily via Windows Update, so a freshly imaged
machine can lack this root and every request fails with
`CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate`. Browsers
hide the problem by triggering the on-demand fetch; Dart does not.

Bundling the root makes the app independent of the host's store. It is *added*
to the platform roots, not substituted for them — see
`lib/data/services/http_client_factory_io.dart`.

## Refreshing it

Download only from the issuer, never copy it out of a chat log or web page:

```bash
curl -fSLo assets/ca/isrg-root-x1.pem https://letsencrypt.org/certs/isrgrootx1.pem
```

Verify before committing. Subject and issuer must be identical (it is a
self-signed root), and it must not be expired:

```bash
openssl x509 -in assets/ca/isrg-root-x1.pem -noout -subject -issuer -dates -fingerprint -sha256
```

Expected subject *and* issuer:

```
CN=ISRG Root X1, O=Internet Security Research Group, C=US
```

ISRG Root X1 is valid until 2035, so this needs no routine maintenance. Revisit
only if the API's certificate chain changes CA.
