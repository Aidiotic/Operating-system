#!/usr/bin/env bash
# NexusOS APT repository — pool layout helpers

pkg_pool_path() {
  local name="$1" ver="$2" arch="$3"
  local letter="${name:0:1}"
  echo "pool/main/${letter}/${name}/${name}_${ver}_${arch}.deb"
}

create_repo_layout() {
  local root="$1"
  mkdir -p "${root}/pool/main"
  mkdir -p "${root}/dists/stable/main/binary-amd64"
  mkdir -p "${root}/dists/stable/main/binary-arm64"
}
