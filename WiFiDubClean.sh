#!/bin/bash

INPUT_FILE=$1
INPUT_BASENAME=$(basename ${INPUT_FILE})
OUTPUT_FILE=$2
FILTER_FILE=$3

if [[ -e ${OUTPUT_FILE} ]]; then
	unlink ${OUTPUT_FILE}
fi

function delete_ext() {
	echo $1|sed 's|\(.*\)\.hccapx|\1|'
}

function in_array() {
	local value=$(basename $1)
	for item in $(cat ${FILTER_FILE}|awk '{print $1}'); do
		lower_item=$(echo $item|tr -d ':'|tr '[:upper:]' '[:lower:]')
		echo "Test ${value} and ${lower_item}"
		if [[ "${value}" == "${lower_item}" ]]; then return 1; fi
	done
	return 0;
}

# Clean bad handshake
echo '[*] Clear handshake'
DUBLICETES_DIR=$(mktemp -d)
wlanhcx2ssid -p ${DUBLICETES_DIR} -i ${INPUT_FILE} -D ${DUBLICETES_DIR}/${INPUT_BASENAME}.cleaned
echo "[+] Done! Cleaned file: ${DUBLICETES_DIR}/${INPUT_BASENAME}.cleaned"

# Split by ESSID
ESSID_DIR=$(mktemp -d)
wlanhcx2ssid -p ${ESSID_DIR} -i ${DUBLICETES_DIR}/${INPUT_BASENAME}.cleaned -e
echo "[+] Success split by ESSID to ${ESSID_DIR}"

# Cicle for delete AP|STA dublicates
RESULT_DIR=$(mktemp -d)
for x in $(ls ${ESSID_DIR}); do
	name=$(delete_ext $x)
	mkdir -p ${ESSID_DIR}/${name}
	echo "[*] Temp dir: ${ESSID_DIR}/${name}"
	wlanhcx2ssid -p ${ESSID_DIR}/${name} -i ${ESSID_DIR}/$x -a
	wlanhcx2ssid -p ${ESSID_DIR}/${name} -i ${ESSID_DIR}/$x -s
	ACTUAL_HCCAPX=$(ls ${ESSID_DIR}/${name}|awk 'NR==1')
	rm -rf $(ls ${ESSID_DIR}/${name}|grep -v ${ACTUAL_HCCAPX})
	cp ${ESSID_DIR}/${name}/${ACTUAL_HCCAPX} ${RESULT_DIR}/${name}.hccapx
	echo "[+] Saved to ${RESULT_DIR}/${name}.hccapx"
done

# Concatenate all files
wlanhc2hcx -o ${OUTPUT_FILE} ${RESULT_DIR}/*.hccapx

if [[ -e ${FILTER_FILE} ]]; then
	FILTER_DIR=$(mktemp -d)
	echo "Create filter dir: ${FILTER_DIR}"
	wlanhcx2ssid -p ${FILTER_DIR} -i ${OUTPUT_FILE} -a
	rm ${OUTPUT_FILE}
	for item_x in $(ls ${FILTER_DIR}); do
		name=$(delete_ext ${FILTER_DIR}/${item_x})
		in_array $name
		if [[ $? -eq 1 ]]; then rm ${FILTER_DIR}/${item_x}; fi
	done
	# Concatenate all files with filter
	wlanhc2hcx -o ${OUTPUT_FILE} ${FILTER_DIR}/*.hccapx > /dev/null
fi

echo "[+] Done! Result file: ${OUTPUT_FILE}"