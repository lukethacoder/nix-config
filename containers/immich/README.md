# Immich Config

Immich requires some extra config on first time setup.

## API Key Config

1. Go through first time config
2. Create an API Key
3. Save API key to the "immich-env" private variables repository
4. Rebuild with API key

## External Libraries

1. Add new External Library
2. Point to `/Photos/*`

> NOTE: make sure this does not point directly at the top level `./Photos` folder, as this is where immich stores non-external library images

External Libraries should follow the folder strcuture:
```bash
# "/2022/12/20 - Karnivool Concert/IMAGE_1234.jpg"
{{y}}/{{MM}}//{{dd}} - {{EVENT_SHOOT_NAME}}/{{filename}}
```

## Storage Template

Configure the storage template to be:

```bash
# "/2022/12-20/IMAGE_1234.jpg"
{{y}}/{{MM}}-{{dd}}/{{filename}}
```

## Features

1. Account Settings -> Features -> People. Check box `Enable` and `Sidebar`
2. Account Settings -> Features -> Star rating. Check box `Enable`