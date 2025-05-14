# Desktop

`Loading...`

## Fixes

### Signal time format not working

https://github.com/signalapp/Signal-Desktop/issues/4252

```
vi .config/Signal/ephemeral.json
```

```diff
- "localeOverride": null
+ "localeOverride": "en-DE"
```



# Servers

## VPS

Using [NixOS-Infect](https://github.com/elitak/nixos-infect) to deploy on Hetzner Cloud.
