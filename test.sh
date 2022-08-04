#!/bin/sh

get_latest() {
	local major=$1
	curl -s "https://api.foojay.io/disco/v3.0/packages?package_type=jdk&latest=available&version=$major&javafx_bundled=false&operating_system=linux&architecture=x64&archive_type=tar.gz&distribution=zulu&lib_c_type=glibc" | jq -r .result[0].java_version
}

disco2jdk() {
	awk -v v=$1 ' BEGIN {
		a[6] = "1.%d.%d-%02d-b%02d"
		a[7] = "1.%d.%d_%02d-b%02d"
		a[8] = a[7]
		match(v, /([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)/, m)
		f = a[m[1]]
		printf (f ? f : v) "\n", m[1], m[2], m[3], m[4]
	}'
}

test_latest() {
	docker run --rm azul/zulu-openjdk$2:$1$3 java -version 2>&1 | awk -v v=$(disco2jdk $(get_latest $1)) '
		BEGIN {
			printf "%-12s: %s\n", "DiscoAPI", v
			s = 0
		}
		/OpenJDK Runtime Environment/ {
			docker_version = $0
		}
		END {
			printf "%-12s: %s\n", "Docker Hub", docker_version
			s = docker_version ~ ("build " v)
			print s ? "OK" : "FAIL"
		       	exit !s
		}
		'
}

"$@"
