#!/usr/bin/env bash
#
# shellcheck disable=SC1091
run_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
fix_dir="${run_dir}/../../../fix"
#cmd="echo rm -rf"  # for dry run
cmd="rm -rf"  # remove excluded files/directories

"${run_dir}"/../init.sh

echo "First, remove the fix files/directories not needed by NCO (i.e. those listed in NCOnize_fix_files/exclude.txt) ......"
section_start=false
knt=0
while IFS= read -r line || [[ -n "${line}" ]]; do
  # strip leading/trailing whitespace
  line="${line#"${line%%[![:space:]]*}"}"   # leading
  line="${line%"${line##*[![:space:]]}"}"   # trailing

  if [[ -z "${line}" ]]; then  # empty line, section ends
    section_start=false
    if (( knt == 1 )); then  # only one line in this section, so remove the whole directory
      ${cmd}  "${fix_dir}/${header}"
    fi
    knt=0
  elif [[ ${line} == *: ]]; then # 4. line ends with ":", section starts
    header="${line%:}"
    section_start=true
    knt=1
  elif [[ ${line} != \#* ]]; then  # if not comments
    if ${section_start}; then
      ${cmd}  "${fix_dir}/${header}/${line}"
    fi
    ((knt++))
  fi
done < "${run_dir}/exclude.txt"

echo "Second, harden all links under the fix/ directory ......"
cd "${fix_dir}/.." || exit 1
set -x
pwd
rsync -aL --exclude ".agent" fix/ fix_NCO/
mv fix fix_old
mv fix_NCO fix
set +x

echo "Done!"
echo "Now the fix/ directory contains no links, and only files needed by NCO."
echo "The old fix/ directory is saved as fix_old/ for reference."
