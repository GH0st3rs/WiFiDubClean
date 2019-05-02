# WiFiDubClean

Cleaning duplicate for Wi-Fi handshakes

## Usage

```bash
$ ./WiFiDubClean.sh [input hccapx] [output hccapx] [filter file or blank]
	filter format: MAC at new line
```

## Example

```bash
$ sudo hcxdumptool -i wlp3s0 -o wifi.pcapng
...
^C
...
$ sudo hcxpcaptool -o wifi.2500 wifi.pcapng
$ ./WiFiDubClean.sh wifi.2500 output.2500
or
$ ./WiFiDubClean.sh wifi.2500 output.2500 /tmp/filter 
```

## Dependencies
* [hcxtools](https://github.com/ZerBea/hcxtools)
