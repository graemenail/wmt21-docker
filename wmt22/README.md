# WMT22

Use one of:
  - https://github.com/larsks/dockerize: upstream
  - https://github.com/graemenail/dockerize: attempts to restore symlinks

It's likely this can be slimmer further by hand.


## Testing

### CPU
```shell
(docker run -i --rm tag-cpu /run.sh --quiet) < input.txt 
```

### GPU
```shell
(docker run -i --rm --gpus all tag-gpu /run.sh --quiet) < input.txt 
```
