#!/usr/bin/env bash

# install a cmdstan release into a specified directory
#  - build binaries, compile example model to build model header
#  - symlink downloaded version as "cmdstan"

while getopts ":d:v:j:" opt; do
  case $opt in
    d) RELDIR="$OPTARG"
    ;;
    v) VER="$OPTARG"
    ;;
    j) JOBS="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [ -z ${JOBS} ]; then
    JOBS="2"
fi

if [ -z ${RELDIR} ]; then
    RELDIR="$HOME/.cmdstanr"
fi

if [[ ! -e ${RELDIR} ]]; then
   mkdir ${RELDIR}
fi
# if [[ ! -d ${RELDIR} ]]; then
#     echo "cannot install cmdstan, ${RELDIR} is not a directory"
#     exit 1
# fi
echo "cmdstan dir: ${RELDIR}"

if [ -z ${VER} ]; then
    TAG=`curl -s https://api.github.com/repos/stan-dev/cmdstan/releases/latest | grep "tag_name"`
    echo $TAG > tmp-tag
    VER=`perl -p -e 's/"tag_name": "v//g; s/",//g' tmp-tag`
    rm tmp-tag
fi
CS=cmdstan-${VER}
echo "cmdstan version: ${VER}"

pushd ${RELDIR} > /dev/null
if [[ -d $cs && -f ${CS}/bin/stanc && -f ${CS}/examples/bernoulli/bernoulli ]]; then
    echo "cmdstan already installed"
    exit 0
fi
echo "installing ${CS}"

echo "downloading ${CS}.tar.gz from github"
curl -s -OL https://github.com/stan-dev/cmdstan/releases/download/v${VER}/${CS}.tar.gz
CURL_RC=$?
if [[ ${CURL_RC} -ne 0 ]]; then
    echo "github download failed, curl exited with: ${CURL_RC}"
    exit ${CURL_RC}
fi
echo "download complete"

echo "unpacking archive"
tar xzf ${CS}.tar.gz
TAR_RC=$?
if [[ ${TAR_RC} -ne 0 ]]; then
    echo "corrupt download file ${CS}.tar.gz, tar exited with: ${TAR_RC}"
    exit ${TAR_RC}
fi

if [[ -h cmdstan ]]; then
    unlink cmdstan
fi
ln -s ${CS} cmdstan
pushd cmdstan > /dev/null
echo "building cmdstan binaries"
make -j${JOBS} build examples/bernoulli/bernoulli
# make build -j${JOBS}
echo "installed ${CS}; symlink: `ls -l ${RELDIR}/cmdstan`"

# cleanup
pushd -0 > /dev/null
dirs -c > /dev/null
echo ""
echo "CmdStan installation location: `ls -Fd ${RELDIR}/* | grep -v @ | grep -v gz`"
echo "Can use symlink: ${RELDIR}/cmdstan"