![nixos](https://socialify.git.ci/escherlies/nixos/image?custom_description=Enrico%27s+nix+config+files&description=1&font=KoHo&language=1&logo=https%3A%2F%2Fpablo.tools%2Fnixoscolorful.svg&name=1&owner=1&pattern=Plus&theme=Auto)

# Desktop

`Loading...`

## Fixes

### Signal time format not working

https://github.com/signalapp/Signal-Desktop/issues/4252

```
vi ~/.config/Signal/ephemeral.json
```

```diff
- "localeOverride": null
+ "localeOverride": "en-DE"
```



# Servers

## VPS

Using [NixOS-Infect](https://github.com/elitak/nixos-infect) to deploy on Hetzner Cloud.
