#!/bin/bash
get_latest() {
	if [ -z "$1" ]
	then
	 	echo "No args with version"
		exit 1
	fi
	local arh=$(get_arch)
	local version=$1
	if (( $version >= 6 && $version < 100 ))
	then
		res=$(curl -s "https://api.foojay.io/disco/v3.0/packages?package_type=jdk&latest=available&version=$version&javafx_bundled=false&operating_system=linux&architecture=$arh&archive_type=tar.gz&distribution=zulu&lib_c_type=glibc" | jq -r .result[0].java_version)
		[ "$res" = "null" ] && echo "Erorr version $version not found in disco api." && exit 1
		echo $res

	else
		echo "Your version ${version} is not in range."
		exit 1 
	fi
}

# some awk magic
disco2jdk() {
	echo $1
	awk -v v=$1 ' BEGIN {
		a[6] = "1.%d.%d-%02d-b%02d"
		a[7] = "1.%d.%d_%02d-b%02d"
		a[8] = a[7]
		match(v, /([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)/, m)
		f = a[m[1]]
		printf (f ? f : v) "\n", m[1], m[2], m[3], m[4]
	}'
}


get_arch() {
	if [ $(uname -m) = "x86_64" ] 
	then
		echo "x64"
	else 
		echo "arm64"
	fi
}

test_latest() {
	# regex 111.111.111+111
	cmd="java --version 2>&1 | tail -n 1 | grep -oE '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\+[[:digit:]]{1,3}'"
	docker_version=$(docker run --pull=always --platform linux/arm64 --rm azul/zulu-openjdk$2:$1$3 sh -c "$cmd")
	if [ $? -eq 0 ] 
	then
		disco2jdk $(get_latest $1)
		converted_from_api=$(get_latest $1)
		echo """
		Docker version: $docker_version
		API version: $converted_from_api
		"""
		
		if [ $docker_version = $converted_from_api ]
		then
			echo "Versions match - OK"
			exit 0
		else 
			echo "Version missmatch."
			exit 1
		fi

	else
		echo "Erorr"
		exit 1
	fi
}

"$@"
